---
description: "Task list for feature implementation"
---

# Tasks: 生活目标守护 iOS App（Target）

**Input**: Design documents from `/specs/001-life-goal-tracker/`（2026-08-18 Flutter 重规划版）

**Prerequisites**: plan.md ✅, spec.md ✅（US1–US5 + 2026-08-18 决策）, research.md ✅, data-model.md ✅, contracts/ ✅（stats-engine / backup-format / widget-intent / ui-contract）, quickstart.md ✅

**Tests**: 已包含——research.md D12 与 contracts/stats-engine.md（"每条口径规则对应一条测试"）明确要求：统计引擎 R1–R9 逐条单元测试（时钟注入时间旅行）、备份往返测试。统计相关任务采用先写测试（失败）再实现。

**Organization**: 按用户故事分阶段（P1 优先），每阶段独立可测试。MVP = US1 + US2（规格定义的最小闭环）。日常验证面 = 全功能 Web（`flutter run -d chrome`），iOS 经 push → Codemagic → TestFlight 实机验收（research D15）。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行（不同文件、无未完成依赖）
- **[Story]**: 所属用户故事（US1–US5）；Setup/Foundation/Polish 无标签
- 所有路径相对仓库根（仓库根即 Flutter 项目根，见 plan.md 工程结构）

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Flutter 工程初始化、iOS 原生孤岛与 CI 门禁

- [X] T001 Initialize Flutter project at repo root: `flutter create . --project-name target --platforms=ios,android,web`（仓库根即项目根, plan.md Structure Decision）；verify `flutter build web` succeeds
- [X] T002 [P] Add dependencies to `pubspec.yaml` per plan.md whitelist（flutter_riverpod, drift, sqlite3_flutter_libs, path_provider, home_widget, flutter_local_notifications, go_router, share_plus, file_picker, clock; dev: drift_dev, build_runner, flutter_test, flutter_lints）and run `flutter pub get`
- [X] T003 Add widget extension target `TargetWidgets` to `ios/Runner.xcodeproj`（home_widget 官方模板, Swift 仅渲染）; configure App Group `group.com.target.shared` entitlements for Runner + TargetWidgets; bump IPHONEOS_DEPLOYMENT_TARGET to 17.0 in `ios/`
- [X] T004 [P] Create `codemagic.yaml` at repo root: push 触发 iOS 构建（含 TargetWidgets 扩展）+ 构建绿即自动 TestFlight 分发（CI 门禁, research D15）
- [X] T005 [P] Add `.gitignore`（Flutter/Dart: .dart_tool/, build/, *.iml 等）与 `analysis_options.yaml`（flutter_lints）at repo root; commit initial skeleton

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 全部故事依赖的领域模型、持久化、平台能力层与 Web 验证基座

**⚠️ CRITICAL**: 本阶段完成前不得开始任何用户故事

- [X] T006 Implement value types `LocalDate`, `LocalTime`, `WeekStart`（周一锚定）, `Weekday` in `lib/core/models/calendar_types.dart` per `specs/001-life-goal-tracker/data-model.md`（设备本地时区换算、ISO 解析）
- [X] T007 [P] Implement `FrequencyPattern` (daily/weekly/weekdays) with applicability query in `lib/core/models/frequency_pattern.dart`
- [X] T008 Implement domain entities Goal, FrequencyVersion, BusyModeSession, CheckIn, MilestoneStep, Reminder, WeeklyReview(+GoalWeekStat), Settings as pure Dart classes in `lib/core/models/entities.dart` per data-model.md（含状态迁移与校验规则：活跃≤5 两类共享、CheckIn isBackfill 推导、同一 effectiveFromWeek 唯一非 busyMode 版本）
- [X] T009 [P] Implement `DateProvider` on `clock` package injection in `lib/core/models/date_provider.dart`（时钟注入, research D6）
- [X] T010 Implement drift schema + database in `lib/core/db/`（tables 与实体 1:1; 平台条件初始化：iOS=App Group 容器 NativeDatabase / Android=应用私有目录 / Web=WasmDatabase+IndexedDB, research D3）+ run build_runner codegen
- [X] T011 Implement repositories with stream queries (GoalRepository, CheckInRepository, ReminderRepository, ReviewRepository, SettingsRepository) in `lib/core/db/repositories.dart`
- [X] T012 Implement platform capability interfaces + per-platform impls in `lib/core/platform/`: notifications（flutter_local_notifications / Web 页内横幅模拟）、widget bridge（home_widget / Web 占位说明）、share（share_plus / Web 浏览器下载）、file pick（file_picker / Web 文件选择）——UI 与业务逻辑只面向接口（plan.md Structure Decision #2）
- [X] T013 [P] Create design tokens (iconKey/colorKey 枚举与色板) in `lib/app/design_tokens.dart` and copy table skeleton `lib/core/copy.dart`（教练式语气文案统一入口, ui-contract.md）
- [X] T014 Implement app shell: `lib/main.dart`（ProviderScope、通知注册、小组件后台回调注册）+ `lib/app/app.dart`（MaterialApp、主题）+ go_router skeleton with Today placeholder in `lib/app/router.dart` per ui-contract.md
- [X] T015 Verify Web 全功能验证基座: `flutter run -d chrome` 跑通 app shell 且刷新后数据保留（drift WasmDatabase/IndexedDB 持久化）; iOS 专属能力呈现占位说明（research D15; quickstart 前置条件）

