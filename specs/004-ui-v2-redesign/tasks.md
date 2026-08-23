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
- [x] T009 [P] [US1] 通知列表原型稿 design/prototypes/v2-notifications.html（时间倒序/类型图标/空态）
  - ✅ 三板：浅色·通知列表（今日页底 sheet，5 条 nrow 类型色格 bell/task_alt/trophy/streak/due，未读红点+全部已读）/ 深色·已读态（标题降次级色）/ 浅色·空态（ring 图形+暂无通知）；底幕为简化今日页（三环+两页签 dock+FAB 可见）
- [x] T010 [P] [US1] 全部目标列表原型稿 design/prototypes/v2-goals-all.html（兼承 US3「查看全部」屏：分类筛选单选/进详情/管理动线）
  - ✅ 四板：浅色·全部（三大类分组头 健康5/习惯1/目标6，12 目标卡=大类色图标格+类型/状态徽章+摘要/进度条）/ 深色·筛选中（运动单选反色实底，计数 12→2 联动）/ 浅色·筛选空态（宠物分类，空态说明+新建 CTA）/ 深色·长按管理菜单（编辑/暂停/删除 danger）；图标域与 T005 映射对账（hiking 属 fitness 故徒步用 flight）；Playwright 全页渲染验证通过

### 评审门禁

- [x] T011 [US1] 原型评审门禁：用户逐屏走查 design/prototypes/ 五稿，通过/返工裁决与轮次记 design/reviews.md，全部冻结后方可实现（**阻塞 T012–T016 与 T023**；返工循环至全冻结）
  - ✅ 七屏全冻结（2026-08-23，R1–R3 三轮全录 design/reviews.md 屏幕评审区）：R1 修 gi() DOM 注入 bug + 补今日/回顾；R2 环六案/色系四系对比稿；R3 三裁决落定并回填（环=案 C 单环三段弧、色系=四案全否保留渐变卡统一同构梯度入 tokens、dock=D2 黑色线条三屏定稿）；末轮五延展屏（editor/detail/settings/notifications/goals-all）用户裁定「过」全数冻结——T012–T016 与 T023 解锁
  - ✅ 冻结基线 = design/prototypes/ v2-{today,review,goal-editor,goal-detail,settings,notifications,goals-all}.html（tokens.css?v=0823b）+ tokens 三端（9656dfd）；门禁 analyze 0 + 133 全绿

### 实现（按冻结稿）

- [x] T012 [US1] 我的页换装：lib/features/settings/settings_view.dart 按冻结稿重做 + 主题三档单选行（消费 themeModeProvider，即时生效持久保留）
  - ✅ 换装完成：push 顶栏（38 圆钮返回 + 我的）/资料卡整卡入口→ProfileAvatar 56/外观组三档单选（跟随系统·浅色·深色，即时生效且落 Settings.themeMode 持久）/通知组总开关+概要时间+按目标提醒二级展开（surfaceAlt 左缩进 + nest hint）/目标·数据·关于组 v2 组卡行形态（30 图标盒 + 52 高 + 行尾值|开关|箭头|对勾，卡无描边）/恢复确认居中弹层（双胶囊按钮）；copy.dart 同步 v2 词汇（backupImport=恢复备份 等）；返回钮过渡式 canPop?pop:go('/today')（T024 迁 push 后自然语义）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（+134，新增 T012 主题三档即时生效持久用例；T032–T036/V7 随 v2 形态与文案碰撞改 key 定位/scrollTo/双命中计数）
