# Data Model: UI/UX 全面重设计（原型先行）

本特性以表现层为主，持久化变更仅一处（Goal 定义模型扩展），其余"实体"为设计资产与流程记录（不入库）。数据库为 Drift（`lib/core/db/tables.dart`），当前 schemaVersion 见 `app_database.dart`。

---

## 1. Goal（持久化实体，扩展）

既有字段不动：`id / name / kind(habit|milestone) / iconKey / colorKey / createdAt / deadline / status / ...`。

### 新增候选字段（迁移 envelope，全部可空）

| 字段 | 语义 | 校验规则 | 最终去留 |
|---|---|---|---|
| `motivation` | 动机——"为什么做"（一句话） | ≤60 字；空=未填写 | 原型评审定 |
| `success_criterion` | 成功标准——"做成什么样算数"（对既有 SMART 机制的模型化承载） | ≤60 字；与 name 联动展示 | 原型评审定 |
| `cue_scene` | 提示场景/提醒时机——"什么时刻该想起它"（FR-012：入选后驱动该目标的提醒时刻，空值回落默认时段并做打扰合并） | ≤40 字 | 原型评审定 |

> 候选集来自 spec FR-010；`screen-editor.html` 将以 2–3 个组合方案呈现，用户选定后**只实现选中的字段**，未选字段不入库。无论选哪个组合，迁移形态不变（可空 `ADD COLUMN`）。

### 迁移规则

- `schemaVersion` 递增 1；`MigrationStrategy.onUpgrade` 对 goal 表逐列 `ALTER TABLE ... ADD COLUMN <col> TEXT NULL`
- 既有行零改动（新列自然为 NULL）→ **零丢失**（FR-005）
- 降级路径不存在（单机 App，不回滚二进制）
- 备份格式：JSON 增加上述可选键；导入时缺失键按 NULL 处理（向后兼容 001 备份文件）

### 状态与展示联动（新维度的 UI 语义）

- `motivation` 为空的既有目标：今日屏/详情展示"渐进补全"入口（不强制填写，edge case 约定）
- `success_criterion` 非空时，打卡确认反馈优先展示该文案（替代通用文案）

## 2. DesignToken（设计资产实体，非持久化）

单一来源：`design/tokens.css`（原型期）→ `lib/app/design_tokens.dart`（定稿后真源）。结构（详见 [contracts/design-language.md](contracts/design-language.md)）：

- **语义色**：background / surface / surfaceAlt / onSurface / onSurfaceVariant / accent / accentOn / positive / warning / divider（浅/深成对）
- **目标色板**：既有 8 色（coral…stone）按新语言校准后保留键名（iconKey/colorKey 存储值不变 → 既有数据无需迁移）
- **字阶**：displayLarge…labelSmall 九档（字号/行高/字重/字距），数字启用 tabular figures
- **间距刻度**：4 的倍数（4/8/12/16/24/32/48）
- **圆角**：sm/md/lg/xl/full 五档
- **阴影/高度**：3 档（低/中/高），深色模式用表面亮度差替代阴影
- **动效**：时长（fast 150ms / base 250ms / slow 450ms / celebration 1200ms）+ 标准缓动曲线

**校验**：`test/design/token_contract_test.dart` 扫描断言 features/app 层无硬编码样式（SC-004 机械化）。

## 3. ScreenInventory（验收清单实体，文档载体 `design/prototypes/index.html`）

| # | 屏幕 | 路径（现状） | 重设计要点 | 状态维度 |
|---|---|---|---|---|
| 1 | 今日视图 | `lib/features/today/today_view.dart` | 首屏总览、≤2 交互打卡、仪式感反馈、成就时刻 | 空/有目标/全完成/深色（忙碌态 2026-08-21 裁决移除） |
| 2 | 目标列表 | `lib/features/goals/goals_view.dart` | 信息层级、生命周期操作 | 空/多目标/暂停态 |
| 3 | 目标编辑器 | `lib/features/goals/goal_editor.dart` | **定义模型候选对比**、模板路径、SMART 内联；单一"目标"概念、无前置类型分叉（FR-011，`milestones/` 并入统一语言） | 创建/编辑/频率变更提示 |
| 4 | 周回顾 | `lib/features/review/review_view.dart` | 数据→生活语言、图形化趋势、决策 ≤3 步 | 有/无数据、低于阈值教练建议 |
| 5 | ~~忙碌模式~~（2026-08-21 用户裁决全 App 移除，见 T022 改写） | `lib/features/busy_mode/busy_mode_view.dart` | 移除：路由/入口/今日屏分支/徽标/降档语义 | — |
| 6 | 补签日历 | `lib/features/today/backfill_calendar.dart` | "补"标记视觉不混淆 | 14 天窗口 |
| 7 | 设置 | `lib/features/settings/settings_view.dart` | 分组、备份入口、通知文案与时机（FR-012） | 深色/占位项 |
| 8 | 品牌素材 | iOS 图标/启动屏/小组件 | 全套品牌（FR-008，名称 Target） | 浅/深系统外观 |

## 4. PrototypeReviewRecord（流程实体，`design/reviews.md`）

- 字段：屏/方向标识、评审轮次、日期、用户意见（原话）、结论（通过 / 修改后再审）、修订说明
- 规则：FR-001 门禁的执行载体——某屏最新结论为"通过"前，该屏不得进入 Flutter 实现；`index.html` 汇总各屏状态

## 关系图（文字）

```
DesignToken ──(真源翻译)──> design_tokens.dart ──(镜像)──> DesignTokens.swift (小组件)
     │                            │
     └── tokens.css ──> HTML 原型 ──评审──> PrototypeReviewRecord ──门禁──> Flutter 落地
Goal(既有) ──可空增量迁移──> Goal(+motivation/+success_criterion/+cue_scene)
```
