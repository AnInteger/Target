import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/goal_icon_catalog.dart';
import 'package:target/core/models/goal_progress.dart';

const today = LocalDate(2026, 8, 25);

Goal goal({
  String id = 'g',
  GoalType type = GoalType.longTerm,
  int cadence = 7,
  int ageDays = 30,
  int? deadlineDays,
  int? habitTarget,
  String iconKey = 'menu_book',
  GoalIconDomain? categoryOverride,
  GoalStatus status = GoalStatus.active,
  DateTime? archivedAt,
}) => Goal(
  id: id,
  name: '测试目标 $id',
  goalType: type,
  iconKey: iconKey,
  colorKey: '',
  categoryOverride: categoryOverride,
  progressCadenceDays: cadence,
  status: status,
  archivedAt: archivedAt,
  createdAt: today.addDays(-ageDays),
  deadline: type == GoalType.shortTerm
      ? today.addDays(deadlineDays ?? 10)
      : null,
  habitTargetPerWeek: type == GoalType.habit ? (habitTarget ?? 5) : null,
);

CheckIn check(String goalId, int daysAgo, {bool revoked = false}) {
  final day = today.addDays(-daysAgo);
  final value = CheckIn(
    id: 'c-$goalId-$daysAgo-$revoked',
    goalId: goalId,
    day: day,
    createdAt: today.atStartOfDay.add(const Duration(hours: 12)),
  );
  return revoked ? value.revoked() : value;
}

MilestoneStep openStep(String goalId, {int position = 0}) => MilestoneStep(
  id: 'm-$goalId-$position',
  goalId: goalId,
  title: '确认下一步',
  position: position,
);

void main() {
  test('short-term score uses 40/30/30 weights', () {
    final result = evaluateGoalProgress(
      goals: [goal(type: GoalType.shortTerm, cadence: 7, deadlineDays: 10)],
      checkIns: [check('g', 8)],
      milestones: {
        'g': [openStep('g')],
      },
      today: today,
    );
    final score = result.byGoal['g']!;
    expect(score.momentum, 70);
    expect(score.clarity, 100);
    expect(score.deadlineBuffer, 70);
    expect(score.total, 79);
  });

  test('cadence thresholds and new-goal grace are exact', () {
    int momentumFor(int daysAgo) => evaluateGoalProgress(
      goals: [goal(cadence: 7)],
      checkIns: [check('g', daysAgo)],
      milestones: {
        'g': [openStep('g')],
      },
      today: today,
    ).byGoal['g']!.momentum;
    expect(momentumFor(7), 100);
    expect(momentumFor(8), 70);
    expect(momentumFor(15), 40);
    expect(momentumFor(22), 0);

    final fresh = evaluateGoalProgress(
      goals: [goal(cadence: 7, ageDays: 7)],
      checkIns: const [],
      milestones: {
        'g': [openStep('g')],
      },
      today: today,
    );
    expect(fresh.byGoal['g']!.momentum, 100);
  });

  test('deadline buffer thresholds are exact', () {
    int bufferFor(int days) => evaluateGoalProgress(
      goals: [goal(type: GoalType.shortTerm, cadence: 7, deadlineDays: days)],
      checkIns: [check('g', 0)],
      milestones: {
        'g': [openStep('g')],
      },
      today: today,
    ).byGoal['g']!.deadlineBuffer!;
    expect(bufferFor(-1), 0);
    expect(bufferFor(7), 40);
    expect(bufferFor(8), 70);
    expect(bufferFor(14), 100);
  });

  test('missing next step has clarity 40 and becomes attention', () {
    final result = evaluateGoalProgress(
      goals: [goal(cadence: 14)],
      checkIns: const [],
      milestones: const {'g': []},
      today: today,
    );
    expect(result.byGoal['g']!.clarity, 40);
    expect(result.attention.single.reason, AttentionReason.needsPlanning);
  });

  test('habit uses weekly completion and the goal name is a clear action', () {
    final result = evaluateGoalProgress(
      goals: [goal(type: GoalType.habit, habitTarget: 5)],
      checkIns: [check('g', 0), check('g', 1), check('g', 6), check('g', 8)],
      milestones: const {},
      today: today,
    );
    final score = result.byGoal['g']!;
    expect(score.frequency, 60);
    expect(score.clarity, 100);
    expect(score.total, 68);
  });

  test('inactive goals and revoked records do not affect current scores', () {
    final result = evaluateGoalProgress(
      goals: [
        goal(id: 'active'),
        goal(id: 'archived', status: GoalStatus.archived),
      ],
      checkIns: [check('active', 0, revoked: true), check('archived', 0)],
      milestones: {
        'active': [openStep('active')],
        'archived': [openStep('archived')],
      },
      today: today,
    );
    expect(result.byGoal.keys, ['active']);
    expect(result.byGoal['active']!.momentum, 0);
  });

  test('archived active goals do not affect scores or dimension counts', () {
    final result = evaluateGoalProgress(
      goals: [
        goal(id: 'active'),
        goal(id: 'archived-active', archivedAt: DateTime.utc(2026, 8, 24)),
      ],
      checkIns: [check('active', 0), check('archived-active', 0)],
      milestones: {
        'active': [openStep('active')],
        'archived-active': [openStep('archived-active')],
      },
      today: today,
    );

    expect(result.byGoal.keys, ['active']);
    expect(result.dimensions[ProgressDimension.goal]!.goalCount, 1);
  });

  test(
    'dimensions are equal-weight averages and preserve no-data semantics',
    () {
      final result = evaluateGoalProgress(
        goals: [
          goal(id: 'a', iconKey: 'favorite'),
          goal(id: 'b', iconKey: 'directions_run'),
        ],
        checkIns: [check('a', 0)],
        milestones: {
          'a': [openStep('a')],
          'b': [openStep('b')],
        },
        today: today,
      );
      expect(result.dimensions[ProgressDimension.health]!.score, 70);
      expect(result.dimensions[ProgressDimension.habit], isNull);
      expect(result.dimensions[ProgressDimension.goal], isNull);
    },
  );

  test('manual category correction determines dimension aggregation', () {
    final result = evaluateGoalProgress(
      goals: [goal(categoryOverride: GoalIconDomain.health)],
      checkIns: [check('g', 0)],
      milestones: {
        'g': [openStep('g')],
      },
      today: today,
    );
    expect(result.dimensions[ProgressDimension.health], isNotNull);
    expect(result.dimensions[ProgressDimension.goal], isNull);
  });

  test('evaluation includes seven real-date daily points', () {
    final result = evaluateGoalProgress(
      goals: [goal()],
      checkIns: [check('g', 0)],
      milestones: {
        'g': [openStep('g')],
      },
      today: today,
    );
    expect(result.dailyPoints.length, 7);
    expect(result.dailyPoints.first.day, today.addDays(-6));
    expect(result.dailyPoints.last.day, today);
  });

  test('adding a first next step today does not rewrite earlier points', () {
    final target = goal();
    final before = evaluateGoalProgress(
      goals: [target],
      checkIns: [check('g', 0)],
      milestones: const {'g': []},
      today: today,
    );
    final after = evaluateGoalProgress(
      goals: [target],
      checkIns: [check('g', 0)],
      milestones: {
        'g': [openStep('g')],
      },
      today: today,
    );

    expect(
      after.dailyPoints.take(6).map((point) => point.dimensions),
      before.dailyPoints.take(6).map((point) => point.dimensions),
    );
    expect(
      after.dailyPoints.last.dimensions[ProgressDimension.goal],
      greaterThan(before.dailyPoints.last.dimensions[ProgressDimension.goal]!),
    );
  });
}
