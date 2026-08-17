# Data Model: 生活目标守护 iOS App（Target）

**Feature**: `specs/001-life-goal-tracker` | **Date**: 2026-08-18
**依据**: [spec.md](./spec.md) Key Entities + FR 全量 + [research.md](./research.md) D6/D7/D9/D10/D11

模型分两层：**领域模型**（`lib/core/models/`，纯 Dart，无 Flutter/平台依赖，统计引擎的输入）与 **drift 持久化 schema**（`lib/core/db/`，与领域模型一一映射；iOS 上数据库文件位于 App Group 容器目录）。本文档定义领域模型；持久化层仅做存储映射，不添加业务规则。

## 通用值类型

```text
LocalDate     = 无时区的日历日（YYYY-MM-DD）。打卡归属、周期计算均用此类型；
               由时间戳经设备本地时区换算为自然日，跨天归属以此为准
LocalTime     = 无时区时刻（HH:mm），提醒与每日概要用
WeekStart     = LocalDate 的受限子集：必须是周一（周一至周日周期的锚点）
```

```text
FrequencyPattern（习惯频率）
├── daily(targetPerDay: Int)            # 每天 N 次（N ≥ 1）
├── weekly(timesPerWeek: Int)           # 每周 N 次，日分布自由（适用日=由打卡定义）
└── weekdays(days: Set<Weekday>, targetPerDay: Int)  # 指定星期几，每天 N 次

适用日(d) 规则：daily → 每天适用；weekdays → d.weekday ∈ days；weekly → 自由分布（见统计契约）
```

## 实体

### Goal（目标）

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| id | UUID | 主键 |
| name | String | 1–30 字，非空 |
| kind | `habit \| milestone` | 创建后不可变更 |
| iconKey / colorKey | String | 取自设计令牌表（非自由值），v1 内置集合 |
| status | `active \| paused \| archived \| achieved` | 默认 active |
| createdAt | LocalDate | 创建当日 |

**约束与状态机**：
- 活跃上限：`status == active` 的目标（两类合计）≤ 5（FR-011）；超限时创建被拒并触发聚焦引导
- 状态迁移：`active ⇄ paused`（FR-009，暂停不出现在今日视图、不计入完成率分母与电量）；`active → achieved`（仅 milestone，全部步骤完成或手动）；`active/paused → archived`（终态，历史数据保留，FR-010）
- 删除即归档：不提供物理删除，历史打卡与周回顾不回溯篡改

### FrequencyVersion（习惯频率版本）— 见 research D7

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| id | UUID | 主键 |
| goalId | UUID | 所属 habit 目标 |
| effectiveFromWeek | WeekStart | 该版本自哪个周一生效 |
| pattern | FrequencyPattern | 见上 |
| source | `initial \| userEdit \| busyMode` | 来源标记 |

**规则**：
- 任一日 d 的有效频率 = `effectiveFromWeek ≤ d 所在周` 中 `effectiveFromWeek` 最大的版本
- 用户编辑频率 → 追加 `source=userEdit, effectiveFromWeek=下一周一`（FR-002：当前周仍按旧口径）
- 同一目标同一 `effectiveFromWeek` 至多一个非 busyMode 版本（重复编辑即覆盖该周的待生效版本）
- busyMode 版本与用户版本可并存于不同周；**恢复忙碌模式 = 移除该 busyMode 版本**（回落到既有版本），FR-018
- milestone 目标无频率版本

### BusyModeSession（忙碌模式会话）— FR-018

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| id | UUID | 主键 |
| weekStart | WeekStart | 覆盖的自然周 |
| entries | [(goalId, downgraded: FrequencyPattern)] | 参与降档的目标与降档频率（≥1 个） |
| startedAt / endedAt | Instant? | endedAt 非空 = 已恢复 |

**规则**：开启 = 创建会话 + 为每个 entry 插入 `source=busyMode` 的本周频率版本；恢复 = 置 endedAt + 移除对应 busyMode 版本；同一目标同一周至多一个 busyMode 版本；今日视图与周回顾期间呈现"忙碌模式"标注。

### CheckIn（打卡记录）— FR-004/005

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| id | UUID | 主键 |
| goalId | UUID | 所属 habit 目标 |
| day | LocalDate | 归属自然日（本地时区；补签=过去任意日期） |
| createdAt | Instant | 实际操作时刻 |
| isBackfill | Bool | `day < 操作日` 时必为 true（"补"标记） |
| status | `valid \| revoked` | 撤销=置 revoked，不物理删除 |

