# Contract: 目标类型 × 打卡 × 统计口径

三类型模型的行为契约（承接 spec 澄清 Q1/Q2 与 research D2/D4）。统计引擎（stats_engine）本特性后只生产本表口径，旧「适用日/达标判定」输出停用。

## 类型定义

| 类型 | 语义 | 截止 | 提醒默认 | 今日呈现 | 完成判定 |
|---|---|---|---|---|---|
| habit 习惯 | 日常节律（一天/三天/一周一次） | 无 | 开关 + cadence + time（FR-013） | 节律点徽章 + 0→1 环 | 不完结（持续型） |
| shortTerm 短期 | 有日子的冲刺（考证/装机/徒步） | 必填 | 到期前提醒 + 到期询问 | 倒计时 chip + 0→1 环 | 手动「标记达成」或续期（FR-018） |
| longTerm 长期 | 长线坚持（大 PRO 计划） | 无 | 可选提醒（默认关） | ∞ 语标 + 0→1 环 | 手动「标记达成」可选 |

三类型均打卡（Q1 裁定）；今日页不按类型过滤。

## 打卡口径（D2）

- 打卡 = 一条 CheckIns 记录（既有实体不变：goalId/day/status/isBackfill）
- 今日环：`当日有效打卡数 ≥ 1` → 满（0→1 封顶）；per-day N 次目标口径退役
- 撤销/补签路径与语义完全不变（V5 回归底线）

## 统计输出口径（stats_engine 收敛后）

| 输出 | 定义 | 消费方 |
|---|---|---|
| streak 连续记录 | 自今日（或昨日）回溯的连续留痕天数（任一目标层面=总 streak；单目标层面=该目标 streak） | 今日页头部语、通知列表里程碑 |
| 周留痕 | 周内 ≥1 次打卡的天数（总/单目标） | 回顾页节奏条（R3 语言不变） |
| 周记录数 | 周内打卡总次数 | 回顾页周摘要 |
| 全完成日 | 当日全部活跃目标均留痕 | celebration 成就时刻（既有）、通知列表 |

停用输出：适用日/达标日/达标率（FrequencyPattern.isApplicableOn 退出调用图）。

## 提醒排程（Reminders.cadence）

```text
cadence=daily   → 每日 time
cadence=threeDay → 自启用日（最近一次打卡或创建日）起每 3 天 time
cadence=weekly  → 每周同 weekday 的 time
isEnabled=false → 即时取消未触发排程，历史不受影响
短期到期询问   → deadline 当日 time（默认 09:00）单次；「到日子了，怎么样？」
```

排程器输入唯一真源 = Reminders 行；cueScene 非空时通知正文附场景语境（既有 T027 语言）。

## 短期生命周期（D4）

```text
active --手动标记达成--> achieved（写 achievedAt）
active --改 deadline--> active（续期，倒计时重置；通知列表询问项消失）
deadline 到点：状态不变，仅 提醒 + 通知列表询问项；超期未处理持续显示超时提示，不自动归档
```
