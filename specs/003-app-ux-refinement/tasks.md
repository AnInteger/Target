# Tasks: App 体验精修（三 Tab 收敛 + 编辑器重构）

**Input**: Design documents from `/specs/003-app-ux-refinement/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: 沿用 002 惯例——不单列测试任务，测试随实现任务内嵌（每个实现任务的完成口径含 `flutter analyze && flutter test` 全绿 + 该任务新增/改写用例的验收断言；quickstart.md 阶段 B 为回归底线）。

**Organization**: 按 user story 分组。Phase 1 原型先行 + Phase 2 数据/口径地基阻塞全部故事；Phase 3–7 一 story 一 phase（US1/US2 = P1，US3/US4/US5 = P2）；Phase 8 收尾横切。

**评审门禁（002 T025 惯例延续）**: Phase 1 的 T007 未通过（用户原话记 `design/reviews.md`）前，**不得开始任何 Flutter 结构任务（T015 起）**；纯数据层任务（T008–T014）不受门禁阻塞，可与原型送审并行。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行（不同文件、无未完成依赖）
- **[Story]**: 所属 user story（US1–US5）；Setup/Foundational/Polish 无 story 标签
- 全部任务含精确文件路径

---

## Phase 1: Setup（原型先行与送审）

**Purpose**: 三 Tab 新骨架先出 HTML 原型送用户浏览器裁决——结构类实现任务的门禁

- [x] T001 设计算法令牌检视：对照三屏新结构（通知列表/设置分组行/编辑器分组卡）审查 `design/prototypes/tokens.css`，缺的令牌（如 sheet 底、分组卡底、角标红点）先改 tokens.css 再镜像 `lib/app/design_tokens.dart`（三端真源惯例，本特性预计少量新增）
  - ✅ 2026-08-22：新增 --scrim（弹层遮罩）/--badge/--badge-on（未读角标，目标色系退役后语义化独立）浅深成对；design_tokens.dart 构造/字段/浅深/copyWith/lerp 全同步，analyze 零问题 69 测试全绿；另建 design/prototypes/goal-icons.js 原型共享图标模块（research D1，40 枚 Material rounded path，供 T002–T005 消费）
- [x] T002 [P] 今日页原型 R5：重构 `design/prototypes/screen-today.html`——三页签胶囊导航（今日/回顾/我的）、头部同图层无分隔线（左账号区 头像环+昵称 | 中日期语 | 右铃铛+＋）、今日之环「今天记录了吗」0→1（类型微标：习惯节律点/短期倒计时 chip/长期 ∞）、目标卡列表（图标+一句话+类型徽章+打卡态）、底部周节奏微条；画板含 典型/空态/深色
  - ✅ 2026-08-22：全量重写 ~740 行，5 画板（典型交互/空态/全记录/典型深/全记录深）；环 0→1 按当日打卡点亮、双 sheet（资料/通知列表四源语言+空态语）、周节奏微条近 7 天滚动窗；Playwright 34 断言走查全过（环点亮/角标/sheet/类型徽章/周条映射）；T004 轮对齐修正：st-scroll 顶垫 24→0 使带顶与回顾/我的同至 56px（FR-008 三屏竖直基准），hero 自带 margin 不受影响
- [x] T003 [P] 编辑器原型 R2：重构 `design/prototypes/screen-editor.html`——三分组折叠（基础信息一句话输入 / 类型分段选择+短期截止或习惯提醒开关 / 图标九宫格）、标准控件形态（文本框/分段/开关/时间选择器）、类型切换联动显隐、保存常驻底部、底部 Tab 可见；画板含 三类型各一 + 深色
  - ✅ 2026-08-22：fork 产出、主会话 Playwright 独立复核 15/15——三分组可折叠（.grp-h 点按）、类型分段联动显隐含 rise 动画、图标九宫格 10 领域分区选中反白、保存「建好这个目标」常驻 ed-savebar、三页签导航今日 chipx 选中；4 画板（默认短期/长期/习惯提醒开/深色短期）；倒计时含 0/负值文案（就是今天/已过 N 天，D4 细化）；placeholder「一句话说清它，比如：月底前能连续跑 3 公里」
- [x] T004 [P] 回顾页原型 R4：改 `design/prototypes/screen-review.html`——空态画板（竖直居中+引导文案+「新建目标」主按钮）、三屏标题对齐并排基准稿（今日/回顾/我的 左缘缩进与竖直基线一致）
  - ✅ 2026-08-22：四画板（典型周/空态/深色/对齐基准稿）；空态竖直居中（内容盒偏差 0）+七格空圈（末格虚线=将开始的那天）+CTA 直达 screen-editor（FR-007 ≤1 交互）；三页签收敛（目标 tab 退役）；导轨 56/86 与三列实测严丝合缝——三屏对齐实测：带顶 56/带高 52/左缘 24/行中心 30 全一致（今日侧配套修 st-scroll 顶垫 24→0 见 T002 commit；我的侧 gl-top 补 min-height 44 见 T005 commit）；另补 tokens.css --font-display-s（700 22px/1.3，此前 review:67/settings:64 引用中静默回退，Dart displayS 已存在仅 CSS 缺口；字阶九档→十档，index.html 画廊同步）
- [x] T005 [P] 我的页原型 R3：重构 `design/prototypes/screen-settings.html`——账号卡（头像+昵称+编辑）+ 分组列表（通知/目标/数据/关于），行 = 图标+标题+行尾（值|开关|箭头）；画板含 深色
  - ✅ 2026-08-22：fork 产出、自带无头截图验证——「我的」头部（--font-display-s，T004 补令牌后 22px/700 生效）+ 账号卡 + 分组 通知/目标/数据/关于（行=图标+标题+行尾值|开关|箭头）+ 按目标提醒二级展开（003 频率档副题）+ 资料 sheet（浮于导航上、8 预设头像 22% 环色底）；3 画板（典型/sheet 弹起/深色）；gi() 仅用于目标内容行首沿用线性语言；T004 轮并入对齐微调：gl-top 补 min-height 44 + 底垫归 0（带顶 56/左缘 24/行中心 30 与今日/回顾实测一致）
- [x] T006 归档声明：`design/prototypes/screen-goals.html` 顶部加横幅——「003 三 Tab 收敛：目标页退役，职能并入今日页卡与详情动线」，文件不再维护
  - ✅ 2026-08-22：归档横幅（goal-amber 边+12% 底内联令牌取值，链接指 screen-today.html）+ title 改「目标列表（已归档）· Target」
- [x] T007 评审门禁：四屏原型起本地服务（`cd design && python3 -m http.server 8390`）送用户浏览器裁决，结论原话记 `design/reviews.md`；未通过则返工对应 T002–T005，通过后方可动 T015 起 Flutter 结构任务
  - ✅ 2026-08-22：四轮收敛——R1 四条反馈（09a138e 返工）→ R2 三裁决（图标区改「分类」+常用行+更多弹窗 / 今日卡整卡可点+最新记录行 / 今日之环移除）→ R3 三裁决（周节奏微条移除 / 更多按钮溢出修复+「保存」改名 / FR-021 文案正式语域，6daf11a 返工）→ **R4 通过**（用户原话「好的，现在评审完成了」，无新增反馈）。最终基准：今日 R7 / 编辑器 R3 / 回顾 R4 / 我的 R3；裁决全程原话入档 design/reviews.md；T015 起 Flutter 结构任务解锁

---

## Phase 2: Foundational（数据与口径地基，阻塞全部故事）

**Purpose**: schema v3、类型模型、图标库、统计口径收敛——所有故事的地基

**⚠️ CRITICAL**: US1–US5 的实现任务全部依赖本相位完成（可与 Phase 1 送审并行推进）

- [x] T008 GoalIconCatalog 常量：新建 `lib/core/models/goal_icon_catalog.dart`——≥9 领域约 40 枚 Material rounded `IconData`（`Icons.*_rounded`，research D1 清单）+ 稳定 key（即持久化 iconKey 值域）+ 旧 iconKey→新 key 迁移映射表 + 领域中文名；配套单测（key 唯一性/领域覆盖 ≥9/映射完备）入 `test/widget_test.dart` 或新 `test/goal_icon_catalog_test.dart`
  - ✅ 2026-08-22：38 枚 / 10 领域（中文 zhLabel）+ byKey（未知兜底 explore）+ byDomain + legacyIconKeyMap 旧 12 键一次性换域 + migrateIconKey；新 test/goal_icon_catalog_test.dart 7 测试（含 JS 键名对账防两侧漂移）——analyze 0 issues、76 tests 全绿；camping 键 SDK 无此图标事件 → 换 cabin（curl 官方 symbols path 三文件同步：dart 枚举/js 模块/对账清单）
- [x] T009 schema v3 迁移：`lib/core/db/tables.dart`——Goals: kind→goalType（TEXT 枚举 longTerm/shortTerm/habit）+ 新列 achievedAt（TEXT Instant NULL）+ colorKey 退役置 NULL（可空化）；Reminders: +cadence（TEXT 枚举 daily/threeDay/weekly，NULL=daily）；SettingsRows: +nickname/avatarKey（TEXT NULL）。`lib/core/db/app_database.dart`：schemaVersion 2→3 + onUpgrade 按 research D3 映射（deadline 非空→shortTerm；daily/weekdays 频率版本→habit+cadence=daily；weekly→habit+cadence=weekly；余→longTerm）+ iconKey 按 T008 映射换域 + cadence 补档 + colorKey 置 NULL；`dart run build_runner build` 重新生成
  - ✅ 2026-08-22：schemaVersion=3 落地；colorKey 弛豫 NOT NULL 实为整表重建（SQLite 无法 ALTER 弛豫，v1/v2 库直接 UPDATE NULL 会炸约束——比计划多一步重建，其余按 D3 决策树/图标换域/cadence 补档/默认提醒行全数落地）；repositories/exporter/importer 三处最简桥接（T011 拆）；analyze 0 issues + flutter test 76/76 绿（migration_test 两旧用例升格 v1→v3 口径：夹具补齐迁移触碰的三张关联表、断言按 D3 重映射）
- [x] T010 迁移对账测试：`test/migration_test.dart` 增四分支存量用例（milestone+截止 / habit+daily / habit+weekly / 暂停 milestone）——升级后目标/打卡/记录/补签计数逐项一致、goalType 符合映射、colorKey=NULL、FrequencyVersions 原样保全
  - ✅ 2026-08-22：_V2Database 夹具四分支（milestone+截止/habit+daily/habit+weekly/暂停 milestone）落库→v3 开库对账——goalType 四映射、iconKey 换域、colorKey 全 NULL、打卡计数/状态/补签逐项一致、FrequencyVersions 原样、提醒三分支（补档 daily/补默认行 09:00 关 weekly/每日概要不动）；对账逼出真 bug：habitGoals 原收录全部目标致非 habit 也被补默认提醒行，修为仅 habit 入表；analyze 0 + 77/77 绿
- [x] T011 entities 演进：`lib/core/models/entities.dart`——GoalType{longTerm,shortTerm,habit} 替换 GoalKind、Goal.+achievedAt、Reminder.+cadence、新 Profile VO（nickname/avatarKey）；全库引用点（repositories/goal_editor/goal_detail/stats 等）机械迁移至编译绿
  - ✅ 2026-08-22：GoalKind 全域退役——Goal.goalType/achievedAt（短期必填截止双断言、achieved 收窄为非 habit）、Reminder.cadence（NULL=daily + effectiveCadence）、Profile VO（SettingsRepository.getProfile/updateProfile）；T009 三处桥接拆除（repositories 直映射 colorKey ''⇔NULL、importer 宽容两值校验 _oneOf）；isMilestone 消费面按语义分流（截止/步骤 UI→isShortTerm、今日二分组→!isHabit、频率行→isHabit）；editor 二元开关暂映射 shortTerm/habit（US2 重构三段选择器）；analyze 0 + 77/77 绿
- [x] T012 stats 口径收敛：`lib/core/stats/stats_engine.dart`——停算适用日/达标判定（FrequencyPattern.isApplicableOn 退出调用图），输出收敛为 streak/周留痕/周记录数/全完成日（contracts/goal-type-model.md 口径表）；今日环改「当日 ≥1 次打卡」0→1 封顶；同步改写 `test/stats_engine_test.dart` 受影响断言
  - ✅ 2026-08-22：引擎全量重写（DayStatus{doneCount,backfilledCount,done}、streakOf/totalStreak/allCompleteToday、weekStatOf{metDays,totalChecks}、totalWeekStat 去重留痕日、battery=done 占比、evaluate 去 frequencyVersions）；GoalWeekStat 实体改 metDays/totalChecks；消费面九文件接新口径（providers/repositories/backup_exporter/widget×2/settlement/review/today/goals/reminder）+ 今日页局部 streak 收敛进 totalStreak；today 环「周三不在一二仍催」按退役口径翻转；备份 importer 快照校验新键必填/旧键（applicableDays/completionRate）宽容放行；测试五文件改写全绿 78/78、analyze 0
- [x] T013 FrequencyVersions 停写：`lib/core/stats/versioning.dart` 及调用点——新目标不再创建频率版本，存量整表只读保全；`test/frequency_version_test.dart` 改写为「停写+保全」断言
  - ✅ 2026-08-22：仓储删除四个写入 API（addInitial/addUserEdit/addBusyMode/removeBusyMode）只留 versionsOf/watchAllVersions；busy_mode 只记会话（busyModeApplied 取自 sessions）；settlement adjust 决策停写（pause 保留）；编辑器创建/编辑路径去版本写入 + 摘「下周生效」提示；versioning 纯函数保留供回显；备份 importer 直插还原=保全不冲突；测试夹具 version_seed.dart 直插存量行，frequency_version_test 改写「新目标零版本行/直插照读回显」，widget/backup/settlement 调用点机械换 seedVersion；analyze 0 + 76/76 全绿
- [x] T014 [P] 文案层：`lib/core/copy.dart`——默认昵称「我」、通知列表空态语「这里会出现你的提醒和值得记下的时刻」、编辑器分组标题（基础信息/目标类型/图标）、短期到期询问「到日子了，怎么样？」、类型徽章名（长期/短期/习惯）等新文案常量
  - ✅ 2026-08-22：新增 003 文案段（profileDefaultNickname/notificationEmptyHint/editorSection×3/typeBadge×3/shortTermDueAsk/cadence×3，均注明契约出处）；顺手清三枚死常量（editorKindHabit/editorKindMilestone/editorNextWeekEffect——后者 T013 停写后无消费方）；analyze 0 + 76/76 全绿

**Checkpoint**: 数据层就绪——四分支迁移对账绿、stats 新口径绿、目录编译绿；Phase 1 门禁通过后即可进故事相位

---

## Phase 3: User Story 1 - 三 Tab 收敛与今日页头部重组 (Priority: P1) 🎯 MVP

**Goal**: 页签收敛为 今日/回顾/我的；今日页头部同图层化（账号区/通知列表/＋新建）；目标管理职能在三 Tab 内闭环

**Independent Test**: 任意界面底部恒三页签；今日卡→详情→编辑/暂停/恢复/删除全程不出三 Tab；顶栏滚动无分隔线；点头像改昵称即时生效；点铃铛见通知列表非设置

### Implementation for User Story 1

- [x] T015 [US1] 路由三分支：`lib/app/router.dart`——StatefulShellRoute 四分支→三分支（today/review/settings→「我的」），`/goal-editor` 与 `/goal/:id` 从根路由移入 today 分支子路由（FR-010 根因修复，research D5），`/goals` 路由退役 + 深链兜底改落 `/today`；`test/widget_test.dart` 增路由结构断言（页签恰 3、编辑器内导航可见、/goals 兜底）
  - ✅ 2026-08-22：三分支 + editor/详情落 today 分支（分支内多顶层路由，导航壳层全程在场）；`/goals` 退役走 GoRouter redirect→/today；mapDeepLink 顺手修潜伏 bug——原生 widget 深链实为 host 式 `target://goal/{id}`，旧判定 `pathSegments.length > 1` 恒假导致 goal 卡点击从未命中 id 分支（改取首段 + query 兜底）；新用例 2（页签恰三枚/编辑器内导航在场+/goals 兜底+深链两态）；analyze 0 + 77/77 绿
