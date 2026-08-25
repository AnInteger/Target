/// 文案表（ui-contract.md「文案与语气」：教练式、非指责，可整体审校 T050）。
///
/// 约定：UI 层不写裸字符串，从 Copy.* 取；带参文案为方法。
library;

abstract final class Copy {
  // ---- 打卡 / 撤销（FR-004）----

  static const checkInDone = '记下了';
  static const undoCheckIn = '撤销';
  static String backfillDone(String day) => '已补上 $day 的记录';
  static const checkInRevoked = '已撤销，统计同步更新';

  // ---- 目标创建 / 编辑（FR-001/011/012）----

  static const editorNewGoal = '新建目标'; // 004 v2：标题随冻结稿（原「新的目标」退役）
  static const editorIconColor = '图标与颜色';
  static const editorSave = '保存';
  static const focusLimitTitle = '先照顾好这 5 个';
  static const focusLimitBody = '目标贵在聚焦。暂停或归档一个，再放新的进来。';

  // ---- 编辑器 · B 案动线（002 T014 定稿；004 v2 编辑器换装后界面
  //      退役，仅存 widget_test「002 句式残留」负向哨兵引用）----

  static const editorFrequencyLabel = '多久做一次？';
  static const editorWhyLabel = '为什么想做？';
  static const editorCriterionLabel = '怎样算做到？';
  static const editorCueLabel = '什么时候提醒你？';

  // ---- 目标管理页 ----

  static const goalsDaysRecorded = '天有记录';

  // ---- 目标详情（T021：管理动线 + 打卡描述 + 历史记录；
  //      004 T014 按冻结稿 v2-goal-detail 换装）----

  static const goalDetailTitle = '目标详情';
  static const goalMissing = '目标不存在或已删除';
  static const goalEdit = '编辑目标';
  static const goalMoreActions = '更多操作';

  /// 打卡动线选填描述（FR-019；40 字上限与编辑器描述一致；
  /// 004 v2 冻结稿提示语）。
  static const checkInNoteHint = '一句话记录（选填）';
  static const goalHistoryTitle = '历史记录';

  /// 今日行动卡标题与主按钮（冻结稿 .card-title / .btn-primary）。
  static const detailTodayCard = '今日记录';
  static const goalCheckInAction = '记录打卡';

  /// 近 7 天点阵脚注（冻结稿 .sub：虚线圈 = 补签）。
  static const weekDotsHint = '虚线圈 = 补签记录；点任意过去日可补签';

  /// 补签弹层（冻结稿板 3：14 天窗口日历单选 + 确认主按钮）。
  static const backfillSheetTitle = '补签日期';
  static const backfillSheetHint = '绿色描边表示已有记录；可补记最近 6 个月的空日期';
  static String backfillConfirm(int month, int day) => '补签 $month 月 $day 日';
  static const backfillTag = '补签';

  /// 日历星期头（周一开头，与周窗口统计同口径）。
  static const List<String> backfillWeekdays = [
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '日',
  ];

  /// 暂停横幅与菜单动作（冻结稿板 4/5：⋯ 收纳 + 暂停态恢复行动）。
  static const goalPausedBanner = '目标已暂停，不参与统计与提醒';
  static const goalResumeAction = '恢复';
  static const menuPauseGoal = '暂停目标';
  static const menuDeleteGoal = '删除目标';

  /// 徽章状态尾缀（冻结稿板 5：「长期 · 创作 · 目标 · 已暂停」）。
  static const goalStatusPausedSuffix = '已暂停';
  static const goalStatusAchievedSuffix = '已达成';
  static const goalStatusArchivedSuffix = '已归档';

  /// 删除二次确认（冻结稿 .dlg：居中对话框 + 双胶囊按钮）。
  static const deleteConfirmTitle = '删除目标';
  static String deleteConfirmBody(String name) => '「$name」及其全部记录将被删除，此操作不可恢复。';
  static const deleteConfirmYes = '删除';
  static const dialogCancel = '取消';

