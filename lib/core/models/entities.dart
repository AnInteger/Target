/// 领域实体（specs/001-life-goal-tracker/data-model.md）。
///
/// 纯 Dart、无 Flutter/平台依赖；业务规则（状态机、频率版本序）
/// 落在本层，drift 持久化层只做字段映射不添加规则。
/// Instant 一律存 UTC DateTime；自然日/周锚点用 LocalDate/WeekStart。
library;

import 'dart:math';

import 'calendar_types.dart';
import 'frequency_pattern.dart';
import 'goal_icon_catalog.dart'
    show GoalIconCatalog, GoalIconDomain, MajorCategory;

/// 生成 UUID v4（实体主键）。无 uuid 依赖，Random.secure 足够。
String newId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-'
      '${h(4)}${h(5)}-${h(6)}${h(7)}-${h(8)}${h(9)}-'
      '${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

// ---------------------------------------------------------------------------
// Goal（目标）
// ---------------------------------------------------------------------------

/// 003 v3 三类型域（research D2/D3；behavior 契约见
/// specs/003-app-ux-refinement/contracts/goal-type-model.md）。
enum GoalType { longTerm, shortTerm, habit }

/// 003 v3 提醒频率档（Reminders.cadence 列值域；NULL 视为 daily）。
enum Cadence { daily, threeDay, weekly }

enum GoalStatus { active, paused, archived, achieved }

LocalDate? _unifiedTargetDate(LocalDate? targetDate, LocalDate? deadline) =>
    targetDate ?? deadline;

FrequencyPattern? _unifiedFrequency(
  FrequencyPattern? frequency,
  int? habitTargetPerWeek,
) =>
    frequency ??
    (habitTargetPerWeek == null ? null : WeeklyFrequency(habitTargetPerWeek));

int? _legacyWeeklyTargetOf(FrequencyPattern? frequency) => switch (frequency) {
  WeeklyFrequency(:final timesPerWeek) => timesPerWeek,
  DailyFrequency() => 7,
  WeekdaysFrequency(:final days) => days.length,
  null => null,
};

bool _hasValidLegacyWeeklyTarget(
  FrequencyPattern? frequency,
  int? habitTargetPerWeek,
) {
  final target = _legacyWeeklyTargetOf(
    _unifiedFrequency(frequency, habitTargetPerWeek),
  );
  return target == null || (target >= 1 && target <= 7);
}

class Goal {
  Goal({
    String? id,
    required this.name,
    GoalType? goalType,
    required this.iconKey,
    required this.colorKey,
    this.categoryOverride,
    int? progressCadenceDays,
    this.status = GoalStatus.active,
    required this.createdAt,
    LocalDate? deadline,
    LocalDate? targetDate,
    int? habitTargetPerWeek,
    FrequencyPattern? frequency,
    this.motivation,
    this.successCriterion,
    this.cueScene,
    this.achievedAt,
    this.archivedAt,
  }) : id = id ?? newId(),
       goalType =
           goalType ??
           (_unifiedTargetDate(targetDate, deadline) != null
               ? GoalType.shortTerm
               : _unifiedFrequency(frequency, habitTargetPerWeek) != null
               ? GoalType.habit
               : GoalType.longTerm),
       progressCadenceDays =
           progressCadenceDays ??
           (_unifiedTargetDate(targetDate, deadline) == null &&
                   _unifiedFrequency(frequency, habitTargetPerWeek) == null
               ? 14
               : 7),
       deadline = _unifiedTargetDate(targetDate, deadline),
       targetDate = _unifiedTargetDate(targetDate, deadline),
       habitTargetPerWeek = _legacyWeeklyTargetOf(
         _unifiedFrequency(frequency, habitTargetPerWeek),
       ),
       frequency = _unifiedFrequency(frequency, habitTargetPerWeek),
       assert(name.trim().isNotEmpty && name.length <= 30, '目标名 1–30 字'),
       assert(
         progressCadenceDays == null ||
             (progressCadenceDays >= 1 && progressCadenceDays <= 365),
         '推进周期 1–365 天',
       ),
       assert(
         _hasValidLegacyWeeklyTarget(frequency, habitTargetPerWeek),
         '习惯周频率须为 1–7',
       ),
       assert(
         motivation == null ||
             (motivation.trim().isNotEmpty && motivation.length <= 60),
         '动机 1–60 字',
       ),
       assert(
         successCriterion == null ||
             (successCriterion.trim().isNotEmpty &&
                 successCriterion.length <= 60),
         '成功标准 1–60 字',
       ),
       assert(
         cueScene == null ||
             (cueScene.trim().isNotEmpty && cueScene.length <= 40),
         '提醒场景 1–40 字',
       );

