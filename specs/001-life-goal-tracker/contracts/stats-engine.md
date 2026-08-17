# Contract: 统计引擎（Stats Engine）

**位置**: `lib/core/stats/`（纯 Dart，无 Flutter/平台依赖） | **性质**: 纯函数，时钟注入
**消费方**: 今日视图、周回顾、生活电量、小组件快照、通知裁剪、单元测试

统计引擎是本产品口径规则的唯一事实来源（single source of truth）——**所有"数字"都从这里出**，界面不得自行计算。

## 输入

```text
StatsEngine.evaluate(
  goals: [Goal],                  // 含 status
  frequencyVersions: [FrequencyVersion],
  busySessions: [BusyModeSession],
  checkIns: [CheckIn],            // 全量（引擎内部按需过滤）
  today: LocalDate,               // 注入的"今天"（由注入时钟换算，设备本地时区）
)
```

## 输出

```text
DayStatus(goalId)      → applicable: Bool, targetCount: Int, doneCount: Int,
                         met: Bool, backfilledCount: Int, busyMode: Bool
Streak(goalId)         → days: Int                // 口径见下
WeekStats(goalId, week)→ GoalWeekStat（实时版）    // 快照结构同 data-model
LifeBattery            → percent: Int?            // nil = 空态（无活跃 habit）
```

## 口径规则（每条对应一条测试）

| # | 规则 | 出处 |
| - | ---- | ---- |
| R1 | 自然日按设备本地时区 `startOfDay` 换算；23:59 与 00:01 分属两日 | spec Edge Cases |
| R2 | 周 = 周一至周日；`effectiveFromWeek ≤ 目标周` 的最新版本即该周有效频率 | FR-002、D7 |
| R3 | 当日完成度 = `min(valid 次数 / 当日目标次数, 1)`；超额计入累计、完成度封顶 | Clarifications |
| R4 | `daily`/`weekdays` 的适用日由模式直接给出；**`weekly(N)` 的适用日 = 该周全部 7 天，达标口径 = 周内达标日数 ≥ N 时全周达标、逐日呈现"周进度 k/N"** | FR-002 |
| R5 | 连击 = 截至今天连续"适用日且达标"天数；非适用日跳过不断链；今天未达标不 retro 扣（连击截至昨天） | FR-005、D10 |
| R6 | 补签（isBackfill）计入其 `day` 的统计，可将断链接回；`backfillCount` 在周回顾如实呈现 | FR-004 |
| R7 | 撤销（revoked）记录不计入任何统计；撤销后连击/完成率即时回退 | FR-004、SC-003 |
| R8 | 忙碌模式周按 busyMode 版本口径结算，`busyModeApplied = true` | FR-018 |
| R9 | 生活电量 = `mean(活跃 habit 当日完成度) × 100`；里程碑与 paused 目标不计入；无活跃 habit → nil（空态） | FR-017、D9 |

## 周结算（WeeklyReview 生成）

- 触发：周一晨（结算"上一周"），存快照 `snapshot = WeekStats(...)`；回顾页展示用实时重算（D11）
- 完成率 < 50% 的目标 → 回顾页呈现调整选项（降频/暂停/拆小），文案走"教练式"文案表（FR-008）

## 一致性保证

- 引擎输出与原始 CheckIn 100% 可核对（SC-003）：任何界面显示的数字必须能由 `evaluate` 复现
- 引擎不写库、无副作用；仓库层（drift）负责把 CheckIn/Goal 变更转发给引擎重算，经 Riverpod 流刷新 UI、并重写小组件快照（research D13）
