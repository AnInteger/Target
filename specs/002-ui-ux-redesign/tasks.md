---
description: "Task list: UI/UX 全面重设计（原型先行）"
---

# Tasks: UI/UX 全面重设计（原型先行）

**Input**: Design documents from `/specs/002-ui-ux-redesign/`

**Prerequisites**: plan.md ✅、spec.md ✅、research.md ✅、data-model.md ✅、contracts/design-language.md + prototype-review.md ✅、quickstart.md ✅

**Tests**: 本特性含测试任务（令牌契约测试、迁移/备份/通知单测、逐屏回归），来源 plan.md Testing 节与 quickstart.md。

**Organization**: 按 User Story 分阶段（US1–US5 对应 spec P1–P5）。**评审门禁已编码为依赖**：每屏"实现"任务被"该屏原型评审通过"任务阻塞（契约 prototype-review.md）；数据库迁移被"字段集评审"阻塞（契约 §3-3）。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行（不同文件、无未完成依赖）
- **[Story]**: 所属用户故事
- 任务均带精确文件路径

## Path Conventions

单 Flutter 项目 + 顶层 `design/` 设计资产目录（见 plan.md Project Structure）。

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 设计资产与设计回归基建

- [X] T001 创建设计资产目录与评审基建：`design/tokens.css`（占位骨架，注释指向 contracts/design-language.md）、`design/prototypes/index.html`（评审入口：风格方向区/屏索引/各屏通过状态列）、`design/reviews.md`（评审记录模板：屏·轮次·日期·意见原话·结论·修订说明）、`design/brand/`
- [X] T002 [P] 令牌契约测试基建 `test/design/token_contract_test.dart`：扫描 `lib/features/` 与 `lib/app/`（`design_tokens.dart` 豁免）断言无 `Color(0x` 字面量与带 color/fontSize 的裸 `TextStyle(`；对现状代码做一次审计并建立**带注释白名单**（SC-004：白名单只减不增）

---

## Phase 2: User Story 1 - 设计方向探索与原型系统 (Priority: P1) 🎯 MVP

**Goal**: 2–3 个风格方向对比 → 用户拍板 → 全套令牌收敛 + Dart 主题基建 + "今日"屏高保真原型评审通过

**Independent Test**: `design/prototypes/` 在浏览器可开；`design/reviews.md` 有 FR-009 风格决策记录与今日屏"通过"结论；`design_tokens.dart` 双主题可编译

### Implementation

- [X] T003 [US1] 用 frontend-design 技能产出 2–3 个风格方向的"今日"屏对比原型 `design/prototypes/direction-a.html` / `direction-b.html` / `direction-c.html`：393×852 手机视口、自包含零外链、点击可演示打卡反馈、各含深色画板（方向探索期允许内联试色，契约 §2-5）
- [x] T004 [US1] 方向评审轮：用户浏览器查看对比 → 意见原话与结论记入 `design/reviews.md` → 未过则修订（轮次+1，至多 2 轮，超则升级口头对齐）→ 选定/融合结论作为 FR-009 决策记录（3 轮后定稿「柔彩仪表盘」direction-g.html v3，2026-08-19）
- [x] T005 [US1] 收敛设计令牌 `design/tokens.css`：按契约 schema 全量写入——语义色浅/深成对、8 目标色校准（键名冻结）、九档字阶（数字 tnum）、间距/圆角/阴影刻度、动效时长与曲线；`design/prototypes/index.html` 增加令牌总览区（含深浅切换；G 标记已定稿；间距刻度增补 20 见契约变更记录）
- [x] T006 [US1] 令牌翻译与主题基建 `lib/app/design_tokens.dart`：Dart 令牌全集（浅/深成对）+ `ThemeData` light/dark 由完整 ColorScheme（令牌组装，弃 fromSeed）+ 数字 `FontFeature.tabularFigures()`；全 App 引用点同步迁移（公共 API 兼容零改动：GoalColor 仅校准值、AppTheme.light/dark 签名不变；新增 TargetPalette/AppSpace/AppRadius/AppMotion/AppTextX 供 US2+ 使用）
- [x] T007 [US1] 深化"今日"屏原型 `design/prototypes/screen-today.html`：典型态/空态/忙碌态/全完成态/深色并列画板；打卡反馈与成就时刻动效可触发演示（标注令牌时长）；导航壳层（页面结构/底部导航）示意一并呈现（6 画板：四态浅色 + 典型/全完成深色；典型态可点击打卡至成就时刻，Playwright 计算样式逐项验证）
- [ ] T008 [US1] "今日"屏原型评审：`design/reviews.md` 记录结论至"通过"（**门禁：通过后 US2 实现任务方可开工**）（R1 六项 + R2 九项 + R3 自审六项已全改；2026-08-20 R4 三项已改——年度守护卡移除、导航条参照重做（inset 对齐/全圆角胶囊/图标等大）、浅色配色令牌级调淡与墨梅 accent，R4 待评审）

