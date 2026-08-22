/// 文案表（ui-contract.md「文案与语气」：教练式、非指责，可整体审校 T050）。
///
/// 约定：UI 层不写裸字符串，从 Copy.* 取；带参文案为方法。
library;

abstract final class Copy {
  // ---- 今日 / 生活电量（FR-017）----

  static const batteryEmpty = '—'; // 无活跃习惯目标的空态（R9：不呈现 0）
  static String batteryLow(int percent) => '该充电了 · $percent%'; // <30%，提示照顾自己
  static String batteryValue(int percent) => '$percent%';
  static const allDoneTitle = '今天都照顾到了';
  static const allDoneSubtitle = '剩下的时间，安心休息。';

  // ---- 打卡 / 撤销（FR-004）----

  static const checkInDone = '记下了';
  static const undoCheckIn = '撤销';
  static String backfillDone(String day) => '已补上 $day 的记录';
  static const checkInRevoked = '已撤销，统计同步更新';

  // ---- 连击 / 频率 ----

  static String streakDays(int n) => '连击 $n 天';
  static const streakBroken = '忙就先放下，线还在'; // 连击断裂
  static String todayProgress(int done, int target) => '$done/$target';

  // ---- 周回顾（FR-008 · R3 纯回看：只描述，不建议，不决策）----

  static const reviewTitle = '上周回顾';
  static const reviewNoApplicableDays = '本周不适用'; // 目标列表右栏空值复用
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
  static const reviewEmptyTitle = '上周还没有记录';
  static const reviewEmptySub = '这一周还没留下什么。去今天屏记上一笔，下周这里就有得看了。';

  // ---- 目标创建 / 编辑（FR-001/011/012）----

  static const editorNewGoal = '新的目标';
  static const editorCustom = '自定义';
  static const editorFromTemplate = '从模板开始';
  static const editorFrequency = '频率';
  static const editorIconColor = '图标与颜色';
  static const editorDeadline = '截止日期';
  static const editorDeadlineRequired = '选一个日子，给里程碑一个锚点';
  static const editorSave = '保存';
  static const focusLimitTitle = '先照顾好这 5 个';
  static const focusLimitBody = '目标贵在聚焦。暂停或归档一个，再放新的进来。';
  static const goalArchived = '已归档，历史记录都在';

  // ---- 编辑器 · B 案动线（002 T014 定稿：单一概念 + 动机先行）----

  static const editorTemplatesLabel = '从一句熟悉的话开始';
  static const editorNameLabel = '想做什么？';
  static const editorFrequencyLabel = '多久做一次？';
  static const editorWhyLabel = '为什么想做？';
  static const editorWhyHint = '一句就够，累的时候它会提醒你';
  static const editorWhyRequired = '写一句为什么吧——哪怕只有几个字';
  static const editorCriterionLabel = '怎样算做到？';
  static const editorCriterionAutoNote = '已按名称拟好，可改';
  static const editorCueLabel = '什么时候提醒你？';
  static const editorCueFallback = '不选场景则按默认时段提醒，同类目标合并打扰';
  static const editorCueScenes = [
    cueEarly,
    cueMidday,
    cueEvening,
    cueNight,
    cueNone,
  ];
  static String editorCuePreview(String scene) => '$scene会提醒你，文案里带上你的「为什么」';
  static const editorOnceLabel = '这是一次性目标';
  static const editorOnceSub = '有完成那天，比如「年底前跑一次 10km」';
  static const editorDdlThisYear = '今年内';
  static const editorDdl3Months = '三个月内';
  static const editorDdlCustom = '自选日期';
  static const editorOnceKindNote = '一次性目标 · 创建后类型不再变更';
  static const editorSaveCreate = '立下这个心愿';
  static const editorLooksLabel = '它长什么样？';

  // ---- 目标管理页 ----

  static const goalsTitle = '目标';
  static const goalsNew = '新建';
  static String goalsSum(int n, int m) =>
      m == 0 ? '$n 个目标 · 本周还没有记录' : '$n 个目标 · 本周留下 $m 次记录';
  static const goalsDaysRecorded = '天有记录';
  static const goalsStepsDone = '步完成';
  static const goalsDeadlineLabel = '截止';
  static const goalsOnceShort = '一次性';
  static String goalsActiveHeader(int n) => '进行中 $n/5';
  static const goalsPausedHeader = '已暂停';
  static const goalsPausedNote = '暂停中 · 记录保留';
  static const goalsResume = '恢复';
  static const goalsClosedHeader = '已结束';
  static const goalsWeekRate = '本周';
  static const goalPauseHint = '先放一放，想回来随时继续';
  static const goalsEmptyTitle = '想守护点什么？';
  static const goalsEmptySub = '从一句熟悉的话开始，或者写一句自己的。';
  static const goalsEmptyOwn = '写一句自己的';
  static String goalsOnceBadge(String deadline) => '一次性 · $deadline';

