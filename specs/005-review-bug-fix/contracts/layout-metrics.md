# Contract: 布局度量契约（layout-metrics）

**消费者**: 屏幕层代码（lib/features/**、lib/app/**）与测试（token_contract_test 扩展、widget 断言）。
**真源**: lib/app/design_tokens.dart（既有 AppSpace/AppScreen/AppRadius/AppMotion 刻度，本轮零新增令牌）。

## 1 · 页缘水平基准（FR-003 / SC-001）

- 全部页面（今日/回顾/全部目标/我的/编辑器/详情）内容左右缘 = `AppScreen.padX`(24)，全 App 唯一。
- 页级与组件级水平 padding 不得叠加出页缘（轮播段按 §3 全出血例外）。
- 测试消费：各页根可滚容器水平 padding 断言 = padX；四屏左缘 x 叠加一致。

## 2 · 次级顶栏几何（FR-007 / FR-008 / SC-005）

- 唯一组件 `PageTopBar`（lib/app/page_top_bar.dart）：返回圆钮视觉 38px + 标题 titleM + trailing 槽；水平 padding = padX；栏内垂直节奏 上 s3 / 下 s2。
- 返回钮触达 44×44（视觉 38 不变）；次级页禁再手写顶栏。
- 今日/回顾 hero 头部（冻结稿结构）不套用本组件。

## 3 · 轮泳卡缘对齐（FR-004 / SC-003）

- `FocusCarousel`：PageView 全出血，`viewportFraction = (W − 2·padX) / W`（LayoutBuilder 取 W）。
- 不变式：首卡左缘 = padX；末卡右缘 = W − padX；对侧 peek = padX；单卡两缘同时成立。

## 4 · 底部 dock 安全区（FR-001/002 / SC-002）

- dock 底幕背景覆盖至屏幕物理底边（高度 = 84 + `MediaQuery.paddingOf.bottom`），inset 区仅背景延伸。
- 互动元素（页签/中央＋）整体上移 inset；触达命中不得缩小；`bottomPadding = 0` 机型几何与既有版恒等。

## 5 · 分支转场（FR-005/006 / SC-004）

- dock 分支切换统一 fade-through：时长/曲线 = `AppMotion.base`(250ms) / `AppMotion.easeStandard`，全 App 单值，禁逐页私设与裸毫秒。
- 转场不得换分支子树身份（保 IndexedStack 状态保留语义）；push 页维持平台默认转场。

## 6 · 今日头部对齐（FR-009）

- 铃铛/头像视觉中线 = 「今日」大标题视觉中线（头部两行结构：日期行 + 标题行居中排）。与冻结稿整块居中的 4–6px 偏差为本轮审查裁定，留档 reviews.md。

## 7 · 不变量（回归红线）

- 004 冻结语言不动：hero 两屏头部结构、配色体系、深色禁重阴影（亮度差分层）、既有 Copy 键。
- 既有 161 例测试口径零回归；测试 key（navTab-*、dockBar、dockFab、goalsAllRow-* 等）不动。
