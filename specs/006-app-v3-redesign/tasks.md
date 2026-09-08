# 006 任务清单

> 纪律：T1xx 全部为「原型/规格」阶段；T2xx 起为代码任务，**T101 全屏冻结前不得开工**（FR-001）。

## Phase 0 · 原型与规格

- [x] T001 新令牌 v3 全量换值落 design/tokens.css（?v=v3a；浅深成对 + 玻璃三档 + 色板）
- [x] T002 移植 Figma 七屏 → v3-goals / v3-activity / v3-goal-detail / v3-milestones / v3-record-sheet（含深色与空态画板）
- [x] T003 补画 v3-goal-editor 完整字段（+目标日期/执行节奏/提醒/里程碑管理）
- [x] T004 补画 v3-settings（设置+我的合并 + 备份冲突弹层）
- [x] T005 补画 v3-widget（浅深 × small/medium）
- [x] T006 补画交互件：筛选 sheet（v3-activity ③）+ 日历投入视图（v3-activity ④）+ 管理菜单（v3-goals ④ / v3-goal-detail ③）
- [x] T007 更新 index.html 评审入口 + reviews.md 送审记录（R1）
- [x] T008 specs/006 落档（spec / data-model / contracts / tasks / quickstart / research）
- [ ] T101 **R1 评审**：用户逐屏裁定；含六项待裁（筛选档/日历口径/设置入口/置顶排序形态/菜单文案/编辑器分组）→ 修订 → 冻结
- [ ] T102 令牌 Dart 镜像 design_tokens.dart + DesignTokens.swift + token_contract_test（三端对账）

## Phase 1 · 数据层重建（T101 冻结后）

- [ ] T201 tables.dart 全新 v8 schema（Goals/ProgressRecords/Milestones/Reminders/SettingsRows 精简）+ entities 重写
- [ ] T202 app_database 清库重建（schemaVersion v8，无迁移）；repositories 重写（含置顶排序、记录 CRUD、里程碑达成流）
- [ ] T203 备份 v7：exporter/importer 全新往返 + 冲突确认覆盖 + 旧版本明确拒绝
- [ ] T204 stats_engine v3：weekInvestment / milestoneSummary / dailyInvestment / activityFeed
- [ ] T205 reminder_service 适配（Reminders 结构不变；全局总开关；通知列表链拆除）
- [ ] T206 小组件快照适配（今日记录数 + 最近记录标题；widget_checkin → record 深链）
- [ ] T207 数据层测试：schema/仓库/备份往返/统计口径/提醒排程

## Phase 2 · 壳层与导航

- [ ] T301 design_tokens.dart 接入全 App（TargetPalette v3 浅深 + 玻璃组件参数）
- [ ] T302 router 重构：/goals 默认 + /activity 分支 + /goal/:id + /goal/:id/milestones + /goal-editor + /settings；redirect 兜底（/today /review /onboarding /profile /goals-all）；深链 target:// 更新
- [ ] T303 Liquid Glass dock（双 tab 胶囊 + 记录钮）替换现有三 tab dock
- [ ] T304 删除清单执行：今日页/旧进展页/通知列表/onboarding/评分链/周结算/FrequencyVersions/BusyMode（analyze 0 验证零残留）
- [ ] T305 导航与壳层测试重写（navigation_redesign_test v3）

## Phase 3 · 各屏实现（每屏随屏动线测试）

- [ ] T401 目标页（置顶大卡/列表/空态/管理菜单/置顶排序模式）
- [ ] T402 动态页（周切换/统计卡/里程碑汇总/feed/筛选 sheet/日历投入）
- [ ] T403 目标详情（时间线/里程碑卡/记录 CTA/⋯ 菜单）
- [ ] T404 里程碑页（接下来/已达成/⋯ 管理/添加 sheet/达成流）
- [ ] T405 记录进展 sheet（目标切换/标题+正文/时长快捷档/日期补记/里程碑关联/保存撤销 toast）
- [ ] T406 目标编辑器（完整字段 sheet；新建/编辑同构）
- [ ] T407 合并设置页（资料卡/外观三档/提醒总开关/备份/关于/冲突弹层）
- [ ] T408 小组件 iOS 实现（DesignTokens.swift v3 + 快照 + 深链）

## Phase 4 · 回归收尾

- [ ] T501 测试套件重组：退役 today/progress/notification/onboarding/迁移/评分套件；新增 v3 套件
- [ ] T502 深浅双主题全屏走查 + 对比度矩阵（005 口径，tool/contrast_audit.dart 适配 v3 令牌）
- [ ] T503 web 构建 + Playwright 全动线走查（FR-016 口径映射 v3）
- [ ] T504 V1–V8 老验收口径在新 IA 下逐条映射对账（V6 忙碌模式等已随删除清单终局）
- [ ] T505 门禁：flutter analyze 0 issue + flutter test 全绿
- [ ] T506 文档收口：README/reviews.md 实现审计 + spec Status → Complete + 真机侧载清单
