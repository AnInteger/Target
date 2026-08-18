# Implementation Plan: UI/UX 全面重设计（原型先行）

**Branch**: `002-ui-ux-redesign` | **Date**: 2026-08-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-ui-ux-redesign/spec.md`

## Summary

对既有生活目标 App 做全面重设计：视觉、信息架构、交互流程可推翻重排，功能层允许调整（重点：目标定义模型深化 FR-010、单一"目标"概念 FR-011、提醒通知文案与时机联动 FR-012），全套品牌升级（主 App + iOS 小组件仅视觉 + 图标 + 启动屏，名称 Target）。技术路线：**原型先行两阶段**——先用 frontend-design 技能在 `design/prototypes/` 产出可在浏览器评审的高保真 HTML 原型（含 2–3 个风格方向对比，用户拍板后深化全部核心屏），设计定稿后令牌机械翻译到 `lib/app/design_tokens.dart`，再逐屏落地 Flutter（每屏"原型通过评审 → 实现 → 回归"闭环）。数据层只做可空列的增量迁移（Drift schema bump），既有数据零丢失。

## Technical Context

**Language/Version**: Dart SDK ^3.13.0 / Flutter 3.47.0（既有）

**Primary Dependencies**: 既有——flutter、flutter_riverpod ^2.6、drift ^2.34、go_router ^17.5、home_widget ^0.9.3、flutter_local_notifications ^22.3；新增——`flutter_launcher_icons`、`flutter_native_splash`（dev_dependencies，仅图标/启动屏资产生成，见 research.md R6）

**Storage**: Drift（iOS 原生 SQLite / Web IndexedDB），既有库不动；目标定义模型扩展用**可空新列 + schemaVersion 递增**迁移（见 data-model.md）

**Testing**: flutter_test（既有 53 用例全绿为回归底线）；新增"设计令牌契约测试"（源码扫描断言 features 层无硬编码颜色/样式，机械化 SC-004）；不引入 golden 测试（中文渲染在 Linux 基线为豆腐块，成本大于收益，见 research.md R8）

**Target Platform**: iOS（主验收面，经 Codemagic → TestFlight 真机）+ Web（本地全功能验证面，release 构建走查，复用 001 的 semantics 无头走查法）

**Project Type**: mobile-app（Flutter 单项目）

**Performance Goals**: 动效 60fps（内建动画体系，禁重布局动画）；打卡主路径 ≤2 次交互（FR-003）；今日视图首帧 ≤1s（本就满足，作回归项）

**Constraints**: 纯本地无账号（延续）；离线全功能；App 体积不因字体显著膨胀（不打包中文 webfont，见 research.md R7）；任一时刻新旧风格并存的屏 ≤1（SC-006）

**Scale/Scope**: 屏幕清单约 9 屏 ×（浅色/深色/空态等状态）；单用户产品，活跃目标 ≤5 典型

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` 存在但为未填写的占位模板（无任何已批准原则）。**Gate 视为通过**——无有效约束可校验。项目事实约束改由 spec 的 Assumptions 承担：数据零丢失（可空迁移）、原型评审门禁（FR-001）、单机无服务端。

Phase 1 后复查：data-model 的迁移设计（全部可空、纯增量）与 spec 假设一致，无违例。复杂度追踪表留空（无需要辩护的违例）。

## Project Structure

### Documentation (this feature)

```text
specs/002-ui-ux-redesign/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── design-language.md   # 设计令牌 schema 与用法规则（UI 契约）
│   └── prototype-review.md  # 原型交付与评审门禁契约（流程契约）
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
design/                          # 新增：设计资产层（原型与令牌的设计侧源）
├── tokens.css                   # 原型侧设计令牌（CSS custom properties；定稿后镜像进 Dart）
├── prototypes/                  # 高保真 HTML 原型（frontend-design 技能产出）
│   ├── index.html               # 评审入口：风格方向对比 + 各屏索引 + 评审状态
│   ├── direction-a|b|c.html     # 风格方向探索（同屏对比，iPhone 视口 393×852）
│   ├── screen-today.html        # 核心屏原型（风格定稿后逐屏深化）
│   ├── screen-goals.html
│   ├── screen-editor.html       # 含目标定义模型 2–3 个候选方案对比
│   ├── screen-review.html
│   └── screen-settings.html
├── brand/                       # 品牌资产母版（1024 PNG 图标母版等）
└── reviews.md                   # 原型评审记录（轮次/意见/通过状态，流程实体载体）

lib/                             # 沿用现有结构，原文件演进（不另起并行目录）
├── app/
│   ├── design_tokens.dart       # 扩展为完整令牌集：语义色/字阶/间距/圆角/阴影/动效（浅深成对）
│   └── theme.dart(并入 design_tokens 或 app.dart)  # ThemeData 两套由令牌驱动
├── features/                    # 逐屏重设计：today/ goals/ review/ busy_mode/ settings/（milestones/ 并入统一目标语言，FR-011）
└── core/                        # db（迁移）/ copy（文案语气随新语言重写，含通知文案 FR-012）

ios/TargetWidgets/
└── DesignTokens.swift           # 新增：色板等令牌的 Swift 镜像（注释注明同步自 design_tokens.dart）

test/
└── design/token_contract_test.dart   # 令牌契约测试（扫描 features 层禁硬编码样式）
```

**Structure Decision**: 单 Flutter 项目内演进 + 新增顶层 `design/` 设计资产目录。原型不进 `lib/`（非交付物、不打包）；`design/` 入库（评审记录与方向决策要可追溯，FR-009 要求决策有记录）。屏幕实现沿用 `lib/features/` 现有文件原地重写，保证 SC-006（不长期并存两套 UI）。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

（无违例，留空。）