**Checkpoint**: 设计语言成立——方向已定、令牌双端就位、今日屏原型通过，可随时进入实现

---

## Phase 3: User Story 2 - 每日打卡动线落地 (Priority: P2)

**Goal**: 今日视图按原型落地：首屏总览、≤2 交互打卡、仪式感反馈、成就时刻、导航壳层

**Independent Test**: Web release 面走查 V1/V2/V6 全过；打卡主路径计时 ≤2 交互；`flutter analyze`/`flutter test` 全绿

### Implementation

- [ ] T009 [US2] 导航壳层与今日视图重写 `lib/app/router.dart`、`lib/app/app.dart`、`lib/features/today/today_view.dart`：按 T007 定稿落地（≤5 目标首屏无滚动、打卡 ≤2 交互、拇指热区、空/忙碌/全完成态）
- [ ] T010 [US2] 打卡反馈与成就时刻动效 `lib/features/today/today_view.dart`（可拆组件文件于 `lib/features/today/`）：内建动画 + 令牌时长/曲线（反馈 ≤600ms、庆祝 ≤1200ms）；连续快速打卡不阻塞不错乱；`lib/features/today/undo_toast.dart` 适配新语言
- [ ] T011 [US2] 今日动线能力等价保留：长按补签入口、Debug 时钟入口等既有快捷语义不丢失（`lib/features/today/`、`lib/features/settings/debug_clock.dart`）
- [ ] T012 [US2] US2 回归：更新/新增 widget 测试（打卡 ≤2 交互、成就时刻、撤销、忙碌态区分）`test/widget_test.dart`；Web release 走查 V1/V2/V6（quickstart 阶段 B）；`flutter analyze` + `flutter test` 全绿

**Checkpoint**: 用户日常最高频路径焕新，产品气质立住

---

## Phase 4: User Story 3 - 目标定义模型与创建流程 (Priority: P3)

**Goal**: 编辑器原型含定义模型候选对比 → 字段集评审 → 可空列迁移 → 编辑器/列表/引导落地，单一"目标"概念

**Independent Test**: 新 UI 下模板与自定义两路径创建目标成功且含新维度；既有目标升级零丢失；V1/V5 回归通过

### Implementation

