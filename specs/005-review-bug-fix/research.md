# Research: 005 走查修复轮

**Date**: 2026-08-23 · **Status**: Complete（对应 spec「输入核验结论」表，全部裁定可回溯代码/冻结稿）

全部 NEEDS CLARIFICATION 在 spec 阶段已清零（裁定默认值落 Assumptions）；本文件固化八项实现层技术裁定（D1–D8），plan/tasks 直接消费。

## D1 · dock 贴底（FR-001/002，最高优）

**Decision**: 去掉 `_Dock` 外层 `SafeArea(top:false)`（router.dart:160），改为 dock 自行消费 `MediaQuery.paddingOf(context).bottom`：底条背景高度 = `84 + bottomInset`（下延至物理底边 y=0），页签/FAB 互动槽整体上移 `bottomInset`；`_AppShell` 的 body DecoratedBox 渐变仍在 dock 之下，无断层露底。

**Rationale**: 现状 SafeArea 把整条 dock（含背景）抬离底边，inset 区露出 Scaffold 纯色。背景延伸 + 内容避让是底部栏安全区的标准解法；`bottomNavigationBar` 槽位下 widget 自身高含 inset 即可，无需 `extendBody`。

**Alternatives**: ①`extendBody: true` + 内容底部 padding——改动面大（每页可滚区都要让位）✗；②保持 SafeArea 但给 Scaffold 设 extendBodyBehindScaffolding——不解决背景断层 ✗。无 inset 机型（`bottomPadding=0`）两方案恒等，回归风险为零。

**测试**: widget test 注入 `MediaMediaQuery.padding.bottom=34` 断言 dockBar 底缘 == 屏底、页签 bottom ≥ 34；inset=0 用例断言几何与现版一致。

## D2 · 页级边距统一 24（FR-003）

**Decision**: 四个 push 页（goals_all_view / settings_view / goal_editor / goal_detail）页级水平 padding 从 `AppSpace.s5`(20) 全部收敛到 `AppScreen.padX`(24)——涉及各页顶栏 padding、可滚列表水平 padding、正文区水平 padding。今日/回顾已 24 不动。

**Rationale**: 24 = 003 FR-008 三屏标题带基准 + 004 hero 冻结值；只动次级页、改动面最小（spec Assumptions 裁定）。**只收敛页缘水平值**；卡片内边距、胶囊内距、组件间缝（垂直向）一律不动——那是节奏设计不是页缘漂移。`goal_detail` 中 `AppSpace.s5 + 8` 类裸算式顺手归档说明（垂直底距非本轮口径，不强行刻度化）。

**Alternatives**: 统一 20（动 hero 冻结稿）✗；16（四页全动 + 与冻结 hero 冲突，外部文档建议已驳回）✗。

## D3 · 轮播首末卡对齐页基准（FR-004）

**Decision**: 今日页结构反转——ListView 水平 padding 改 0，`_Head`/`_RingZone`/`_EmptyCTA` 等非轮播段各自包 `Padding(horizontal: AppScreen.padX)`；`FocusCarousel` 段全出血：`LayoutBuilder` 取全宽 W，`viewportFraction = (W - 2*AppScreen.padX) / W`（PageView 自身无水平 padding）。数学上首卡左缘/末卡右缘恒 = padX，对侧邻卡 peek 恒 = padX。

**Rationale**: 现状「页 padding 24 × fraction 0.9」叠加出 ≈41pt 首卡缘（390pt 屏）。全出血 + 按净宽求分数是 peek 轮泳的标准解；卡宽由 ≈308 变 342（更接近冻结稿 .fcard 版心），露边 24 对称。卡内布局弹性，无需改。

**Alternatives**: ①保结构、动态 fraction=(净宽-2*peek)/净宽——首卡缘仍多一层 24，治标 ✗；②`Clip.none + padEnds` hack——负 padding/溢出裁剪不可控 ✗。

**测试**: 断言首卡左缘 x == padX、末卡右缘 == W-padX、单卡两缘同时成立；横滑 peek 可见（既有双向横滑用例回归）。

## D4 · dock 分支切换 fade-through 转场（FR-005/006）

**Decision**: `_AppShell` 内自研 `_FadeThrough` StatefulWidget 包住 `navigationShell`：`didUpdateWidget` 检测 `shell.currentIndex` 变化 → `AnimationController(AppMotion.base 250ms, AppMotion.easeStandard)`，前半段 opacity 1→0、后半段 0→1（IndexedStack 瞬切发生在中点视觉最暗处，等效 fade-through）。不换子树 Key、不重建分支——T022「分支状态保留页位」语义零改动。

