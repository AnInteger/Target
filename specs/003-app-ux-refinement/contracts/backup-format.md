# Contract: 备份格式 v3

演进自 001 backup-format（当前 v2）。目标：v2/v3 双向可读（spec 边界用例）、零丢失（FR-016）。

## 变更清单（相对 v2）

| 区块 | 变更 |
|---|---|
| 顶层 `schemaVersion` | 2 → 3 |
| goals[] | + `goalType`（longTerm/shortTerm/habit）；+ `achievedAt`（ISO Instant \| null）；`iconKey` 值域换 GoalIconCatalog key；`colorKey` 导出为 null（列退役）；`motivation/successCriterion/cueScene` 照旧导出（保全） |
| reminders[] | + `cadence`（daily/threeDay/weekly \| null=daily） |
| settings | + `nickname`、`avatarKey` |
| frequencyVersions[] | 照旧导出（停写保全，导入后仍可被旧口径读取） |

## 宽容解析规则（双向）

- **新读旧（v3 App ← v2 文件）**：goalType 缺失 → 按 data-model.md 迁移映射重推导（有截止→shortTerm；有 daily/weekdays/weekly 节律→habit；余→longTerm）；cadence 缺失 → daily；nickname/avatarKey 缺失 → 默认
- **旧读新（v2 App ← v3 文件）**：未知字段忽略（001 既有宽容策略），goalType/achievedAt/cadence 丢弃后按 v2 语义可用（kind 由频率版本推导，与 D3 映射互逆）
- 任一方向导入后：目标/打卡/记录/补签计数逐项一致（V7 回归 + 迁移对账用例）

## 导出触发

我的页 → 数据分组 → 备份与导出（入口位置变化，能力与文件命名习惯不变）。