  /// 身份区 meta 胶囊（冻结稿 .meta：连续/本周/提醒；短期倒计时）。
  static String streakMeta(int n) => '连续 $n 天';
  static String weekMeta(int done, int elapsed) => '本周 $done/$elapsed 次';
  static String reminderMeta(String cadenceLabel, String time) =>
      '$cadenceLabel · $time 提醒';
  static String deadlineCountdownMeta(int days) => days > 0
      ? '距截止 $days 天'
      : days == 0
      ? '截止日就是今天'
      : '已过 ${-days} 天';
  static String deadlineDateMeta(String iso) => '$iso 截止';
  static String historyCountMeta(int n) => '历史 $n 条记录';
  static String createdMeta(String iso) => '创建于 $iso';

  /// 续期行副题（冻结稿板 2 .sub）。
  static const renewHint = '续期后倒计时重置，已有记录保留';

  // ---- 首启引导（SC-001 · 004 v2 品牌屏：一句中文主张 + 开始使用）----

  static const onboardingTitle = '把在意的事，一天一天守好。';
  static const onboardingSubtitle = '记录每一天的坚持，回看每一周的变化。';
  static const onboardingStart = '开始使用';

  // ---- 里程碑（FR-013）----

  static const milestoneDone = '达成了，恭喜！';
  static const milestoneStepsHeader = '里程碑'; // 004 v2 冻结稿卡题
  static const milestoneAddStep = '添加'; // 004 v2 冻结稿 .ms-add 按钮字
  static const milestoneDeleteStep = '删除步骤';
  static const milestoneStepHint = '添加步骤…'; // 004 v2 冻结稿输入占位
  static const milestonePostponed = '截止日已更新';

  // 短期到期处理（003 D4：到点只提醒不判决——标记达成/续期双入口；
  // 004 v2 常驻行形态，冻结稿板 2 字面）。
  static const goalMarkAchieved = '标记达成';
  static const goalRenewDeadline = '续期（调整截止日期）';

  // ---- 提醒 / 通知（FR-006/007）----

  static const notifDeniedTitle = '通知未开启';
  static const notifDeniedBody = '不开通知也能用全部功能；想开的话，去系统设置里找 Target。';
  static const notifEnable = '开启通知';
  static const notifAck = '知道了';

  // ---- 提醒场景（FR-012：编辑器 chips 与调度器共用同一套词汇；
  //      004 v2 编辑器场景档退役，仅存 widget_test 残留哨兵引用）----

  static const cueEarly = '早起后';
  static const cueMidday = '午休时';
  static const cueEvening = '晚饭后';
  static const cueNight = '睡前';

  // ---- 每日概要 / 逐目标提醒（FR-006/008/012）----

  static const dailyBriefTitle = '今天的小事';
  static const dailyBriefAllDone = '都照顾到了，安心过今天。';
  static String dailyBriefSummary(int unmet) =>
      unmet == 1 ? '还有 1 件小事在等你，不着急。' : '还有 $unmet 件小事在等你，不着急。';

  // 逐目标提醒（场景档驱动）：单目标带「为什么」（编辑器预览承诺的句式）。

  /// 单目标正文（写了为什么）：「为了身体轻一点，今天散步了吗？」
  static String reminderAsk(String motivation, String name) =>
      '为了$motivation，今天$name了吗？';

  /// 单目标正文（没写为什么）。003 T045 语域清查：口语化改正式陈述。
  static const reminderNudge = '今天还没有记录。';

  static const reminderGoalHint = '目标提醒在编辑目标时设置，按所选频率定时提醒。';

  // ---- 备份（FR-015）----

  static const backupExport = '导出备份';
  static const backupImport = '恢复备份';
  static const backupImportConflictTitle = '恢复备份';
  static const backupImportConflictBody = '将用备份文件中的全部数据替换当前数据。此操作不可撤销。';
  static const backupImportOverwrite = '恢复';
  static const backupImportCorrupt = '备份文件不完整，已取消导入';
  static const backupImportDone = '导入完成';
  static const backupImportCancel = '取消';
  static const backupExported = '备份已生成';

