/// T044：快照里程碑扩展测试（contracts/widget-intent.md）。
///
/// 习惯行 schema 不变；里程碑行带 kind/stepsDone/stepsTotal/deadline
/// （可选键，旧 Swift 解码兼容）；weekProgress 只数习惯。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/platform/widgets/widget_snapshot.dart';
import 'package:target/core/stats/stats_engine.dart';

final LocalDate _today = const LocalDate(2026, 8, 19);

StatsEvaluation _evaluate(List<Goal> goals) => StatsEngine.evaluate(
      goals: goals,
      frequencyVersions: [
        for (final g in goals.where((g) => g.isHabit))
          FrequencyVersion(
            id: 'v-${g.id}',
            goalId: g.id,
            effectiveFromWeek: WeekStart.of(g.createdAt),
            pattern: const DailyFrequency(1),
            source: FrequencySource.initial,
          ),
      ],
      busySessions: const [],
      checkIns: const [],
      today: _today,
    );

Goal _habit(String id) => Goal(
    id: id,
    name: '习惯$id',
    goalType: GoalType.habit,
    iconKey: 'star',
    colorKey: 'teal',
    createdAt: const LocalDate(2026, 8, 3));

Goal _milestone(String id, {LocalDate? deadline}) => Goal(
    id: id,
    name: '里程碑$id',
    goalType: GoalType.shortTerm,
    iconKey: 'flag',
    colorKey: 'coral',
    createdAt: const LocalDate(2026, 8, 3),
    deadline: deadline ?? const LocalDate(2026, 12, 31));

void main() {
  test('里程碑行：kind/steps 进度/deadline，无习惯口径键', () {
    final goals = [_habit('h'), _milestone('m')];
    final snap = buildTodaySnapshot(
      goals: goals,
      stats: _evaluate(goals),
      today: _today,
      now: DateTime(2026, 8, 19, 10),
      stepsOf: (id) => id == 'm'
          ? [
              MilestoneStep(id: 's1', goalId: 'm', title: 'a', isDone: true, doneAt: DateTime(2026, 8, 18)),
              MilestoneStep(id: 's2', goalId: 'm', title: 'b'),
            ]
          : const [],
    );
    final rows = List<Map<String, Object?>>.from(snap['goals'] as List);

    final habit = rows.firstWhere((r) => r['id'] == 'h');
    expect(habit.containsKey('kind'), isFalse, reason: '习惯行 schema 保持 T028 不变');
    expect(habit['targetCount'], 1);

    final ms = rows.firstWhere((r) => r['id'] == 'm');
    expect(ms['kind'], 'milestone');
    expect(ms['stepsDone'], 1);
    expect(ms['stepsTotal'], 2);
    expect(ms['deadline'], '2026-12-31');
    expect(ms.containsKey('targetCount'), isFalse,
        reason: 'Swift 端这些键已转可选，不发的行不发');
  });

  test('weekProgress 只统计习惯；无 stepsOf 时里程碑步骤为 0', () {
    final goals = [_habit('h'), _milestone('m')];
    final snap = buildTodaySnapshot(
      goals: goals,
      stats: _evaluate(goals),
      today: _today,
      now: DateTime(2026, 8, 19, 10),
    );
    final wp = snap['weekProgress'] as Map<String, Object?>;
    expect(wp['totalGoals'], 1);
    final ms =
        (snap['goals'] as List).firstWhere((r) => (r as Map)['id'] == 'm') as Map<String, Object?>;
    expect(ms['stepsTotal'], 0);
  });

  test('暂停里程碑不入快照（与习惯口径一致：仅 active）', () {
    final paused = _milestone('m').copyWith(status: GoalStatus.paused);
    final snap = buildTodaySnapshot(
      goals: [paused],
      stats: _evaluate([paused]),
      today: _today,
      now: DateTime(2026, 8, 19, 10),
    );
    expect(snap['goals'], isEmpty);
  });
}
