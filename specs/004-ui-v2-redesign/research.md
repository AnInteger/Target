# Research: 004 UI v2 重构

基准图 4 张（`references/`）+ spec 澄清七裁决（导航/Focus 轮播/标题/环形态/减分制/推翻边界/原型门禁）为输入。代码勘察基线：003 完结态（analyze 0 / test 128 绿，schema v4）。

## D1 设计令牌重建（推翻「柔彩仪表盘」）

**Decision**: `lib/app/design_tokens.dart` 全量重定义为基准图语言（深 #121212 底 / 浅 #F5F5F7 底、白卡/深灰卡、主色块、大圆角、克制留白），保持 `TargetPalette`（ThemeExtension 浅深成对）+ 字阶/间距/圆角刻度的**结构不变、值全换**；`GoalColor` 8 色枚举退役（colorKey 列 003 已退役不读，枚举随之删除）；三大类常驻色（健康/习惯/目标）进 palette。
**Rationale**: 现有三端真源机制（Flutter ↔ `design/tokens.css` ↔ `ios/TargetWidgets/DesignTokens.swift`）被 003 验证有效——结构保留可让 token_contract_test、小组件快照、原型侧全部继续工作，只换值。spec「推翻边界到交互层」不要求推翻 token 基建。
**Alternatives**: 新建平行 token 文件逐屏切换（否——双真源必然漂移；003 已用扫描测试强制单真源）。

## D2 主题三档切换（跟随系统/浅色/深色）

**Decision**: `SettingsRows` 新增 `themeMode` TEXT 枚举列（`system|light|dark`，NULL=system），schema **v5** 纯 ADD COLUMN（延续 003 T044 惯例）；`MaterialApp` 接 `themeMode:`（现为缺省跟随系统），我的页新设置行三档单选。
**Rationale**: 现有 `theme:`/`darkTheme:` 双主题已就位，缺的只有持久化偏好与注入点——一列一个 provider 即闭环，零迁移风险（ADD COLUMN）。
**Alternatives**: 独立 kv 表 / SharedPreferences（否——Settings 单例是既有惯例，备份编码同步改一处即可）。

## D3 三大类健康度引擎（减分制）

**Decision**: 纯函数 + Riverpod provider（输入 goals + checkIns + today，输出三类分）。口径冻结：**每大类分 = (100 − 3 × 近 7 天零记录活跃目标数).clamp(0,100)**；窗口 = 含今日的滚动 7 天；「零记录」= 窗口内该目标无任何 CheckIns 行（打卡与补签同计，一行即非零）；暂停（非 active）目标不参与；类内零活跃目标 = 无数据态（非满分非 0）。打卡/补签写入 → provider invalidate → 分数即时回升（状态式，无记账表）。
**Rationale**: 用户裁决公式的最直接实现；纯派生零落库，单测可全量对账；Riverpod invalidate 链路是现有打卡流的既有机制。
**Alternatives**: 期望频率归一达成率（用户未选）；扣分记账落库（否——「打卡即清零」在状态式下自动成立，记账表是负资产）。

## D4 大类-小类静态映射（10 领域补全）

**Decision**: `GoalIconDomain` 枚举新增 `major` 属性（`MajorCategory{health, habit, goal}` 中文 健康/习惯/目标）。映射：**健康**=运动/健康/冥想/**社交**/**宠物**，**习惯**=生活，**目标**=学习/创作/旅行/理财。（2026-08-23 更新：social/pets 归健康为用户 clarify 裁定 B，推翻本决策原拟的「习惯」补全）
**Rationale**: spec 裁决覆盖 8 领域，实际库为 10（social/pets 为 003 research D1 后增）——后增两域的归属已由用户 2026-08-23 亲自裁定；映射挂枚举零迁移零存储（领域本就由 iconKey 运行时派生）。
**Alternatives**: Goals 加大类列落库（否——派生即可，落库反而引入与 iconKey 不一致的可能）。

