/// 可解释的目标管理评分。所有输入均来自目标、记录与里程碑事实；不推断
/// 用户的身体、情绪、工作强度或未提供的生活原因。
library;

import 'calendar_types.dart';
import 'entities.dart';
import 'goal_icon_catalog.dart';

enum ProgressDimension { health, habit, goal }

enum ScoreBand { stable, calibrate, adjust, replan }

enum ScoreDriver { momentum, clarity, deadlineBuffer, frequency }

enum AttentionReason { needsPlanning, rhythmInterrupted, deadlineNear }

class GoalScore {
  const GoalScore({
    required this.goalId,
    required this.total,
    required this.momentum,
    required this.clarity,
    this.deadlineBuffer,
    this.frequency,
  });

  final String goalId;
  final int total;
  final int momentum;
  final int clarity;
  final int? deadlineBuffer;
  final int? frequency;

  ScoreBand get band => scoreBandOf(total);
}

class DimensionProgress {
  const DimensionProgress({
    required this.dimension,
    required this.score,
    required this.goalCount,
  });

  final ProgressDimension dimension;
  final int score;
  final int goalCount;

  ScoreBand get band => scoreBandOf(score);
}

class DailyProgressPoint {
  const DailyProgressPoint({required this.day, required this.dimensions});

  final LocalDate day;
  final Map<ProgressDimension, int> dimensions;
}

class AttentionItem {
  const AttentionItem({
    required this.goalId,
    required this.reason,
    required this.urgency,
  });

  final String goalId;
  final AttentionReason reason;

  /// 越大越紧急；只用于同类原因的稳定排序。
  final int urgency;
}

class GoalProgressEvaluation {
  const GoalProgressEvaluation({
    required this.byGoal,
    required this.dimensions,
    required this.dailyPoints,
    required this.attention,
    required this.hasProgressEvents,
  });

  final Map<String, GoalScore> byGoal;
  final Map<ProgressDimension, DimensionProgress> dimensions;
  final List<DailyProgressPoint> dailyPoints;
  final List<AttentionItem> attention;

  /// 是否存在可追溯到具体日期的真实进展事件（有效记录或已完成里程碑）。
  /// 分数本身可能由目标期限、节奏等静态信息产生，不能据此伪造趋势。
  final bool hasProgressEvents;
}

ScoreBand scoreBandOf(int score) {
  if (score >= 80) return ScoreBand.stable;
  if (score >= 60) return ScoreBand.calibrate;
  if (score >= 40) return ScoreBand.adjust;
  return ScoreBand.replan;
}

GoalProgressEvaluation evaluateGoalProgress({
  required List<Goal> goals,
  required List<CheckIn> checkIns,
  required Map<String, List<MilestoneStep>> milestones,
  required LocalDate today,
}) {
  final current = _evaluateAt(
    goals: goals,
    checkIns: checkIns,
    milestones: milestones,
    day: today,
  );
  final daily = <DailyProgressPoint>[];
  for (var offset = 6; offset >= 0; offset--) {
    final day = today.addDays(-offset);
    final evaluation = _evaluateAt(
      goals: goals,
      checkIns: checkIns,
      milestones: milestones,
      day: day,
      // 里程碑没有创建时间，无法可靠回算过去是否已有下一步。
      // 历史日期使用中性清晰度，仅今天采用当前规划状态。
      useCurrentMilestoneClarity: day == today,
    );
    daily.add(
      DailyProgressPoint(
        day: day,
        dimensions: {
          for (final entry in evaluation.dimensions.entries)
            entry.key: entry.value.score,
        },
      ),
    );
  }
  return GoalProgressEvaluation(
    byGoal: current.byGoal,
    dimensions: current.dimensions,
    dailyPoints: daily,
    attention: current.attention,
    hasProgressEvents: current.hasProgressEvents,
  );
}

