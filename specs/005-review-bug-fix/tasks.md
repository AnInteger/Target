---
description: "Task list for 005 走查修复轮"
---

# Tasks: 005 走查修复轮——布局度量统一 · 安全区 · 转场 · 触达

**Input**: Design documents from `/specs/005-review-bug-fix/`（spec.md 五故事 + 核验结论表 / plan.md / research.md D1–D8 / data-model.md 零变更 / contracts/layout-metrics.md 七节 / quickstart.md 阶段 A–F）

**Prerequisites**: 全部就绪（004 完结态基线：analyze 0 / test 161 绿 / schema v5 / 分支 005-review-bug-fix 已立、spec+plan 已入库）

**Tests**: plan.md Testing 已声明（inset 几何 / 页缘单值 / 轮播卡缘 / 转场终态 / 触达 44）——用例随对应任务同 commit；本轮无独立测试先行任务（修复型任务用例与实现同批）。

**Organization**: 按用户故事分相（US1 安全区 → US2 页缘 → US3 轮播 → US4 转场 → US5 顶栏/触达/头部 → 收口）；无 Foundational 相——零数据变更、零新令牌、无跨故事地基（data-model.md 结论），Phase 1 基线核验后直入故事。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行（不同文件、无未完成前置）
- **[Story]**: 归属用户故事（US1–US5）
- 每条任务带精确文件路径

## 硬口径（沿 003/004，每任务必过）

- 每任务 `flutter analyze` 0 issue + `flutter test` 全绿（161 基线零回归 + 本轮新增），一任务一 commit：`005 T0XX: 中文标题`，`--author="sunxing <sunxing@users.noreply.github.com>"`
- tasks.md 勾选时任务行下附 ✅ 双子行（✅ 实现完成 / ✅ 门禁通过）
- 度量值只出自 lib/app/design_tokens.dart 既有刻度（本轮零新令牌、零裸数值）；dart format 只点名本任务文件（仓库教训：整树 format 会 churn）
- 004 冻结语言不动（hero 两屏头部结构 / 配色 / 深色禁重阴影 / 既有 Copy 键 / 测试 key：navTab-*、dockBar、dockFab、goalsAllRow-* 等）

---

## Phase 1: Setup

**Purpose**: 基线核验与执行口径落档

- [x] T001 核验实现基线：`flutter analyze` 0 issue + `flutter test` 161/161 绿（004 收口态复验），在 specs/005-review-bug-fix/tasks.md 顶部确认执行口径生效（commit 格式与 ✅ 双子行约定）
  - ✅ 实现完成：基线复验通过（analyze 0 / test 161 全绿），硬口径节（commit 格式+双子行+零新令牌+冻结语言红线）已在文件顶部生效
  - ✅ 门禁通过：`flutter analyze` No issues found · `flutter test` 00:15 +161 All tests passed

---

## Phase 2: User Story 1 - dock 贴底与安全区 (Priority: P1) 🎯 MVP

**Goal**: dock 底幕延伸至屏幕物理底边，全面屏无断层；互动元素避让 Home 指示区（FR-001/002，research D1）

**Independent Test**: 带底部 inset 机型断言 dockBar 底缘 = 屏底、页签不侵入 inset；inset=0 机型几何与 004 版恒等

- [x] T002 [US1] dock 安全区改造（D1）：lib/app/router.dart `_Dock` 去外层 `SafeArea(top:false)`、改自消费 `MediaQuery.paddingOf(context).bottom`——底条背景高度 84+inset 下延至物理底边（顶缘发丝线仍在条顶）、页签与 FAB 互动槽整体上移 inset；test/ 新增 inset=34 / inset=0 两组几何用例（dockBar 底=屏底、页签 bottom≥inset、inset=0 与现版恒等、dockFab 命中回归）
  - ✅ 实现完成：`_Dock` 去 SafeArea 改自消费 bottomInset——SizedBox 高 84+22+inset、dockBar Positioned top:22→bottom:0（背景贴物理底边）、三槽行 Positioned(top:0,bottom:inset) 互动槽整体避让；inset=0 几何与 004 恒等
  - ✅ 门禁通过：analyze 0 + test 163/163（新增 005 T002 两例：inset=34 底幕贴底 844/高 118/页签与 FAB 止于 inset 上+dockFab 命中回归；inset=0 底条 84 高+FAB 凸出 22 恒等）

