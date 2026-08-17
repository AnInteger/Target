/// 统计引擎（contracts/stats-engine.md）：所有界面数字的唯一事实来源。
///
/// 纯函数、无 Flutter/平台依赖、不写库；`today` 由注入时钟换算传入。
/// 口径规则 R1–R9 与契约一一对应，任何显示值必须能由本引擎复现。
library;

import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';
import 'versioning.dart';

/// 单目标单日状态（今日视图 / 小组件快照消费）。
class DayStatus {
  const DayStatus({
    required this.goalId,
    required this.applicable,
    required this.targetCount,
    required this.doneCount,
    required this.met,
    required this.backfilledCount,
    required this.busyMode,
  });

  final String goalId;

  /// 今日是否适用（频率口径 + 目标已创建 + habit）。
  final bool applicable;

  /// 当日目标次数；weekly(N) 逐日呈现口径 = 1（≥1 次即达标日，R4）。
  final int targetCount;

  /// 当日有效打卡次数（超额如实计数，完成度封顶只影响比率，R3）。
  final int doneCount;
  final bool met;
  final int backfilledCount;

  /// 该日口径是否来自 busyMode 版本（R8）。
  final bool busyMode;

  /// 当日完成度 = min(done/target, 1)，封顶（R3）。
  double get completion =>
      targetCount == 0 ? 0 : (doneCount / targetCount).clamp(0.0, 1.0).toDouble();
}

/// 生活电量（R9）：percent null = 空态（无今日适用的活跃习惯）。
class LifeBattery {
  const LifeBattery(this.percent);

  final int? percent;
}

/// 一次 evaluate 的结果：按 goalId 查询各口径数字。
class StatsEvaluation {
  StatsEvaluation({
    required List<Goal> goals,
    required List<FrequencyVersion> frequencyVersions,
    required List<BusyModeSession> busySessions,
    required List<CheckIn> checkIns,
    required LocalDate today,
  })  : _goals = {for (final g in goals) g.id: g},
        _versionsByGoal = {} {
    for (final v in frequencyVersions) {
      _versionsByGoal.putIfAbsent(v.goalId, () => []).add(v);
    }
    _validByGoalDay = {};
    for (final c in checkIns.where((c) => c.isValid)) {
      _validByGoalDay.putIfAbsent(c.goalId, () => {}).putIfAbsent(c.day, () => []).add(c);
    }
    _busySessions = busySessions;
    _today = today;
  }

  final Map<String, Goal> _goals;
  final Map<String, List<FrequencyVersion>> _versionsByGoal;
  late final Map<String, Map<LocalDate, List<CheckIn>>> _validByGoalDay;
  late final List<BusyModeSession> _busySessions;
  late final LocalDate _today;

  /// [day] 缺省 = 注入的今天。里程碑/未创建日 → 恒零非适用。
  DayStatus dayStatusOf(String goalId, [LocalDate? day]) {
    final d = day ?? _today;
    final goal = _goals[goalId];
    if (goal == null || !goal.isHabit) return _zero(goalId);
    if (d.isBefore(goal.createdAt)) return _zero(goalId);
    final version = effectiveVersion(_versionsByGoal[goalId] ?? const [], d);
    if (version == null) return _zero(goalId);

    final pattern = version.pattern;
    final applicable = pattern.isApplicableOn(d);
    final targetCount = switch (pattern) {
      WeeklyFrequency() => 1, // R4：达标日 = 当日 ≥1 次
      DailyFrequency(:final targetPerDay) => targetPerDay,
      WeekdaysFrequency(:final targetPerDay) => targetPerDay,
    };
    final checks = _validByGoalDay[goalId]?[d] ?? const <CheckIn>[];
    final doneCount = checks.length;
    return DayStatus(
      goalId: goalId,
      applicable: applicable,
      targetCount: targetCount,
      doneCount: doneCount,
      met: applicable && doneCount >= targetCount,
      backfilledCount: checks.where((c) => c.isBackfill).length,
      busyMode: version.source == FrequencySource.busyMode,
    );
  }

