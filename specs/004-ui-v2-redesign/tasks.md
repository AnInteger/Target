---
description: "Task list for 004 UI v2 重构"
---

# Tasks: 004 UI v2 重构——基准图驱动的双主题视觉语言与页面骨架翻新

**Input**: Design documents from `/specs/004-ui-v2-redesign/`（spec.md 六故事 / plan.md / research.md D1–D9 / data-model.md / contracts/ui-contract.md + health-score.md / quickstart.md 阶段 A–F）

**Prerequisites**: 全部就绪（003 完结态基线：analyze 0 / test 128 绿 / schema v4）

**Tests**: plan.md Testing 已声明三类新用例（token 三端对账 / themeMode 迁移与备份往返 / health_score 口径对账）——对应任务内含测试，随任务同 commit。

**Organization**: 按用户故事分相；FR-015 原型门禁为 US1 相内硬阻塞（T011 冻结前不得实现五个延展屏）。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行（不同文件、无未完成前置）
- **[Story]**: 归属用户故事（US1–US6）
- 每条任务带精确文件路径

## 硬口径（沿 003，每任务必过）

- 每任务 `flutter analyze` 0 issue + `flutter test` 全绿，一任务一 commit：`004 T0XX: 中文标题`，`--author="sunxing <sunxing@users.noreply.github.com>"`
- tasks.md 勾选时任务行下附 ✅ 双子行（✅ 结果 / ✅ 验证）
- 令牌三端（dart / tokens.css / swift）必须一次提交内同步
- 基准图已覆盖屏（今日/回顾/初始屏/导航）以 references/ 为实现基准不出原型；延展五屏以冻结原型为实现基准

---

## Phase 1: Setup

**Purpose**: 基线核验与执行口径落档

- [x] T001 核验实现基线：`flutter analyze` 0 issue + `flutter test` 128/128 绿，在 specs/004-ui-v2-redesign/tasks.md 顶部记录执行口径（commit 格式与 ✅ 双子行约定生效）
  - ✅ 基线核对通过：003 完结态复验 0 issue + 128/128 绿；分支 004-ui-v2-redesign 已立，五件套文档先行入库（65f2414）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（+128）

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 全部故事共同消费的地基——令牌、主题持久化、大类映射

**⚠️ CRITICAL**: US1–US6 的实现任务均不得早于本相完成

- [x] T002 [P] 令牌三端全量换值（D1）：lib/app/design_tokens.dart 重定义 TargetPalette 深浅成对值（深 #121212 底/浅 #F5F5F7 底、主色、大圆角、字阶）+ 三大类常驻色（健康/习惯/目标）+ GoalColor 枚举退役清引用；同提交同步 design/tokens.css 与 ios/TargetWidgets/DesignTokens.swift；更新 test/design/token_contract_test.dart 对账
  - ✅ 三端换值完成：深 #121212/#1E1E1E/#252525 ↔ 浅 #F5F5F7/白卡/中性墨、主强调蓝 #2196F3↔#00B0FF、完成绿 #34C759↔#4ADE80、bgGrad 收近平、玻璃材质近实卡化、字阶 displayL 32/titleM 20·600/bodyL 16；MajorColors 三色（绿/橙/蓝）+ kAvatarRingByKey 8 色 + kCelebrationDotPalette 7 色入真源；GoalColor 枚举删除（colorKey 恒空，5 处调用点迁 accent/positive，Swift goalColor() 退役统一 accent，widget 零行为回归）；tokens.css --goal-* 收编 --major-*，DesignTokens.swift 增 majorColor() 备 T005 接驳
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（+129，新增三端逐键对账用例：CSS :root/dark 17 键 + Swift light/dark 9 键 + GoalColor 三端不复活断言）
- [x] T003 [P] schema v5 主题偏好列（D2）：lib/core/db/tables.dart SettingsRows 新增 themeMode TEXT 枚举（system|light|dark，NULL=system）+ lib/core/db/app_database.dart 纯 ADD COLUMN 迁移 v4→v5 + lib/core/db/repositories.dart 读写 + lib/core/backup/backup_exporter.dart 与 backup_importer.dart 可选键双向宽容（缺失→NULL，沿 T044 note 先例）；test/migration_test.dart 与 test/backup_test.dart 增补（v4→v5 对账 + themeMode 往返）
  - ✅ schema v5 落地：SettingsRows.themeMode TEXT 可空列 + AppDatabase v4→v5 纯 ADD COLUMN + build_runner 再生成；entities 增 AppThemeMode 三档枚举（parse 未知→system）与 Settings.themeMode 字段；仓库 update 写 .name / _to 归一；备份导出可选键（NULL 不导出）、导入 _normThemeMode 缺键/未知值→NULL（=system）；_V3Database 补 settings_rows 表（v5 迁移链旧库 helper 踩空修复）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（+131：新增 v4→v5 迁移对账【存量照读/资料保全/三档往返】+ themeMode 双向宽容【dark 往返/缺键→system/未知值 neon→system/light 重导出】）