## D5 关注卡轮播

**Decision**: `PageView.builder` + `viewportFraction`（露边暗示可滑）；卡序 = `max(最新 CheckIn.createdAt, goal.createdAt)` 降序；数据源仅 `status == active`，暂停/删除经 provider 自动移出；「查看全部」push 全部目标列表页（`/goals-all`，today 分支子路由）。
**Rationale**: 现有 goalsProvider/checkIns 流已含全部所需信号，轮播是纯视图层；露边卡片是横向滑动惯例 affordance。
**Alternatives**: 单卡+左右箭头（否——移动端手势优先）；HorizontalListView（否——失去逐卡聚焦语义）。

## D6 导航改造（两页签 + 中央 FAB）

**Decision**: `StatefulShellRoute` 3 分支 → 2 分支（today/review）；`/settings` 改为 today 分支子路由（全屏 push，今日页头部头像入口）；底部壳层 `_PillNav` 重做为「今日 | 中央凸起圆形＋ | 回顾」，中央按钮 `context.go('/goal-editor')`（编辑器仍落 today 分支子路由，003 深链语义保留）。
**Rationale**: 分支删除是 go_router 声明式改动；settings 转 push 全屏符合「头像二级页」裁决；深链面（today/review/goal/{id}）无 settings 引用，兜底不受影响。
**Alternatives**: settings 留 shell 内第三分支仅隐藏 tab（否——死代码 + 深链歧义）。

## D7 初始屏（黑底极简品牌屏）

**Decision**: 重做现有 `/onboarding` 首屏视觉：纯深底 + 品牌图形 + 一句中文主张 + 「开始使用」主按钮；`onboardingCompleted` 首启判定机制与既有流不变，仅呈现层推翻。
**Rationale**: 首启判定/深链/设置位（app.dart `_maybeShowOnboarding`）003 已打通且测试覆盖，动机制必引回归——只翻视觉是零风险路径。
**Alternatives**: 新增独立 splash 路由（否——与 onboardingCompleted 双状态源）。

## D8 原型评审门禁（FR-015）执行方式

**Decision**: 延展界面（编辑器/详情/我的/通知/全部列表）先在 `design/prototypes/` 出 HTML 走查稿（003 T007 模式：新令牌先落 `design/tokens.css`，原型即令牌消费者）；评审轮次与裁决记 `design/reviews.md`，全部冻结后才排实现任务。基准图已覆盖的屏（今日/回顾/初始屏/导航）以基准图为实现基准，不再出原型。
**Rationale**: tokens.css 是三端真源的原型侧，原型先行=令牌先行，评审通过即令牌冻结；003 R1–R7 已验证该流程能把返工挡在代码前。
**Alternatives**: 直接在 Flutter 里出原型页（否——改稿成本高一个量级）。

## D9 回顾页三区块数据

**Decision**: 周 view 全量实时派生（不复用 WeeklyReviews 结算快照）：周完成率 = 周内各活跃目标「应记日已记率」的均值口径沿用现有 stats 层（GoalWeekStat），逐日完成度 = 当日有记录目标数/当日活跃目标数，环比 = 本周 vs 上周完成率之差（上周无数据 → 无可比较态）。周切换 = `WeekStart` 参数化 provider。
**Rationale**: WeeklyReviews 是「周一晨结算留痕」，回看往周靠快照会漏掉补签与目标删除的实时口径；现有 statsProvider 已是实时派生体系，扩展比读快照一致性好。
**Alternatives**: 读结算快照（否——补签后快照与实时不一致，spec FR-009 要求与底层记录一致）。

## 基线勘误（相对 spec）

- spec FR-014「八个领域小类」实为**十个**（social/pets 后增）——2026-08-23 clarify 用户裁定 social/pets 归**健康**，FR-014 已改写为十领域口径，spec 与 data-model.md 映射现一致（用户原裁决的 8 项归属未变）。
