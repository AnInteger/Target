/// 领域实体（specs/001-life-goal-tracker/data-model.md）。
///
/// 纯 Dart、无 Flutter/平台依赖；业务规则（状态机、活跃上限、频率版本序）
/// 落在本层，drift 持久化层只做字段映射不添加规则。
/// Instant 一律存 UTC DateTime；自然日/周锚点用 LocalDate/WeekStart。
library;

import 'dart:math';

import 'calendar_types.dart';
import 'frequency_pattern.dart';

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

enum GoalKind { habit, milestone }

/// 003 schema v3 三类型域（Goals.goalType 列值域，research D3）。
/// T009 起表/迁移层使用；T011 将替换 [GoalKind] 成为 Goal 的类型字段。
enum GoalType { longTerm, shortTerm, habit }

/// 003 schema v3 提醒频率档（Reminders.cadence 列值域；NULL 视为 daily）。
enum Cadence { daily, threeDay, weekly }

enum GoalStatus { active, paused, archived, achieved }

/// 活跃目标上限（两类合计，FR-011）。
const int kMaxActiveGoals = 5;

class Goal {
  Goal({
    String? id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.colorKey,
    this.status = GoalStatus.active,
    required this.createdAt,
    this.deadline,
    this.motivation,
    this.successCriterion,
    this.cueScene,
  })  : id = id ?? newId(),
        assert(name.trim().isNotEmpty && name.length <= 30, '目标名 1–30 字'),
        assert(kind == GoalKind.milestone || deadline == null,
            '仅 milestone 可有截止日期'),
        assert(
            motivation == null ||
                (motivation.trim().isNotEmpty && motivation.length <= 60),
            '动机 1–60 字'),
        assert(
            successCriterion == null ||
                (successCriterion.trim().isNotEmpty &&
                    successCriterion.length <= 60),
            '成功标准 1–60 字'),
        assert(
            cueScene == null ||
                (cueScene.trim().isNotEmpty && cueScene.length <= 40),
            '提醒场景 1–40 字');

  final String id;
  final String name;
  final GoalKind kind;

  /// 设计令牌表内置键（iconKey/colorKey 枚举集合见 lib/core/design/tokens.dart）。
  final String iconKey;
  final String colorKey;
  final GoalStatus status;
  final LocalDate createdAt;

  /// 仅 milestone 有值；倒计时 = deadline − 今天（FR-013）。
  final LocalDate? deadline;

  /// US3 定义模型（002 B 案 envelope，schema v2 起可空列）：旧目标为 NULL
  /// → 今日卡/列表卡出现「补一句为什么」渐进补全入口（T014 定稿）。
  final String? motivation;

  /// 怎样算做到；非空 → 打卡反馈优先展示（002 data-model §1）。
  final String? successCriterion;

  /// 提醒场景（早起后/午休时/晚饭后/睡前/不打扰）；入选 → 驱动该目标
  /// 提醒时刻（FR-012），空或「不打扰」→ 回落默认时段、同档合并。
  final String? cueScene;

  bool get isHabit => kind == GoalKind.habit;
  bool get isMilestone => kind == GoalKind.milestone;

  /// 状态机（data-model）：active ⇄ paused；active → achieved（仅 milestone）；
  /// active/paused → archived（终态）。创建后 kind 不可变更。
  bool canTransitTo(GoalStatus to) {
    switch (status) {
      case GoalStatus.active:
        return to == GoalStatus.paused ||
            to == GoalStatus.archived ||
            (to == GoalStatus.achieved && isMilestone);
      case GoalStatus.paused:
        return to == GoalStatus.active || to == GoalStatus.archived;
      case GoalStatus.archived:
      case GoalStatus.achieved:
        return false; // 终态（历史数据保留，不物理删除）
    }
  }

  Goal copyWith({
    String? name,
    GoalStatus? status,
    String? iconKey,
    String? colorKey,
    LocalDate? deadline,
    String? motivation,
    String? successCriterion,
    String? cueScene,
  }) =>
      Goal(
        id: id,
        name: name ?? this.name,
        kind: kind,
        iconKey: iconKey ?? this.iconKey,
        colorKey: colorKey ?? this.colorKey,
        status: status ?? this.status,
        createdAt: createdAt,
        deadline: deadline ?? this.deadline,
        motivation: motivation ?? this.motivation,
        successCriterion: successCriterion ?? this.successCriterion,
        cueScene: cueScene ?? this.cueScene,
      );

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.iconKey == iconKey &&
      other.colorKey == colorKey &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.deadline == deadline &&
      other.motivation == motivation &&
      other.successCriterion == successCriterion &&
      other.cueScene == cueScene;