- [x] T004 themeModeProvider 与注入：lib/app/providers.dart 新增 themeModeProvider（读 Settings，缺省 system）+ lib/app/app.dart MaterialApp 接 themeMode:（与 003 行为等价，存量用户零感知）（depends T003）
  - ✅ themeModeProvider 落地：watch settingsProvider 映射 AppThemeMode→ThemeMode（未加载/NULL→system），MaterialApp.router 接 themeMode:；Settings 流变化即时生效，存量库 NULL 列 = 003 行为零感知
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（131 全绿零回归；三档写读与持久化往返已由 T003 迁移/备份用例覆盖）
- [x] T005 [P] MajorCategory 与十领域映射（D4）：lib/core/models/goal_icon_catalog.dart GoalIconDomain 新增 major 属性（MajorCategory{health 健康, habit 习惯, goal 目标}；social/pets→health，2026-08-23 用户裁定）+ lib/core/models/entities.dart Goal.majorOf 派生（iconKey→domain→major，未匹配兜底 explore→goal）；test/goal_icon_catalog_test.dart 增十领域归属对账
  - ✅ MajorCategory 枚举（zhLabel 键名 health/habit/goal 冻结）+ GoalIconDomain 增 major 构造参数：fitness/health/mind/social/pets→健康、life→习惯、learning/create/travel/finance→目标（social/pets→健康为用户裁定 B）；Goal.major getter 派生（零落库，未匹配 byKey 兜底 explore→travel 域→目标大类，与 data-model.md 结论一致——原文「创作域」为笔误）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（133 全绿 = 131 + 新增十领域归属对账、Goal.major 派生兜底两用例）

**Checkpoint**: 地基就绪——令牌/主题持久化/大类映射可用，用户故事可开工

---

## Phase 3: User Story 1 - 全局设计语言 v2：双主题基准 + 原型门禁 + 延展屏重做 (Priority: P1) 🎯 MVP

**Goal**: 基准图视觉语言落为三端令牌并全屏消费；延展五屏出原型、评审冻结、按冻结稿实现；主题三档可达

**Independent Test**: 系统深浅两模式逐页走查无旧风格残留；我的页三档主题即时生效重启保留；五延展屏有冻结原型为实现基准；功能动线全通（quickstart 阶段 A+B）

### 原型稿（FR-015 门禁输入，均消费 T002 后的 design/tokens.css）

- [x] T006 [P] [US1] 编辑器原型稿 design/prototypes/v2-goal-editor.html（三类型/分类图标/提醒频率+时间/一句话描述/保存，新语言延展设计）
  - ✅ 四板：浅色·习惯创建（模板条+类型三段+一句话描述 0/40+分类 6 常用+更多弹层+提醒开关每天 08:00）/ 深色·短期创建（截止必填 2026-11-30+倒计时 100 天+保存点亮）/ 浅色·分类全量弹层（10 域分组大类色点）/ 深色·长期编辑（类型锁定+提醒关态）；形态决策（全屏 push 无底签、底部固定保存 CTA、类型编辑锁定）与 FR-016 对账入文件头
- [x] T007 [P] [US1] 详情原型稿 design/prototypes/v2-goal-detail.html（打卡+选填描述/补签/历史/达成续期/编辑/暂停恢复/删除）
  - ✅ 五板：浅色·习惯详情（大类色 hero+meta+今日记录卡+7 天点阵含补签+历史 3 条）/ 深色·短期详情（倒计时 hero+里程碑进度+标记达成/续期）/ 浅色·补签弹层（14 天日历，已记青柠描边、未来禁用）/ 深色·管理菜单+删除确认（⋯ 菜单+居中 dlg）/ 浅色·暂停态（琥珀横幅+恢复+hero 降不透明度）
