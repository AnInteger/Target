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
- [X] T008 [US1] "今日"屏原型评审：`design/reviews.md` 记录结论至"通过"（**门禁：通过后 US2 实现任务方可开工**）✅ **2026-08-20 R4 通过**（历经 R1 六项 + R2 九项 + R3 自审六项 + R4 四项修订——年度守护卡移除、导航条参照重做、浅色墨梅 accent、底幕渐变可见化；设计语言随今日屏定稿）

**Checkpoint**: 设计语言成立——方向已定、令牌双端就位、今日屏原型通过，可随时进入实现

---

## Phase 3: User Story 2 - 每日打卡动线落地 (Priority: P2)

**Goal**: 今日视图按原型落地：首屏总览、≤2 交互打卡、仪式感反馈、成就时刻、导航壳层

**Independent Test**: Web release 面走查 V1/V2/V6 全过；打卡主路径计时 ≤2 交互；`flutter analyze`/`flutter test` 全绿

### Implementation

- [x] T009 [US2] 导航壳层与今日视图重写 `lib/app/router.dart`、`lib/app/app.dart`、`lib/features/today/today_view.dart`：按 T007 定稿落地（≤5 目标首屏无滚动、打卡 ≤2 交互、拇指热区、空/忙碌/全完成态）⚠️ 2026-08-21 裁决忙碌态全 App 移除——已实现的忙碌分支随 T022 拆除（原型侧已删忙碌画板）
- [x] T010 [US2] 打卡反馈与成就时刻动效 `lib/features/today/today_view.dart`（可拆组件文件于 `lib/features/today/`）：内建动画 + 令牌时长/曲线（反馈 ≤600ms、庆祝 ≤1200ms）；连续快速打卡不阻塞不错乱；`lib/features/today/undo_toast.dart` 适配新语言
- [x] T011 [US2] 今日动线能力等价保留：长按补签入口、Debug 时钟入口等既有快捷语义不丢失（`lib/features/today/`、`lib/features/settings/debug_clock.dart`）
- [x] T012 [US2] US2 回归：更新/新增 widget 测试（打卡 ≤2 交互、成就时刻、撤销、忙碌态区分）`test/widget_test.dart`；Web release 走查 V1/V2/V6（quickstart 阶段 B）；`flutter analyze` + `flutter test` 全绿

**Checkpoint**: 用户日常最高频路径焕新，产品气质立住

---

## Phase 4: User Story 3 - 目标定义模型与创建流程 (Priority: P3)

**Goal**: 编辑器原型含定义模型候选对比 → 字段集评审 → 可空列迁移 → 编辑器/列表/引导落地，单一"目标"概念

**Independent Test**: 新 UI 下模板与自定义两路径创建目标成功且含新维度；既有目标升级零丢失；V1/V5 回归通过

### Implementation

- [x] T013 [US3] 编辑器与列表原型 `design/prototypes/screen-editor.html`（+ `screen-goals.html` 列表语言示意）：单一"目标"概念无前置类型分叉（FR-011）、2–3 个定义模型候选方案对比（动机/成功标准/提醒时机等组合，FR-010/FR-012）、模板路径与 SMART 建议内联、渐进补全空态
- [x] T014 [US3] 编辑器评审：`design/reviews.md` 记录选定字段集与动线（**门禁：通过前禁止动数据库 schema**，契约 §3-3）✅ **2026-08-20 R1 通过——方案 B「为什么」定稿**（motivation 必填一句 / success_criterion 自动拟可改 / cue_scene 选填，A/C 字段不入库）
- [x] T015 [US3] 数据迁移 `lib/core/db/tables.dart`、`lib/core/db/app_database.dart`、`lib/core/models/entities.dart`：按选定字段集加**可空列** + schemaVersion 递增 + `build_runner` 再生成 `app_database.g.dart` + 迁移与既有数据零丢失单测 `test/`
- [x] T016 [US3] 备份格式扩展 `lib/core/backup/backup_exporter.dart`、`lib/core/backup/backup_importer.dart`：新字段为可选键（缺键兼容 001 备份）+ 单测 `test/`
- [x] T017 [US3] 编辑器与列表落地 `lib/features/goals/goal_editor.dart`、`lib/features/goals/goals_view.dart`、`lib/features/goals/goal_templates.dart`、`lib/features/goals/smart_suggestion.dart`：新动线（无类型分叉、SMART 内联、新维度、一次性/截止日属性化、频率变更下周一生效提示保留）+ 旧目标空维度渐进补全入口 ⚠️ **2026-08-21 用户补审否决列表 R1（「不符合要求，差太多了」）→ screen-goals.html R2 重做送审中；R2 通过后 goals_view 列表卡语言需返工（真实数据回显/记录语言/卡结构），编辑器动线不受影响**
- [x] T018 [US3] kind 合并与引导：里程碑专属视图并入统一呈现（收敛 `lib/features/milestones/`、调 `lib/app/router.dart`）、`lib/features/goals/onboarding.dart` 跟随新语言
- [x] T019 [US3] US3 回归：创建双路径、V1/V5 场景、既有目标升级零丢失、`flutter analyze` + `flutter test` 全绿