**Rationale**: go_router `StatefulShellRoute.indexedStack` 无内建分支转场；`AnimatedSwitcher` 包同一 `navigationShell` 实例不触发（子树身份不变）。双段透明度方案实现 ~30 行、无依赖；转场期间底幕渐变（壳层画布）恒定，最暗帧即回到底幕，视觉自然。时长/曲线全取 `AppMotion` 既有刻度，无裸毫秒。`FadeTransition` 不拦截 hit——快速连点 goBranch 照常，终态由 IndexedStack 决定，无错页。push 页（settings/editor/detail/goals-all）维持平台默认转场不动。

**Alternatives**: ①AnimatedSwitcher + KeyedSubtree——同一 shell 实例不触发，或强换 Key 丢分支状态 ✗；②引入动画路由库——超杀 ✗；③不修（0ms 硬切）——FR-005 驳回 ✗。

**测试**: 切页用例断言转场件在场 + 250ms 后终态页签正确；快速连点（tap×N pumpAndSettle）终态一致；既有 navTab 断言全量回归。

## D5 · 次级顶栏同构 PageTopBar（FR-007）

**Decision**: 新建共享组件 `lib/app/page_top_bar.dart`：结构 = 返回圆钮（视觉 38px 冻结稿几何、触达 44×44）+ 标题（titleM）+ 右侧 trailing 槽；水平 padding = `AppScreen.padX`，栏内垂直节奏 s3/s2（对齐冻结稿 .ga-top/.dt-top 现值）。四处替换：goals_all `_TopBar`（trailing=计数+新建胶囊）、settings 顶行（无 trailing）、goal_editor 顶行（无 trailing；保留其 `Navigator.maybePop` 语义）、goal_detail `_TopBar`（trailing=⋯菜单钮）。

**Rationale**: 四页现况 = 同一形态四份手写（返回 38 + titleM + 各异 trailing），正是审查「四种头部结构」中的次级三种；hero 两屏（今日/回顾冻结稿）不动。组件化后度量变更只剩一处。

**Alternatives**: 逐页改数值不做组件——能过 SC 但留四份拷贝，下次再漂移 ✗。

## D6 · 小图标触达 ≥44（FR-008）

**Decision**: 统一模式：`SizedBox(44×44) + Center(视觉件 36/38px)` 包 InkWell——今日 `_CircleButton`（铃铛 36）、PageTopBar 返回钮（38）、回顾日历钮（38）、详情 ⋯ 钮、编辑器同类钮全部套用。视觉尺寸/冻结稿零变化。

**Rationale**: 36/38 < 44 最低触达标准；外扩命中区是 Flutter 惯用解，无视觉代价。

**Alternatives**: `MaterialTapTargetSize` 全局——只作用于部分组件且波及全库布局 ✗。

## D7 · 今日头部对齐基准（FR-009）

**Decision**: `_Head` 重构为两行：首行日期 label（左）；次行 Row（`CrossAxisAlignment.center`）= 大标题「今日」+ 铃铛 + 头像——铃铛/头像视觉中线恒与大标题中线重合。与冻结稿（v2-today.html `.head align-items:center` 整块居中）存在 4–6px 有意偏差，属本轮审查裁定（审查指出「标题与按钮不共中线」），偏差留档 reviews.md。

**Rationale**: spec FR-009 已裁定；改动仅是头部内部重排，不动配色/字号/信息结构。若真机走查观感劣于冻结稿，回退成本一处。

**Alternatives**: 维持整块居中 + 留档「设计如此」——审查项闭环不充分 ✗。

## D8 · 不修项与待复核项口径（FR-009a/010）

**Decision**: ①「卡片零阴影」「hero 字号混用」两说不属实：浅色卡均挂 shadowLow、今日/回顾同为 displayL 32——不修，核验表留档；②「切换粘连」「今日页大块空白」两项：quickstart 阶段 E 真机/模拟器复核——复现则按缺陷修复并补档，未复现记录裁定依据（D4 转场上线后「粘连」大概率消解——0ms 硬切下的残影感与无过渡直接相关）。

**Rationale**: 代码层未复现项不预写修复；复核结论 100% 留档满足 FR-010。

## 汇总 · 改动面清单

| 文件 | 改动 |
|---|---|
| lib/app/router.dart | D1 dock 贴底 · D4 _FadeThrough |
| lib/app/page_top_bar.dart | D5 新建共享顶栏（含 D6 返回钮 44 触达） |
| lib/features/today/today_view.dart | D3 结构反转+段 padding · D6 铃铛 44 · D7 头部两行 |
| lib/features/today/focus_carousel.dart | D3 全出血 fraction |
| lib/features/goals/goals_all_view.dart | D2 边距 24 · D5 顶栏替换 · D6 |
| lib/features/settings/settings_view.dart | D2 · D5 |
| lib/features/goals/goal_editor.dart | D2 · D5 |
| lib/features/goals/goal_detail.dart | D2 · D5 · D6 |
| lib/features/review/review_view.dart | D6 日历钮 44 |
| test/（既有+新增） | 各 D 对应用例 · 回归 161 基线 |

数据面：零新增实体/字段，schema v5 不动（见 data-model.md）。
