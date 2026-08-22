# Implementation Plan: App 体验精修（三 Tab 收敛 + 编辑器重构）

**Branch**: `003-app-ux-refinement` | **Date**: 2026-08-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-app-ux-refinement/spec.md`

## Summary

真机四屏反馈驱动的一次结构性精修：(1) 信息架构从四页签收敛为 今日/回顾/我的 三页签，目标页职能并入今日页卡与详情动线；(2) 今日页头部重组——同图层无分隔线、左上账号区（本地资料）、右上铃铛改应用内通知列表（推导式），通知设置迁我的页；(3) 新建/编辑器重构——进 today 分支保留底部导航、分组折叠表单、目标类型改 长期/短期/习惯（删除频率问答）、描述一句话、提醒开关化（一天/三天/一周一次 + 时间）、Material 圆角图标库选图标、颜色退场；(4) 回顾页空态居中可跳新建 + 三屏标题对齐；(5) 我的页按主流设置结构重组；(6) schema v3 迁移零丢失（旧频率→三类型映射、退役字段保全不上屏）。工作流沿用 002 惯例：HTML 原型先行送审 → 通过后动 Flutter。

## Technical Context

**Language/Version**: Dart ^3.13 / Flutter 3.47.0

**Primary Dependencies**: 既有——flutter_riverpod ^2.6、drift ^2.34、go_router ^17.5（StatefulShellRoute.indexedStack）、flutter_local_notifications ^22、home_widget ^0.9、share_plus/file_picker（备份）。**本特性零新增依赖**（目标图标用 Flutter 内置 Material rounded 变体，见 research D1）

**Storage**: drift 单机库，本特性升 schema v2 → v3（goals 重映射 + 新列，见 data-model.md）

**Testing**: flutter_test——既有 69 用例为回归底线；新增迁移对账用例（旧库→三类型）、类型×提醒行为、通知列表推导、路由结构断言

**Target Platform**: iOS 18+（真机为最终验收面）；Web 为本地全功能验证面（002 验证技巧延续）

**Performance Goals**: 打卡主路径 ≤2 次交互不变；创建习惯目标 ≤8 次交互；滚动 60fps 无图层跳变

**Constraints**: 离线单机、无后端（账号区仅本地资料）；免版权图标资产；既有数据零丢失

**Scale/Scope**: 单用户；目标数十量级；改动面 = 路由壳层 + 四屏视图 + 编辑器 + 设置 + 迁移 + 统计口径收敛

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` 存在但为未填充的模板占位（无任何已生效原则）——无门禁可评，视为通过。项目实际沿用的治理约束来自 001/002 规格与评审惯例，已内化进本计划：原型先行评审门禁（FR-001 类结构改动先出 HTML 原型）、令牌三端真源、既有回归场景不回退。

## Project Structure

### Documentation (this feature)

```text
specs/003-app-ux-refinement/
├── plan.md              # 本文件
├── research.md          # Phase 0 决策记录
├── data-model.md        # schema v3 + 实体演进
├── quickstart.md        # 验证指南
├── contracts/
│   ├── ui-contract.md   # 三 Tab 路由/屏区块/编辑器分组契约
│   ├── goal-type-model.md # 类型×打卡×统计口径契约
│   └── backup-format.md # 备份 v3 契约
└── tasks.md             # /speckit-tasks 生成（本命令不创建）
```

### Source Code (repository root)

```text
design/
├── prototypes/          # 原型先行：screen-today.html(R5)/screen-review.html(R4)/
│   │                    # screen-settings.html(R3)/screen-editor.html(R2) 重构送审；
│   │                    # screen-goals.html 随三 Tab 收敛归档（不再维护）
│   └── tokens.css       # 令牌真源（如需新令牌先改此处）
lib/
├── app/
│   ├── router.dart      # 四分支→三分支；/goal-editor 与 /goal/:id 移入 today 分支
│   └── design_tokens.dart
├── core/
│   ├── db/tables.dart        # schema v3：goals.goalType 重映射、Reminders.cadence、
│   │                         # SettingsRows.nickname/avatarKey、colorKey 退役可空
│   ├── models/entities.dart  # GoalType 三值、NotificationItem/Profile VO
│   ├── stats/                # 达标/适用日概念退役，收敛 streak/计数/节奏（stats_engine）
│   └── copy.dart             # 新文案（账号默认昵称/通知列表/编辑器分组标题）
├── features/
│   ├── today/today_view.dart       # 头部重组：账号区/通知列表入口/同图层
│   ├── notifications/              # 新：推导式通知列表页
│   ├── profile/                    # 新：本地资料编辑（昵称+预设头像）
│   ├── goals/goal_editor.dart      # 重构：分组折叠 + 类型 + 开关提醒 + 图标库
│   ├── goals/goal_detail.dart      # 短期：达成标记/续期入口
│   ├── review/review_view.dart     # 空态居中 + CTA + 标题对齐
│   └── settings/settings_view.dart # 主流设置结构重组（含通知设置迁入）
└── (goals_view.dart 随页签移除而退役)
test/                    # 迁移对账/类型行为/路由断言/既有 69 用例回归
```

**Structure Decision**: 沿用 002 的 lib/ 分层（app/core/features），不引入新顶层目录；新增 features/notifications 与 features/profile 两个小模块；goals_view.dart 是唯一整体退役文件（其职能由今日页卡 + 详情页吸收）。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

无 constitution 违规（constitution 为占位）。范围复杂度自评：统计口径收敛（达标概念退役波及 stats_engine 与既有测试断言）是最大风险面，已在 research D2 记录决策与回归策略。