**Checkpoint**: 基础就绪——可并行开始各用户故事

---

## Phase 3: User Story 1 - 快速捕捉生活目标 (Priority: P1) 🎯 MVP

**Goal**: 模板/自定义 30 秒建目标，SMART 引导，5 个上限聚焦，目标生命周期管理
**Independent Test**: 空应用 → 选模板 → 目标出现在今日视图 ≤30 秒（quickstart V1, Web 可验）

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T016 [P] [US1] Unit tests for frequency versioning rules in `test/frequency_version_test.dart`: R2 版本选择（effectiveFromWeek ≤ 目标周取最新）、用户编辑追加下周一生效版本、同周覆盖待生效版本、busyMode 版本并存与恢复移除（contracts/stats-engine.md R2, research D7）

### Implementation for User Story 1

- [X] T017 [P] [US1] Create goal template library data (好好吃饭/规律运动/早睡/屏幕休息/个人项目等, FR-012) in `lib/features/goals/goal_templates.dart`
- [X] T018 [US1] Implement GoalEditor flow in `lib/features/goals/goal_editor.dart`: 类型选择（习惯/里程碑）→ 模板或自定义 → 频率编辑（每天 N 次/每周 N 次/指定星期几, FR-002）→ 图标/颜色（FR-001）; 编辑进行中目标频率提示"下周一生效"
- [X] T019 [US1] Implement SMART guidance（模糊名称"变健康"→具体化建议一键采用, FR-001）in `lib/features/goals/smart_suggestion.dart` + 接入 GoalEditor
- [X] T020 [US1] Implement GoalsView management screen（活跃≤5/暂停/已归档分区、目标卡片连击与周完成率）in `lib/features/goals/goals_view.dart`
- [X] T021 [US1] Implement goal lifecycle in `lib/features/goals/goal_lifecycle.dart`: 暂停/恢复（FR-009）、达成关闭与归档保留历史（FR-010）、活跃上限 5 两类共享 + 聚焦引导弹层（FR-011）
- [X] T022 [US1] Implement first-launch onboarding（模板引导建首个目标, SC-001）in `lib/features/goals/onboarding.dart` + Settings.onboardingCompleted 落库

**Checkpoint**: US1 独立可用——空应用 30 秒建出首个目标

---

## Phase 4: User Story 2 - 今日一览与一键打卡（记分表） (Priority: P1) 🎯 MVP

**Goal**: 生活电量视觉核心 + 今日打卡闭环（含小组件直接打卡）+ 统计引擎
**Independent Test**: 预置 3 目标 → 打开 → 逐一打卡 → 进度/连击即时更新 ≤10 秒（quickstart V2, Web 可验; 小组件走 V3 TestFlight）

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T023 [P] [US2] Unit tests for stats engine R1–R3/R5–R7/R9 in `test/stats_engine_test.dart`: 跨天归属（23:59/00:01）、当日次数封顶、连击（非适用日跳过不断链/今天未达标截至昨天）、补签计入与断链回接、撤销回退、电量=活跃习惯当日完成度均值、无活跃 habit→null 空态（时钟注入时间旅行, contracts/stats-engine.md）