**Checkpoint**: dock 贴底达成——005 最显眼缺陷闭环，可独立交付

---

## Phase 3: User Story 2 - 页缘分层对齐 hero 24 / 次级 16 (Priority: P1)

**Goal**: hero 两屏 24 维持、次级四页收敛 16（分层基准，同层跨屏零左右跳动；FR-003，research D2 / clarify 裁定）

**Independent Test**: hero 两屏根容器水平 padding 断言 = padX(24)、次级四页断言 = s4(16)；同层左缘叠加一致（深浅双主题）

- [x] T003 [P] [US2] 全部目标页+我的页页缘收敛：lib/features/goals/goals_all_view.dart 与 lib/features/settings/settings_view.dart 页级水平 `AppSpace.s5`(20)→`AppSpace.s4`(16)（列表档基准；顶栏/筛选行/列表/正文区水平值，卡片内距与垂直节奏不动）+ test/ 次级档页缘断言用例
  - ✅ 实现完成：goals_all 三处页级（ListView/_TopBar/_FilterRow）+ settings 两处（顶栏/ListView）水平 s5→s4；sheet/对话框/胶囊/chip 卡内值零触碰
  - ✅ 门禁通过：analyze 0 + test 164/164（新增 005 T003 一例：goals-all 列表 padding 不变式+筛选首 chip/目标卡左缘=16 同线、settings ListView 同档）
- [x] T004 [P] [US2] 编辑器+详情页页缘收敛：lib/features/goals/goal_editor.dart 与 lib/features/goals/goal_detail.dart 同口径 s5→s4(16)（含正文可滚区；`AppSpace.s5+8` 类垂直裸算式顺手留档说明不强行刻度化）+ test/ 次级四屏（+编辑器/详情）左缘一致（16）用例
  - ✅ 实现完成：编辑器三处（顶栏/ListView/底部主行动区）+ 详情两处（_TopBar/ListView——原左 s2 偏离冻结稿 .dt-list 对称 20 的漂移一并归直）；两处弹层 s5+8 裸算式留档注释；sheet/对话框内距零触碰
  - ✅ 门禁通过：analyze 0 + test 165/165（新增 005 T004 一例：编辑器/详情根 ListView 页缘=16 对称）

**Checkpoint**: SC-001 页缘分层达成（hero 两屏同线 24 + 次级四屏同线 16）

---

## Phase 4: User Story 3 - 轮播首末卡对齐页基准 (Priority: P2)

**Goal**: 今日页关注轮播首卡左缘/末卡右缘 = 页基准，保留对称 peek（FR-004，research D3）

**Independent Test**: 首卡左缘 x==padX、末卡右缘==W−padX、单卡两缘同时成立；既有双向横滑/分支状态回归

- [x] T005 [US3] 今日页结构反转+轮播全出血（D3）：lib/features/today/today_view.dart ListView 水平 padding 归 0、`_Head`/`_RingZone`/`_EmptyCTA` 等非轮播段自包 `Padding(horizontal: AppScreen.padX)`；lib/features/today/focus_carousel.dart 改 `LayoutBuilder` 全宽 W 求 `viewportFraction=(W−2·padX)/W`（PageView 自身无水平 padding）；test/ 卡缘不变式用例（首/末/单卡/peek 可见）+ 既有轮播用例回归
  - ✅ 实现完成：ListView 水平归 0，_Head/_RingZone/cap 行/_EmptyCTA 自包 padX；FocusCarousel 全出血——LayoutBuilder 求 fraction=(W−2·padX)/W（padEnds 默认 true 双端各补 padX），卡内 s2 水平内距拆除（卡占满净宽 342 槽位），controller 随宽变重建保页位
  - ✅ 门禁通过：analyze 0 + test 166/166（新增 005 T005 一例：标题带/cap 行左缘=24、首卡左缘 24、邻卡左缘 366、末卡右缘 366、单卡两缘、页点退化、末卡主行动动线回归）

