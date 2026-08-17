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
  static const backfillTag = '补';
  static String backfillDone(String day) => '已补上 $day 的记录';
  static const checkInRevoked = '已撤销，统计同步更新';

  // ---- 连击 / 频率 ----

  static String streakDays(int n) => '连击 $n 天';
  static const streakBroken = '忙就先降档，线还在'; // 连击断裂，配忙碌模式入口
  static const freqEditTakesEffect = '新频率下周一生效，本周仍按原计划';
  static String todayProgress(int done, int target) => '$done/$target';

  // ---- 周回顾（FR-008，R6 补签透明）----

  static const reviewTitle = '上周回顾';
  static String reviewCompletion(double rate) =>
      '${(rate * 100).round()}%';
  static String reviewBackfills(int n) => '补签 $n 次';
  static const reviewBusyTag = '忙碌周';
  static const reviewNoteHint = '这一周，什么帮到了你？';
  static const reviewDecisionContinue = '继续';
  static const reviewDecisionAdjust = '调频';
  static const reviewDecisionPause = '暂停';
  static const reviewSuggestionLow = '要不要调小一点？'; // <50%，非红色警告
  static String trendWeeks(int n) => '近 $n 周趋势';
  static const reviewNoApplicableDays = '本周不适用'; // 完成率不呈现（非 0）

  // ---- 忙碌模式（FR-018）----

  static const busyTitle = '忙碌模式';
  static const busySubtitle = '降档不熄火，忙完这阵再回来';
  static const busyBadge = '忙碌中';
  static String busyPreview(String from, String to) => '$from → $to';
  static const busyStart = '开启降档';
  static const busyStartHint = '本周生效';
  static const busyResume = '恢复正常';
  static const busyResumed = '已恢复，节奏回来了';

  // ---- 目标创建 / 编辑（FR-001/011/012）----

  static const editorNewGoal = '新的目标';
  static const editorKindHabit = '习惯';
  static const editorKindMilestone = '里程碑';
  static const editorCustom = '自定义';
  static const editorFromTemplate = '从模板开始';
  static const editorNextWeekEffect = '新频率下周一生效，本周仍按原口径';
  static const editorFrequency = '频率';
  static const editorIconColor = '图标与颜色';
  static const editorDeadline = '截止日期';
  static const editorDeadlineRequired = '选一个日子，给里程碑一个锚点';
  static const editorSave = '保存';
  static String smartSuggest(String suggestion) => '换成更具体的？「$suggestion」';
  static const smartApply = '采用建议';
  static const focusLimitTitle = '先照顾好这 5 个';
  static const focusLimitBody = '目标贵在聚焦。暂停或归档一个，再放新的进来。';
  static const goalArchived = '已归档，历史记录都在';

  // ---- 目标管理页 ----

  static const goalsTitle = '目标';
  static String goalsActiveHeader(int n) => '进行中 $n/5';
  static const goalsPausedHeader = '暂停中';
  static const goalsClosedHeader = '已结束';
  static const goalsEmpty = '还没有目标，从一件小事开始';
  static const goalsEmptyCta = '创建第一个目标';
  static const goalsWeekRate = '本周';

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

  // ---- 提醒 / 通知（FR-006/007）----

  static const notifDeniedTitle = '通知未开启';
  static const notifDeniedBody = '不开通知也能用全部功能；想开的话，去系统设置里找 Target。';
  static const notifEnable = '开启通知';
  static const notifEnabled = '通知已开启';
  static const notifAck = '知道了';

  // ---- 每日概要 / 逐目标提醒（FR-006/008）----

  static const dailyBriefTitle = '今天的小事';
  static const dailyBriefAllDone = '都照顾到了，安心过今天。';
  static String dailyBriefSummary(int unmet) => unmet == 1
      ? '还有 1 件小事在等你，不着急。'
      : '还有 $unmet 件小事在等你，不着急。';
  static const dailyBriefReviewLine = '上周回顾已生成，花两分钟看看这一周';
  static String goalReminderBody(int done, int target) =>
      '还差一点点：今日 $done/$target';
  static const remindersHeader = '目标提醒';
  static const reminderGoalHint = '到点轻轻提醒，不催促';
  static const reminderMondayHint = '周一的概要会带上上周回顾';

  // ---- 备份（FR-015）----

  static const backupExport = '导出备份';
  static const backupImport = '导入备份';
  static const backupImportConflictTitle = '导入会覆盖当前全部数据';
  static const backupImportConflictBody = '两份不会混合——继续将替换为备份内容。';
  static const backupImportOverwrite = '覆盖本地';
  static const backupImportCorrupt = '备份文件不完整，已取消导入';
  static const backupImportDone = '导入完成';
  static const backupHint = '数据只存在这台设备上，记得定期导出备份';

  // ---- 设置 / 其他 ----

  static const settingsTitle = '设置';
  static const dailyBriefTimeLabel = '每日概要时间';
  static const widgetIosOnly = '桌面小组件与提醒推送为 iPhone 专属功能';
  static const debugClock = 'Debug 时钟';
  static const appName = 'Target';

  // ---- 今日页（FR-017/US2）----

  static const backfillCalendarTitle = '补一补过去两周';
  static const backfillHint = '点缺卡的日期补上，线接回来';
  static const todayNav = '今日';
  static const goalsNav = '目标';
  static const settingsNav = '设置';
}
