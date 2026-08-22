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

  // ---- 周回顾（FR-008 · R3 纯回看：只描述，不建议，不决策）----

  static const reviewTitle = '上周回顾';

  /// 周摘要：「留下 N 次记录 · M 个目标」（努力语言，无完成率）。
  static String reviewWeekSum(int records, int goals) =>
      records == 0 ? '还没有留下记录' : '留下 $records 次记录 · $goals 个目标';

  static const reviewLegendRecorded = '有记录';
  static const reviewLegendMissed = '没记录';
  static const reviewLegendNa = '不适用';
  static const reviewTrendCap = '近 4 周';
  // 观察语三档（R3：只说这一周怎么过的，不指挥下周）。
  static const reviewCoachAll = '这一周很扎实，该在的都在。';
  static const reviewCoachOkay = '有几天被挤掉了，正常的一周。';
  static const reviewCoachLow = '这周留下得不多，看看都停在哪几天。';
  static const reviewEmptyTitle = '还没有可回看的一周';
  static const reviewEmptySub = '先建一个目标、留下几次记录，\n这里会把那一周替你收好。';

  // ---- 目标创建 / 编辑（FR-001/011/012）----

  static const editorNewGoal = '新的目标';
  static const editorIconColor = '图标与颜色';
  static const editorSave = '保存';
  static const focusLimitTitle = '先照顾好这 5 个';
  static const focusLimitBody = '目标贵在聚焦。暂停或归档一个，再放新的进来。';
  static const goalArchived = '已归档，历史记录都在';

  // ---- 编辑器 · B 案动线（002 T014 定稿：单一概念 + 动机先行）----

  static const editorFrequencyLabel = '多久做一次？';
  static const editorWhyLabel = '为什么想做？';
  static const editorCriterionLabel = '怎样算做到？';
  static const editorCueLabel = '什么时候提醒你？';

  // ---- 目标管理页 ----

  static const goalsTitle = '目标';
  static const goalsDaysRecorded = '天有记录';
  static const goalsPausedNote = '暂停中 · 记录保留';
  static const goalPauseHint = '先放一放，想回来随时继续';
  static const goalsEmptyOwn = '写一句自己的';

  // ---- 目标详情（T021：管理动线 + 打卡描述 + 历史记录）----

  static const goalEdit = '编辑目标';
  static const goalMoreActions = '更多操作';

  /// 详情头提醒行（003 T038 修正：真源 Reminders 行）：「提醒 · 一天一次 · 08:30」。
  static String goalReminderLine(String detail) => '提醒 · $detail';

  /// 打卡动线选填描述（FR-019；40 字上限与编辑器描述一致）。
  static const checkInNoteHint = '选填一句话描述';
  static const goalHistoryTitle = '记录';

  // ---- 首启引导（SC-001）----

  static const onboardingTitle = '先照顾好一件小事';
  static const onboardingSubtitle = '选一个想守护的习惯，30 秒就能开始';
  static const onboardingSkip = '先随便看看';

  // ---- 里程碑（FR-013）----

  static String milestoneProgress(int done, int total) => '$done/$total';
  static String milestoneCountdown(int days) =>
      days >= 0 ? '还剩 $days 天' : '过了 ${-days} 天';
  static const milestoneOverdue = '不急，下一步是什么？'; // 过期温和提示
  static const milestoneDone = '达成了，恭喜！';
  static const milestoneStepsHeader = '拆成小步';
  static const milestoneAddStep = '加一步';
  static const milestoneDeleteStep = '删除步骤';
  static const milestoneStepHint = '一句话描述这一步'; // 003 T045 语域清查：口语劝诫改正式描述
  static const milestonePostponed = '截止日已更新';

  // 短期到期处理（003 D4：到点只提醒不判决——标记达成/续期双入口）。
  static const goalMarkAchieved = '标记达成';
  static const goalRenewDeadline = '续期';

  // ---- 提醒 / 通知（FR-006/007）----

  static const notifDeniedTitle = '通知未开启';
  static const notifDeniedBody = '不开通知也能用全部功能；想开的话，去系统设置里找 Target。';
  static const notifEnable = '开启通知';
  static const notifAck = '知道了';

  // ---- 提醒场景（FR-012：编辑器 chips 与调度器共用同一套词汇）----

  static const cueEarly = '早起后';
  static const cueMidday = '午休时';
  static const cueEvening = '晚饭后';
  static const cueNight = '睡前';

  // ---- 每日概要 / 逐目标提醒（FR-006/008/012）----

  static const dailyBriefTitle = '今天的小事';
  static const dailyBriefAllDone = '都照顾到了，安心过今天。';
  static String dailyBriefSummary(int unmet) => unmet == 1
      ? '还有 1 件小事在等你，不着急。'
      : '还有 $unmet 件小事在等你，不着急。';
  static const dailyBriefReviewLine = '上周回顾已生成，花两分钟看看这一周';

  // 逐目标提醒（场景档驱动）：单目标带「为什么」（编辑器预览承诺的句式）。

  /// 单目标正文（写了为什么）：「为了身体轻一点，今天散步了吗？」
  static String reminderAsk(String motivation, String name) =>
      '为了$motivation，今天$name了吗？';

  /// 单目标正文（没写为什么）。003 T045 语域清查：口语化改正式陈述。
  static const reminderNudge = '今天还没有记录。';

  static const reminderGoalHint = '目标提醒在编辑目标时设置，按所选频率定时提醒。';
  static const reminderMondayHint = '周一的概要会带上上周回顾。';

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

  static const settingsTitle = '我的';

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

  static const backfillCalendarTitle = '补一补过去两周';
  static const backfillHint = '点想补的日期，线就接回来';
  static const todayNav = '今日';
  static const goalsNav = '目标';
  static const reviewNav = '回顾';
  static const mineNav = '我的';

  // ---- 今日页 · R7 定稿（T017 头部带 + 统一卡；旧今日之环语言退役）----

  static const todaySection = '今日目标';
  static const todayNewGoal = '新建目标';
  static const todayCheckAction = '记录一次努力';

  /// 头部带日期语：「8月19日 周三」。
  static String todayDateLine(int month, int day, String weekdayZh) =>
      '$month月$day日 $weekdayZh';

  /// 节注（今日之环退役后承接进度一句话）：「已记录 2/5」。
  static String todayRecordedNote(int done, int total) => '已记录 $done/$total';

  /// 最新记录行描述兜底（FR-019 未填描述时）。
  static const checkInDefaultNote = '完成打卡';

  static const todayLatestNone = '还没有记录';
  static String todayLatestDaysAgo(int n) => '$n 天前';

  // 空态邀请卡（R3 裁决 3：正式语域）。
  static const todayEmptyTitle = '还没有目标';
  static const todayEmptyBody = '点击右上角 ＋ 创建第一个目标';

  // 成就时刻（每个目标今天都有记录）。
  static const celebrationTitle = '🎉 每个目标都有进展';
  static String celebrationNote(int n) => '今日 $n 次记录';

  // ---- 003 文案层（T014：三 Tab / 编辑器分组 / 通知列表 / 类型徽章）----

  // 账号资料（FR-004：未填写不强迫，默认头像 + 默认昵称）。
  static const profileDefaultNickname = '我';
  static const profileSheetTitle = '编辑资料';
  static const profileNicknameLabel = '昵称';
  static const profileAvatarLabel = '选择头像';
  static const profileDone = '完成';

  // 通知列表（sheet，推导式 D6：无已读态，空态一句话）。
  static const notificationEmptyHint = '这里会出现你的提醒和值得记下的时刻';
  static const notificationTitle = '通知';

  // 分组头（今天/昨天/明天；更早按日期）。
  static const notifDayToday = '今天';
  static const notifDayTomorrow = '明天';
  static const notifDayYesterday = '昨天';
  static String notifDayDate(int month, int day) => '$month月$day日';

  // 四源条目文案（行 = 图标 + 标题 + 副题 + 时刻）。
  static const notifSubGoalReminder = '目标提醒';
  static const notifSubBrief = '每天一份，不催促';
  static const notifSubMilestone = '里程碑';
  static const notifSubAchievement = '成就时刻';

  /// 短期到期询问（D4：只提醒不判决；tap → 目标详情）。
  static String notifDueTitle(String name) => '$name到日子了，怎么样？';
  static String notifDueSub(int daysOver) => daysOver <= 0
      ? '短期目标 · 今天'
      : '短期目标 · $daysOver 天前';

  /// streak 里程碑（当前总连击命中的档位）。
  static String notifStreak(int n) => '连续记录 $n 天，节奏稳住了';

  /// 全完成日（当日全部活跃目标均有记录）。
  static const notifAllDoneDay = '每个目标都有记录的一天';

  /// 目标达成事件（achievedAt 落在近 7 天）。
  static String notifAchieved(String name) => '$name，达成了';

  // 编辑器分组标题（ui-contract「编辑器分组」；T023 R2 裁决 1 平铺无折叠）。
  static const editorSectionCategory = '分类';
  static const editorSectionBasics = '基础信息';
  static const editorSectionType = '目标类型';

  // 分类图标（T026：常用行 + 「更多」弹窗全量，R2 裁决 1）。
  static const editorPickCategoryTitle = '选择分类';
  static const editorIconMoreLabel = '更多分类图标';
  static const editorIconCloseLabel = '关闭';

  /// 图标格语义名（原型 aria-label 同款口径：键名即名）。
  static String editorIconSemantics(String key) => '分类图标 $key';

  /// 一句话描述示范（research D8：完整短句式 placeholder）。
  static const editorNameHint = '例如：月底前能连续跑 3 公里';

  /// 短期截止日行标签（原型 R3：「截止日」+ 必填小标）。
  static const editorDeadlineLabel = '截止日';
  static const editorRequiredTag = '必填';

  /// 习惯/长期提醒开关行标签与副题（原型 R3 attr 行）。
  static const editorReminderSwitch = '提醒';
  static const editorReminderSub = '按频率定时提醒';

  /// 提醒时间行标签（开关开后出现，T025）。
  static const editorRemindTimeLabel = '提醒时间';

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

  // 习惯提醒频率档（FR-013 开关化 cadence）。
  static const cadenceDaily = '一天一次';
  static const cadenceThreeDay = '三天一次';
  static const cadenceWeekly = '一周一次';
}