- [x] T016 [US1] goals_view 退役：删除 `lib/features/goals/goals_view.dart`，浏览/管理职能落点确认（今日页卡列表承载浏览，详情承载管理）；清除全部残留引用
  - ✅ 2026-08-22：文件删除，全库零残留引用；今日页 `_SectionHeader` 去「查看全部」死导航（onViewAll 参数与 InkWell 退场，节头收敛为「今日目标」单标签——T017 将按 R7 重构为「今日目标+已记录 x/n」）；列表语言旧用例（为什么第二行/暂停恢复/小结行）随视图退役删除——暂停机制仍有 settlement_test 覆盖，UI 恢复入口由 T021 详情管理动线补回；analyze 0 + 77/77 绿
- [ ] T017 [US1] 今日头部重组：`lib/features/today/today_view.dart`——头部与内容同连续图层（背景贯通、无分隔线，FR-003）：左 = 账号区（头像环+昵称，tap→资料 sheet）；中 = 日期语；右 = 铃铛（角标=今日新增推导条目数）+ ＋（→/goal-editor）；目标卡列表改 GoalIconCatalog 图标+一句话+类型徽章+最新记录行（「相对时间-描述」，未填兜底「完成打卡」，FR-019），整卡可点直达详情、卡上无按钮，今日之环卡与周节奏微条均移除（FR-020，R2 裁决 2 + R3 裁决 1）；空态文案正式 App 语域（R3 裁决 3）（依赖 T015/T018/T019/T008/T044）
- [ ] T018 [P] [US1] 本地资料编辑：新建 `lib/features/profile/profile.dart`——资料编辑 bottom sheet（昵称输入 + 8 枚预设头像选择，图标+令牌环），读写 SettingsRows.nickname/avatarKey（经 repositories），保存即时生效、重启保留、未填显示默认头像+「我」；配套单测（默认兜底/往返持久化）
- [ ] T019 [P] [US1] 通知列表推导：新建 `lib/features/notifications/notification_list.dart` + 推导逻辑——四源合成（①Reminders 排程+cadence 的今日/明日提醒时刻 ②近 7 天成就与全完成日 ③streak 里程碑 ④deadline≤今天且未 achieved 的到期询问，research D6），时间倒序、按天分组、行=类型图标+标题+相对时间、空态友好语；tap 行→/goal/:id；配套推导单测（四源各自+混排排序）
- [ ] T020 [US1] 铃铛接入：`lib/features/today/today_view.dart`——铃铛 tap 打开通知列表 sheet（不遮底部导航）、角标数=今日新增推导条目；今日页旧通知设置入口拆除（迁往 US4 T035 落位）
- [ ] T021 [US1] 详情管理动线补全：`lib/features/goals/goal_detail.dart`——吸收 goals_view 退役后的管理职能（编辑/暂停/恢复/删除全入口可达，FR-002）；极简目标详情不空（图标+描述+类型徽章+打卡节奏占位，spec 边界用例 3）；打卡动线内选填一句话描述（写 CheckIns.note，FR-019），历史记录行显示描述（未填兜底「完成打卡」）
- [ ] T044 [US1] CheckIns 描述列（schema v4，R2 评审追加）：`lib/core/db/tables.dart` + `app_database.dart`——CheckIns +note TEXT NULL、schemaVersion 3→4（纯 ADD COLUMN 迁移 + drift schema 刷新）；repositories 打卡写入贯通 note；备份 v4 导出/导入（note 缺失宽容 NULL，contracts/backup-format.md）；配套迁移与备份往返用例
- [ ] T022 [US1] 验收走查：FR-001~006 逐条核对——`flutter build web --release` 走查（导航恒三页签/滚动无分隔线/账号编辑往返/铃铛列表空态与四类混排）+ `flutter analyze && flutter test` 全绿；结论记 `design/reviews.md`

