# Data Model: 003 App 体验精修

演进自 001/002 的 drift schema（现 v2）。存储约定不变（见 tables.dart 头注：LocalDate→"YYYY-MM-DD"、枚举→.name、Instant→UTC ISO-8601）。本特性升 **schema v3**。

## 实体演进

### Goal（表 Goals，改造）

| 列 | 变更 | 说明 |
|---|---|---|
| id / name / createdAt / status | 不变 | name 语义升级为「一句话描述」（~40 字上限），无新列（research D8） |
| kind | **重映射为 goalType**（TEXT 枚举 `longTerm`/`shortTerm`/`habit`） | 旧值：habit/milestone。迁移规则见下 |
| deadline | 不变 | shortTerm 专属语义：倒计时 + 到期提醒；改值即「续期」 |
| **achievedAt** | **新增** TEXT Instant NULL | NULL=未达成；手动「标记达成」写入（research D4）。GoalStatus 保留 achieved 归档语义不动——achievedAt 是短期判定时间戳，两者职责分离 |
| iconKey | 语义切换 | 值域改为 GoalIconCatalog 的 key（Material rounded 策展，research D1）；迁移时旧值按映射表换新 |
| colorKey | **退役置 NULL** | 列保留（可空化迁移），任何界面不再读取 |
| motivation / successCriterion | 保留列、退出界面 | 退役字段保全（FR-016）；不再有写入路径 |
| cueScene | 保留 | 提醒文案语境；是否上编辑器分组由原型轮裁定 |

**类型迁移映射（v2→v3 一次性，research D3）**：

```text
kind=oneshot…（现库实为 habit/milestone 两值）
  ├─ deadline IS NOT NULL            → shortTerm
  ├─ 存在 daily/weekdays 频率版本     → habit（Reminders.cadence=daily，时间沿用现存 Reminder）
  ├─ 存在 weekly 频率版本             → habit（cadence=weekly）
  └─ 其余（milestone 无截止/无频率/暂停中）→ longTerm
```

（实际旧值域以 entities.dart 为准：`GoalKind { habit, milestone }`——milestone 有截止者归 shortTerm，habit 有节律者归新 habit，余归 longTerm。）

### Reminder（表 Reminders，加一列）

| 列 | 变更 | 说明 |
|---|---|---|
| goalId / time / isEnabled | 不变 | FR-013 的开关即 isEnabled |
| **cadence** | **新增** TEXT 枚举（取值 `daily`/`threeDay`/`weekly`） | 提醒频率档（一天/三天/一周一次）；NULL 视为 daily |

排程语义：cadence=daily → 每日 time；threeDay → 每 3 天自启用日起；weekly → 每周同 weekday。排程器（reminder_service）按档计算下一触发；关闭 isEnabled 即时取消未触发排程。

### SettingsRows（加两列，research D7）

| 列 | 变更 | 说明 |
|---|---|---|
| dailyBriefTime / onboardingCompleted / notificationDeniedAcknowledged | 不变 | |
| **nickname** | **新增** TEXT NULL | 默认「我」（呈现层兜底，不落库） |
| **avatarKey** | **新增** TEXT NULL | 8 枚预设头像 key（图标 + 令牌环）；NULL = 默认枚 |

### 停写保全（不删除、不再写入）

- `FrequencyVersions`：整表冻结（存量只读）；新目标不建频率版本
- `BusyModeSessions` / `BusyModeEntries`：002 已停用（忙碌移除），维持现状
- `WeeklyReviews`：快照 JSON 内含旧达标口径数据——历史快照不回写，新快照按记录口径生成

### 新增值对象（不落库）

- **NotificationItem**（推导，research D6）：`kind`（upcomingReminder/celebration/streak/deadlineAsk）+ `title` + `when` + `goalId?`。由 ①Reminders 排程 ②近 7 天 celebration/stats ③streak ④deadline≤今天且未 achieved 四源合成，时间倒序、按天分组，无已读态。
- **Profile**（VO）：`nickname` + `avatarKey`，读写 SettingsRows 单例行。
- **GoalIconCatalog**（常量）：领域（≥9 类）→ 图标 key 列表；key 即持久化的 iconKey 值域。

### 校验规则（承接 spec FR）

- goalType ∈ {longTerm, shortTerm, habit}；仅 shortTerm 允许 deadline 非空（表单保证）
- name 非空、≤40 字；创建流程无 motivation/successCriterion/频率问答写入路径
- cadence 三档（daily/threeDay/weekly）对习惯与长期目标的提醒均可用（长期默认关，开后同习惯档——见 goal-type-model 表）；shortTerm 的提醒为到期询问单次，cadence 不适用恒 NULL。约束由表单保证，库层不按类型校验
- 活跃目标上限 5（kMaxActiveGoals，001 FR-011）不变，类型不分摊

### 状态迁移（Goal 生命周期）

```text
active ⇄ paused（既有）
active → achieved：用户手动「标记达成」（写 achievedAt；短期主路径，任何类型可用）
（截止日到点不改变状态——仅发提醒 + 通知列表出现询问项，research D4）
archived：既有归档语义不变
```

## 备份格式（v3，详见 contracts/backup-format.md）

schemaVersion 3；goals +goalType/+achievedAt、reminders +cadence、settings +nickname/+avatarKey；未知字段忽略、缺失取默认——v2 文件导入走 D3 同款映射，v3 文件被旧版本读取时基础字段完整可用。

## 迁移测试口径

四分支存量各造一条（milestone+截止 / habit+daily / habit+weekly / 暂停 milestone）→ 升级后：目标/打卡/补签计数逐项一致、类型符合映射、今日页全部可见可打卡、旧字段（频率/颜色/为什么/怎样算）零上屏。