- [x] T013 [P] [US1] 编辑器换装：lib/features/goals/goal_editor.dart 按冻结稿重做（连带 lib/features/goals/goal_templates.dart 与 goal_type_badge.dart 控件形态；FR-016 底线零丢失）（depends T011）
  - ✅ 换装完成：push 顶栏（38 圆钮返回 + 新建目标/编辑目标）/创建态模板横滑条（药丸统一 trip_origin 环徽，冻结稿 .tpl 同款）/组卡序 类型→一句话描述→分类→提醒（短期换里程碑提示卡）/SegmentedPill 新公共控件（surfaceAlt 轨道 + 选中段 surface 浮起加粗）/类型编辑锁定（T006 冻结形态决策：编辑态 Opacity .55 + IgnorePointer + 「创建后不可变更」小标）/分类卡常用 6 格 + 域归属色点行 + 「更多」上滑弹层（38 枚按 10 域分组、组头大类色点、6 列 Wrap、78% 屏高、点选即关/scrim 关）/名称计数器右下 + 底部固定全宽胶囊保存（置灰 .4 无影）/提醒卡开关→频率三档+时间行（关态副题）；goal_type_badge v2 组合式「类型 · 域 · 大类」（surfaceAlt 底 + 大类常驻色文字，倒计时移交详情 meta）；cadence 词汇三屏收敛 每天/隔三天/每周（copy.dart 单源）；FR-016 零丢失：截止日期/提醒同步 upsert/焦点上限/必填校验全保留
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（+134；T023/T025/T026/T035/T036/T021/T039 随 v2 形态与词汇改写——类型锁定语义替改型删行、SegmentedPill 单值断言、弹层分域滚动收集全量 38 枚、组合徽章兜底 explore→旅行域）
- [x] T014 [P] [US1] 详情换装：lib/features/goals/goal_detail.dart 按冻结稿重做（打卡/补签/历史/标记达成/续期/编辑/暂停恢复/删除全可达）（depends T011）
  - ✅ 换装完成：全文件重写为冻结稿 v2-goal-detail 结构——38 圆钮顶栏（返回/backButtonTooltip 兼容 pageBack + ⋯ 收纳菜单）/hero 身份区（52px 大类色图标盒 + GoalTypeBadge 状态尾缀「已暂停·已达成·已归档」+ meta 胶囊按类型分流：短期=倒计时+截止日、习惯长期=连续+本周+提醒、非活跃=历史条数+创建日）/今日记录卡（选填描述 + 记录打卡主按钮 + 近 7 天点阵 34px 圆、命中实心打勾、过去日虚线圈 Painter、点过去日开补签弹层）/补签弹层（14 天窗口月历单选、已有记录青圈边、未来与超窗灰置不可点、确认按钮带「补签 M 月 D 日」文案）/里程碑卡（大类色 8px 进度条 + 百分比 + 自绘圆形复选 + 添加步骤行）/行动行卡（短期常驻标记达成+续期（date picker 锚定今日）、通用编辑目标行）/历史卡（MM-DD + 描述兜底 + 补签 tag）/暂停横幅 + 底部危险删除行线；删除二次确认居中弹层（双胶囊按钮）→ GoalRepository.deleteGoal 新增事务级联清 checkIns/milestoneSteps/reminders/frequencyVersions/goals 五表（FR-016 物理删除）；showGoalActions 动作面板与 archiveGoal 归档退役（收纳进 ⋯ 菜单）；期间用户定位出周点阵循环 i++ 笔误致 flutter_tester 无限 build 压死 WSL VM（已改 i-- 落警告注释，多轮崩溃根因闭环）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（+136：T014 新增补签弹层全流程用例（周点阵→日历单选→落库 isBackfill→toast→历史卡补签 tag）与删除级联用例（二次确认取消/确认→四子表清空+退出详情）；T021/T029/T038/T038 到期等 10 处存量断言随冻结稿改写——reminder 胶囊短期不出现、menuSheet 内菜单动作用 descendant 定位、折叠区 scrollTo）
- [x] T015 [P] [US1] 通知列表换装：lib/features/notifications/notification_list.dart 按冻结稿重做（倒序/类型图标/空态）（depends T011）
  - ✅ 换装完成：sheet 落 v2 基底（surface 圆角顶 + shadowHigh + 40×4 抓手条 + 72% 屏高上限 + notificationSheet key）；分组头退役 → 行尾相对时刻 notificationRelTime（当日内 刚刚→N 分钟前→N 小时前 收敛、未到报「今天 HH:mm」、昨天/明天带时刻、2–6 天前报天数、更远 M月d日，tabular 数字）；行 = 38px rMd 语义色格图标（蓝=提醒·event / 青柠=达成·全部完成·check_circle·verified / 琥珀=连续·fire·临近截止·alarm——形状+色相双通道 FR-013）+ bodyL 标题/bodyS 副题省略 + 行间 1px 分隔线；空态升级图形化（88px surfaceAlt 圆环 history 图标 + 暂无通知 + 引导句）；四源推导逻辑与 planReminders 同源口径零改动；原型「未读点/全部已读」为演示交互（需已读持久化，D6 无已读态保留），notifDay* 组头键退役、今日/回顾最新记录行改挂 todayLatestToday/Yesterday 自键；期间一次误整树 dart format 造 53 文件 churn 已回滚重放（教训：仓库多为旧版格式，format 只点名本任务文件）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（+137：新增行形态用例（蓝格 event 图标 ×4 + 明天 09:00 相对时刻 descendant 定位）与 notificationRelTime 八分支纯函数用例；空态用例补 notifEmptyTitle 断言；T041 通知落地回归绿）