GoalProgressEvaluation _evaluateAt({
  required List<Goal> goals,
  required List<CheckIn> checkIns,
  required Map<String, List<MilestoneStep>> milestones,
  required LocalDate day,
  bool useCurrentMilestoneClarity = true,
}) {
  final active = goals
      .where(
        (goal) =>
            goal.status == GoalStatus.active && !day.isBefore(goal.createdAt),
      )
      .toList();
  final byGoal = <String, GoalScore>{};
  final attention = <AttentionItem>[];
  var hasProgressEvents = false;

  for (final goal in active) {
    final steps = milestones[goal.id] ?? const <MilestoneStep>[];
    final validChecks = checkIns
        .where(
          (check) =>
              check.goalId == goal.id &&
              check.isValid &&
              !check.day.isAfter(day),
        )
        .toList();
    if (validChecks.isNotEmpty ||
        steps.any((step) {
          final doneAt = step.doneAt;
          return step.isDone &&
              doneAt != null &&
              !LocalDate.fromDateTime(doneAt.toLocal()).isAfter(day);
        })) {
      hasProgressEvents = true;
    }
    final momentum = _momentum(
      goal: goal,
      checks: validChecks,
      steps: steps,
      day: day,
    );
    final clarity = _clarity(
      goal,
      steps,
      useCurrentMilestoneClarity: useCurrentMilestoneClarity,
    );

    late final GoalScore score;
    if (goal.isHabit) {
      final frequency = _habitFrequency(goal, validChecks, day);
      score = GoalScore(
        goalId: goal.id,
        total: (frequency * .8 + clarity * .2).round(),
        momentum: momentum,
        clarity: clarity,
        frequency: frequency,
      );
    } else if (goal.isShortTerm) {
      final buffer = _deadlineBuffer(goal, day);
      score = GoalScore(
        goalId: goal.id,
        total: (momentum * .4 + clarity * .3 + buffer * .3).round(),
        momentum: momentum,
        clarity: clarity,
        deadlineBuffer: buffer,
      );
    } else {
      score = GoalScore(
        goalId: goal.id,
        total: (momentum * .6 + clarity * .4).round(),
        momentum: momentum,
        clarity: clarity,
      );
    }
    byGoal[goal.id] = score;

    if (clarity < 100) {
      attention.add(
        AttentionItem(
          goalId: goal.id,
          reason: AttentionReason.needsPlanning,
          urgency: 100 - clarity,
        ),
      );
    } else if (score.deadlineBuffer != null && score.deadlineBuffer! <= 40) {
      attention.add(
        AttentionItem(
          goalId: goal.id,
          reason: AttentionReason.deadlineNear,
          urgency: 100 - score.deadlineBuffer!,
        ),
      );
    } else if ((score.frequency ?? momentum) < 100) {
      final rhythm = score.frequency ?? momentum;
      attention.add(
        AttentionItem(
          goalId: goal.id,
          reason: AttentionReason.rhythmInterrupted,
          urgency: 100 - rhythm,
        ),
      );
    }
  }

  final dimensions = <ProgressDimension, DimensionProgress>{};
  for (final dimension in ProgressDimension.values) {
    final scores = active
        .where((goal) => _dimensionOf(goal.effectiveDomain.major) == dimension)
        .map((goal) => byGoal[goal.id]!.total)
        .toList();
    if (scores.isEmpty) continue;
    dimensions[dimension] = DimensionProgress(
      dimension: dimension,
      score: (scores.reduce((a, b) => a + b) / scores.length).round(),
      goalCount: scores.length,
    );
  }

  const priority = {
    AttentionReason.needsPlanning: 0,
    AttentionReason.deadlineNear: 1,
    AttentionReason.rhythmInterrupted: 2,
  };
  attention.sort((a, b) {
    final reasonOrder = priority[a.reason]!.compareTo(priority[b.reason]!);
    if (reasonOrder != 0) return reasonOrder;
    final urgencyOrder = b.urgency.compareTo(a.urgency);
    if (urgencyOrder != 0) return urgencyOrder;
    return a.goalId.compareTo(b.goalId);
  });

  return GoalProgressEvaluation(
    byGoal: Map.unmodifiable(byGoal),
    dimensions: Map.unmodifiable(dimensions),
    dailyPoints: const [],
    attention: List.unmodifiable(attention),
    hasProgressEvents: hasProgressEvents,
  );
}

int _momentum({
  required Goal goal,
  required List<CheckIn> checks,
  required List<MilestoneStep> steps,
  required LocalDate day,
}) {
  LocalDate? latest;
  for (final check in checks) {
    if (latest == null || check.day.isAfter(latest)) latest = check.day;
  }
  for (final step in steps) {
    final doneAt = step.doneAt;
    if (!step.isDone || doneAt == null) continue;
    final doneDay = LocalDate.fromDateTime(doneAt.toLocal());
    if (doneDay.isAfter(day)) continue;
    if (latest == null || doneDay.isAfter(latest)) latest = doneDay;
  }

  final elapsed = latest == null
      ? day.differenceInDays(goal.createdAt)
      : day.differenceInDays(latest);
  final cadence = goal.progressCadenceDays;
  if (elapsed <= cadence) return 100;
  if (elapsed <= cadence * 2) return 70;
  if (elapsed <= cadence * 3) return 40;
  return 0;
}

int _clarity(
  Goal goal,
  List<MilestoneStep> steps, {
  required bool useCurrentMilestoneClarity,
}) {
  if (goal.isHabit) return 100;
  if (!useCurrentMilestoneClarity) return 100;
  final hasOpenStep = steps.any((step) => !step.isDone);
  return hasOpenStep ? 100 : 40;
}

int _deadlineBuffer(Goal goal, LocalDate day) {
  final remaining = goal.deadline!.differenceInDays(day);
  if (remaining < 0) return 0;
  final cadence = goal.progressCadenceDays;
  if (remaining <= cadence) return 40;
  if (remaining < cadence * 2) return 70;
  return 100;
}

int _habitFrequency(Goal goal, List<CheckIn> checks, LocalDate day) {
  final windowStart = day.addDays(-6);
  final completed = checks
      .where(
        (check) => !check.day.isBefore(windowStart) && !check.day.isAfter(day),
      )
      .length;
  final target = goal.habitTargetPerWeek ?? 5;
  return ((completed / target) * 100).clamp(0, 100).round();
}

ProgressDimension _dimensionOf(MajorCategory category) => switch (category) {
  MajorCategory.health => ProgressDimension.health,
  MajorCategory.habit => ProgressDimension.habit,
  MajorCategory.goal => ProgressDimension.goal,
};
