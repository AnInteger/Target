# Implementation Plan: 005 走查修复轮——布局度量统一 · 安全区 · 转场 · 触达

**Branch**: `005-review-bug-fix` | **Date**: 2026-08-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-review-bug-fix/spec.md`

## Summary

外部审查十条核验后收编四类属实缺陷：①dock 被外层 SafeArea 整条抬离物理底边——改为背景下延至 y=0、互动元素避让 inset（D1）；②页级边距双标准——分层基准：hero 两屏 24 不动、四个 push 页收敛 `AppSpace.s4`(16)（D2，clarify 用户裁定）；③今日轮播首卡缘叠加 ≈41pt——ListView 结构反转 + 全出血 fraction=(W−2·padX)/W（D3）；④dock 切页 0ms 硬切 + 次级顶栏四份手写 + 图标触达 36/38<44 + 今日头部整块居中错位——fade-through 自研包壳（D4）、共享 `PageTopBar`（D5）、44 触达外扩（D6）、头部两行重构（D7）。两不属实不修、两未复现转真机复核（D8）。零数据变更、004 冻结语言不动。

## Technical Context

**Language/Version**: Dart 3 / Flutter（stable，`$HOME/development/flutter/bin`）

**Primary Dependencies**: flutter_riverpod（状态注入）、go_router `StatefulShellRoute.indexedStack`（两分支壳层）、sqflite/schema v5（本轮零触碰）

**Storage**: SQLite（schema v5 不动；无迁移）

**Testing**: flutter_test + integration_test 既有件系；基线 161/161（004 收口态），本轮净增用例后全绿；widget 测试注入 MediaQuery padding 验安全区

**Target Platform**: iOS 真机/模拟器（全面屏 Home 指示条与无 inset 两类机型），桌面 web 可走查大部分项

**Project Type**: mobile-app（纯界面度量/适配/动效修复轮）

**Performance Goals**: 转场 250ms 恒帧率不掉帧；无新增构建耗时面

**Constraints**: 004 冻结语言不动（hero 头部/配色/深色禁重阴影）；既有 161 测试口径与全部测试 key 零回归；度量值只出自 design_tokens.dart（禁裸数值）；dart format 只点名本轮任务文件（仓库教训）

**Scale/Scope**: 9 个 lib 文件（1 新建 + 8 修改）+ 测试；无后端、无小组件侧改动（tokens 三端零换值，token_contract_test 无需动值）

## Constitution Check

`.specify/memory/constitution.md` 为未填写模板（无项目宪章条款）→ 沿用仓库硬口径作为门禁：

| Gate | 判据 | 状态 |
|---|---|---|
| 静态检查 | `flutter analyze` 0 issue | 待实现后执行 |
| 测试门禁 | `flutter test` 全绿（161 基线零回归 + 新增） | 待实现后执行 |
| 冻结语言 | 004 hero/配色/阴影契约不变（research D8、契约 §7） | 设计已对齐 |
| 度量来源 | 全部取自 design_tokens 既有刻度，零新令牌、零裸数值 | 设计已对齐 |
| 提交纪律 | 一任务一 commit（`005 T0XX: 中文标题`） | tasks 阶段执行 |

无违例 → Complexity Tracking 留空。

## Project Structure

### Documentation (this feature)

```text
specs/005-review-bug-fix/
├── plan.md              # 本文件
├── research.md          # D1–D8 技术裁定
├── data-model.md        # 零数据变更结论
├── contracts/
│   └── layout-metrics.md  # 布局度量契约（七节）
├── quickstart.md        # 六阶段走查指南
└── tasks.md             # /speckit-tasks 生成（未创建）
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── router.dart            # D1 dock 贴底 · D4 _FadeThrough 分支转场
│   ├── page_top_bar.dart      # D5 新建·共享次级顶栏（含 44 触达返回钮）
│   └── design_tokens.dart     # 零改动（消费既有 AppSpace/AppScreen/AppMotion）
├── features/
│   ├── today/
│   │   ├── today_view.dart    # D3 结构反转+分段 padding · D6 铃铛 44 · D7 头部两行
│   │   └── focus_carousel.dart# D3 全出血 viewportFraction
│   ├── goals/
│   │   ├── goals_all_view.dart# D2 边距 16 · D5 顶栏替换（trailing=计数+新建胶囊）
│   │   ├── goal_editor.dart   # D2 · D5（保留 maybePop 语义）
│   │   └── goal_detail.dart   # D2 · D5（trailing=⋯菜单）· D6
│   ├── settings/settings_view.dart # D2 · D5
│   └── review/review_view.dart     # D6 日历钮 44
test/
├── widget_test.dart 等        # 既有 161 基线回归（页签/深链/轮播用例随动）
└── （本轮新增）               # dock inset 几何 · 页缘单值 · 轮播卡缘 · 转场终态 · 触达
```

**Structure Decision**: 沿用 004 既有 lib/app + lib/features 单体结构；唯一新文件 `lib/app/page_top_bar.dart`（跨四页共享的壳层件归 app/，同 router/dock 先例）。无新目录、无分层变更。

## Complexity Tracking

> 无 Constitution Check 违例，留空。