### Implementation for User Story 2

- [X] T024 [US2] Implement `StatsEngine.evaluate` (DayStatus/Streak/WeekStats 实时版/LifeBattery) in `lib/core/stats/stats_engine.dart` per contracts/stats-engine.md（纯函数, 无 Flutter 依赖; 消费 T006–T011）
- [X] T025 [US2] Implement CheckInService（打卡+1、当日/补签撤销、任意过去日期补签并标记"补", FR-004）in `lib/core/stats/check_in_service.dart`; 补签日历 UI in `lib/features/today/backfill_calendar.dart`
- [X] T026 [US2] Implement TodayView in `lib/features/today/today_view.dart`: 生活电量环为视觉核心（FR-017, 空态"—"）、今日目标列表 x/y + 打卡按钮、全部达标成就态（US2-6）、打卡后连击/周进度经 Riverpod 流即时刷新
- [X] T027 [US2] Implement inline undo toast（当日/补签打卡均可撤销, FR-004; 撤销后统计即时回退 R7）in `lib/features/today/undo_toast.dart`
- [X] T028 [P] [US2] Implement widget snapshot writer in `lib/core/platform/widgets/widget_snapshot.dart`: battery/updatedAt/goals/weekProgress keys 经 HomeWidget.saveWidgetData 写 App Group 并触发刷新（contracts/widget-intent.md 快照 schema, research D13）
- [X] T029 [P] [US2] Implement native widget timeline + families in `ios/TargetWidgets/TodayWidgetBundle.swift`: 读快照渲染 systemSmall（电量环）/systemMedium（今日列表+打卡按钮）/accessoryCircular/accessoryRectangular; 预生成次日 0 点切换条目; 过期快照按缓存渲染不崩溃（纯渲染, 无业务逻辑）
- [X] T030 [US2] Implement widget interactive check-in: 注册 home_widget 后台 isolate Dart 回调 in `lib/core/platform/widgets/widget_checkin.dart`（校验 active/未达标 → 写 CheckIn → 重算 → 重写快照）; 降级路径 = 深链 `target://goal/{id}` 打开对应目标（contracts/widget-intent.md, research D13）
- [X] T031 [US2] Wire data-change propagation in `lib/app/app.dart` + providers: CheckIn/Goal 变更 → Riverpod 流刷新 UI + 小组件快照重写（跨天 0 点边界亦触发, research D13 Timeline 策略）

**Checkpoint**: US1+US2 = MVP——今日打卡闭环完整, push 后 TestFlight 可验小组件

---

## Phase 5: User Story 3 - 提醒：让目标主动找上门 (Priority: P2)

**Goal**: 逐目标提醒 + 全局晨间概要，已达标不催促，权限被拒降级
**Independent Test**: 设一条定时提醒到点到达且内容正确; 已达标目标 0 催促（quickstart V4/V8; Web 页内模拟可验, 系统通知走 TestFlight）

### Implementation for User Story 3

- [ ] T032 [US3] Implement ReminderService in `lib/features/settings/reminder_service.dart`: 经 T012 通知接口调度 scope=goal/dailyBrief 本地通知（FR-006）; Web 实现为页内横幅模拟; dailyBrief 默认 08:00 内容含各目标当日状态概览
- [ ] T033 [US3] Implement no-push-when-met filtering in `lib/features/settings/reminder_service.dart`: 数据变更后重建 pending 请求，剔除当日已达标目标的催促（FR-006, SC-005）
- [ ] T034 [US3] Implement notification-permission degradation in `lib/features/settings/settings_view.dart`: 被拒时全功能可用 + "如何开启通知"说明、不反复弹窗（FR-007）
- [ ] T035 [US3] Implement reminder settings UI（每日概要时间、逐目标提醒开关与时间）in `lib/features/settings/settings_view.dart`; 周一晨概要附带周回顾深链入口（FR-008 联动, 页面在 US4）

**Checkpoint**: US3 独立可用——目标会在设定时间主动浮现

---

## Phase 6: User Story 4 - 周回顾：规律的问责节奏 (Priority: P2)