  // ---- 目标详情（T021：管理动线 + 打卡描述 + 历史记录）----

  static const goalEdit = '编辑目标';
  static const goalMoreActions = '更多操作';

  /// 详情头提醒行：「提醒 · 晚饭后」。
  static String goalReminderLine(String scene) => '提醒 · $scene';

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
  static const milestoneStepHint = '一步就好，别贪多';
  static const milestonePostponed = '截止日已更新';
  static const milestoneCloseTitle = '先放下';
  static const milestoneCloseAck = '这个目标先收进抽屉，不打分';

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
  static const cueNone = '不打扰';

  // ---- 每日概要 / 逐目标提醒（FR-006/008/012）----

  static const dailyBriefTitle = '今天的小事';
  static const dailyBriefAllDone = '都照顾到了，安心过今天。';
  static String dailyBriefSummary(int unmet) => unmet == 1
      ? '还有 1 件小事在等你，不着急。'
      : '还有 $unmet 件小事在等你，不着急。';
  static const dailyBriefReviewLine = '上周回顾已生成，花两分钟看看这一周';

  // 逐目标提醒（场景档驱动）：单目标带「为什么」（编辑器预览承诺的句式）。

  /// 场景档单目标标题：「晚饭后 · 散步」。
  static String reminderTitleScene(String scene, String name) => '$scene · $name';

  /// 场景档合并标题（同档多目标合成一条，FR-012）。
  static String reminderTitleSceneMany(String scene, int n) => '$scene · $n 件小事';

  /// 默认档（未选场景，20:00 轻提醒）合并标题。
  static String reminderTitleDefaultMany(int n) => '今晚 · $n 件小事';

  /// 单目标正文（写了为什么）：「为了身体轻一点，今天散步了吗？」
  static String reminderAsk(String motivation, String name) =>
      '为了$motivation，今天$name了吗？';

  /// 单目标正文（没写为什么）。
  static const reminderNudge = '今天还没记录，做一次就算数。';

  /// 合并档正文：名单 + 挑一件顺手的。
  static String reminderNames(List<String> names) =>
      '${names.join(' · ')}，挑一件顺手的开始。';

  static const reminderGoalHint =
      '目标提醒的时刻在编辑目标时选——早起后 / 午休时 / 晚饭后 / 睡前；'
      '没选的 20:00 轻提醒，同一时段几个目标合并成一条，不连环打扰。';
  static const reminderMondayHint = '周一的概要会带上上周回顾。';

  // ---- 备份（FR-015）----

  static const backupExport = '导出备份';
  static const backupImport = '导入备份';
  static const backupImportConflictTitle = '导入会覆盖当前全部数据';
  static const backupImportConflictBody = '两份不会混合——继续将替换为备份内容。';
  static const backupImportOverwrite = '覆盖本地';
  static const backupImportCorrupt = '备份文件不完整，已取消导入';
  static const backupImportDone = '导入完成';
  static const backupImportCancel = '取消';
  static const backupHeader = '备份与数据';
  static const backupExported = '备份已生成';

  // ---- 数据风险与隐私（FR-014）----

  static const onboardingDataNote = '数据只存在这台设备上，不上传云端';

  // ---- 设置 / 其他（T026 R2：聚焦 App 本身，无目标内容）----

  static const settingsTitle = '我的';
  static const settingsMeName = '星行';
  static const dailyBriefTimeLabel = '提醒';
  static const dailyBriefSub = '每天一份，不催促';
  static const notifOffHint = '开关会记住你的偏好，开通知后按这里的时间提醒。';
  static const backupExportSub = '生成一份文件，带走全部记录';
  static const backupImportSub = '整份替换，不与现有数据混合';
  static const privacyFoot = '数据只在这台设备上——不上传、不联网，记得定期导出备份。';
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
  static const notifSubDue = '短期目标';
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