- [x] T016 [P] [US1] 资料编辑与调试时钟换装：lib/features/profile/profile.dart + lib/features/settings/debug_clock.dart 新语言重做（depends T011）
  - ✅ 换装完成：资料 sheet 按冻结稿 v2-settings 板 4 重做——sheet 容器换 v2 基底（transparent bg + surface/rXl 顶 + shadowHigh + 40×4 抓手条 + profileSheet key + 键盘 viewInsets 保留）；头部内联「完成」按钮与预览行（头像 56 + 昵称并排）退役 → titleS「编辑资料」标题 + 全宽昵称输入（surfaceAlt 底 + 1px divider 边 + rMd + bodyL + 内垫 s4/s3，focused 转 accent——与编辑器输入同语言，maxLength 12/空白归 NULL/key 不变）；头像区 64px accent 双环 Wrap → 4 等分列网格（Expanded+Center = repeat(4,1fr) justify-center 语义，行距 s4）56px 格（surfaceAlt 底 + 26px 环色图标 + 2.5px 描边 transparent→ring 选中，AnimatedContainer 150ms；再点回默认枚/Semantics 领域名/avatarCell-key 保留）；底部新增全宽胶囊主按钮「保存」（accent 底 + accentOn titleS + shadowMid，Material+InkWell rFull，与详情 _PillButton 同族）→ Copy.profileDone 值改「保存」、profileNicknameLabel/profileAvatarLabel 两键退役（冻结稿无节标签）；ProfileAvatar/profileNicknameOf 共用件零改动。调试钟换装（无对应画板，按已冻结组件拼装）：入口行 ListTile → _SettingsRow 同构行（30px surfaceAlt rSm 色格 schedule_rounded 17 + bodyL 标题 + bodyS 副题（已固定 iso/跟随系统时间）+ chevron 14，minHeight 52 内垫 s4/s3）；弹层 plain sheet → v2 sheet 容器 + 抓手条 + titleS 标题 + bodyS 状态行（今天=iso + 周锚点）+ 三菜单行（图标 20 + bodyL 标题 + 可选 bodyS 副题，目标菜单 .menu 行语法，rounded 图标）；_travel/_refresh/dateProvider 切换逻辑与 2020–2035 picker 窗口零改动
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（137：profile 用例落库往返/再点回默认/12 字上限/重开回显全绿——预览首字断言随预览行退役改挂 controller.text；widget_test T026 账号卡→sheet→保存回归绿；debug 钟无测试触点，行为逻辑未动）
- [x] T017 [US1] 文案语域全量清查：lib/core/copy.dart 与各屏新写文案过 FR-012（正式语域、无口语化解释句、无本地存储说明；基准图模板残留英文零进入）
  - ✅ 清查完成：copy.dart 387 键全量过 FR-012 三线——①英文残留：值域仅 Target（应用名）/Debug 时钟（dev 专用 kDebugMode）/25km/h（示例单位）合法在场，features 层内联串扫描零英文模板漏入（settings 迁移表名 map 键为内部标识、值为中文展示名）；②本地存储说明：备份组文案仅述操作与后果（「将用备份文件中的全部数据替换当前数据。此操作不可撤销。」），无存储位置/路径/设备说明；③口语化：004 新写文案（weekDotsHint/backfillSheetHint/notifStreak/notifSubBrief/editorMilestoneHint 等）均在 003 教练式语域带内，editorMilestoneHint 与冻结稿 v2-goal-editor.html:338 字面吻合；两处内联「知道了」（goal_lifecycle/goal_editor 聚焦上限弹层）归一挂 Copy.notifAck；死键 5 枚清除（goalsTitle/goalsPausedNote/milestoneProgress/milestoneCountdown/editorIconCloseLabel——004 换装后 lib+test 零引用），B案四标签/cue×4/goalsNav/editorIconColor 共 9 键界面已退役但 widget_test 持「002 句式残留」负向哨兵引用，保留并注释存续原因
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（137：哨兵断言（cue×4/B案标签/goalsNav/editorIconColor findsNothing）与 T038 迁移终查全绿，零用例改写）

**Checkpoint**: 设计语言全屏落位，延展屏功能能力零丢失，双主题可走查

---

## Phase 4: User Story 2 - 今日页骨架 v2：新头部 + 三大类健康度环 (Priority: P1)

**Goal**: 今日页重组为「头部 + 三环嵌套健康度 + 空态」；减分制健康度纯派生落地