- [x] T008 [P] [US1] 我的页原型稿 design/prototypes/v2-settings.html（主题三档行/通知设置/备份导出恢复/资料编辑入口）
  - ✅ 五板：浅色·我的页全页（me 卡+外观组 3 行选中对勾+通知/目标/数据/关于组，inset-groups）/ 深色·我的页（深色选中态）/ 浅色·按目标提醒展开（二级缩进骑行/读书行）/ 深色·资料编辑弹层（昵称+8 头像环色，kAvatarRingByKey 镜像为例外声明）/ 浅色·恢复备份确认 dlg
- [ ] T009 [P] [US1] 通知列表原型稿 design/prototypes/v2-notifications.html（时间倒序/类型图标/空态）
- [ ] T010 [P] [US1] 全部目标列表原型稿 design/prototypes/v2-goals-all.html（兼承 US3「查看全部」屏：分类筛选单选/进详情/管理动线）

### 评审门禁

- [ ] T011 [US1] 原型评审门禁：用户逐屏走查 design/prototypes/ 五稿，通过/返工裁决与轮次记 design/reviews.md，全部冻结后方可实现（**阻塞 T012–T016 与 T023**；返工循环至全冻结）

### 实现（按冻结稿）

- [ ] T012 [US1] 我的页换装：lib/features/settings/settings_view.dart 按冻结稿重做 + 主题三档单选行（消费 themeModeProvider，即时生效持久保留）
- [ ] T013 [P] [US1] 编辑器换装：lib/features/goals/goal_editor.dart 按冻结稿重做（连带 lib/features/goals/goal_templates.dart 与 goal_type_badge.dart 控件形态；FR-016 底线零丢失）（depends T011）
- [ ] T014 [P] [US1] 详情换装：lib/features/goals/goal_detail.dart 按冻结稿重做（打卡/补签/历史/标记达成/续期/编辑/暂停恢复/删除全可达）（depends T011）
- [ ] T015 [P] [US1] 通知列表换装：lib/features/notifications/notification_list.dart 按冻结稿重做（倒序/类型图标/空态）（depends T011）
- [ ] T016 [P] [US1] 资料编辑与调试时钟换装：lib/features/profile/profile.dart + lib/features/settings/debug_clock.dart 新语言重做（depends T011）
- [ ] T017 [US1] 文案语域全量清查：lib/core/copy.dart 与各屏新写文案过 FR-012（正式语域、无口语化解释句、无本地存储说明；基准图模板残留英文零进入）

**Checkpoint**: 设计语言全屏落位，延展屏功能能力零丢失，双主题可走查

---

## Phase 4: User Story 2 - 今日页骨架 v2：新头部 + 三大类健康度环 (Priority: P1)

**Goal**: 今日页重组为「头部 + 三环嵌套健康度 + 空态」；减分制健康度纯派生落地

**Independent Test**: 造健康 2 目标（其一 7 天前记录）+ 习惯 1 今日打卡 + 目标 1 暂停 → 三环 97/100/无数据；打卡后即时回升；点头像进我的页（quickstart 阶段 C）

- [ ] T018 [P] [US2] HealthScore 纯函数：lib/core/models/health_score.dart（新文件，口径=contracts/health-score.md：100−3×近 7 天零记录活跃目标数，clamp(0,100)；窗口含今日滚动 7 天；补签同计；暂停不参与；类内零活跃=无数据态）+ test/health_score_test.dart 全量对账（含跨天窗口右移、穿底夹 0）
- [ ] T019 [US2] healthScoreProvider：lib/app/providers.dart（goals/checkIns/today 任一流变化失效重算，dayTicker 跨天联动窗口右移）（depends T005, T018）
- [ ] T020 [US2] 今日页头部与三环：lib/features/today/today_view.dart 重做——中文「星期, 日期」行 + 大标题「今日」+ 右上头像入口（同一连续图层无分隔线）+ 三环同心嵌套组件（三类各一色、独立计分无综合分、无数据态、全库零活跃环区让位空态新建 CTA）（depends T002, T019）

**Checkpoint**: 今日页骨架与基准图 01/02 头部+环区对应，健康度与手工核算一致

---

## Phase 5: User Story 3 - 关注卡轮播 + 查看全部 (Priority: P1)

**Goal**: 今日页环区下方为活跃目标主色关注卡轮播；「查看全部」进全部目标列表

**Independent Test**: 3 目标其一打卡 → 轮播 3 卡最近互动居首可滑动；主行动按钮直达详情；查看全部开列表筛选管理可用（quickstart 阶段 D）