**Checkpoint**: MVP 可交付——三 Tab 骨架 + 今日页新头部独立可用，V1–V8 主路径不回退

---

## Phase 4: User Story 2 - 编辑器重构：分组表单+三类型+开关提醒+图标库 (Priority: P1)

**Goal**: 创建/编辑动线在三 Tab 内、分组平铺（无折叠，R2 裁决 1）、标准控件；分类区=常用行+更多弹窗；类型=长期/短期/习惯；提醒开关化；图标库选分类图标、颜色退场

**Independent Test**: 三 Tab 内点新建底部页签仍在；一句话→类型→（习惯）提醒频率+时间→图标→保存，全程无频率问答/颜色/心理字段；新目标即时上今日页可打卡

### Implementation for User Story 2

- [ ] T023 [US2] 编辑器骨架：重构 `lib/features/goals/goal_editor.dart`——分组平铺容器无折叠（「分类」区置顶 / 基础信息 / 目标类型与提醒，R2 裁决 1）+ 保存常驻底部（导航条上方，按钮文案统一「保存」，R3 裁决 2）；编辑既有目标同构（类型可改，改型联动显隐）；表单内不出现任何行为说明句（R3 裁决 3）
- [ ] T024 [US2] 基础信息组：一句话描述输入（goals.name 语义升级，~40 字上限，placeholder 示范完整短句「月底前能连续跑 3 公里」式，research D8）——无「为什么想做/怎样算做到」字段与写入路径（FR-014）
- [ ] T025 [US2] 类型与提醒组：分段选择 长期|短期|习惯 + 联动——短期→截止日选择器（必填）+ 倒计时预告；习惯→提醒开关→（开）频率档 [一天一次|三天一次|一周一次] + 时间选择器（FR-012/013）；写 Reminders.isEnabled/cadence/time；长期默认无提醒（可开后同习惯档）
- [ ] T026 [US2] 分类组：「分类」区 = 常用一行（固定策展约 6 枚）+「更多」按钮打开悬浮选择弹窗（GoalIconCatalog 全量、按领域分组），常用行与弹窗选中态同步、单选即存 iconKey（FR-011/015，R2 裁决 1）；无颜色步；表单不再出现 colorKey 写入
- [ ] T027 [US2] 模板与建议对齐：`lib/features/goals/goal_templates.dart` + `lib/features/goals/smart_suggestion.dart`——模板改三类型语言（无频率问答/无颜色），预填一句话示范
- [ ] T028 [US2] 提醒排程档位：`lib/features/settings/reminder_service.dart`——按 cadence 排程（daily 每日 time / threeDay 自启用日起每 3 天 / weekly 每周同 weekday，contracts/goal-type-model.md）+ 短期到期询问单次（deadline 当日默认 09:00）+ 关开关即时取消未触发排程；`test/reminder_service_test.dart` 增三档+到期询问+关闭取消用例
- [ ] T029 [US2] 短期生命周期：`lib/features/goals/goal_detail.dart`——「标记达成」（写 achievedAt）与「续期」（改 deadline，通知列表询问项消失）双入口；截止到点不自动终结、超期持续提示可打卡（FR-018，research D4）；配套行为单测
- [ ] T030 [US2] 验收走查：SC-002 计步——创建习惯目标 ≤8 次交互 ≤60 秒、全程底部页签可见、无频率问答/颜色/心理字段（SC-005 断言 0 自然语言设置项）；`flutter analyze && flutter test` 全绿；结论记 `design/reviews.md`

