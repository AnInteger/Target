# Implementation Plan: UI v2 重构——基准图驱动的双主题视觉语言与页面骨架翻新

**Branch**: `004-ui-v2-redesign` | **Date**: 2026-08-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-ui-v2-redesign/spec.md`（七裁决全录 Clarifications：两页签+中央 FAB、关注卡轮播+查看全部、中文标题、三环嵌套减分制、推翻到交互层、原型评审门禁）

## Summary

以 4 张基准图（`references/`）为视觉与骨架权威，推翻「柔彩仪表盘」旧风格：三端令牌全量换值（D1）、主题三档持久化（schema v5 仅一列，D2）、导航收敛两页签+中央 FAB（D6）、今日页重做为「头部+三大类健康度三环+关注卡轮播+查看全部」（D3/D4/D5）、回顾页三区块实时派生（D9）、初始屏黑底极简重做（D7）。**推翻边界到交互层**：003 交互裁决不再约束，唯功能能力清单（FR-016）与文案语域保留；图中未覆盖界面一律先原型评审冻结后实现（FR-015，D8）。

## Technical Context

**Language/Version**: Dart 3 / Flutter（既有项目，pubspec 锁定）

**Primary Dependencies**: flutter_riverpod（状态）、go_router StatefulShellRoute（导航壳）、drift（schema v4→v5）、Material Symbols rounded（图标库沿用）

**Storage**: drift 单机库（schema **v5** = Settings 加 `themeMode` 一列，纯 ADD COLUMN；三大类映射/健康度/周统计/关注卡序全部运行时派生零落库）

**Testing**: flutter_test + widget 测试（`tester.runAsync` 包真实 IO 的既有惯例）；新增 health_score 口径对账、themeMode 迁移/备份往返、token 三端对账；基线 128 项零回归

**Target Platform**: iOS 真机/模拟器 + 桌面 web（走查用）；`ios/TargetWidgets` 小组件随令牌三端同步

**Project Type**: mobile-app（本地无账号）

**Performance Goals**: 60 fps 动效（轮播/环形动画）；健康度为纯派生 O(目标数×记录数) 量级，无性能风险

**Constraints**: 离线全功能；文案正式语域（无口语化解释句/无存储位置说明）；图表深浅两主题可辨不单靠色相（FR-013）

**Scale/Scope**: 屏数 ~9（今日/回顾/初始屏/编辑器/详情/我的/全部列表/通知/资料）；延展界面 5 屏走原型门禁

## Constitution Check

`.specify/memory/constitution.md` 为未定制模板（占位符），无成文 gates——**通过**。项目事实约束（沿 003 硬口径，tasks 阶段继续执行）：每任务 `flutter analyze` 0 + `flutter test` 全绿一 commit；tasks.md 勾选附 ✅ 双子行；令牌三端一次提交内同步。

## Project Structure

### Documentation (this feature)

```text
specs/004-ui-v2-redesign/
├── plan.md              # 本文件
├── research.md          # Phase 0：D1–D9 决策与备选
├── data-model.md        # Phase 1：schema v5 + 派生模型（MajorCategory/HealthScore/周统计）
├── quickstart.md        # Phase 1：阶段 A–F 验证指南
├── contracts/
│   ├── ui-contract.md   # 路由树/屏区块/门禁清单/全局不变量
│   └── health-score.md  # 三大类健康度计算与呈现契约
├── references/          # 基准图 4 张（实现基准）
└── tasks.md             # Phase 2（/speckit-tasks 生成）
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── design_tokens.dart      # D1 全量换值（结构不变），GoalColor 退役
│   ├── app.dart                # themeMode 注入
│   ├── router.dart             # D6 分支 3→2、/settings 迁移、导航壳重做
│   └── providers.dart          # themeModeProvider / healthScoreProvider / 周视图
├── core/
│   ├── db/                     # schema v5（Settings.themeMode）+ 备份键
│   ├── models/
│   │   ├── entities.dart       # MajorCategory + GoalIconDomain.major（goal_icon_catalog.dart）
│   │   └── health_score.dart   # D3 纯函数（新文件）
│   └── stats/                  # D9 周视图派生扩展
└── features/
    ├── today/today_view.dart   # 头部/三环/轮播重做；focus_carousel.dart（新）
    ├── review/review_view.dart # 三区块重做
    ├── goals/                  # editor/detail/goals_all（原型冻结后重做）
    ├── settings/               # 我的页（主题三档行）+ profile
    └── notifications/          # 通知列表（原型冻结后换装）

design/
├── tokens.css                  # 原型侧令牌真源（D8 门禁起点）
├── prototypes/                 # 延展界面 HTML 走查稿（评审冻结）
└── reviews.md                  # 评审轮次与裁决记录

test/                           # health_score / themeMode 迁移 / token 对账 / 既有 128 零回归
ios/TargetWidgets/DesignTokens.swift  # 令牌三端同步（D1）
```

**Structure Decision**: 沿用既有 lib 布局不新增顶层目录；新文件仅 `core/models/health_score.dart` 与 `features/today/focus_carousel.dart`，其余为原地重做。

## Complexity Tracking

无 Constitution 违规需豁免。工程复杂度备注（不豁免、仅提示 tasks 排序）：tokens 三端同步是最大面积单点（一次提交内 dart+css+swift+小组件快照回归），原型门禁（FR-015）阻塞编辑器/详情/我的/通知/全部列表五个屏的实现任务——tasks 依赖图须显式表达。
