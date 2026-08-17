# Contract: 备份文件格式（`.targetbackup`）

**消费方**: 设置页导出/导入（FR-015）| **性质**: 单个 JSON 文件，版本化 schema

## 文件结构

```json
{
  "format": "target-backup",
  "version": 1,
  "exportedAt": "2026-08-18T08:00:00+08:00",
  "data": {
    "goals":             [ { ...Goal }, ... ],
    "frequencyVersions": [ { ...FrequencyVersion }, ... ],
    "busySessions":      [ { ...BusyModeSession }, ... ],
    "checkIns":          [ { ...CheckIn }, ... ],
    "milestoneSteps":    [ { ...MilestoneStep }, ... ],
    "reminders":         [ { ...Reminder }, ... ],
    "weeklyReviews":     [ { ...WeeklyReview }, ... ],
    "settings":          { ...Settings }
  }
}
```

- 字段与 [data-model.md](../data-model.md) 实体一一对应；`LocalDate` → `"YYYY-MM-DD"`，`LocalTime` → `"HH:mm"`，`Instant` → ISO 8601
- 数组可为空（`[]`），不可缺键——缺键 = 文件损坏

## 导出（Export）

- 设置页一键触发 → 序列化全量实体 → 经系统分享面板保存/转发
- 文件名：`Target-备份-YYYYMMDD.targetbackup`
- 自定义 UTType（`com.target.backup`, conforms to `public.json`）

## 导入（Import）

1. 文件选择器（限定 `.targetbackup`）→ 解析
2. **校验**：`format == "target-backup"`；`version` 受支持；schema 逐实体校验（字段缺失/类型错误 → 明确报错，不部分导入）
3. **冲突**：本地已有数据 → 弹窗"覆盖本地 / 取消"，**不得静默合并**（FR-015）
4. 覆盖 = 原子替换整个 store（先写临时副本，成功后切换），导入完成后展示核对摘要（各实体记录数）

## 版本迁移

- `version` 仅增不改；未来版本提供 `1 → N` 链式迁移后再校验
- 不认识的更高版本 → 拒绝导入并提示升级应用

## 隐私

文件含全部个人数据、无加密（v1）；导出分享行为由用户主导，产品内在设置页与首启说明中明示"备份文件包含全部目标数据"。
