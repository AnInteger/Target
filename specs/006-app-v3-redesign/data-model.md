# 006 数据模型 · schema v8（清库重建）

- 存量不迁移（D10）：`schemaVersion` 升 v8，onUpgrade/onCreate 直接重建库。
- 备份格式 **v7**：仅新格式导出/导入；v1–v6 文件不再支持（导入器删除宽容链）。

## 1. 表结构（全新）

### Goals

| 列 | 类型 | 说明 |
|---|---|---|
| id | TEXT PK | |
| name | TEXT | 必填 ≤40 字 |
| why | TEXT NULL | 为什么想做（≤60 字；原 motivation 语义） |
| categoryKey | TEXT NULL | 分类键（目录内置；NULL=未分类） |
| iconKey | TEXT | 图标（38 枚目录） |
| colorKey | TEXT | 颜色（iOS 8 色板键；默认=分类默认色） |
| pinned | BOOL | 置顶（默认 false） |
| pinnedOrder | INT NULL | 置顶组内排序（仅置顶目标有值） |
| targetDate | TEXT NULL | 目标日期（YYYY-MM-DD） |
| frequencyPattern | TEXT NULL | 执行节奏 JSON（沿用 frequency_pattern.dart 编码） |
| status | TEXT | active|paused|achieved|archived |
| achievedAt | INSTANT NULL | 手动标记达成时间 |
| archivedAt | INSTANT NULL | 归档时间 |
| createdAt | DATE | |

（goalType/colorKey 旧列、progressCadenceDays、habitTargetPerWeek、
categoryOverride、cueScene、successCriterion、deadline 全部不建。）

### ProgressRecords（替代 CheckIns）

| 列 | 类型 | 说明 |
|---|---|---|
| id | TEXT PK | |
| goalId | TEXT FK→Goals | |
| title | TEXT | 必填 ≤40 字 |
| body | TEXT NULL | 正文/心得 ≤500 字 |
| durationMinutes | INT NULL | 投入时长 |
| day | DATE | 记录归属日 |
| createdAt | INSTANT | 创建时刻（补记=补的时刻） |
| isBackfill | BOOL | day < 创建日当天 |
| kind | TEXT | normal \| milestoneAchievement |
| milestoneId | TEXT NULL | FK→Milestones（关联/达成事件） |

### Milestones（由 MilestoneSteps 更名迁移语义，全新建表）

| 列 | 类型 | 说明 |
|---|---|---|
| id | TEXT PK | |
| goalId | TEXT FK | |
| title | TEXT | |
| description | TEXT NULL | 达成时是什么样（≤60 字） |
| position | INT | 排序；第一条未达成 = 下个路标 |
| isDone | BOOL | |
| doneAt | INSTANT NULL | 达成时刻（同时生成达成记录） |

### Reminders（保留结构）

| 列 | 类型 | 说明 |
|---|---|---|
| id / goalId / time / isEnabled / cadence | | cadence: daily\|threeDays\|weekly（NULL=daily） |

### SettingsRows（单例）

| 保留 | 新增/变化 |
|---|---|
| id, dailyBriefTime→**删除** | nickname, avatarKey |
| notificationDeniedAcknowledged | remindersEnabled（全局总开关，默认 true） |
| themeMode | 删除：onboardingCompleted、scoreAlgorithmStartedOn、defaultShort/LongCadenceDays |

**不建表**：WeeklyReviews、FrequencyVersions、BusyModeSessions、BusyModeEntries。

## 2. 派生与聚合（stats_engine v3 全新实现）

- `weekInvestment(weekStart)` → { totalMinutes, recordCount, perDay[7] }（分钟；无时长记录计入 recordCount 不计入 minutes）。
- `milestoneSummary(weekStart)` → { achievedThisWeek, pendingAll }。
- `dailyInvestment(month)` → [{day, minutes, recordCount}]（日历视图数据源；环填充 = minutes / 月峰值）。
- `activityFeed({range, goalId?})` → 记录+达成事件混排时间倒序。
- 旧评分/健康分/advice/连击/周结算 API 全部不保留。

## 3. 备份格式 v7

```json
{
  "format": "target-backup",
  "version": 7,
  "exportedAt": "<ISO-8601 UTC>",
  "settings": { "nickname": null, "avatarKey": null, "themeMode": null,
                "remindersEnabled": true },
  "goals": [{
    "id": "…", "name": "…", "why": null, "categoryKey": "fitness",
    "iconKey": "pool", "colorKey": "blue", "pinned": true, "pinnedOrder": 0,
    "targetDate": null, "frequencyPattern": null, "status": "active",
    "achievedAt": null, "archivedAt": null, "createdAt": "2026-09-01",
    "milestones": [{ "id": "…", "title": "…", "description": null,
                     "position": 0, "isDone": false, "doneAt": null }],
    "reminders": [{ "id": "…", "time": "08:30", "isEnabled": true, "cadence": "daily" }],
    "records": [{ "id": "…", "title": "…", "body": null, "durationMinutes": 30,
                  "day": "2026-09-07", "createdAt": "<ISO>", "isBackfill": false,
                  "kind": "normal", "milestoneId": null }]
  }]
}
```

- 导出/导入全字段往返一致（逐字段断言，沿用 backup_test 口径）。
- 恢复到非空库：显式确认 → 覆盖（事务重建）。
- 旧 version≤6 文件：导入报「不支持的备份版本」。

## 4. 分类目录（内置常量）

| key | 名称 | 默认色 |
|---|---|---|
| fitness | 运动与健康 | blue |
| learning | 学习与成长 | orange |
| language | 语言学习 | green |
| create | 创作与表达 | purple |
| life | 生活方式 | teal |
| mind | 身心与冥想 | indigo |
| finance | 理财 | green→teal 择一（实现期令牌对齐后冻结） |
| social | 社交与关系 | pink |
| travel | 旅行与探索 | teal |
| pets | 宠物 | orange |
| other | 其他 | gray（on-surface-variant 级） |

分类名沿用图标十域语义重组为用户语；iconKey 域 → 分类建议（不静默决定，
沿用 2026-08-26 §10 边界）。