**Checkpoint**: "目标不明确"的根因（定义太浅 + 类型前置分叉）被模型级解决

---

## Phase 5: User Story 4 - 回顾与调整流程 (Priority: P4)

**Goal**: 周回顾按新语言重设计：数据翻译成生活语言与图形，纯回看（2026-08-21 用户裁决：不控制下周、聚焦查看；忙碌态全 App 移除）

**Independent Test**: V4 周结算全流程（Debug 时钟跳周一）、V5 补签在新 UI 下回归通过；忙碌模式移除后无残留入口与视觉

### Implementation

- [x] T020 [US4] 周回顾原型 `design/prototypes/screen-review.html` ✅ **2026-08-21 R3 修订送审**——用户裁决「聚焦查看」：决策动线（继续/调频/暂停/一句话回顾/保存）全删、教练语改观察语、补签状态不上本屏（「补」角标/徽标/画板删）、忙碌画板删（六板→两板 ①典型 ②深色）；并修复 pager 纵向可滑 bug（flex-shrink:0 + overflow-y:hidden，根因见 reviews.md R3 条目）。（R1 2026-08-20 送审：语义转向落地，周节奏条替代完成率）（2026-08-21 R3 通过——「行吧，先这样继续了」，T021/T023/T024 解锁）
- [x] T021 [US4] 周回顾评审（`design/reviews.md`）通过后重写 `lib/features/review/review_view.dart`：图形化趋势（`CustomPainter`）、生活化观察语 `lib/core/copy.dart`、逐目标横滑卡 + 指示点（PageView）——**纯回看，无决策动线**（R3 裁决：决策语义移除，调频/暂停走目标编辑器）✅ 2026-08-21——R3 定稿整屏重写：周摘要（区间 + `reviewWeekSum` 留下 N 次记录 · M 个目标）+ 三态图例 + PageView 横滑卡（节奏条 7×26px 圆：实心勾/空圈/4px 点；近 4 周透明度阶梯柱；观察语三档 `reviewCoachAll/Okay/Low` 低档警示色）+ 目标色圆点指示器可点跳卡 + 空态虚线卡；copy.dart 决策文案 11 条删除（reviewCompletion/reviewDecision*/reviewSave 等），决策 UI 全拆（结算与 WeeklyReview 实体留服务层）；新增 T021 冒烟测试（周摘要/图例/4/7 节奏数/观察语/无「下周怎么走」），64 测试全绿
- [x] T022 [US4] 忙碌模式全 App 移除（2026-08-21 用户裁决「忙碌的状态也可以去掉了，其他页面也去掉，不用设置这么多」）：收敛 `lib/features/busy_mode/busy_mode_view.dart` 与路由入口、拆今日屏忙碌态分支（today_view.dart/测试）、拆列表忙碌徽标、清理提醒降档语义与既有 busy 数据字段（保留列迁移可空，不丢历史库）；spec FR-005 等价物条款随此裁决豁免忙碌项（reviews.md R3 条目为凭）（✅ 2026-08-21 完成：busy_mode 视图目录与 /busy 路由删除；today/goals/review/补签日历/iOS 小组件的忙碌展示与文案全拆（回顾屏补签计数一并撤）；`BusyModeService` 保留但仅剩一个职责——App 启动自动收尾升级前遗留的活跃降档会话（app.dart `_closeLegacyBusySessions`，恢复原频率+结束会话，历史留痕不丢）；busy 表/FrequencySource.busyMode/结算统计/备份往返等历史解释链原样保留；analyze 零告警、63/63 测试全绿——忙碌用例随功能移除，64→63）
- [x] T023 [US4] [P] 补签日历新视觉 `lib/features/today/backfill_calendar.dart`："补"标记与当日打卡不混淆、14 天窗口、FittedBox 布局保留 + V5 widget 测试更新 `test/widget_test.dart`（注：R3 裁决只去回顾屏的补签状态展示，今日屏长按补签功能保留——如用户再裁撤则本任务改为移除）✅ 2026-08-21——定稿语言重绘：surface 面板 + 顶部 rLg 圆角与 36×4 抓手 + titleS 标题/bodyS 提示；单日格 42×56 = 已成（目标色实心 + 白勾）/ 待补（divider 描边 + ＋ 邀请），周末行距 s2；V5 测试无需改动（周X + 日数文本结构保留）零改动通过；无引用的 `Copy.backfillTag`（「补」角标，R3 已裁不上回顾屏）删除
- [x] T024 [US4] US4 回归：V4/V5/V6 全场景走查（quickstart 阶段 B）、`flutter analyze` + `flutter test` 全绿 ✅ 2026-08-21——口径随 R3 裁决更新：V4 重走＝纯回看（周摘要/图例/节奏条/观察语，无决策无完成率，debug 构建跳下周一实测有卡路径 ✓ 空态本周新建目标如实不上卡 ✓）、V5 长按补签 Web 实测（新视觉弹层 + 补 4 笔 + toast 撤销 ✓，语义面拖拽不可达改由组件测试钉横滑：T021 测试扩第二目标 1/7 低档 + PageView 滑动断言）、V6 忙碌模式已废（T022 移除）；`flutter analyze` 0 issue、全量 65 测试全绿、控制台零错误；设置页为仅存旧风格屏（≤1，SC-006 达标，待 T026）