**Checkpoint**: SC-003 达成——今日页最直观布局缺陷闭环

---

## Phase 5: User Story 4 - 分支切换统一转场 (Priority: P2)

**Goal**: dock 今日↔回顾切换 fade-through（250ms easeStandard 单值），无残影、不错页、保分支状态（FR-005/006，research D4）

**Independent Test**: 切页有 250ms 双段过渡、终态与所点页签一致；快速连点不错页；既有 navTab/深链用例零回归

- [x] T006 [US4] _FadeThrough 分支转场（D4）：lib/app/router.dart `_AppShell` 内新增 `_FadeThrough` StatefulWidget 包 `navigationShell`——`didUpdateWidget` 检测 `shell.currentIndex` 变化驱动 `AnimationController(AppMotion.base, AppMotion.easeStandard)` 双段透明度（前半 1→0 后半 0→1，IndexedStack 瞬切落于视觉最暗帧）；不换子树 Key（保 T022 分支状态）；push 页维持平台默认；test/ 转场终态+快速连点+分支状态保留用例
  - ✅ 实现完成：`_FadeThrough`（TweenSequence 双段 1→0→0→1 各段 easeStandard · AppMotion.base 250ms）包 shell body，索引变即 forward；不换子树 Key/不重建分支；dock 在转场件外连点照常；push 页不经此件；FadeTransition 挂 shellFade key
  - ✅ 门禁通过：analyze 0 + test 167/167（新增 005 T006 一例：首帧 1/中点≈0/末帧 1 双段、终态页签一致、连点 ×3 不错页、weekRange 周锚往返保留）。顺手修 T029 日期脆弱：真实现于周一必炸，「周一 partial/今日 full」几何改 FixedDateProvider 锚 2026-08-19（周三）定死

**Checkpoint**: SC-004 达成——切换生硬闭环；「粘连」待 D4 后复核（T012）

---

## Phase 6: User Story 5 - 顶栏同构 · 触达 44 · 头部对齐 (Priority: P3)

**Goal**: 四个次级 push 页顶栏同构一组件；小图标触达 ≥44；今日铃铛/头像与标题共中线（FR-007/008/009，research D5/D6/D7）

**Independent Test**: 四页顶栏几何叠加一致断言；触达区逐钮 ≥44 断言；头部中线对齐断言

- [x] T007 [US5] 新建共享顶栏 lib/app/page_top_bar.dart（D5+D6）：返回圆钮视觉 38px/触达 44×44（SizedBox+Center 模式）+ 标题 titleM + trailing 槽；水平 padding=AppSpace.s4(16)（次级页列表档，契约 §2）、栏内垂直 s3/s2；hero 两屏不套用
  - ✅ 实现完成：`PageTopBar`——38 视觉圆钮（chevron 24，冻结稿 .ga-btn/.dt-btn 几何）外套 44×44 触达槽 + titleM 标题 + titleAccessory 紧邻配件（计数）+ trailing 右槽 + onBack 可注入（默认 Navigator.maybePop）；水平 s4 / 垂直 s3·s2；返回钮挂 pageTopBarBack key
  - ✅ 门禁通过：analyze 0 + test 167/167（本任务仅立件不接线，同构断言随 T008）
