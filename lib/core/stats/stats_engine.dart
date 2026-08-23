/// 统计引擎：所有界面数字的唯一事实来源。
///
/// 003 口径收敛（contracts/goal-type-model.md）：适用日/达标判定退役
/// （FrequencyPattern.isApplicableOn 退出调用图），只生产——
/// streak 连续留痕 / 周留痕天数 / 周记录数 / 全完成日。
/// 打卡 = 一条有效 CheckIns；当日 ≥1 次 → 环满（0→1 封顶）。
/// 三类型均打卡，引擎不按类型过滤（消费方自选活跃集）。
///
/// 004 US5 周视图派生（回顾页三区块，实时派生不读 WeeklyReviews 快照）：
/// 周概览（平均完成率 + 上周环比）/ 每日活动（逐日聚合）/ 单目标周完成度。
/// 应记日 = 目标已创建且（概览口径）当前仍活跃的自然日；本周只算已过
/// 天数（不因周末未到稀释，沿 weekStatOf 实时口径）。
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

/// 每日活动单日聚合（回顾页七天点阵，004 US5）。
class DayActivity {
  const DayActivity({
    required this.day,
    required this.checks,
    required this.doneGoals,
    required this.activeGoals,
    required this.isFuture,
  });

  final LocalDate day;

  /// 当日全部有效打卡次数（不限目标状态——历史活动如实计数）。
  final int checks;

  /// 当日活跃目标中已留痕数（活跃 = 当前 active 且创建日 ≤ 当日）。
  final int doneGoals;

  /// 当日应记目标数（分母；0 = 当日无应记）。
  final int activeGoals;

  /// 未来日（点阵不完成态——打卡日着色永不落在未到的日子）。
  final bool isFuture;

  /// 着色档：full = 应记全留痕 / partial = 部分 / none = 零留痕或无应记。
  DayFill get fill {
    if (activeGoals == 0 || doneGoals == 0) return DayFill.none;
    return doneGoals == activeGoals ? DayFill.full : DayFill.partial;
  }
}

/// 点阵着色档（对勾实底 / 描边圈 / 灰底，FR-013 双编码不单靠色相）。
enum DayFill { none, partial, full }

/// 单目标周完成度（回顾页本周目标卡 x/y 与线性进度，004 US5）。
/// 状态不设滤（回看口径——暂停/达成目标的历史周照常出数，是否上屏
/// 由消费方选卡）。
class GoalWeekRate {
  const GoalWeekRate({required this.metDays, required this.expectedDays});

  /// 周留痕天数（= weekStatOf 同口径）。
  final int metDays;

  /// 周应记天数（创建日起算、本周截至今日；0 = 该周无应记 → 「—」）。
  final int expectedDays;

  /// 完成度 0..1；null = 该周无应记。
  double? get fraction => expectedDays == 0 ? null : metDays / expectedDays;
}

/// 周概览（回顾页本周概览卡，004 US5）：平均完成率 + 上周环比。
class WeekOverview {
  const WeekOverview({required this.rate, required this.lastRate});

  /// 周平均完成率 0..100 = Σ留痕日 / Σ应记日（活跃目标池，舍入取整）；
  /// null = 该周零应记（「该周暂无记录」）。
  final int? rate;

  /// 上周同口径；null = 上周零应记（环比无可比较）。
  final int? lastRate;

  /// 环比 = 本周 − 上周（百分点）；null = 任一周零应记（无可比较）。
  int? get delta => rate == null || lastRate == null ? null : rate! - lastRate!;
}