**规则**：
- 当日可多次（每日 N 次，FR-002），`(goalId, day)` 不唯一，次数即该日 valid 记录数
- 当日有效次数 ≥ 当日目标次数 → 当日达标；超额计入累计次数、当日完成度封顶 100%（Clarifications）
- 补签：任意过去日期，标记"补"、可撤销、计入该日统计；周回顾呈现当期补签次数
- 撤销即时回退连击/完成率（SC-003：统计与记录 100% 一致）

### MilestoneStep（里程碑步骤）— FR-013

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| id | UUID | 主键 |
| goalId | UUID | 所属 milestone 目标 |
| title | String | 1–50 字 |
| isDone / doneAt | Bool / Instant? | 可回退（误点） |

**规则**：进度 = done/total；全部完成 → 目标可一键 `achieved`；截止日期存于 Goal 侧扩展字段 `deadline: LocalDate?`（仅 milestone 有值，倒计时 = deadline − 今天）。

### Reminder（提醒）— FR-006

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| id | UUID | 主键 |
| scope | `goal(goalId) \| dailyBrief` | 目标提醒 / 全局每日概要 |
| time | LocalTime | 触发时刻 |
| isEnabled | Bool | 默认 true |

**规则**：dailyBrief 默认 08:00（设置可改）；周一晨的 dailyBrief 附带周回顾引导（FR-008）；当日已达标的目标不发催促——构建通知时查询当日状态后裁剪（FR-006）；通知未授权 → 全功能可用、不报错（FR-007）。

### WeeklyReview（周回顾）— FR-008、research D11

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| id | UUID | 主键 |
| weekStart | WeekStart | 结算的那一周（周一） |
| settledAt | Instant | 周一晨结算时刻 |
| snapshot | [GoalWeekStat] | 结算时快照（下方） |
| note | String? | 用户反思笔记 |
| decision | `continue_ \| adjust(FrequencyPattern) \| pause` | 下周决定 |

```text
GoalWeekStat（快照行）
├── goalId
├── applicableDays: Int      # 该周适用日数（按当周有效频率；weekly=7 自由分布口径见统计契约）
├── metDays: Int             # 达标日数
├── completionRate: Double   # metDays / applicableDays（无适用日 → 不呈现，非 0）
├── backfillCount: Int       # 当期补签次数（透明呈现）
└── busyModeApplied: Bool    # 该周是否经历忙碌降档
```

**规则**：周一晨（dailyBrief 前）自动结算上一周并存档快照；回顾页展示时**实时重算**当前值（补签可改写历史），快照仅留痕；`decision=adjust` → 生成下周的 `userEdit` 频率版本；`decision=pause` → 目标置 paused。

### Settings（单例）

| 字段 | 类型 | 规则 |
| ---- | ---- | ---- |
| dailyBriefTime | LocalTime | 默认 08:00 |
| onboardingCompleted | Bool | 首启引导（含模板建目标，SC-001） |
| notificationDeniedAcknowledged | Bool | 权限被拒说明已展示 |

## 派生值（不落库，统计引擎纯函数输出）

| 派生值 | 定义 | 出处 |
| ---- | ---- | ---- |
| 当日完成度 | `min(valid 次数 / 当日目标次数, 1)`；weekly 自由分布见统计契约 | FR-002 |
| 连击 streak | 连续"适用日且达标"天数，非适用日跳过不断链（research D10） | FR-005 |
| 周完成率 | GoalWeekStat 同口径，实时版 | FR-008 |
| 生活电量 | `mean(活跃 habit 目标当日完成度) × 100`；里程碑不计入；无活跃 habit → 空态 | FR-017、research D9 |
| 里程碑进度/倒计时 | done/total；`deadline − today` | FR-013 |

## 关系总览

```text
Goal 1─n FrequencyVersion（habit）
Goal 1─n CheckIn（habit）
Goal 1─n MilestoneStep（milestone）
Goal 1─1 Reminder（scope=goal 时）
Goal 1─n GoalWeekStat（经 WeeklyReview.snapshot）
BusyModeSession n─n Goal（经 entries，落地为 busyMode 频率版本）
WeeklyReview 1─n GoalWeekStat
```

## 备份映射

全部实体 + Settings 序列化为单一 JSON（版本化），字段与上表一一对应；格式契约见 [contracts/backup-format.md](./contracts/backup-format.md)。