**Checkpoint**: 创建动线重构完成；三类型行为（打卡/提醒/倒计时/达成）全部可用

---

## Phase 5: User Story 3 - 回顾空态与标题一致性 (Priority: P2)

**Goal**: 回顾页空态竖直居中带 CTA 直达新建；三屏大标题左缘与基线像素对齐

**Independent Test**: 清空数据进回顾页——空态居中、CTA ≤1 交互直达新建；并排截图比对三屏标题对齐

### Implementation for User Story 3

- [ ] T031 [US3] 回顾空态：`lib/features/review/review_view.dart`——空状态竖直居中（非偏上曲线框）+ 引导文案 + 「新建目标」主按钮 → `context.go('/goal-editor')`（落 today 分支，FR-007）
- [ ] T032 [US3] 三屏标题对齐：以今日页为基准出对齐规格（左缘缩进/竖直基线常量化入 `lib/app/design_tokens.dart`），`lib/features/review/review_view.dart` 与 `lib/features/settings/settings_view.dart` 大标题统一（FR-008）
- [ ] T033 [US3] 验收走查：空数据场景 + 三屏截图并排比对（SC-004）；`flutter analyze && flutter test` 全绿

**Checkpoint**: 表层一致性完成，不动结构

---

## Phase 6: User Story 4 - 我的页主流设置结构重组 (Priority: P2)