**Checkpoint**: 产品"教练"角色完成升级，次级流程不再有旧观感

---

## Phase 6: User Story 5 - 设置、通知与品牌收尾 (Priority: P5)

**Goal**: 设置/备份新 UI、通知文案与时机联动（FR-012）、全套品牌素材（图标/启动屏/小组件视觉）、深色全屏达标

**Independent Test**: V7 备份回归；深色遍历全屏 AA 达标；push → Codemagic 绿 → 真机核对品牌与通知

### Implementation

- [x] T025 [US5] 设置屏原型 `design/prototypes/screen-settings.html` + 评审通过（`design/reviews.md`）：分组、备份入口、通知设置、深色画板 ✅ **2026-08-21 R2 通过**（「行吧，先这样继续了」，T026/T027/T029/T030 解锁）（R1 后用户裁决「不需要展示目标的内容，聚焦 APP 本身的设置」→ 逐目标提醒行移除、身份卡去目标统计、场景指引留 hint；导入冲突弹层/隐私脚注/深色/常驻四页签 nav 保留。另：目标列表 R1 通过被用户补审否决「差太多了」→ screen-goals.html R2 整屏重做同日送审，实现任务门禁相应顺延）
- [x] T026 [US5] 设置落地 `lib/features/settings/settings_view.dart`：新语言重写 + V7 备份导出/导入（冲突对话框、计数 toast）回归 ✅ 2026-08-21——screen-settings.html R2 全量落地：displayS「我的」+ 身份卡（44 渐变头像「星」+ 名字，无目标统计）+ 提醒组（概要行 icon/标题/副文/08:00 tnum/Switch positiveFill + 场景指引两条，时间选择/开关持久化沿用 _briefRowId 原逻辑）+ 备份与数据两行（导出/导入逻辑逐字保留）+ 虚线隐私脚注 + Debug 时钟（kDebugMode）+ Web 占位（kIsWeb）；权限卡重做（FR-007：已知未开启且未「知道了」才显示，展示时提示换 notifOffHint——画板②口径；态提升到 SettingsView 统一判定）；R1 逐目标提醒行/目标内容全删（`锻炼` 不上屏有断言）；组卡改 Material 承色 + Container 描边投影（goals 卡同款，修 ListTile 墨迹断言）；copy 清理：settingsNav/notifEnabled/remindersHeader/goalsEmptyCta 孤儿删除；V7 以组件测试钉住：导出走分享网关 + 「备份已生成」toast、本地有数据必弹「导入会覆盖当前全部数据」→「覆盖本地」→ 计数 toast「导入完成：目标 1…」（export→import 往返假件）；`flutter analyze` 0 issue、全量 65 测试全绿、Web headless 走查语义全对 + 时间选择器/开关交互 ✓ + 控制台零错误
- [x] T027 [US5] [P] 通知重设计（FR-012）`lib/core/copy.dart` + `lib/features/settings/reminder_service.dart`：文案新品牌语气；提醒时刻按目标提醒时机字段调度（空值回落默认时段、同档时机多目标打扰合并）+ 调度单测 `test/` ✅ 2026-08-21：cueScene 场景档驱动——早起后 07:30/午休时 12:30/晚饭后 19:30/睡前 21:30（原型仅钉默认 20:00 与「睡前 21:30」两锚，其余为本轮定值）/空值与未知值回落默认档 20:00/同档多目标合并一条（名单+「挑一件顺手的开始」）/「不打扰」不提醒；单目标正文带「为什么」（编辑器预览句式「为了×，今天×了吗？」），没写则「今天还没记录，做一次就算数。」；场景词表与编辑器 chips 同源（Copy.cue* 常量重建 editorCueScenes）；001 逐目标 Reminder 行退役失效（编辑器已不写、调度不再读，仅 dailyBrief 行仍管概要）；goalReminderId 哈希删→档位稳定 id 2-6；goalReminderBody 孤儿删；调度单测 4 条新增（场景时刻+为什么正文/同档合并/不打扰+未知回落/旧行失效），69 测试全绿
- [ ] T028 [US5] 品牌母版与 iOS 资产 `design/brand/` + `pubspec.yaml`：Target 图标 1024 母版（浅/深）→ 配置 `flutter_launcher_icons` + `flutter_native_splash`（dev_dependencies）→ `dart run` 生成 iOS 全档资产（图标/启动屏）⏳ **方向先行：icon-proposal.html 三案候选（今日之环/墨梅一瓣/今字印）2026-08-21 送审中——选定后精修母版进生成链，生成步骤仍守 T025 门禁**
- [x] T029 [US5] [P] 小组件视觉同步 `ios/TargetWidgets/DesignTokens.swift`（色板镜像，文件头注明同步自 `design_tokens.dart`）+ MediumView/锁屏 circular 外观刷新：**功能与数据流不动**（FR-008）✅ 2026-08-21：DesignTokens.swift 新建（语义色浅/深成对 WidgetPalette + 8 目标色浅/深表——001 旧色值 E2725B 系全部换标定新值 + 头像渐变对 + 圆角刻度；已补 pbxproj 四处条目 objectVersion 54 显式引用）；SmallView/MediumView/锁屏 circular 刷新——电量环轨道 onSurface 15%/进度 positiveFill 青柠、<30% warning 琥珀（弃 systemGray5/orange 系统色），Medium 头部加「星」渐变身份徽 + tabular 数字，目标行圆图标 → 26pt 圆角方 GoalChip（目标色 18% 底+首字），达成勾 positiveFill/未达成目标色；AccessoryRectangular/containerBackground/打卡 Intent/快照 schema 全部未动；本机无 Xcode，Swift 编译验证挂 T033 Codemagic 首次构建
- [x] T030 [US5] 深色模式全屏核对：浅/深遍历全部屏，正文对比度 ≥4.5:1（SC-005），问题项修正并记录抽查结果 `design/reviews.md` ✅ **2026-08-21 通过，源码零修改**——正文配对矩阵（onSurface/onSurfaceVariant × surface/surfaceAlt/bgGrad 四档含玻璃混合，浅深两套）全部 ≥4.5:1；边缘项 3 条留档（light amber 2.94:1 图形级 / 白图标压目标色装饰对 / positive·warning×surfaceAlt 理论对，实际屏无此组合）；最终 web 构建 8 屏（4 屏 × 浅深）无头截图全部视觉核验通过（浅色「我的」首轮误读经转写式复核排除——路由不感知配色 + 深色同 URL 正常，判视觉模型误读）；陈旧投递假 404（http.server 无 Cache-Control 缓存 main.dart.js）探针定因后全新重建重验；过程坑留档见 reviews.md「实现审计」节