  final String id;
  final String name;

  /// Legacy 兼容分类；新代码从 [targetDate]/[frequency] 派生。
  final GoalType goalType;

  /// 设计令牌表内置键（iconKey/colorKey 枚举集合见 lib/core/design/tokens.dart）。
  final String iconKey;
  final String colorKey;

  /// 图标会推断领域；用户手动更正后以覆盖值为准。
  final GoalIconDomain? categoryOverride;

  /// Legacy 兼容推进节奏；新代码从统一规划设置派生。
  final int progressCadenceDays;
  final GoalStatus status;
  final LocalDate createdAt;

  /// Legacy 兼容截止日；新代码使用 [targetDate]。
  final LocalDate? deadline;

  /// 统一的可选目标日期。
  final LocalDate? targetDate;

  /// Legacy 兼容周目标；新代码使用 [frequency]。
  final int? habitTargetPerWeek;

  /// 统一的可选频率计划。
  final FrequencyPattern? frequency;

  /// 手动达成时刻（UTC；NULL=未达成）。
  final DateTime? achievedAt;

  /// 归档时刻（UTC）；归档与 active/paused/achieved 状态正交。
  final DateTime? archivedAt;

  /// US3 定义模型（002 B 案 envelope，schema v2 起可空列）：旧目标为 NULL
  /// → 今日卡/列表卡出现「补一句为什么」渐进补全入口（T014 定稿）。
  final String? motivation;

  /// 怎样算做到；非空 → 打卡反馈优先展示（002 data-model §1）。
  final String? successCriterion;

  /// 提醒场景（早起后/午休时/晚饭后/睡前/不打扰）；入选 → 驱动该目标
  /// 提醒时刻（FR-012），空或「不打扰」→ 回落默认时段、同档合并。
  final String? cueScene;

  bool get isHabit => goalType == GoalType.habit;
  bool get isShortTerm => goalType == GoalType.shortTerm;
  bool get isLongTerm => goalType == GoalType.longTerm;
  bool get isArchived => archivedAt != null;
  bool get isActive => status == GoalStatus.active && !isArchived;

  static int defaultCadenceFor(GoalType type) =>
      type == GoalType.longTerm ? 14 : 7;

  GoalIconDomain get effectiveDomain =>
      categoryOverride ?? GoalIconCatalog.byKey(iconKey).domain;

  /// 三大类派生（004 T005 · data-model.md 的 majorOf）：iconKey →
  /// 领域 → 大类，零落库；未匹配键兜底 explore（travel 域 → 目标
  /// 大类，沿 byKey 兜底，结论与 data-model 一致）。
  MajorCategory get major => effectiveDomain.major;

  /// 状态机：未归档目标可暂停/恢复/达成，达成后可重新开启。
  bool canTransitTo(GoalStatus to) {
    if (isArchived) return false;
    return switch (status) {
      GoalStatus.active => to == GoalStatus.paused || to == GoalStatus.achieved,
      GoalStatus.paused => to == GoalStatus.active || to == GoalStatus.achieved,
      GoalStatus.achieved => to == GoalStatus.active,
      GoalStatus.archived => false,
    };
  }