/// 一次 evaluate 的结果：按 goalId 查询各口径数字。
class StatsEvaluation {
  StatsEvaluation({
    required List<Goal> goals,
    required this.busySessions,
    required List<CheckIn> checkIns,
    required LocalDate today,
  }) : _goals = {for (final g in goals) g.id: g} {
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

  /// 单目标最近一次有效留痕日（无记录 → null；提醒排程 threeDay/weekly
  /// 档的锚定日，contracts/goal-type-model）。
  LocalDate? lastCheckInDayOf(String goalId) {
    final days = _validByGoalDay[goalId]?.keys.toList();
    if (days == null || days.isEmpty) return null;
    days.sort((a, b) => a.compareTo(b));
    return days.last;
  }

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

  bool _anyDone(LocalDate day) => _validByGoalDay.values.any(
    (byDay) => (byDay[day] ?? const []).isNotEmpty,
  );

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
      busyModeApplied: busySessions.any(
        (s) =>
            s.isActive &&
            s.weekStart == week &&
            s.entries.any((e) => e.goalId == goalId),
      ),
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

  /// 目标在 [week] 的应记天数：[week.monday, min(week.sunday, 今日)] 与
  /// 创建日之后取交（本周实时截断——不因周末未到稀释）。
  /// [activeOnly] 概览口径只数当前仍活跃的目标（守护面，沿 battery）；
  /// 单目标完成度（weekRateOf）回看口径不滤。
  int _expectedDays(Goal g, WeekStart week, {required bool activeOnly}) {
    if (activeOnly && g.status != GoalStatus.active) return 0;
    final end = week.sunday.isAfter(_today) ? _today : week.sunday;
    final start = week.monday.isAfter(g.createdAt) ? week.monday : g.createdAt;
    if (start.isAfter(end)) return 0;
    return end.differenceInDays(start) + 1;
  }

  /// 单目标周完成度（回顾页本周目标卡）：metDays = weekStatOf 同口径，
  /// expectedDays = 创建日起算的应记天数（状态不滤）。
  GoalWeekRate weekRateOf(String goalId, WeekStart week) {
    final goal = _goals[goalId];
    if (goal == null) {
      return const GoalWeekRate(metDays: 0, expectedDays: 0);
    }
    return GoalWeekRate(
      metDays: weekStatOf(goalId, week).metDays,
      expectedDays: _expectedDays(goal, week, activeOnly: false),
    );
  }

  /// 周概览（回顾页本周概览卡）：平均完成率 = 活跃目标池 Σ留痕日/
  /// Σ应记日（按应记天数加权，2 目标跨 3 天手工核算即 5/6）；
  /// 上周零应记 → lastRate/delta = null（环比「无可比较」）。
  WeekOverview weekOverview(WeekStart week) {
    int rateOf(WeekStart w) {
      var met = 0, expected = 0;
      for (final g in _goals.values) {
        final exp = _expectedDays(g, w, activeOnly: true);
        if (exp == 0) continue; // 分子分母同池（暂停目标不灌入留痕）
        expected += exp;
        met += weekStatOf(g.id, w).metDays;
      }
      return expected == 0 ? -1 : (met * 100 / expected).round();
    }

    final rate = rateOf(week);
    final last = rateOf(week.previous);
    return WeekOverview(
      rate: rate < 0 ? null : rate,
      lastRate: last < 0 ? null : last,
    );
  }

  /// 每日活动（回顾页七天点阵）：周一→周日逐日聚合。checks 计全量
  /// 有效打卡（含已暂停目标的历史留痕）；done/active 只数当前活跃目标
  /// （创建日 ≤ 当日）——未来日恒 isFuture（点阵不完成态）。
  List<DayActivity> dayActivities(WeekStart week) {
    return [for (var i = 0; i < 7; i++) _activityOn(week.monday.addDays(i))];
  }

  DayActivity _activityOn(LocalDate day) {
    var checks = 0, done = 0, active = 0;
    for (final g in _goals.values) {
      final st = dayStatusOf(g.id, day);
      checks += st.doneCount;
      final isActive =
          g.status == GoalStatus.active && !day.isBefore(g.createdAt);
      if (isActive) {
        active++;
        if (st.done) done++;
      }
    }
    return DayActivity(
      day: day,
      checks: checks,
      doneGoals: done,
      activeGoals: active,
      isFuture: day.isAfter(_today),
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
  }) => StatsEvaluation(
    goals: goals,
    busySessions: busySessions,
    checkIns: checkIns,
    today: today,
  );
}
