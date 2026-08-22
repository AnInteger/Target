# Data Model: 004 UI v2 重构

演进自 003 完结态 drift schema（现 **v4**）。存储约定不变（tables.dart 头注：LocalDate→"YYYY-MM-DD"、枚举→.name、Instant→UTC ISO-8601）。本特性升 schema **v5**（仅 Settings 一列）。**核心原则：UI 重构尽量零落库**——三大类映射与健康度全部运行时派生，唯一持久化新增是主题偏好。

## 实体演进

### Settings（表 SettingsRows，加一列 → schema v5）

| 列 | 变更 | 说明 |
|---|---|---|
| **themeMode** | **新增** TEXT 枚举 `system`/`light`/`dark`，NULL | NULL = 跟随系统（= 003 完结态行为，存量用户零感知）；「我的」页三档单选写入；MaterialApp `themeMode` 消费 |
| 其余列 | 不变 | dailyBriefTime / nickname / avatarKey / onboardingCompleted / notificationDeniedAcknowledged |

迁移：纯 ADD COLUMN（沿 003 T044 惯例，无数据改写）；备份文件同步新增可选键 `themeMode`（缺失→NULL，双向宽容——沿 T044 note 先例）。

### Goal / CheckIn / Reminder / MilestoneStep / WeeklyReview / BusyMode*

**全部不变**。推翻范围是呈现与交互层（spec 2026-08-23 裁决），数据模型无涉及；`colorKey` 列继续保留不读（003 已退役），004 起连 `GoalColor` 枚举一并删除（D1）。

## 新增派生模型（零落库）

### MajorCategory（新枚举，纯代码）

```text
MajorCategory { health(健康), habit(习惯), goal(目标) }
```

三大类各持一色（D1 入 palette）；中文界面名取 zhLabel。

### 大类-小类静态映射（GoalIconDomain.major，D4）

| 大类 | 领域（小类） | 依据 |
|---|---|---|
| 健康 health | 运动 fitness、健康 health、冥想 mind、**社交 social**、**宠物 pets** | 前三项为 2026-08-23 spec 裁决；social/pets 为库内后增领域，2026-08-23 clarify 用户裁定归健康（推翻 plan 原拟「习惯」） |
| 习惯 habit | 生活 life | spec 裁决 |
| 目标 goal | 学习 learning、创作 create、旅行 travel、理财 finance | spec 裁决 |

- 挂载点：`GoalIconDomain` 枚举属性 `major`；`Goal.majorOf = GoalIconCatalog.byKey(iconKey).domain.major`
- 未匹配 iconKey 兜底 `explore`（创作域→大类「目标」），沿既有 byKey 兜底
- **零迁移**：领域本就由 iconKey 运行时派生，无存储变更

### HealthScore（三大类健康度，纯派生，D3）

| 项 | 定义 |
|---|---|
| 窗口 | 含今日的滚动 7 天（`today-6 … today`） |
| 零记录目标 | 该目标在窗口内**无任何 CheckIns 行**（打卡与补签同计，一行即非零；不看 status 字段） |
| 参与集合 | `Goal.status == active` 且非暂停的全部目标（暂停不扣分） |
| 类分 | `(100 − 3 × 该类零记录活跃目标数).clamp(0, 100)` |
| 无数据态 | 类内零活跃目标 → 该环无数据呈现（非满分非 0） |
| 复算时机 | goals/checkIns 任一流变化（打卡、补签、暂停/恢复、删除自动触发）；纯函数可全量单测对账 |

### 周统计（回顾页三区块，纯派生，D9）

| 指标 | 口径 |
|---|---|
| 周完成率 | 周内活跃目标「已记日 / 应记日」均值（沿用现有 stats 层 GoalWeekStat 实时派生，不读 WeeklyReviews 快照） |
| 逐日完成度 | 当日有记录目标数 / 当日活跃目标数（周一…周日圆点） |
| 环比 | 本周完成率 − 上周完成率；上周零应记 → 「无可比较」 |
| 未来日 | 不呈已完成态 |
| 周切换 | WeekStart 参数化，往周实时派生 |

### 关注卡序（纯派生，沿 spec Q2 裁决）

`max(目标最新 CheckIn.createdAt, goal.createdAt)` 降序；仅 active；首卡 = 最近互动目标，不记忆滑动位置。

## 值域冻结提醒

- `themeMode` 值域三枚即冻结（备份兼容层同 T044：未知值→system）
- MajorCategory 键名 `health`/`habit`/`goal` 冻结（未来若上小组件/导出，以此为持久化键）