  Goal copyWith({
    String? name,
    GoalStatus? status,
    String? iconKey,
    String? colorKey,
    GoalIconDomain? categoryOverride,
    int? progressCadenceDays,
    LocalDate? deadline,
    LocalDate? targetDate,
    bool clearTargetDate = false,
    int? habitTargetPerWeek,
    FrequencyPattern? frequency,
    bool clearFrequency = false,
    String? motivation,
    String? successCriterion,
    String? cueScene,
    DateTime? achievedAt,
    bool clearAchievedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    final planningChanged =
        deadline != null ||
        targetDate != null ||
        clearTargetDate ||
        habitTargetPerWeek != null ||
        frequency != null ||
        clearFrequency;
    return Goal(
      id: id,
      name: name ?? this.name,
      goalType: planningChanged ? null : goalType,
      iconKey: iconKey ?? this.iconKey,
      colorKey: colorKey ?? this.colorKey,
      categoryOverride: categoryOverride ?? this.categoryOverride,
      progressCadenceDays:
          progressCadenceDays ??
          (planningChanged ? null : this.progressCadenceDays),
      status: status ?? this.status,
      createdAt: createdAt,
      deadline: clearTargetDate
          ? null
          : (targetDate ?? deadline ?? this.deadline),
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      habitTargetPerWeek: clearFrequency
          ? null
          : (_legacyWeeklyTargetOf(frequency) ??
                habitTargetPerWeek ??
                this.habitTargetPerWeek),
      frequency: clearFrequency ? null : (frequency ?? this.frequency),
      motivation: motivation ?? this.motivation,
      successCriterion: successCriterion ?? this.successCriterion,
      cueScene: cueScene ?? this.cueScene,
      achievedAt: clearAchievedAt ? null : (achievedAt ?? this.achievedAt),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      other.id == id &&
      other.name == name &&
      other.goalType == goalType &&
      other.iconKey == iconKey &&
      other.colorKey == colorKey &&
      other.categoryOverride == categoryOverride &&
      other.progressCadenceDays == progressCadenceDays &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.deadline == deadline &&
      other.targetDate == targetDate &&
      other.habitTargetPerWeek == habitTargetPerWeek &&
      other.frequency == frequency &&
      other.motivation == motivation &&
      other.successCriterion == successCriterion &&
      other.cueScene == cueScene &&
      other.achievedAt == achievedAt &&
      other.archivedAt == archivedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    goalType,
    iconKey,
    colorKey,
    categoryOverride,
    progressCadenceDays,
    status,
    createdAt,
    deadline,
    targetDate,
    habitTargetPerWeek,
    frequency,
    motivation,
    successCriterion,
    cueScene,
    achievedAt,
    archivedAt,
  );
}

// ---------------------------------------------------------------------------
// FrequencyVersion（习惯频率版本，research D7）
// ---------------------------------------------------------------------------

enum FrequencySource { initial, userEdit, busyMode }

class FrequencyVersion {
  const FrequencyVersion({
    required this.id,
    required this.goalId,
    required this.effectiveFromWeek,
    required this.pattern,
    required this.source,
  });

  final String id;
  final String goalId;

  /// 自哪个周一生效（周锚点， monday）。
  final WeekStart effectiveFromWeek;
  final FrequencyPattern pattern;
  final FrequencySource source;

  /// [day] 的有效频率判定：本版本生效周 ≤ 该日所在周（取最大者，由调用方排序）。
  bool covers(LocalDate day) => !effectiveFromWeek.isAfterWeekOf(day);

  @override
  bool operator ==(Object other) =>
      other is FrequencyVersion &&
      other.id == id &&
      other.goalId == goalId &&
      other.effectiveFromWeek == effectiveFromWeek &&
      other.pattern == pattern &&
      other.source == source;

  @override
  int get hashCode =>
      Object.hash(id, goalId, effectiveFromWeek, pattern, source);
}

// ---------------------------------------------------------------------------
// BusyModeSession（忙碌模式会话，FR-018）
// ---------------------------------------------------------------------------

/// 单个目标的降档条目：该周以 [downgraded] 频率计。
class BusyModeEntry {
  const BusyModeEntry({required this.goalId, required this.downgraded});

  final String goalId;
  final FrequencyPattern downgraded;

  @override
  bool operator ==(Object other) =>
      other is BusyModeEntry &&
      other.goalId == goalId &&
      other.downgraded == downgraded;

  @override
  int get hashCode => Object.hash(goalId, downgraded);
}

class BusyModeSession {
  BusyModeSession({
    String? id,
    required this.weekStart,
    required this.entries,
    required this.startedAt,
    this.endedAt,
  }) : id = id ?? newId(),
       assert(entries.isNotEmpty, '忙碌会话至少含 1 个降档目标');

  final String id;
  final WeekStart weekStart;
  final List<BusyModeEntry> entries;

  /// UTC 时刻；endedAt 非空 = 已恢复。
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isActive => endedAt == null;

  BusyModeSession copyWith({DateTime? endedAt}) => BusyModeSession(
    id: id,
    weekStart: weekStart,
    entries: entries,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is BusyModeSession &&
      other.id == id &&
      other.weekStart == weekStart &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(id, weekStart, startedAt, endedAt);
}

// ---------------------------------------------------------------------------
// CheckIn（打卡记录，FR-004/005）
// ---------------------------------------------------------------------------

enum CheckInStatus { valid, revoked }

class CheckIn {
  CheckIn({
    String? id,
    required this.goalId,
    required this.day,
    required this.createdAt,
    this.status = CheckInStatus.valid,
    this.note,
  }) : id = id ?? newId(),
       // day < 操作日 → 必为补签（不变量，构造时自动判定，恢复自备份同样成立）。
       isBackfill = day.isBefore(LocalDate.fromDateTime(createdAt.toLocal()));

  final String id;
  final String goalId;

  /// 归属自然日（本地时区）；补签 = 过去任意日期。
  final LocalDate day;

  /// 实际操作时刻（UTC）。
  final DateTime createdAt;
  final bool isBackfill;
  final CheckInStatus status;

  /// 一句话描述（FR-019，schema v4）：NULL=未填，显示层兜底「完成打卡」。
  final String? note;

  /// 撤销 = 置 revoked，不物理删除（统计即时回退，SC-003）。
  CheckIn revoked() => CheckIn(
    id: id,
    goalId: goalId,
    day: day,
    createdAt: createdAt,
    status: CheckInStatus.revoked,
    note: note,
  );

  bool get isValid => status == CheckInStatus.valid;

  @override
  bool operator ==(Object other) =>
      other is CheckIn &&
      other.id == id &&
      other.goalId == goalId &&
      other.day == day &&
      other.createdAt == createdAt &&
      other.isBackfill == isBackfill &&
      other.status == status &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, goalId, day, createdAt, isBackfill, status, note);
}

// ---------------------------------------------------------------------------
// MilestoneStep（里程碑步骤，FR-013）
// ---------------------------------------------------------------------------

class MilestoneStep {
  MilestoneStep({
    String? id,
    required this.goalId,
    required this.title,
    this.position = 0,
    this.isDone = false,
    this.doneAt,
  }) : id = id ?? newId(),
       assert(title.trim().isNotEmpty && title.length <= 50, '步骤名 1–50 字'),
       assert(!isDone || doneAt != null, '完成步骤须带完成时刻');

  final String id;
  final String goalId;
  final String title;
  final int position;
  final bool isDone;

  /// UTC 完成时刻；可回退（误点）→ 置回 null。
  final DateTime? doneAt;

  /// 可回退（误点）：done=true 幂等保留首次完成时刻，done=false 清空。
  MilestoneStep toggled({required DateTime now, required bool done}) =>
      MilestoneStep(
        id: id,
        goalId: goalId,
        title: title,
        position: position,
        isDone: done,
        doneAt: done ? (doneAt ?? now) : null,
      );

  @override
  bool operator ==(Object other) =>
      other is MilestoneStep &&
      other.id == id &&
      other.goalId == goalId &&
      other.title == title &&
      other.position == position &&
      other.isDone == isDone &&
      other.doneAt == doneAt;

  @override
  int get hashCode => Object.hash(id, goalId, title, position, isDone, doneAt);
}

// ---------------------------------------------------------------------------
// Reminder（提醒，FR-006）
// ---------------------------------------------------------------------------

/// scope：goalId 非空 = 目标提醒；null = 全局每日概要（dailyBrief）。
class Reminder {
  Reminder({
    String? id,
    this.goalId,
    required this.time,
    this.isEnabled = true,
    this.cadence,
  }) : id = id ?? newId();

  final String id;

  /// null ⇔ scope = dailyBrief（默认 08:00，见 Settings）。
  final String? goalId;
  final LocalTime time;
  final bool isEnabled;

  /// 003 v3 提醒频率档（FR-013 开关化提醒）；NULL 视为 daily。
  final Cadence? cadence;

  Cadence get effectiveCadence => cadence ?? Cadence.daily;

  bool get isDailyBrief => goalId == null;

  Reminder copyWith({LocalTime? time, bool? isEnabled, Cadence? cadence}) =>
      Reminder(
        id: id,
        goalId: goalId,
        time: time ?? this.time,
        isEnabled: isEnabled ?? this.isEnabled,
        cadence: cadence ?? this.cadence,
      );

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.goalId == goalId &&
      other.time == time &&
      other.isEnabled == isEnabled &&
      other.cadence == cadence;

  @override
  int get hashCode => Object.hash(id, goalId, time, isEnabled, cadence);
}

// ---------------------------------------------------------------------------
// WeeklyReview（周回顾，FR-008 / research D11）
// ---------------------------------------------------------------------------

/// 结算快照行（003 口径收敛，contracts/goal-type-model.md）。
class GoalWeekStat {
  const GoalWeekStat({
    required this.goalId,
    required this.metDays,
    required this.totalChecks,
    required this.backfillCount,
    this.busyModeApplied = false,
  });

  final String goalId;

  /// 周留痕：周内 ≥1 次打卡的天数。
  final int metDays;

  /// 周记录数：周内有效打卡总次数。
  final int totalChecks;
  final int backfillCount;

  /// 002 及之前的忙碌模式降档标记（003 起停算，历史快照照读）。
  final bool busyModeApplied;

  @override
  bool operator ==(Object other) =>
      other is GoalWeekStat &&
      other.goalId == goalId &&
      other.metDays == metDays &&
      other.totalChecks == totalChecks &&
      other.backfillCount == backfillCount &&
      other.busyModeApplied == busyModeApplied;

  @override
  int get hashCode =>
      Object.hash(goalId, metDays, totalChecks, backfillCount, busyModeApplied);
}

/// 下周决定：继续 / 调整频率（生成 userEdit 版本）/ 暂停。
sealed class ReviewDecision {
  const ReviewDecision();
}

class ContinueDecision extends ReviewDecision {
  const ContinueDecision();
}

class AdjustDecision extends ReviewDecision {
  const AdjustDecision(this.newPattern);

  final FrequencyPattern newPattern;
}

class PauseDecision extends ReviewDecision {
  const PauseDecision();
}

class WeeklyReview {
  WeeklyReview({
    String? id,
    required this.weekStart,
    required this.settledAt,
    required this.snapshot,
    this.note,
    this.decision = const ContinueDecision(),
  }) : id = id ?? newId();

  final String id;

  /// 结算的那一周（周一）。回顾页展示时实时重算，快照仅留痕。
  final WeekStart weekStart;

  /// 周一晨结算时刻（UTC）。
  final DateTime settledAt;
  final List<GoalWeekStat> snapshot;
  final String? note;
  final ReviewDecision decision;

  WeeklyReview copyWith({String? note, ReviewDecision? decision}) =>
      WeeklyReview(
        id: id,
        weekStart: weekStart,
        settledAt: settledAt,
        snapshot: snapshot,
        note: note ?? this.note,
        decision: decision ?? this.decision,
      );

  @override
  bool operator ==(Object other) =>
      other is WeeklyReview &&
      other.id == id &&
      other.weekStart == weekStart &&
      other.settledAt == settledAt &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, weekStart, settledAt, note);
}

// ---------------------------------------------------------------------------
// Settings（单例）
// ---------------------------------------------------------------------------

/// 主题偏好三档（004 v2 · research D2）：settings.theme_mode TEXT 枚举，
/// 值域即 .name 并已冻结；NULL/未知值 → system（跟随系统 = 003 完结态
/// 行为，存量用户零感知）。
enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode parse(String? raw) => values.firstWhere(
    (m) => m.name == raw,
    orElse: () => AppThemeMode.system,
  );
}