- [ ] T021 [P] [US3] 关注卡轮播组件：lib/features/today/focus_carousel.dart（新文件；PageView.builder+viewportFraction 露边；卡序=max(最新 CheckIn.createdAt, goal.createdAt) 降序仅 active；状态标签+目标名+一句话描述+主行动按钮+辅助行；单卡退化无滑动指示）
- [ ] T022 [US3] 轮播接入今日页：lib/features/today/today_view.dart（环区下方挂载；主行动按钮进该目标记录动线；「查看全部」入口；暂停/删除经流实时移出）（depends T020, T021）
- [ ] T023 [US3] 全部目标列表页：lib/app/router.dart 新增 /goals-all（today 分支子路由）+ lib/features/goals/goals_all_view.dart（新文件，按冻结稿 v2-goals-all 实现：全部+各小类单选筛选、筛选空态说明、进详情/编辑/暂停恢复/删除全动线）（depends T011 冻结, T022）

**Checkpoint**: 今日页三区块（头部/三环/轮播）齐，浏览与管理职能迁移至列表页完成

---

## Phase 6: User Story 4 - 底部导航改版与「我的」页去向 (Priority: P2)

**Goal**: 底部导航收敛两页签 + 中央凸起新建按钮；我的页收进头像二级入口

**Independent Test**: 任意页面底部恒为「今日 | 中央＋ | 回顾」；中央按钮 ≤1 交互直达编辑器；头像进我的页职能 ≤2 击可达（quickstart 阶段 D）

- [ ] T024 [US4] 路由两分支改造：lib/app/router.dart StatefulShellRoute 3→2 分支（today/review）；/settings 改 today 分支全屏 push 子路由；/goal-editor 保持 today 子路由；/goals 兜底 /today 核验
- [ ] T025 [US4] 底部导航壳重做：lib/app/router.dart _PillNav 换新语言——今日 | 中央凸起圆形＋ | 回顾，任意页面恒定，中央按钮直达 /goal-editor（depends T024）
- [ ] T026 [US4] 导航与深链回归：test/widget_test.dart 用例更新（target:// today/review/goal/{id} 映射不变；第三页签移除后旧断言清退；头像→我的页职能可达核验）（depends T024, T025）

**Checkpoint**: 导航结构全局恒定，深链面零回归

---

## Phase 7: User Story 5 - 回顾页 v2 三区块 (Priority: P2)

**Goal**: 回顾页按基准图 04 重构为周平均/每日活动/本周目标三区块，实时派生支持周切换

**Independent Test**: 2 目标跨 3 天打卡 → 周平均与手工核算一致；七天圆点打卡日着色未来日不完成；切上周数据正确且上周无数据环比「无可比较」（quickstart 阶段 E）

- [ ] T027 [P] [US5] 周视图派生扩展：lib/core/stats/stats_engine.dart（周完成率沿用 GoalWeekStat 实时口径；逐日完成度=当日有记录/当日活跃；环比=本周−上周、上周零应记→无可比较；WeekStart 参数化周切换）+ test/stats_engine_test.dart 对账（不读 WeeklyReviews 快照）
- [ ] T028 [US5] 回顾页头部与周平均区块：lib/features/review/review_view.dart 重做——小字语义位 + 大标题「回顾」+ 周切换入口 + 完成率环与环比（depends T002, T027）
- [ ] T029 [US5] 每日活动与本周目标区块：lib/features/review/review_view.dart 续——七天圆点行（M–S 语义、按完成度着色、未来日不完成态）+ 本周目标列表（目标名+线性进度+百分比）+「查看全部」入口 + 空态引导 CTA 直达编辑器（depends T028）

**Checkpoint**: 回顾页三区块与基准图 04 对应，统计口径与底层记录一致

---

## Phase 8: User Story 6 - 初始屏 v2 黑底极简品牌屏 (Priority: P2)

**Goal**: 首启初始屏视觉重做为深底品牌屏，机制不动

**Independent Test**: 清数据冷启动 → 品牌图形+中文主张+主按钮 → 今日页；再次启动不再出现（quickstart 阶段 E）

- [ ] T030 [US6] 初始屏视觉重做：lib/features/goals/onboarding.dart（纯深底+品牌图形+一句中文主张+「开始使用」主按钮；onboardingCompleted 判定机制不变；无注册/登录/条款/社交证明）（depends T002）

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: 全功能回归、双主题走查、全量对账与文档收口