- [x] T008 [US5] 四页顶栏替换（D5，依赖 T007）：goals_all_view（trailing=计数+新建胶囊）、settings_view（无 trailing）、goal_editor（保留 Navigator.maybePop 语义）、goal_detail（trailing=⋯菜单钮）各自手写顶栏退役换 PageTopBar；test/ 四顶栏几何同构断言 + 既有返回/菜单动线用例回归
  - ✅ 实现完成：goals_all（计数配件+新建胶囊）/settings（titleKey 锚+canPop 兜底回今日）/editor（默认 onBack=maybePop 语义零变化）/detail（⋯ 菜单钮入 trailing）四页手写顶栏全退役换 PageTopBar；icon 26→24 对齐冻结稿 .ga-btn/.dt-btn 几何；三处 _BackButton/_TopBar 类删除
  - ✅ 门禁通过：analyze 0 + 新增 005 T008 一例绿（44 触达/38 视觉同心/标题左缘 72 四页同线/详情返回弹栈）；全量回归按用户裁定延至 T011 统一跑
- [x] T009 [P] [US5] 触达 44 扫尾（D6）：lib/features/today/today_view.dart `_CircleButton`（铃铛 36 视觉→44 触达）、lib/features/review/review_view.dart 日历钮、goal_detail ⋯ 若独立于 PageTopBar 的残余小钮——统一 SizedBox(44)+Center 外扩，视觉尺寸零变化；test/ 触达区断言
  - ✅ 实现完成：今日铃铛（36 视觉→44 触达，挂 todayBell key）+ 回顾周切换两钮（30→44，weekPrev/weekNext key 沿用）+ 详情 ⋯ 菜单钮（38→44，T008 后唯一残余小钮，挂 goalMoreButton key）统一 SizedBox(44)+Center 外扩，视觉尺寸零变化
  - ✅ 门禁通过：analyze 0 + 新增 005 T009 一例绿（三处命中区 44/视觉 36·30·38 同心/铃铛中线复验/周切换文案变化/⋯ 弹菜单）；全量回归按用户裁定延至 T011 统一跑
- [x] T010 [P] [US5] 今日头部两行重构（D7）：lib/features/today/today_view.dart `_Head` 改「日期行 + 标题行（标题+铃铛+头像 CrossAxisAlignment.center）」——铃铛/头像视觉中线恒与大标题中线重合；与冻结稿整块居中的 4–6px 有意偏差于 T012 留档；test/ 中线对齐断言 + 头像/铃铛动线回归
  - ✅ 实现完成：_Head 改两行——日期行（labelS+字距）+ 标题行（displayL 大标题+铃铛+头像 CrossAxisAlignment.center）：铃铛/头像视觉中线恒与大标题中线重合（冻结稿整块居中的 4–6px 有意偏差待 T012 留档）；头像/铃铛动线零变化
  - ✅ 门禁通过：analyze 0 + 新增 005 T010 一例绿（三中线重合/两行结构/头像→我的返回弹栈/铃铛→通知弹层）；全量回归按用户裁定延至 T011 统一跑

**Checkpoint**: SC-005 达成——次级页一致性收尾

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: 回归、复核留档与文档收口

- [x] T011 全量回归+quickstart 代码层走查：跑 specs/005-review-bug-fix/quickstart.md 阶段 A–D（深浅双主题逐项）+ 阶段 F 门禁（analyze 0 + 全量绿，既有 161 零回归确认）；FR-009a 抽查（创建/打卡/编辑/暂停恢复删除/通知/资料/备份往返）
  - ✅ 实现完成：quickstart A–D/F 代码层走查全过——A=dock inset 双例（T002）、B=hero 24/次级 16 页缘断言（T003/T004/T005+回顾 padX 核实）、C=卡缘不变式+触达/中线（T005/T009/T010）、D=fade-through 双段+连点+分支状态（T006）、F=FR-009a 全流程由 003/004 套件承（170 全绿）；深色零新阴影（PageTopBar 沿用 surface/divider/shadowLow）
  - ✅ 门禁通过：analyze 0 + test 170/170 全绿（161 基线零回归 + 本轮 T002–T010 新增 9 例）；唯一回归 T032「同带」旧断言系 005 D7 两行重构预期解除，已改留档注释（竖直中线不变式由 005 T010 持有）