**Independent Test**: 造健康 2 目标（其一 7 天前记录）+ 习惯 1 今日打卡 + 目标 1 暂停 → 三环 97/100/无数据；打卡后即时回升；点头像进我的页（quickstart 阶段 C）

- [x] T018 [P] [US2] HealthScore 纯函数：lib/core/models/health_score.dart（新文件，口径=contracts/health-score.md：100−3×近 7 天零记录活跃目标数，clamp(0,100)；窗口含今日滚动 7 天；补签同计；暂停不参与；类内零活跃=无数据态）+ test/health_score_test.dart 全量对账（含跨天窗口右移、穿底夹 0）
  - ✅ 实现完成：evaluateHealth 纯函数（goals/checkIns/today 注入）——窗口 W=[today−6,today] 一次预聚合 recorded 集合（isValid 过滤撤销行 + 日界双闭），三分桶循环 MajorCategory.values 全键产出 CategoryHealth（activeGoals/zeroRecordGoals 计数，score=clamp(100−3N,0,100) 为派生 getter，hasData=activeGoals>0）；HealthSnapshot.byCategory 三键全量 + isEmpty=全类无数据（全库零活跃 → 环区让位空态）；目标→大类经 GoalIconCatalog.byKey(iconKey).domain.major 派生（FR-014），零 DB/零 provider 依赖，T019 直接挂流
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（148 = 137+11：六组对账——①契约验收造数（97/100/无数据+打卡即清零）②窗口边界 t-6/t-7+补签同计+撤销不计③阶梯 100−3N 与 34 个穿底夹 0④暂停/归档/达成不参与+恢复即现环 97⑤十领域分桶 5/1/4 及全零分 85/97/88⑥跨天窗口右移（左缘记录跨天移出回落 97、长期零记录不自动回升））
- [x] T019 [US2] healthScoreProvider：lib/app/providers.dart（goals/checkIns/today 任一流变化失效重算，dayTicker 跨天联动窗口右移）（depends T005, T018）
  - ✅ 实现完成：healthScoreProvider = Provider<HealthSnapshot?> 挂在 statsProvider 同族模板上——watch goalsProvider/checkInsProvider（.value 任一 null → null 三环加载态）+ todayProvider（dateProviderProvider 派生，dayTicker 跨天 invalidate 自动联动窗口右移），就绪即委托 T018 evaluateHealth 纯函数；流式失效重算无需自建监听（riverpod watch 链：打卡/补签/暂停恢复/删除/新建任一 DB 变更经 watchAll 流回放触发）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（149 = 148+1：⑦容器级接线测试——goals/checkIns 双 broadcast 流 override + dateProviderProvider 锚 FixedDateProvider（SystemDateProvider 读真实系统日会窗口错位），全序列 null→97（流就绪零记录）→100（checkIns 流替换左缘补卡失效重算）→97（dateProvider 切 t+1 窗口右移左缘记录出窗））
- [x] T020 [US2] 今日页头部与三环：lib/features/today/today_view.dart 重做——中文「星期, 日期」行 + 大标题「今日」+ 右上头像入口（同一连续图层无分隔线）+ 三环同心嵌套组件（三类各一色、独立计分无综合分、无数据态、全库零活跃环区让位空态新建 CTA）（depends T002, T019）
  - ✅ 实现完成：today_view 全文件重做——_Head（labelS 字距日期行「星期日 · 8 月 23 日」+ displayL 大标题「今日」+ 44px 头像 surface 双层环/低投影，tap → /settings「我的」页 Q1 裁决；铃铛=T009 冻结通知入口驻留、＋=T025 FAB 前过渡）+ _RingZone（R3 案 C 单环三段弧：_TriArcPainter 128/r56/描边 11/三槽 120°·lead 1.5°·gap 9°·butt 端帽·12 点起步健康→习惯→目标，弧长=分数；中心=有数据类平均分 tabular+「健康度」；图例 10px 色点+分数 /100）+ 无数据态（段空置只余底轨+色点淡化 35%+类名弱化+「—」）+ 空态让位（health.isEmpty → _EmptyCTA 板 4 冻结稿：96px surfaceAlt 圆底 eco 图形+两行引导+accent 胶囊新建 CTA）；数据源 healthScoreProvider（T019）；今日目标列表暂承 003 形态待 T022；copy 新增 todayHeadDate/todayHealthLabel/todayHealthSuffix/todayHealthNone、todayEmptyBody 换冻结稿两行语、todayDateLine 退役；router _NavTab 挂 navTab-{location} key（大标题与页签同文后测试改 key 定位，六处「页签在场」断言换 key）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（149/149：34 widget 用例零回归——空态/计步/迁移/深链/通知全过；健康度与手工核算一致由 T018 六组对账背书，今日页消费同 provider）