**Goal**: 账号卡置顶 + 分组设置列表（通知/目标/数据/关于），行=图标+标题+行尾值|开关|箭头

**Independent Test**: 账号卡可编辑资料；通知设置在页内可达且能力等价；备份导出/导入回归过；深浅两态可读

### Implementation for User Story 4

- [ ] T034 [US4] 设置结构重组：重构 `lib/features/settings/settings_view.dart`——账号卡（复用 T018 profile sheet）+ 分组列表：通知（提醒总开关值行/每日简报时间/按目标提醒二级）/ 目标（活跃目标数→今日页、补签说明只读）/ 数据（备份与导出/导入）/ 关于（版本/隐私脚注）（FR-009，ui-contract.md 我的页结构）
- [ ] T035 [US4] 通知设置迁入：提醒总开关/每日简报时间/按目标提醒自今日页旧设置面迁至我的页通知分组，能力等价（FR-006）；今日页设置职能彻底拆除（与 T020 衔接终查）
- [ ] T036 [US4] 验收走查：结构走查（行形态全标准）+ 深浅两态对比 + V7 备份导出导入回归在新入口下通过；`flutter analyze && flutter test` 全绿

**Checkpoint**: 设置收纳层完成，三 Tab 配套齐全

---

## Phase 7: User Story 5 - 既有数据零丢失迁移收口 (Priority: P2)