**Goal**: 周一晨自动结算上周、周回顾三选决策、忙碌模式降档不熄火
**Independent Test**: Debug 时钟跳至周一 08:05 → 结算提醒 + 回顾页数据正确（quickstart V4, Web 可验）

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T036 [P] [US4] Unit tests for weekly settlement & busy mode (R4/R8) in `test/settlement_test.dart`: weekly(N) 全周适用/达标口径、周一晨结算快照幂等防重、忙碌周按降档口径结算 busyModeApplied、恢复后回落原频率、decision=adjust 生成下周 userEdit 版本、decision=pause 置 paused

### Implementation for User Story 4

- [ ] T037 [US4] Implement WeeklySettlementService（周一晨结算上一周、存 WeeklyReview 快照、幂等; 触发=应用启动 + 概要提醒前）in `lib/core/stats/settlement_service.dart`（research D11）
- [ ] T038 [US4] Implement ReviewView in `lib/features/review/review_view.dart`: 各目标完成率卡、近 4 周趋势、补签次数透明呈现、忙碌标注、反思输入框、决策三选（继续/调频下周生效/暂停）、<50% 目标呈现教练式建议（FR-008; 展示实时重算, 快照仅留痕）——文案取 `lib/core/copy.dart`
- [ ] T039 [US4] Implement BusyMode in `lib/features/busy_mode/busy_mode_view.dart` + `lib/core/stats/busy_mode_service.dart`: 选择目标→逐个降档预览→一键开启（插入本周 busyMode 频率版本, 当周生效豁免 FR-002）→一键恢复（移除版本）; 今日列表与周回顾"忙碌模式"徽标（FR-018）
- [ ] T040 [US4] Wire deep links `target://today` / `target://review` / `target://goal/{id}` in `lib/app/router.dart`（go_router, research D14; 小组件/通知深链落点）

**Checkpoint**: US4 独立可用——目标按周被重新审视而非腐烂

---

## Phase 7: User Story 5 - 里程碑目标：旅行与个人项目 (Priority: P2)

**Goal**: 带截止日与步骤清单的一次性目标，倒计时与进度
**Independent Test**: 建带截止日和 3 步骤的里程碑 → 倒计时与 1/3 进度正确（quickstart V1 里程碑分支, Web 可验）

### Implementation for User Story 5

- [ ] T041 [P] [US5] Implement milestone editor extension（deadline、步骤增删改; 复用 GoalEditor 的里程碑分支）in `lib/features/milestones/milestone_editor.dart`
- [ ] T042 [US5] Implement MilestoneView detail in `lib/features/milestones/milestone_view.dart`: 步骤勾选可回退、进度 done/total、截止倒计时、过期温和"顺延/关闭"选项（FR-013, US5-3）
- [ ] T043 [US5] Integrate milestones into TodayView（进度概要与倒计时）and GoalsView cards; 全部步骤完成 → 一键 achieved in `lib/features/today/today_view.dart`
- [ ] T044 [P] [US5] Add milestone rows to widget medium family（只读进度概要）in `ios/TargetWidgets/TodayWidgetBundle.swift` + snapshot goals keys 扩展 in `lib/core/platform/widgets/widget_snapshot.dart`

**Checkpoint**: 全部用户故事独立可用

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 备份闭环、数据风险明示、调试工具、文案审校与端到端验收