  // ---- 设置 / 其他（004 v2 冻结稿 v2-settings.html：账号卡 + 外观/通知/
  // 目标/数据/关于分组，行 = 图标 + 标题 + 行尾值|开关|箭头|对勾）----

  static const profileTitle = '我的';
  static const settingsTitle = '设置';

  static const settingsMeSub = '编辑资料';
  static const settingsSectionAppearance = '外观';
  static const settingsSectionNotif = '通知';
  static const settingsSectionGoals = '目标';
  static const settingsSectionData = '数据';
  static const settingsSectionAbout = '关于';

  // 主题三档（FR-002：切换即时生效并持久保留）。
  static const settingsThemeSystem = '跟随系统';
  static const settingsThemeLight = '浅色';
  static const settingsThemeDark = '深色';

  static const settingsGoalsActiveTitle = '进行中目标';
  static const settingsBackfillTitle = '补签';
  static const settingsBackfillSub = '在目标详情页选择过去日期补记';
  static const settingsVersionTitle = '版本';
  static const settingsVersionValue = '1.0.0';

  // 通知分组行（v2-settings：总开关 + 概要时间 + 按目标提醒二级）。
  static const settingsNotifMasterTitle = '通知';
  static const settingsNotifMasterSub = '提醒与每日概要';
  static const settingsBriefTitle = '每日概要时间';
  static const settingsBriefSub = '每天此时汇总当日待办';
  static const settingsGoalRemindersTitle = '按目标提醒';

  /// 二级展开行副题；无行时另用 [settingsGoalRemindersNoneSub]。
  static String settingsGoalRemindersSub(int n) => '已开启 $n 个';
  static const settingsGoalRemindersNoneSub = '在编辑目标时开启提醒';

  /// 二级展开后的说明（v2-settings 板 3 hint）。
  static const settingsNestHint = '关闭单个目标的提醒后，每日概要不受影响';

  /// 二级逐行副题：「一天一次 · 09:00」。
  static String settingsGoalReminderLine(String cadenceLabel, String time) =>
      '$cadenceLabel · $time';
  static const notifOffHint = '开关会记住你的偏好，开通知后按这里的时间提醒。';
  static const backupExportSub = '生成备份文件';
  static const backupImportSub = '从备份文件导入';
  static const widgetIosOnly = '桌面小组件与提醒推送为 iPhone 专属功能';
  static const debugClock = 'Debug 时钟';
  static const appName = 'Target';

  // ---- 今日页（FR-017/US2）----

  // 004 T022：今日页长按补签弹层退役（backfillCalendarTitle/
  // backfillHint 死键清扫；补签统一走详情页 14 天日历）。
  static const todayNav = '今日';
  static const goalsNav = '目标'; // 004 dock 无目标页签，存 widget_test 哨兵
  static const progressNav = '进展';
  static const mineNav = '我的';

  // ---- 今日页（004 T020 v2 重做：头部日期语 + 大标题 + 三段弧环；
  //      003 头部带日期语退役）----

  // 004 T022：「今日目标」节头/节注随 003 目标列表退役（todaySection/
  // todayRecordedNote 死键清扫），列表职能换关注卡轮播。
  static const todayNewGoal = '新建目标';
  // 004 v2：打卡按钮字统一「记录打卡」（goalCheckInAction），
  // 「记录一次努力」退役。

  /// v2 头部日期行（v2-today 冻结稿 .date）：「星期日 · 8 月 23 日」。
  static String todayHeadDate(String weekdayZh, int month, int day) =>
      '星期$weekdayZh · $month 月 $day 日';

  /// 三段弧环中心标签（.ctr i）。
  static const todayHealthLabel = '健康度';

  /// 图例分数后缀（.lg .li span）。
  static const todayHealthSuffix = '/ 100';

  /// 图例无数据态占位（类内零活跃：不显示数字）。
  static const todayHealthNone = '—';

  /// 最新记录行描述兜底（FR-019 未填描述时）。
  static const checkInDefaultNote = '完成打卡';