- [ ] T013 [US3] 编辑器与列表原型 `design/prototypes/screen-editor.html`（+ `screen-goals.html` 列表语言示意）：单一"目标"概念无前置类型分叉（FR-011）、2–3 个定义模型候选方案对比（动机/成功标准/提醒时机等组合，FR-010/FR-012）、模板路径与 SMART 建议内联、渐进补全空态
- [ ] T014 [US3] 编辑器评审：`design/reviews.md` 记录选定字段集与动线（**门禁：通过前禁止动数据库 schema**，契约 §3-3）
- [ ] T015 [US3] 数据迁移 `lib/core/db/tables.dart`、`lib/core/db/app_database.dart`、`lib/core/models/entities.dart`：按选定字段集加**可空列** + schemaVersion 递增 + `build_runner` 再生成 `app_database.g.dart` + 迁移与既有数据零丢失单测 `test/`
- [ ] T016 [US3] 备份格式扩展 `lib/core/backup/backup_exporter.dart`、`lib/core/backup/backup_importer.dart`：新字段为可选键（缺键兼容 001 备份）+ 单测 `test/`
- [ ] T017 [US3] 编辑器与列表落地 `lib/features/goals/goal_editor.dart`、`lib/features/goals/goals_view.dart`、`lib/features/goals/goal_templates.dart`、`lib/features/goals/smart_suggestion.dart`：新动线（无类型分叉、SMART 内联、新维度、一次性/截止日属性化、频率变更下周一生效提示保留）+ 旧目标空维度渐进补全入口
- [ ] T018 [US3] kind 合并与引导：里程碑专属视图并入统一呈现（收敛 `lib/features/milestones/`、调 `lib/app/router.dart`）、`lib/features/goals/onboarding.dart` 跟随新语言
- [ ] T019 [US3] US3 回归：创建双路径、V1/V5 场景、既有目标升级零丢失、`flutter analyze` + `flutter test` 全绿

**Checkpoint**: "目标不明确"的根因（定义太浅 + 类型前置分叉）被模型级解决

---

## Phase 5: User Story 4 - 回顾与调整流程 (Priority: P4)

**Goal**: 周回顾/忙碌/补签按新语言重设计：数据翻译成生活语言与图形，决策 ≤3 步

**Independent Test**: V4 周结算全流程（Debug 时钟跳周一）、V5 补签、V6 忙碌在新 UI 下回归通过

### Implementation

- [ ] T020 [US4] 周回顾原型 `design/prototypes/screen-review.html`：完成率/近 4 周趋势/教练建议的图形化生活语言呈现、继续/调整/暂停决策 ≤3 步、忙碌与补签画板
- [ ] T021 [US4] 周回顾评审（`design/reviews.md`）通过后重写 `lib/features/review/review_view.dart`：图形化趋势（`CustomPainter`）、生活化文案 `lib/core/copy.dart`、决策动线 ≤3 步保留"下周一生效"语义
- [ ] T022 [US4] 忙碌模式视觉区分 `lib/features/busy_mode/busy_mode_view.dart` + 今日屏忙碌态：与正常态明确区分、最低档、恢复正常回落
- [ ] T023 [US4] [P] 补签日历新视觉 `lib/features/today/backfill_calendar.dart`："补"标记与当日打卡不混淆、14 天窗口、FittedBox 布局保留 + V5 widget 测试更新 `test/widget_test.dart`
- [ ] T024 [US4] US4 回归：V4/V5/V6 全场景走查（quickstart 阶段 B）、`flutter analyze` + `flutter test` 全绿

**Checkpoint**: 产品"教练"角色完成升级，次级流程不再有旧观感

---

## Phase 6: User Story 5 - 设置、通知与品牌收尾 (Priority: P5)

**Goal**: 设置/备份新 UI、通知文案与时机联动（FR-012）、全套品牌素材（图标/启动屏/小组件视觉）、深色全屏达标

**Independent Test**: V7 备份回归；深色遍历全屏 AA 达标；push → Codemagic 绿 → 真机核对品牌与通知

### Implementation