  @override
  int get hashCode => Object.hash(id, name, kind, iconKey, colorKey, status,
      createdAt, deadline, motivation, successCriterion, cueScene);
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
  bool covers(LocalDate day) =>
      !effectiveFromWeek.isAfterWeekOf(day);

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
  })  : id = id ?? newId(),
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
  })  : id = id ?? newId(),
        // day < 操作日 → 必为补签（不变量，构造时自动判定，恢复自备份同样成立）。
        isBackfill =
            day.isBefore(LocalDate.fromDateTime(createdAt.toLocal()));

  final String id;
  final String goalId;

  /// 归属自然日（本地时区）；补签 = 过去任意日期。
  final LocalDate day;

  /// 实际操作时刻（UTC）。
  final DateTime createdAt;
  final bool isBackfill;
  final CheckInStatus status;

  /// 撤销 = 置 revoked，不物理删除（统计即时回退，SC-003）。
  CheckIn revoked() => CheckIn(
        id: id,
        goalId: goalId,
        day: day,
        createdAt: createdAt,
        status: CheckInStatus.revoked,
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
      other.status == status;

  @override
  int get hashCode => Object.hash(id, goalId, day, createdAt, isBackfill, status);
}

// ---------------------------------------------------------------------------
// MilestoneStep（里程碑步骤，FR-013）
// ---------------------------------------------------------------------------

class MilestoneStep {
  MilestoneStep({
    String? id,
    required this.goalId,
    required this.title,
    this.isDone = false,
    this.doneAt,
  })  : id = id ?? newId(),
        assert(title.trim().isNotEmpty && title.length <= 50, '步骤名 1–50 字'),
        assert(!isDone || doneAt != null, '完成步骤须带完成时刻');

  final String id;
  final String goalId;
  final String title;
  final bool isDone;

  /// UTC 完成时刻；可回退（误点）→ 置回 null。
  final DateTime? doneAt;

  /// 可回退（误点）：done=true 幂等保留首次完成时刻，done=false 清空。
  MilestoneStep toggled({required DateTime now, required bool done}) =>
      MilestoneStep(
        id: id,
        goalId: goalId,
        title: title,
        isDone: done,
        doneAt: done ? (doneAt ?? now) : null,
      );

  @override
  bool operator ==(Object other) =>
      other is MilestoneStep &&
      other.id == id &&
      other.goalId == goalId &&
      other.title == title &&
      other.isDone == isDone &&
      other.doneAt == doneAt;

  @override
  int get hashCode => Object.hash(id, goalId, title, isDone, doneAt);
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
  }) : id = id ?? newId();

  final String id;

  /// null ⇔ scope = dailyBrief（默认 08:00，见 Settings）。
  final String? goalId;
  final LocalTime time;
  final bool isEnabled;

  bool get isDailyBrief => goalId == null;

  Reminder copyWith({LocalTime? time, bool? isEnabled}) => Reminder(
        id: id,
        goalId: goalId,
        time: time ?? this.time,
        isEnabled: isEnabled ?? this.isEnabled,
      );

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.goalId == goalId &&
      other.time == time &&
      other.isEnabled == isEnabled;

  @override
  int get hashCode => Object.hash(id, goalId, time, isEnabled);
}

// ---------------------------------------------------------------------------
// WeeklyReview（周回顾，FR-008 / research D11）
// ---------------------------------------------------------------------------

/// 结算快照行（data-model GoalWeekStat）。
class GoalWeekStat {
  const GoalWeekStat({
    required this.goalId,
    required this.applicableDays,
    required this.metDays,
    required this.completionRate,
    required this.backfillCount,
    required this.busyModeApplied,
  });

  final String goalId;

  /// 该周适用日数（当周有效频率；weekly=7 自由分布口径，统计契约 R4）。
  final int applicableDays;
  final int metDays;

  /// metDays / applicableDays；无适用日 → null（不呈现，非 0）。
  final double? completionRate;
  final int backfillCount;
  final bool busyModeApplied;

  @override
  bool operator ==(Object other) =>
      other is GoalWeekStat &&
      other.goalId == goalId &&
      other.applicableDays == applicableDays &&
      other.metDays == metDays &&
      other.completionRate == completionRate &&
      other.backfillCount == backfillCount &&
      other.busyModeApplied == busyModeApplied;

  @override
  int get hashCode => Object.hash(goalId, applicableDays, metDays,
      completionRate, backfillCount, busyModeApplied);
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

class Settings {
  const Settings({
    this.dailyBriefTime = const LocalTime(8, 0),
    this.onboardingCompleted = false,
    this.notificationDeniedAcknowledged = false,
  });

  final LocalTime dailyBriefTime;
  final bool onboardingCompleted;
  final bool notificationDeniedAcknowledged;

  Settings copyWith({
    LocalTime? dailyBriefTime,
    bool? onboardingCompleted,
    bool? notificationDeniedAcknowledged,
  }) =>
      Settings(
        dailyBriefTime: dailyBriefTime ?? this.dailyBriefTime,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        notificationDeniedAcknowledged:
            notificationDeniedAcknowledged ?? this.notificationDeniedAcknowledged,
      );
}