  static const todayLatestNone = '还没有记录';
  static String todayLatestDaysAgo(int n) => '$n 天前';

  /// 最新记录行日桶语（今日/回顾两屏同源口径；004 T015 通知组头
  /// 退役后自键，不再借用通知块词汇）。
  static const todayLatestToday = '今天';
  static const todayLatestYesterday = '昨天';

  // 空态（004 T020 按 v2-today 板 4 冻结稿：环区让位 + 新建 CTA）。
  static const todayEmptyTitle = '还没有目标';
  static const todayEmptyBody = '创建第一个目标，开始记录每一天的坚持。\n健康度将随打卡记录逐步累积。';

  // ---- 关注卡轮播（004 T021，v2-today 冻结稿 .fcard .tag）----

  /// 状态标签（● 前缀白字胶囊）：短期进行中 / 今日已记录 → 进行中；
  /// 今日待记录 → 待办。
  static const focusTagActive = '进行中';
  static const focusTagTodo = '待办';

  /// 轮播节头（.cap .t）与「查看全部」入口（.cap .see → /goals-all）。
  static const focusSection = '关注';
  static const focusSeeAll = '查看全部 ›';

  /// 全部目标页大标题（004 T022 先立过渡页，T023 按冻结稿全量实现）。
  static const goalsAllTitle = '全部目标';

  // ---- 全部目标页（004 T023，v2-goals-all 冻结稿）----

  /// 筛选 chips（单选：全部 + 十小类）与顶栏新建胶囊（.new）。
  static const goalsFilterAll = '全部';
  static const goalsNewCapsule = '新建';

  /// 筛选空态（.fempty）：分类名明示 + 新建 CTA（复用 todayNewGoal）。
  static const goalsFilterEmptyTitle = '该分类暂无目标';
  static String goalsFilterEmptyBody(String name) => '「$name」分类下还没有目标';

  /// 卡摘要行（.r2 口径同详情 meta 胶囊的延展）：
  /// 达成 = 完成日照面；今日已记录但连击未起算的习惯兜底；
  /// 短期 = 倒计时 · 里程碑完成百分比（配 .prog 进度条）。
  static String goalAchievedMeta(String day) => '$day 标记达成';
  static const goalRecordedTodayMeta = '今天已记录';
  static String shortTermProgressMeta(int percent) => '已完成 $percent%';

  // 成就时刻（每个目标今天都有记录）。
  static const celebrationTitle = '🎉 每个目标都有进展';
  static String celebrationNote(int n) => '今日 $n 次记录';

  // ---- 003 文案层（T014：三 Tab / 编辑器分组 / 通知列表 / 类型徽章）----

  // 账号资料（FR-004：未填写不强迫，默认头像 + 默认昵称；004 板 4
  // 冻结稿：sheet 无节标签，保存 = 全宽胶囊主按钮）。
  static const profileDefaultNickname = '我';
  static const profileSheetTitle = '编辑资料';
  static const profileDone = '保存';

  // 通知列表（sheet，推导式 D6：无已读态；004 T015 按冻结稿换装——
  // 分组头退役，行尾相对时刻 + 语义色格图标 + 图形化空态）。
  static const notificationTitle = '通知';
  static const notifEmptyTitle = '暂无通知';
  static const notificationEmptyHint = '有新的提醒与达成记录时会显示在这里';

  // 行尾相对时刻（冻结稿 .tm）：当日内按粒度收敛，跨日报桶语 + 时刻；
  // 推导列表的未来仅今日+明日两档（时刻表窗口）。
  static const notifJustNow = '刚刚';
  static String notifMinutesAgo(int n) => '$n 分钟前';
  static String notifHoursAgo(int n) => '$n 小时前';
  static String notifDaysAgo(int n) => '$n 天前';
  static String notifTodayAt(String time) => '今天 $time';
  static String notifYesterdayAt(String time) => '昨天 $time';
  static String notifTomorrowAt(String time) => '明天 $time';
  static String notifDateAt(int month, int day) => '$month月$day日';