- [ ] T025 [US5] 设置屏原型 `design/prototypes/screen-settings.html` + 评审通过（`design/reviews.md`）：分组、备份入口、通知设置、深色画板
- [ ] T026 [US5] 设置落地 `lib/features/settings/settings_view.dart`：新语言重写 + V7 备份导出/导入（冲突对话框、计数 toast）回归
- [ ] T027 [US5] [P] 通知重设计（FR-012）`lib/core/copy.dart` + `lib/features/settings/reminder_service.dart`：文案新品牌语气；提醒时刻按目标提醒时机字段调度（空值回落默认时段、同档时机多目标打扰合并）+ 调度单测 `test/`
- [ ] T028 [US5] 品牌母版与 iOS 资产 `design/brand/` + `pubspec.yaml`：Target 图标 1024 母版（浅/深）→ 配置 `flutter_launcher_icons` + `flutter_native_splash`（dev_dependencies）→ `dart run` 生成 iOS 全档资产（图标/启动屏）
- [ ] T029 [US5] [P] 小组件视觉同步 `ios/TargetWidgets/DesignTokens.swift`（色板镜像，文件头注明同步自 `design_tokens.dart`）+ MediumView/锁屏 circular 外观刷新：**功能与数据流不动**（FR-008）
- [ ] T030 [US5] 深色模式全屏核对：浅/深遍历全部屏，正文对比度 ≥4.5:1（SC-005），问题项修正并记录抽查结果 `design/reviews.md`

**Checkpoint**: 全套品牌成立——图标、启动屏、小组件、通知与主 App 一体

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: 一致性清零、全量验收、发布

- [ ] T031 令牌白名单清零：消灭 `test/design/token_contract_test.dart` 白名单中全部遗留硬编码条目（SC-004 达成 100% 取值于令牌）
- [ ] T032 全量走查：quickstart.md 阶段 B 全表 + 001 的 V1–V8 全场景回归 + SC-001…SC-006 逐条核对 + `design/reviews.md` 确认全部核心屏"通过"
- [ ] T033 发布验证：`flutter analyze` + `flutter test` 全绿 → `git push` → Codemagic 绿 → TestFlight 真机核对（quickstart 阶段 C：图标/启动屏/小组件/深色/动效帧率/通知时机与文案）
- [ ] T034 文档收尾：更新 `specs/002-ui-ux-redesign/` 各文档状态与根 README（若涉及新命令/新目录说明）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖，立即开始
- **US1 (Phase 2)**: 依赖 Phase 1；是全部后续故事的地基（令牌 + 方向）
- **US2–US5**: 依赖 US1 的令牌与主题基建（T006）；**推荐严格按 P1→P5 顺序推进**（SC-006：任一时刻新旧风格并存的屏 ≤1，顺序落地天然满足）

### 评审门禁（契约 prototype-review.md 编码）

- T009–T012（US2 实现）被 **T008 今日屏评审通过** 阻塞
- T015/T016（数据库迁移、备份扩展）被 **T014 字段集评审通过** 阻塞
- T021–T024 被 **T020+T021 前置评审** 阻塞；T026+ 被 **T025 评审通过** 阻塞
- 风格方向未定（T004）前禁止产出 `screen-*.html` 与任何令牌翻译（T005–T008 串行）

### Within Each User Story

- 原型 → 评审 → 实现 → 回归，严格串行
- 每完成一屏即小步提交（延续 001 提交风格：`T0XX: 中文标题`）

### Parallel Opportunities

- T001 ∥ T002（不同文件）
- T022 ∥ T023（US4 内不同文件，均需 T021 后）
- T026 ∥ T027、T028 ∥ T029（US5 内不同文件，T026/T028 各自评审门禁后）

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 基建 → 2. US1 方向对比 + 令牌 + 今日屏原型通过 → **停下让用户在浏览器里看**
3. 此刻已可验证：风格方向对不对、设计语言是否成立（零代码风险）

### Incremental Delivery（每屏一个交付点）

US1 原型体系 → US2 今日屏上线（气质立住）→ US3 定义模型（根因解决）→ US4 回顾体系 → US5 品牌与通知闭环 → Polish 全量验收
每个故事完成即独立可验收（quickstart 阶段 B 对应场景），不破坏已完成故事

---

## Notes

- [P] = 不同文件且无未完成依赖
- 评审记录一律写 `design/reviews.md`（流程实体，FR-001/FR-009 的执行载体）
- 禁止跳过评审门禁直接实现（spec FR-001、契约 prototype-review.md §3）
- 原型一律自包含 HTML（393×852），延续"用户浏览器验收"的环境约束