  DayStatus _zero(String goalId) => DayStatus(
        goalId: goalId,
        applicable: false,
        targetCount: 0,
        doneCount: 0,
        met: false,
        backfilledCount: 0,
        busyMode: false,
      );

  /// 连击（R5）：截至今天连续"适用日且达标"天数。
  /// 今天未达标不扣（连击截至昨天）；非适用日跳过不断链；
  /// weekly(N) 达标周内的休整日视为非适用日。
  int streakOf(String goalId) {
    final goal = _goals[goalId];
    if (goal == null || !goal.isHabit) return 0;
    var streak = 0;
    var day = _today;
    while (!day.isBefore(goal.createdAt)) {
      final st = dayStatusOf(goalId, day);
      final pattern = effectivePattern(_versionsByGoal[goalId] ?? const [], day);
      if (!st.applicable) {
        day = day.addDays(-1);
        continue;
      }
      if (st.met) {
        streak++;
      } else if (pattern is WeeklyFrequency &&
          weekStatOf(goalId, day.weekStart).metDays >= pattern.timesPerWeek) {
        // 该周 quota 已满：休整日跳过不断链。
      } else if (day == _today) {
        // 今天还没打：不 retro 扣，继续向昨天走。
      } else {
        break; // 适用日缺卡，断链
      }
      day = day.addDays(-1);
    }
    return streak;
  }

  /// 周结算（R2/R4/R6/R8）。本周实时：适用日只算已过天数（不因周末未到稀释）。
  GoalWeekStat weekStatOf(String goalId, WeekStart week) {
    final goal = _goals[goalId];
    if (goal == null || !goal.isHabit) {
      return _emptyStat(goalId);
    }
    final version = effectiveVersion(_versionsByGoal[goalId] ?? const [], week.monday);
    final end = week.sunday.isAfter(_today) ? _today : week.sunday;
    var applicableDays = 0, metDays = 0, backfillCount = 0;
    if (version != null) {
      for (var d = week.monday; d.isSameOrBefore(end); d = d.addDays(1)) {
        if (d.isBefore(goal.createdAt)) continue;
        if (!version.pattern.isApplicableOn(d)) continue;
        final st = dayStatusOf(goalId, d);
        applicableDays++;
        backfillCount += st.backfilledCount;
        if (st.met) metDays++;
      }
    }
    final busy = version?.source == FrequencySource.busyMode ||
        _busySessions.any((s) =>
            s.isActive &&
            s.weekStart == week &&
            s.entries.any((e) => e.goalId == goalId));
    return GoalWeekStat(
      goalId: goalId,
      applicableDays: applicableDays,
      metDays: metDays,
      completionRate:
          applicableDays == 0 ? null : metDays / applicableDays,
      backfillCount: backfillCount,
      busyModeApplied: busy,
    );
  }

  /// 生活电量（R9）：活跃 habit 当日完成度均值；无今日适用目标 → null。
  LifeBattery get battery {
    double sum = 0;
    var n = 0;
    for (final g in _goals.values) {
      if (!g.isHabit || g.status != GoalStatus.active) continue;
      final st = dayStatusOf(g.id, _today);
      if (!st.applicable) continue;
      sum += st.completion;
      n++;
    }
    return LifeBattery(n == 0 ? null : (sum / n * 100).round());
  }

  GoalWeekStat _emptyStat(String goalId) => GoalWeekStat(
        goalId: goalId,
        applicableDays: 0,
        metDays: 0,
        completionRate: null,
        backfillCount: 0,
        busyModeApplied: false,
      );
}

/// 引擎入口：一次注入全量数据，返回可查询的评估结果。
abstract final class StatsEngine {
  static StatsEvaluation evaluate({
    required List<Goal> goals,
    required List<FrequencyVersion> frequencyVersions,
    required List<BusyModeSession> busySessions,
    required List<CheckIn> checkIns,
    required LocalDate today,
  }) =>
      StatsEvaluation(
        goals: goals,
        frequencyVersions: frequencyVersions,
        busySessions: busySessions,
        checkIns: checkIns,
        today: today,
      );
}