  // 四源条目文案（行 = 图标 + 标题 + 副题 + 时刻）。
  static const notifSubGoalReminder = '目标提醒';
  static const notifSubBrief = '每天一份，不催促';
  static const notifSubMilestone = '里程碑';
  static const notifSubAchievement = '成就时刻';

  /// 短期到期询问（D4：只提醒不判决；tap → 目标详情）。
  static String notifDueTitle(String name) => '$name到日子了，怎么样？';
  static String notifDueSub(int daysOver) =>
      daysOver <= 0 ? '短期目标 · 今天' : '短期目标 · $daysOver 天前';

  /// streak 里程碑（当前总连击命中的档位）。
  static String notifStreak(int n) => '连续记录 $n 天，节奏稳住了';

  /// 全完成日（当日全部活跃目标均有记录）。
  static const notifAllDoneDay = '每个目标都有记录的一天';

  /// 目标达成事件（achievedAt 落在近 7 天）。
  static String notifAchieved(String name) => '$name，达成了';

  // 编辑器分组标题（004 v2 冻结稿组序：类型→一句话描述→分类→提醒/里程碑）。
  static const editorSectionCategory = '分类';
  static const editorSectionBasics = '目标名称';
  static const editorSectionType = '类型';

  // 分类图标（T026：常用行 + 「更多」弹窗全量，R2 裁决 1）。
  static const editorPickCategoryTitle = '选择分类';
  static const editorIconMoreLabel = '更多分类图标';
  static const editorIconMoreShort = '更多';
  static const editorSectionReminder = '提醒';

  /// 图标格语义名（原型 aria-label 同款口径：键名即名）。
  static String editorIconSemantics(String key) => '分类图标 $key';

  /// 一句话描述示范（research D8 完整短句式；004 v2 冻结稿示例）。
  static const editorNameHint = '例如：骑行台训练，均速突破 25km/h';

  /// 短期截止日行标签（v2 冻结稿：「截止日期」+ 必填小标）。
  static const editorDeadlineLabel = '截止日期';
  static const editorRequiredTag = '必填';
  static const editorOptionalTag = '选填';

  /// 类型锁定小标（v2 冻结稿板 4：编辑态类型不可改——004 形态决策）。
  static const editorTypeLockedTag = '创建后不可变更';

  /// 习惯/长期提醒开关行标签（v2 冻结稿 attr 行）；关闭态副题随之切换。
  static const editorReminderSwitch = '开启提醒';
  static const editorReminderOffSub = '关闭时不发送该目标的提醒';

  /// 频率区标题（提醒开关开后出现，v2 冻结稿卡内小标）。
  static const editorCadenceLabel = '频率';

  /// 提醒时间行标签（开关开后出现，T025）。
  static const editorRemindTimeLabel = '提醒时间';

  /// 短期里程碑提示卡（v2 冻结稿板 2：步骤在详情页逐步添加）。
  static const editorMilestoneTitle = '里程碑';
  static const editorMilestoneHint = '第一步在详情页逐步添加';

  /// 短期倒计时预告（原型 R3 count-pv；0/已过分支同款）。
  static String editorCountdownPreview(int days) => days > 0
      ? '距截止还有 $days 天'
      : days == 0
      ? '截止日就是今天'
      : '已过 ${-days} 天';

  // 类型徽章（D2 三类型域：长期/短期/习惯）。
  static const typeBadgeLongTerm = '长期';
  static const typeBadgeShortTerm = '短期';
  static const typeBadgeHabit = '习惯';

  // 短期到期询问（D4：截止日只提醒不判决，到点推送 + 通知列表条目）。
  static const shortTermDueAsk = '到日子了，怎么样？';

  // 习惯提醒频率档（FR-013 开关化 cadence；004 v2 冻结稿短标签——
  // 编辑器分段/我的页二级行/详情提醒行三处同源）。
  static const cadenceDaily = '每天';
  static const cadenceThreeDay = '隔三天';
  static const cadenceWeekly = '每周';
}