- [x] T012 FR-010 复核留档 + reviews.md 续录：模拟器复核「切换粘连」（T006 转场上线后复测）与「今日页大块空白」（对照 24 设计值）——复现则修复补档、未复现记录裁定依据；D7 头部中线与 D2 次级页 20→16 两处冻结稿有意偏差留档；真机项标注沿用 003 T043 合并窗口；design/reviews.md 续「实现审计」条目（T002–T010 各任务结论）
  - ✅ 实现完成：D4 转场上线后「切换粘连」代码层不复现（IndexedStack 同帧换子+_FadeThrough 透明度包壳，旧新页无双绘；模拟器/真机面沿 003 T043 合并窗口待复测）；「今日页大块空白」核 TodayView 垂直节奏 s5/s2/s3 未动、无异常Spacer，裁定为轮播卡内容高度自然留白；D7 头部中线与 D2 次级 20→16 两处冻结稿有意偏差随 reviews.md 留档
  - ✅ 门禁通过：design/reviews.md 续「005 实现审计」条目（T002–T010 逐任务结论+两偏差留档）落库
- [x] T013 文档收口：spec.md Status: Draft→Complete 附收口摘要（四属实全修/两不属实留档/两复核结论）；tasks.md 全勾核对；memory 终态更新
  - ✅ 实现完成：spec.md Status Draft→Complete 附收口摘要（四属实全修/两不属实留档/两复核结论+门禁数字）；tasks.md T001–T013 全勾核对；memory 终态更新（005 完结、留口=真机侧载轮）
  - ✅ 门禁通过：收口前门禁沿 T011 统一门禁（analyze 0 + test 170/170），本轮零代码改动

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1（基线）**: 无依赖，先行
- **Phase 2–6（US1→US5）**: 按优先级顺序执行（US1/US2 同为 P1，先 US1——单文件 router.dart 且为最高优缺陷；US2 两任务 [P] 可并行；US3/US4 相互独立；US5 内 T007→T008 串行、T009/T010 与 T008 不同文件可并行）
- **Phase 7（收口）**: 依赖全部故事完成

### User Story Dependencies

- **US1 (dock)**: 独立（router.dart 单文件）
- **US2 (页缘)**: 独立；与 US5 T008 顶栏替换同文件先后——US2 先行改数值、US5 再换组件（避免双改冲突）
- **US3 (轮播)**: 独立（today_view + focus_carousel；与 US5 T010 同文件不同区，顺序执行）
- **US4 (转场)**: 独立（router.dart；与 US1 T002 同文件——T002 先行）
- **US5 (顶栏/触达/头部)**: T008 依赖 T007；其余独立

### Parallel Opportunities

- T003 ∥ T004（不同 feature 文件，可真并行）
- T009、T010 各自与 T008 并行（不同文件），但 **T009 与 T010 共享 today_view.dart 不可互并行**——顺序执行 T010 → T009
- 多人场景：US1+US4（router.dart）与 US2（四 feature 文件）与 US3（today 两文件）可三线并行（US4 让 US1 先）

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 基线 → 2. Phase 2 US1 dock 贴底 → **STOP 可交付**（最显眼缺陷闭环）
3. Incremental: US2 页缘 → US3 轮播 → US4 转场 → US5 顶栏/触达 → Phase 7 收口

### 每任务节奏

实现（含用例）→ `flutter analyze` 0 + `flutter test` 全绿 → tasks.md 勾选附 ✅ 双子行 → commit `005 T0XX: 中文标题`

---

## Notes

- 修复型任务用例与实现同批提交（无 TDD 先行批）；用例优先断言「不变式」而非像素（契约 layout-metrics.md §1–6 即断言清单）
- 冻结稿偏差两处均为有意裁定：D7 头部中线（4–6px）、D2 次级四页 20→16（clarify 用户裁定，列表密度优化）——T012 统一留档；其余全部为对齐冻结稿意图的修复
- 真机侧载轮沿用 003 T043 合并窗口（本轮 quickstart 阶段 E 两项 + FR-010 真机面）