- [ ] T045 [P] Implement backup exporter（全量实体+Settings → 版本化 JSON `.targetbackup`; iOS 分享面板 + UTType 声明 `com.target.backup`; Web 浏览器下载）in `lib/core/backup/backup_exporter.dart` per contracts/backup-format.md（FR-015）
- [ ] T046 [P] Implement backup importer in `lib/core/backup/backup_importer.dart`: schema 逐实体校验（缺失/类型错误明确报错不部分导入）、更高版本拒绝、冲突弹窗"覆盖本地/取消"绝不静默合并、原子替换、记录数摘要; Web 文件选择; UI 接入 `lib/features/settings/settings_view.dart`
- [ ] T047 Unit tests for backup round-trip + 冲突拒绝 + 损坏文件拒绝 in `test/backup_test.dart`
- [ ] T048 Add data-risk & privacy disclosure（换机/重装需备份、数据仅存本地、备份文件含全部数据, FR-014）to `lib/features/settings/settings_view.dart` 与首启引导
- [ ] T049 Implement Debug 时钟菜单（开发构建显示; 时间旅行验证周结算, research D6）in `lib/features/settings/debug_clock.dart` 接入 `lib/features/settings/settings_view.dart`
- [ ] T050 Copy tone review pass（教练式非指责全局审校: 40% 完成率/连击断裂/低电量表达）over `lib/core/copy.dart` per ui-contract.md 文案与语气
- [ ] T051 End-to-end acceptance walkthrough per quickstart.md V1–V8: Web 全功能走查（含刷新持久化）+ push 触发 Codemagic 构建绿 → TestFlight iPhone 实机验收（含小组件 V3、系统通知 V8）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖，立即开始
- **Foundational (Phase 2)**: 依赖 Phase 1 —— **阻塞全部用户故事**
- **User Stories (Phase 3+)**: 均依赖 Phase 2 完成
- **Polish (Phase 8)**: 依赖全部所需故事完成（T045–T047 备份只依赖 Phase 2, 可提前）

### User Story Dependencies

- **US1 (P1)**: Phase 2 后即可开始, 不依赖其他故事
- **US2 (P1)**: Phase 2 后即可开始（与 US1 并行; T024 统计引擎依赖 T006–T011, T029/T030 依赖 T003）
- **US3 (P2)**: 依赖 US1（有目标可提醒）与 US2（当日达标状态）的模型/服务
- **US4 (P2)**: 依赖 US2（打卡数据与统计引擎）
- **US5 (P2)**: Phase 2 后即可开始（里程碑不依赖打卡; T043 集成需要 US2 的 TodayView）

### Within Each User Story

- 测试任务（如有）先写并确认失败，再实现
- 模型 → 服务 → UI → 集成
- 每个故事完成后在其 Checkpoint 独立验证（Web 走查 + push 构建）

### Parallel Opportunities

- Phase 1: T002/T004/T005 并行; Phase 2: T007/T009/T013 并行
- US1 内: T016/T017 并行; US2 内: T023/T028/T029 并行; US4 内: T036 先行后 T037–T040 大体并行; US5 内: T041/T044 并行
- Polish: T045/T046 并行
- 不同故事可并行推进（单人开发按优先级串行即可）

---

## Parallel Example: User Story 2

```bash
# 先并行发起测试与快照/原生组件（不同文件、无相互依赖）：
Task: "Unit tests for stats engine R1–R3/R5–R7/R9 in test/stats_engine_test.dart"
Task: "Widget snapshot writer in lib/core/platform/widgets/widget_snapshot.dart"
Task: "Native widget timeline + families in ios/TargetWidgets/TodayWidgetBundle.swift"

# 再串行实现引擎与服务：
Task: "Implement StatsEngine.evaluate in lib/core/stats/stats_engine.dart"
Task: "Implement CheckInService in lib/core/stats/check_in_service.dart"
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational（含 T015 Web 基座验证——日常循环从第一天就可用）
3. Complete US1 → Web 走查 quickstart V1
4. Complete US2 → Web 走查 V2 + push/TestFlight 验 V3 小组件
5. **STOP and VALIDATE**: MVP 闭环（看见→打卡→反馈）独立成立

### Incremental Delivery

1. Setup + Foundational → 基础就绪
2. + US1 → 想法 30 秒安放（MVP 之半）
3. + US2 → 打卡闭环（MVP 完成, 可日常自用）
4. + US3 → 忙碌时目标主动浮现
5. + US4 → 周节奏与忙碌模式
6. + US5 → 里程碑; Polish → 备份/明示/验收 → v1 完整范围

---

## Notes

- [P] = 不同文件、无未完成依赖
- [Story] 标签映射到 spec.md 用户故事, 便于追溯
- 每个任务或逻辑组完成后提交 git（push 即触发 Codemagic 门禁, 保持构建为绿）
- 检查点处停下独立验证（Web 主面; iOS 专属走 TestFlight）
- 避免: 模糊任务、同文件冲突、破坏故事独立性的跨故事依赖