**Goal**: v2 存量升级零丢失（对账收口）+ 备份 v3 双向互导 + 旧字段全界面零残留

**Independent Test**: 带旧字段存量库启动新版——目标/打卡/记录/补签逐项对账一致；类型符合映射；界面无颜色/频率/心理字段残留

### Implementation for User Story 5

- [ ] T037 [US5] 备份 v3：`lib/core/backup/backup_exporter.dart` + `lib/core/backup/backup_importer.dart`——schemaVersion 3（goals +goalType/+achievedAt、reminders +cadence、settings +nickname/avatarKey、colorKey 导出 null）；宽容解析双向（v3 读 v2 走 D3 映射重推导、v2 读 v3 忽略未知字段，contracts/backup-format.md）；`test/backup_test.dart` 增双向互导用例（往返计数一致）
- [ ] T038 [US5] 迁移端到端对账：web 双跑——构造 v2 存量库（四分支各一）→ 升级启动 → 目标/打卡/记录/补签逐项对账 + 被映射目标按原节奏继续提醒 + 全界面旧字段（频率/颜色/为什么/怎样算）零上屏终查（SC-003/SC-006）
- [ ] T039 [US5] 验收核对：spec US5 四条 acceptance 场景逐条核对（含「每日 3 次频率→习惯且计数连续」「带截止→短期倒计时正确」）；结论记 `design/reviews.md`

