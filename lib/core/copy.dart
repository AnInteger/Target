/// v3 文案（FR-013 正式语域；基准 = Figma 定稿 + R1–R3 修订）。
///
/// 界面不出现口语化解释句与本地存储位置说明（FR-021 延续）。
/// UI 层不写裸字符串，从 Copy.* 取；带参文案为方法。
library;

abstract final class Copy {
  // ---- 目标页 ----
  static const goalsTitle = '目标';
  static const pinnedSection = '置顶';
  static const pinnedEdit = '编辑';
  static const othersSection = '其他目标';
  static const goalsEmptyTitle = '还没有目标';
  static const goalsEmptyBody = '创建第一个目标，开始记录。';
  static const goalsEmptyCta = '新建目标';
  static const recentRecordLabel = '最近记录';
  static String hasRecordAt(String label) => '$label有新记录';
  static const noRecordYet = '尚未记录';
  static const nextMilestoneLabel = '下个里程碑';

  // ---- 编辑置顶模式 ----
  static const editPinnedTitle = '编辑置顶';
  static const editPinnedDone = '完成';
  static const editPinnedOthers = '其他目标 · 点图钉加入置顶';

  // ---- 动态页 ----
  static const activityTitle = '动态';
  static const weekInvestment = '本周投入';
  static String weekRecords(int n) => '共 $n 条记录';
  static String weekInvestmentValue(int h, int m) =>
      h > 0 ? '$h 小时 $m 分钟' : '$m 分钟';
  static const milestoneCardTitle = '里程碑';
  static const milestoneAchievedThisWeek = '本周达成';
  static const milestonePending = '待达成';
  static String milestoneCount(int n) => '$n 个';
  static const recentFeed = '最近动态';
  static const calendarEntry = '日历';
  static String feedMilestone(String name) => '达成：$name';
  static String feedDuration(int minutes) => '投入 $minutes 分钟';
  static const activityEmptyTitle = '本周还没有记录';
  static const activityEmptyBody = '可从目标页或右下角记录按钮开始。';
  static const dailyInvestmentTitle = '每日投入';
  static const calendarLegendNone = '无投入';
  static const calendarLegendRing = '环 = 当日投入 / 当月峰值';
  static String investedMinutes(int minutes) => '$minutes 分钟';

  // ---- 目标详情 ----
  static const detailRecords = '进展记录';
  static const recordProgress = '记录进展';
  static const milestoneEntryTitle = '里程碑';
  static String nextWaypoint(String name) => '下个路标 · $name';
  static const milestoneAchievedEntry = '达成里程碑';

  // ---- 里程碑页 ----
  static const milestonesTitle = '里程碑';
  static const milestonesAdd = '添加里程碑';
  static String pendingGroup(int n) => '接下来 · $n';
  static String doneGroup(int n) => '已达成 · $n';
  static String relatedRecords(int n) => '$n 条相关记录';
  static const noRelatedRecords = '还没有相关记录';
  static const milestoneFieldTitle = '里程碑名称';
  static const milestoneFieldDesc = '达成时是什么样？（可选）';
  static const milestoneMenuDone = '标记为达成';
  static const milestoneMenuEdit = '编辑里程碑';
  static const milestoneMenuDelete = '删除';
  static const milestonesHint = '点击里程碑查看记录。';

  // ---- 记录进展 sheet ----
  static const recordSheetTitle = '记录进展';
  static const recordGoalLabel = '关联目标';
  static const recordWhatLabel = '今天为目标做了什么？';
  static const recordTitleHint = '一句话标题（必填）';
  static const recordBodyHint = '经过与心得（选填）';
  static const recordDuration = '投入时间';
  static const recordDate = '日期';
  static const recordMilestone = '关联里程碑';
  static const recordMilestonePick = '选择（可选）';
  static const durationSheetTitle = '投入时间';
  static const durationQuestion = '大约投入了多久？';
  static String durationMinutes(int m) => '$m 分钟';
  static const durationCustom = '自定义…';
  static const cancel = '取消';
  static const save = '保存';
  static const done = '完成';
  static const recordSavedToast = '已记录';
  static const undo = '撤销';
  static const recordRemovedToast = '已删除记录';