class Settings {
  const Settings({
    this.dailyBriefTime = const LocalTime(8, 0),
    this.onboardingCompleted = false,
    this.notificationDeniedAcknowledged = false,
    this.themeMode = AppThemeMode.system,
    this.defaultShortCadenceDays = 7,
    this.defaultLongCadenceDays = 14,
    this.scoreAlgorithmStartedOn,
  });

  final LocalTime dailyBriefTime;
  final bool onboardingCompleted;
  final bool notificationDeniedAcknowledged;

  /// 主题偏好（004 v5）：DB NULL 与 'system' 等价，实体侧统一非空枚举。
  final AppThemeMode themeMode;

  final int defaultShortCadenceDays;
  final int defaultLongCadenceDays;
  final LocalDate? scoreAlgorithmStartedOn;

  Settings copyWith({
    LocalTime? dailyBriefTime,
    bool? onboardingCompleted,
    bool? notificationDeniedAcknowledged,
    AppThemeMode? themeMode,
    int? defaultShortCadenceDays,
    int? defaultLongCadenceDays,
    LocalDate? scoreAlgorithmStartedOn,
  }) => Settings(
    dailyBriefTime: dailyBriefTime ?? this.dailyBriefTime,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    notificationDeniedAcknowledged:
        notificationDeniedAcknowledged ?? this.notificationDeniedAcknowledged,
    themeMode: themeMode ?? this.themeMode,
    defaultShortCadenceDays:
        defaultShortCadenceDays ?? this.defaultShortCadenceDays,
    defaultLongCadenceDays:
        defaultLongCadenceDays ?? this.defaultLongCadenceDays,
    scoreAlgorithmStartedOn:
        scoreAlgorithmStartedOn ?? this.scoreAlgorithmStartedOn,
  );
}

// ---------------------------------------------------------------------------
// Profile（账号资料 VO，003 research D7）
// ---------------------------------------------------------------------------

/// Settings 单例行的资料两列（nickname/avatar_key，均 NULL=未设置）。
/// 展示层默认昵称等文案归 copy.dart（T014），VO 只承载原始值。
class Profile {
  const Profile({this.nickname, this.avatarKey});

  final String? nickname;
  final String? avatarKey;

  static const Profile empty = Profile();

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.nickname == nickname &&
      other.avatarKey == avatarKey;

  @override
  int get hashCode => Object.hash(nickname, avatarKey);
}