**Checkpoint**: 零丢失承诺兑现，数据面收官

---

## Phase 8: Polish & Cross-Cutting Concerns（收尾横切）

**Purpose**: 全量回归、入口收口、文档与交付

- [ ] T040 V1–V8 全回归：001 quickstart 场景在新信息架构下全部走查（FR-017，允许入口等价调整不允许能力回退；打卡主路径 ≤2 交互）+ `flutter analyze && flutter test` 0 issue 全绿（69+ 存量 + 本特性新增）
- [ ] T041 深链与外部入口回归：`lib/app/router.dart` target:// 深链映射全走查（today/review/goal-{id} 不变、goal 无 id 兜底 /today）+ 通知 tap 落地页 + iOS 小组件 tap 入口在新路由下可达（spec 边界用例 7）
- [ ] T042 [P] 文档收口：`design/reviews.md` 记录本特性全部送审/验收结论；`specs/003-app-ux-refinement/quickstart.md` 完成口径核对（SC-001~007 逐条）；spec.md Status 更新；memory 更新实现状态
- [ ] T043 [P] 真机合并轮清单：整理用户侧动作清单（Codemagic 手动触发 `ios-unsigned` → iLoader 侧载）——核对点：新图标/启动屏（T028 资产首次真机亮相）、三 Tab 手感、通知到点语气、打卡动效帧率（quickstart 阶段 C；用户「顺带测试」合并轮）
- [ ] T045 [P] 文案语域清查（FR-021，R3 裁决 3）：`lib/core/copy.dart` 违禁常量处置——onboardingDataNote/privacyFoot（本地存储说明）删除并同步消费方、reminderNudge「做一次就算数」等口语化提示正式化或删除（shortTermDueAsk「到日子了，怎么样？」为用户裁定通知文案，保留）；全屏走查无寒暄/比喻式提示残留；`flutter analyze && flutter test` 全绿

