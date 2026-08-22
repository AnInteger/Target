/// 统计引擎：所有界面数字的唯一事实来源。
///
/// 003 口径收敛（contracts/goal-type-model.md）：适用日/达标判定退役
/// （FrequencyPattern.isApplicableOn 退出调用图），只生产——
/// streak 连续留痕 / 周留痕天数 / 周记录数 / 全完成日。
/// 打卡 = 一条有效 CheckIns；当日 ≥1 次 → 环满（0→1 封顶）。
/// 三类型均打卡，引擎不按类型过滤（消费方自选活跃集）。
library;

import '../models/calendar_types.dart';
import '../models/entities.dart';

/// 单目标单日状态（今日环 / 小组件快照 / 回顾页节奏条消费）。
class DayStatus {
  const DayStatus({
    required this.goalId,
    required this.doneCount,
    required this.backfilledCount,
  });

  final String goalId;

  /// 当日有效打卡次数（超额如实计数）。
  final int doneCount;

  /// 当日补签次数。
  final int backfilledCount;

  /// 当日环：≥1 次打卡即满（0→1 封顶）。
  bool get done => doneCount >= 1;
}

/// 生活电量：今日环均值（done 目标占比）；null = 无活跃目标（空态）。
class LifeBattery {
  const LifeBattery(this.percent);

  final int? percent;
}

/// 一次 evaluate 的结果：按 goalId 查询各口径数字。
class StatsEvaluation {
  StatsEvaluation({
    required List<Goal> goals,
    required this.busySessions,
    required List<CheckIn> checkIns,
    required LocalDate today,
  })  : _goals = {for (final g in goals) g.id: g} {
    for (final c in checkIns.where((c) => c.isValid)) {
      _validByGoalDay
          .putIfAbsent(c.goalId, () => {})
          .putIfAbsent(c.day, () => [])
          .add(c);
    }
    _today = today;
  }

  final Map<String, Goal> _goals;
  final List<BusyModeSession> busySessions;
  final Map<String, Map<LocalDate, List<CheckIn>>> _validByGoalDay = {};
  late final LocalDate _today;

  /// [day] 缺省 = 注入的今天；目标未创建 → 恒零。
  DayStatus dayStatusOf(String goalId, [LocalDate? day]) {
    final d = day ?? _today;
    final goal = _goals[goalId];
    if (goal == null || d.isBefore(goal.createdAt)) return _zero(goalId);
    final checks = _validByGoalDay[goalId]?[d] ?? const <CheckIn>[];
    return DayStatus(
      goalId: goalId,
      doneCount: checks.length,
      backfilledCount: checks.where((c) => c.isBackfill).length,
    );
  }

  DayStatus _zero(String goalId) =>
      DayStatus(goalId: goalId, doneCount: 0, backfilledCount: 0);

  /// 单目标 streak：自今日（或昨日）回溯的连续留痕天数。
  /// 今天未留痕不扣（今天还有机会，自昨天起算）。
  int streakOf(String goalId) {
    final goal = _goals[goalId];
    if (goal == null) return 0;
    var streak = 0;
    var day = dayStatusOf(goalId).done ? _today : _today.addDays(-1);
    while (!day.isBefore(goal.createdAt)) {
      if (!dayStatusOf(goalId, day).done) break;
      streak++;
      day = day.addDays(-1);
    }
    return streak;
  }

  /// 总 streak：任一目标留痕的连续天数（今日页头部语）。
  int get totalStreak {
    var streak = 0;
    var day = _anyDone(_today) ? _today : _today.addDays(-1);
    while (_anyDone(day)) {
      streak++;
      day = day.addDays(-1);
    }
    return streak;
  }

  bool _anyDone(LocalDate day) => _validByGoalDay.values
      .any((byDay) => (byDay[day] ?? const []).isNotEmpty);

  /// 全完成日：当日全部活跃目标均留痕（无活跃目标 → false）。
  bool get allCompleteToday {
    final active = _goals.values
        .where((g) => g.status == GoalStatus.active)
        .toList();
    if (active.isEmpty) return false;
    return active.every((g) => dayStatusOf(g.id, _today).done);
  }

  /// 单目标周统计（周留痕 metDays / 周记录数 totalChecks）。
  /// 本周实时：只算已过天数（不因周末未到稀释）。
  GoalWeekStat weekStatOf(String goalId, WeekStart week) {
    final goal = _goals[goalId];
    if (goal == null) return _emptyStat(goalId);
    final end = week.sunday.isAfter(_today) ? _today : week.sunday;
    var metDays = 0, totalChecks = 0, backfillCount = 0;
    for (var d = week.monday; d.isSameOrBefore(end); d = d.addDays(1)) {
      if (d.isBefore(goal.createdAt)) continue;
      final st = dayStatusOf(goalId, d);
      if (st.done) metDays++;
      totalChecks += st.doneCount;
      backfillCount += st.backfilledCount;
    }
    return GoalWeekStat(
      goalId: goalId,
      metDays: metDays,
      totalChecks: totalChecks,
      backfillCount: backfillCount,
      busyModeApplied: busySessions.any((s) =>
          s.isActive &&
          s.weekStart == week &&
          s.entries.any((e) => e.goalId == goalId)),
    );
  }

  /// 总周统计（回顾页周摘要：留痕天数 / 记录数）。
  GoalWeekStat totalWeekStat(WeekStart week) {
    final end = week.sunday.isAfter(_today) ? _today : week.sunday;
    var metDays = 0, totalChecks = 0, backfillCount = 0;
    final seen = <LocalDate>{};
    for (final byDay in _validByGoalDay.values) {
      byDay.forEach((day, checks) {
        if (day.isBefore(week.monday) || day.isAfter(end)) return;
        totalChecks += checks.length;
        backfillCount += checks.where((c) => c.isBackfill).length;
        if (seen.add(day)) metDays++; // 每自然日只计一次
      });
    }
    return GoalWeekStat(
      goalId: '',
      metDays: metDays,
      totalChecks: totalChecks,
      backfillCount: backfillCount,
    );
  }

  /// 生活电量：活跃目标今日环均值（done 占比 ×100）。
  LifeBattery get battery {
    var done = 0, n = 0;
    for (final g in _goals.values) {
      if (g.status != GoalStatus.active) continue;
      n++;
      if (dayStatusOf(g.id, _today).done) done++;
    }
    return LifeBattery(n == 0 ? null : (done / n * 100).round());
  }

  GoalWeekStat _emptyStat(String goalId) => GoalWeekStat(
        goalId: goalId,
        metDays: 0,
        totalChecks: 0,
        backfillCount: 0,
      );
}

/// 引擎入口：一次注入全量数据，返回可查询的评估结果。
abstract final class StatsEngine {
  static StatsEvaluation evaluate({
    required List<Goal> goals,
    required List<BusyModeSession> busySessions,
    required List<CheckIn> checkIns,
    required LocalDate today,
  }) =>
      StatsEvaluation(
        goals: goals,
        busySessions: busySessions,
        checkIns: checkIns,
        today: today,
      );
}