**Checkpoint**: 今日页骨架与基准图 01/02 头部+环区对应，健康度与手工核算一致

---

## Phase 5: User Story 3 - 关注卡轮播 + 查看全部 (Priority: P1)

**Goal**: 今日页环区下方为活跃目标主色关注卡轮播；「查看全部」进全部目标列表

**Independent Test**: 3 目标其一打卡 → 轮播 3 卡最近互动居首可滑动；主行动按钮直达详情；查看全部开列表筛选管理可用（quickstart 阶段 D）

- [x] T021 [P] [US3] 关注卡轮播组件：lib/features/today/focus_carousel.dart（新文件；PageView.builder+viewportFraction 露边；卡序=max(最新 CheckIn.createdAt, goal.createdAt) 降序仅 active；状态标签+目标名+一句话描述+主行动按钮+辅助行；单卡退化无滑动指示）
  - ✅ 实现完成：FocusCarousel(goals/checkIns/stats/today/onOpenGoal 注入式组件，挂载与「查看全部」入口留 T022)——_ordered 派生卡序（isValid 记录按 goalId 聚最新 createdAt，max(最新, goal.createdAt) 降序，仅 active，纯计算不落库）+ PageView.builder(viewportFraction 0.9 + 卡间 s2 内距 = 露邻卡边，卡高 208 固定) + _FocusCard 按冻结稿 .fcard（MajorGradients byKey(iconKey→domain.major) 同构梯度底 + rLg + shadowMid；右上 40px 白 18% rMd 图标格白图标；● 状态胶囊白 22%（短期/今日已记录=进行中，否则待办）；titleM 目标名 maxLines 1；一句话描述=successCriterion→motivation→cueScene 择先非空 maxLines 2 白 85%；底部白胶囊「记录打卡」中性墨字 kFocusGoInk（R3 去 accent，新令牌入 design_tokens 过 SC-004 契约）+ 辅助行 tabular（短期=deadlineCountdownMeta、习惯/长期=streak>0 连击，口径同详情页 meta 胶囊））+ 页点（N>1 才出，6/18px divider/onSurface 去彩，AnimatedContainer 200ms；单卡退化无指示）；copy 新增 focusTagActive/focusTagTodo
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（149 全绿；组件未挂载无新用例，token 契约初犯 Color(0x…) 字面量已令牌化为 kFocusGoInk 修正后通过）
- [x] T022 [US3] 轮播接入今日页：lib/features/today/today_view.dart（环区下方挂载；主行动按钮进该目标记录动线；「查看全部」入口；暂停/删除经流实时移出）（depends T020, T021）
  - ✅ 实现完成：today_view 003 目标列表退役，环区下方挂 _CarouselSection（冻结稿 .caro/.cap：cap 行「关注」titleM +「查看全部 ›」bodyM accent → /goals-all，s3 顶距/s3 底距）+ FocusCarousel（onOpenGoal → /goal/{id} 记录动线；goals/checkIns/stats/today 全量注入，组件内过滤 active——暂停/删除经 goalsProvider 流实时移出）；/goals-all 路由今日落分支（router）+ goals_all_view.dart 过渡页（大标题+行 tap → 详情，T023 按冻结稿全量换装）；今日页长按补签退役——backfill_calendar.dart 删除（补签统一走详情页 14 天日历），copy 死键清扫 todaySection/todayRecordedNote/backfillCalendarTitle/backfillHint，新增 focusSection/focusSeeAll/goalsAllTitle；focus_carousel 挂 focusCard-{id}/focusDots 测试锚点 key；widget_test：openGoalFromFocus helper（露边邻卡 onstage 不可点→hitTestable 判定双向横滑再点卡上按钮）、US2/T010/US3 迁移三处动线改写（名字 tap 不再导航）、T038 旧字段哨兵改口径（八分饱/亲眼=卡面描述合法源移出，末卡横滑构建）、V5 长按补签用例删除（动线退役，详情补签 1900s 用例在）、新增 T022 挂载用例（cap/查看全部往返/主行动次卡翻页/暂停流移出+单卡退化页点消失）
  - ✅ flutter analyze → "No issues found!"；flutter test → "All tests passed!"（149 全绿 = 149 基线 −V5 长按补签 1 +T022 轮播挂载 1）
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