**Checkpoint**: 全套品牌成立——图标、启动屏、小组件、通知与主 App 一体

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: 一致性清零、全量验收、发布

- [X] T031 令牌白名单清零：消灭 `test/design/token_contract_test.dart` 白名单中全部遗留硬编码条目（SC-004 达成 100% 取值于令牌）✅ **2026-08-20 提前达成**——唯一条目 goals_view.dart 3 处 fontSize 已随 T017 重写自然消灭，条目移除、白名单清空；契约测试绿（后续屏重写若引入硬编码将被空名单直接拦红，机制闭环）；flutter test 64 全绿
- [x] T032 全量走查：quickstart.md 阶段 B 全表 + 001 的 V1–V8 全场景回归 + SC-001…SC-006 逐条核对 + `design/reviews.md` 确认全部核心屏"通过" ✅ **2026-08-21 通过**——analyze 0 issue + 69 测试全绿；web 实测打卡 1 次交互即时刷新 + 刷新持久（SC-002）；V1–V8 按当前裁决口径全过（V4 决策动线/V6 忙碌已由用户 2026-08-21 裁决废止，纯回看+忙碌清零按新口径核验；V3 挂 T033 真机）；SC-001 六屏全通过+方向留档、SC-004 白名单空复跑绿、SC-005 随 T030、SC-006 并存 0 屏；核心屏 reviews.md 状态全「通过」（品牌图标非核心屏仍挂起）；明细见 reviews.md「实现审计」T032 节
- [ ] T033 发布验证：`flutter analyze` + `flutter test` 全绿 → `git push` → Codemagic 绿 → TestFlight 真机核对（quickstart 阶段 C：图标/启动屏/小组件/深色/动效帧率/通知时机与文案）⏳ 2026-08-21 agent 侧完成：analyze 0 issue + 69 测试全绿、45 提交已 push（4666294..24277b5）；**Codemagic 为手动触发**（codemagic.yaml `ios-unsigned`：unsigned.ipa → iLoader 自签装机，无 TestFlight 链路）——剩用户手动：控制台触发构建（T029 小组件首次 Swift 编译验证点）→ 下载 unsigned.ipa 自签装机 → quickstart 阶段 C 真机核对
- [x] T034 文档收尾：更新 `specs/002-ui-ux-redesign/` 各文档状态与根 README（若涉及新命令/新目录说明）✅ 2026-08-21——README 由 Flutter 模板实体化（项目定位/常用命令/结构要点：令牌三端真源、design 原型先行、specs 结构/验证指南）；spec.md Status → Implemented（遗留 T028 选案与 T033 用户手动侧）；quickstart 前置与阶段 C 修正为实际发布回路（Codemagic 手动触发 ios-unsigned → unsigned.ipa → iLoader 自签，无 TestFlight 链路）

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
- **2026-08-21 用户三条裁决**：① 目标列表 R1 否决重做（screen-goals.html R2 送审中——通过前 goals_view 列表部分不返工，避免二次返工）；② 周回顾逐目标卡改左右滑动（已改）；③ 设置聚焦 App 本身去目标内容（已改，随 R1/R2 合并裁决）
- **2026-08-21 用户第二轮裁决（周回顾）**：① 回顾屏去决策动线、聚焦查看；② 补签状态不上回顾屏（今日屏补签功能保留）；③ 忙碌态全 App 移除（T022 改写为移除任务，涟漪见 reviews.md R3 条目）；④ pager 纵向可滑 bug 修复。周回顾随 R3 送审
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