**Checkpoint**: 全特性收官——SC-001~007 逐条过、tasks.md 全勾、reviews.md 结论齐

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1（原型）**: 无依赖，即起。T007 评审门禁 = T015 起 Flutter 结构任务的硬前置（T008–T014 数据层不受门禁阻塞，可并行）
- **Phase 2（地基）**: T008 → T009（迁移用图标映射）；T009 → T010/T011；T012/T013 同文件链顺序；T014 [P] 独立。**阻塞全部故事相位**
- **Phase 3（US1）**: 依赖 Phase 1 门禁 + Phase 2 完成。T015 → T016/T017；T018/T019 [P] 可先行；T020/T021 收口
- **Phase 4（US2）**: 依赖 T015（编辑器进 today 分支）+ T008/T011（类型与图标）。T023 → T024/T025/T026；T027 [P]；T028 [P]；T029 依赖 T025
- **Phase 5（US3）/ Phase 6（US4）**: 各自独立，依赖 Phase 2 + T015；可与 Phase 4 交错
- **Phase 7（US5）**: 依赖 T009/T010（迁移已在 Phase 2 落地，此处收口备份互导与端到端对账）
- **Phase 8（收尾）**: 依赖全部故事完成

### User Story Dependencies

- **US1 (P1)**: 地基后即起，无跨故事依赖——MVP
- **US2 (P1)**: 依赖 US1 的 T015 路由三分支（编辑器落位）；数据面只依赖 Phase 2
- **US3 (P2)**: 独立（T032 触及三屏标题，建议在 US1/US4 屏面定稿后做）
- **US4 (P2)**: 依赖 T018（profile sheet 复用）与 T035↔T020 拆迁衔接
- **US5 (P2)**: 数据依赖全在 Phase 2；收口在故事最后

### Within Each User Story

- 模型/数据先行（已在 Phase 2 统一解决）→ 路由/结构 → 视图 → 接线 → 验收走查
- 每个故事以验收走查任务（T022/T030/T033/T036/T039）收口，`flutter analyze && flutter test` 全绿为硬口径

### Parallel Opportunities

- Phase 1: T002/T003/T004/T005 四屏原型四文件并行；T007 送审等待期与 Phase 2 数据层并行
- Phase 2: T014 与 T008 并行（不同文件）；T010 与 T012 并行（测试文件不同）
- Phase 3: T018（profile）与 T019（notification）并行
- Phase 4: T027 与 T028 并行；T024/T025/T026 三组表单实现可流水
- US3 与 US4 整相位居后并行（不同屏文件）

---

## Parallel Example: User Story 1

```bash
# 路由骨架完成后，两个新模块并行：
Task: "T018 [US1] 本地资料编辑 lib/features/profile/profile.dart"
Task: "T019 [US1] 通知列表推导 lib/features/notifications/notification_list.dart"

# Phase 1 四屏原型并行：
Task: "T002 今日页原型 R5 design/prototypes/screen-today.html"
Task: "T003 编辑器原型 R2 design/prototypes/screen-editor.html"
Task: "T004 回顾页原型 R4 design/prototypes/screen-review.html"
Task: "T005 我的页原型 R3 design/prototypes/screen-settings.html"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 原型送审（T001–T007）——门禁未过则返工原型，不烧 Flutter 工时
2. Phase 2 数据地基（T008–T014）——可与送审并行
3. Phase 3 US1（T015–T022）
4. **STOP and VALIDATE**: 三 Tab 骨架独立可测——恒三页签/管理闭环/头部新三件套（SC-001/SC-006 部分）

### Incremental Delivery

1. 地基 + US1 → 三 Tab 骨架可走查（MVP）
2. + US2 → 创建动线新心智（三类型/开关提醒/图标库）
3. + US3 → 表层一致性（空态/标题）
4. + US4 → 设置收纳层
5. + US5 → 迁移/备份零丢失收口 → Phase 8 全回归 + 真机合并轮

### 每任务硬口径（002 惯例）

- 完成即 `flutter analyze && flutter test` 全绿（内嵌测试口径，见 quickstart 阶段 B）
- 任务勾选 `[x]` 时附 ✅ 一行结论（改了什么/验了什么）
- 每任务或逻辑组一 commit（`T0XX: 中文标题`）

---

## Notes

- [P] = 不同文件、无未完成依赖；[US#] 映射 spec.md user story
- 测试不单列相位：随实现任务内嵌（quickstart.md 阶段 B 为回归底线、阶段 C 为迁移对账）
- T007 评审门禁是 002 T025 惯例的延续——原型未过审不动结构，避免 Flutter 返工
- 真机轮与 002 遗留的「新图标/启动屏构建侧载」合并（用户「顺带测试」），见 T043