  // ---- 编辑器 ----
  static const editorAddTitle = '添加目标';
  static const editorEditTitle = '编辑目标';
  static const fieldName = '目标名称';
  static const fieldNameHint = '例如：自在地游泳';
  static const fieldWhy = '为什么想做？（可选）';
  static const fieldWhyHint = '例如：想在水里放松地呼吸';
  static const fieldCategory = '分类';
  static const fieldIconColor = '图标与颜色';
  static const fieldPinned = '置顶目标';
  static const fieldTargetDate = '目标日期';
  static const fieldFrequency = '执行节奏';
  static const dateNone = '不设日期';
  static const dateSet = '指定日期';
  static const freqNone = '不设节奏';
  static const freqDaily = '每天';
  static const freqWeekly = '每周 N 次';
  static const freqWeekdays = '指定星期';
  static const frequencySheetTitle = '执行节奏';
  static const frequencyQuestion = '多久推进一次？';
  static String timesPerWeek(int n) => '$n 次 / 周';
  static const editorNote = '只填名称即可保存，其余可随时补充。';
  static const reminderGroup = '提醒（可选）';
  static const reminderToggle = '提醒';
  static const reminderTime = '时间';
  static const reminderCadence = '频率';
  static const milestoneGroup = '里程碑（可选）';
  static const firstMilestoneGroup = '第一个里程碑（可选）';
  static const editorGoalSavedToast = '已保存';

  // ---- 设置（与我的合并） ----
  static const settingsTitle = '设置';
  static const editProfileHint = '编辑昵称与头像';
  static const appearanceGroup = '外观';
  static const themeSystem = '跟随系统';
  static const themeLight = '浅色';
  static const themeDark = '深色';
  static const reminderGroupSettings = '提醒';
  static const reminderPush = '提醒推送';
  static const reminderPerGoalHint = '逐目标提醒在编辑目标时设置';
  static const backupGroup = '备份与数据';
  static const backupExport = '导出备份';
  static const backupImport = '从备份恢复';
  static String backupLast(String date) => '上次：$date';
  static const aboutGroup = '关于';
  static const versionRow = '版本';
  static const settingsFoot = 'Target';
  static const restoreConfirmTitle = '恢复备份？';
  static String restoreConfirmBody(String date, int goals, int records) =>
      '备份文件（$date）包含 $goals 个目标、$records 条记录。\n'
      '当前设备数据将被覆盖，此操作不可撤销。';
  static const restoreOverwrite = '覆盖恢复';
  static const profileSavedToast = '已保存';

  // ---- 生命周期菜单（长按/⋯，按状态显隐） ----
  static const menuRecord = '记录进展';
  static const menuEdit = '编辑';
  static const menuPin = '置顶';
  static const menuUnpin = '取消置顶';
  static const menuPause = '暂停';
  static const menuResume = '恢复';
  static const menuAchieve = '标记达成';
  static const menuReopen = '重新打开';
  static const menuArchive = '归档';
  static const menuUnarchive = '取消归档';
  static const menuDelete = '删除';
  static String deleteConfirmTitle(String name) => '删除「$name」？';
  static const deleteConfirmBody = '该目标及其全部记录、里程碑与提醒将被删除，此操作不可恢复。';

  // ---- 状态 / 分类 / 频率档 ----
  static const statusActive = '进行中';
  static const statusPaused = '已暂停';
  static const statusAchieved = '已达成';
  static const statusArchived = '已归档';

  static const cadenceDaily = '一天一次';
  static const cadenceThreeDay = '三天一次';
  static const cadenceWeekly = '一周一次';

  static const categoryUncategorized = '未分类';

  static String categoryOf(String key) => switch (key) {
    'fitness' => '运动与健康',
    'learning' => '学习与成长',
    'language' => '语言学习',
    'create' => '创作与表达',
    'travel' => '旅行与探索',
    'finance' => '理财',
    'life' => '生活方式',
    'mind' => '身心与冥想',
    'social' => '社交与关系',
    'pets' => '宠物',
    _ => '其他',
  };

  // ---- 相对时间 ----
  static const today = '今天';
  static const yesterday = '昨天';
  static String daysAgo(int n) => '$n 天前';

  // ---- 记录元信息 ----
  static String recordMilestoneLink(String title) => '里程碑 · $title';

  // ---- 通用导航 ----
  static const back = '返回';

  // ---- 详情信息流顶部（v3.1：无记录目标也有基本盘）----
  static String detailDayN(int n) => '第 $n 天';
  static String detailDaysLeft(int n) => '剩 $n 天';
  static const detailNoDeadline = '无期限';
  static String detailRecordCount(int n) => '$n 条记录';
  static const detailStatDay = '坚持天数';
  static const detailStatDeadline = '剩余时间';
  static const detailStatRecord = '累计记录';
  static String detailMilestonesDone(int done, int total) => '里程碑 $done/$total';

  // ---- 头像与权限 ----
  static const profileEditNickname = '修改昵称';
  static const profileAvatarFromGallery = '从相册选择头像';
  static const profileAvatarFromCamera = '拍照设置头像';
  static const profileAvatarRemove = '移除头像';
  static const notifyPermissionDenied = '通知权限未开启，提醒将无法送达，请在系统设置中允许';
}