- [ ] T031 FR-016 全功能回归：按 quickstart 阶段 F 清单全动线走查（创建三类型/分类图标/提醒频率+时间/打卡+描述/补签/编辑/暂停恢复/删除/通知/备份导出→清库→恢复含 themeMode 往返/资料/统计），结论记 design/reviews.md 实现审计
- [ ] T032 双主题全页走查与图表可辨核验：系统深浅各一轮全部页面（quickstart 阶段 B/E；FR-013 完成态与未完成态不单靠色相；SC-001/SC-002/SC-003 逐条核），问题项修复后复走查
- [ ] T033 全量回归收口：flutter analyze 0 + flutter test 全绿（既有 128 项零回归 + 004 新增用例全量）；SC-004/SC-005/SC-006 对账结论落 quickstart「完成口径」
- [ ] T034 文档收口：design/reviews.md 004 实现审计条目齐、spec.md Status: Complete、specs/004-ui-v2-redesign/tasks.md 全勾无留口

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖，立即开工
- **Foundational (Phase 2)**: 依赖 Phase 1；**阻塞全部用户故事**（T002 令牌阻塞一切视觉实现；T003/T004 阻塞主题三档；T005 阻塞三环与关注卡三色）
- **US1 (Phase 3)**: 依赖 T002（原型消费 tokens.css）；**T011 评审门禁阻塞 T012–T016 与 T023**——延展屏实现一律在冻结后
- **US2 (Phase 4)**: 依赖 T002/T005；T019 依赖 T018；T020 依赖 T019
- **US3 (Phase 5)**: 依赖 T020（今日页骨架）；T023 依赖 T011（goals-all 冻结稿）
- **US4 (Phase 6)**: 依赖 T012（我的页换装后再迁路由）；T025 依赖 T024
- **US5 (Phase 7)**: 依赖 T002；T027 可与 US1 实现任务并行
- **US6 (Phase 8)**: 依赖 T002，独立可并行
- **Polish (Phase 9)**: 依赖全部故事完成

### User Story Dependencies

- US1 为其余故事的视觉地基（P1 先行）；US2/US3 同属今日页须按序（骨架→轮播）；US4 在 US1 我的页换装后落地；US5/US6 独立
- 跨故事共享实体已前置：MajorCategory（T005→US2/US3）、themeMode（T003/T004→US1）、tokens（T002→全部）

### Parallel Opportunities

- Phase 2：T002 ‖ T003 ‖ T005（三块互不相交）
- Phase 3：T006–T010 五份原型稿并行（不同文件）；T013 ‖ T014 ‖ T015 ‖ T016（冻结后不同屏）
- Phase 5–8：T027（stats 纯派生）与 US3/US4/US6 的 UI 任务并行
- 单人执行时按相序串行即可，[P] 供跳排参考

---

## Parallel Example: User Story 1

```bash
# 原型五稿并行（均只消费 design/tokens.css，互不相交）：
Task: "编辑器原型稿 design/prototypes/v2-goal-editor.html"
Task: "详情原型稿 design/prototypes/v2-goal-detail.html"
Task: "我的页原型稿 design/prototypes/v2-settings.html"
Task: "通知列表原型稿 design/prototypes/v2-notifications.html"
Task: "全部列表原型稿 design/prototypes/v2-goals-all.html"
# → T011 用户评审冻结 → 实现四屏并行开工
```

---

## Implementation Strategy

### MVP First (Phase 1 + 2 + US1)

1. Setup + Foundational（令牌/主题/映射地基）
2. 原型五稿 + 评审冻结（FR-015）
3. US1 实现（延展屏换装 + 主题三档 + 语域清查）
4. **STOP and VALIDATE**: 双主题走查 + 功能动线（quickstart A+B）——此时设计语言 v2 已全局成立

### Incremental Delivery

- US1（设计语言+门禁）→ US2（今日页骨架+三环）→ US3（轮播+列表）→ US4（导航）→ US5（回顾）→ US6（初始屏）→ Polish 收口
- 每相完成即独立可验（各相 Independent Test 即 quickstart 对应阶段）；任意 checkpoint 可暂停不破坏已有绿色基线

---

## Notes

- [P] = 不同文件且无未完成前置；单人串行执行时按相序即可
- 每任务一 commit（`004 T0XX: 中文标题`），analyze 0 + test 全绿方可勾选，勾选附 ✅ 双子行
- 延展屏实现基准=冻结原型（design/prototypes/v2-*.html）；基准图屏实现基准=references/ 四图——两套基准不混用
- 原型返工不改任务编号，轮次记 design/reviews.md（003 T007/R1–R7 模式）
