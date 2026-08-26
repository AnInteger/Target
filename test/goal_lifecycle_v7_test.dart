import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart'
    show AppDatabase, GoalsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/features/goals/goal_lifecycle.dart';

Goal _goal(String id) => Goal(
  id: id,
  name: '目标 $id',
  goalType: GoalType.longTerm,
  iconKey: 'explore',
  colorKey: '',
  createdAt: const LocalDate(2026, 8, 1),
  targetDate: const LocalDate(2026, 12, 31),
  frequency: const WeeklyFrequency(3),
);

void main() {
  test('日期、频率和里程碑能力不再由 legacy goalType 互斥', () {
    final goal = _goal('combined');
    expect(goal.targetDate, isNotNull);
    expect(goal.frequency, const WeeklyFrequency(3));
  });

  test('省略 legacy goalType 时从统一规划字段派生兼容值', () {
    final goal = Goal(
      name: '统一计划',
      iconKey: 'explore',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      targetDate: const LocalDate(2026, 12, 31),
      frequency: const WeeklyFrequency(3),
    );

    expect(goal.goalType, GoalType.shortTerm);
    expect(goal.progressCadenceDays, 7);
    expect(goal.deadline, const LocalDate(2026, 12, 31));
  });

  test('legacy 截止日和周目标输入会归一化为统一规划', () {
    final dated = Goal(
      name: '考证',
      goalType: GoalType.shortTerm,
      iconKey: 'school',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      deadline: const LocalDate(2026, 10, 1),
    );
    final habit = Goal(
      name: '跑步',
      goalType: GoalType.habit,
      iconKey: 'fitness',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      habitTargetPerWeek: 4,
    );

    expect(dated.targetDate, const LocalDate(2026, 10, 1));
    expect(dated.progressCadenceDays, 7);
    expect(habit.frequency, const WeeklyFrequency(4));
    expect(habit.progressCadenceDays, 7);
  });

  test('显式统一字段优先且清除后不会被 legacy 字段回填', () {
    final goal = Goal(
      name: '优先级',
      goalType: GoalType.shortTerm,
      iconKey: 'explore',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      deadline: const LocalDate(2026, 9, 1),
      targetDate: const LocalDate(2026, 10, 1),
      habitTargetPerWeek: 2,
      frequency: const WeeklyFrequency(5),
    );

    expect(goal.targetDate, const LocalDate(2026, 10, 1));
    expect(goal.deadline, const LocalDate(2026, 10, 1));
    expect(goal.frequency, const WeeklyFrequency(5));

    final cleared = goal.copyWith(clearTargetDate: true, clearFrequency: true);
    expect(cleared.targetDate, isNull);
    expect(cleared.deadline, isNull);
    expect(cleared.frequency, isNull);
    expect(cleared.habitTargetPerWeek, isNull);
    expect(cleared.goalType, GoalType.longTerm);
    expect(cleared.progressCadenceDays, 14);
  });

  test('统一周频率仍保持 1–7 的 legacy 值域校验', () {
    expect(
      () => Goal(
        name: '过高频率',
        iconKey: 'fitness',
        colorKey: '',
        createdAt: const LocalDate(2026, 8, 1),
        frequency: const WeeklyFrequency(8),
      ),
      throwsAssertionError,
    );
  });

  test('归档可逆且重新开启会清除达成时间', () {
    final achieved = _goal('done').copyWith(
      status: GoalStatus.achieved,
      achievedAt: DateTime.utc(2026, 8, 20),
      archivedAt: DateTime.utc(2026, 8, 21),
    );
    final reopened = achieved.copyWith(
      status: GoalStatus.active,
      clearAchievedAt: true,
      clearArchivedAt: true,
    );
    expect(reopened.status, GoalStatus.active);
    expect(reopened.achievedAt, isNull);
    expect(reopened.archivedAt, isNull);
  });

  test('copyWith 可显式清除日期和频率', () {
    final cleared = _goal('clear-planning')
        .copyWith(clearTargetDate: true, clearFrequency: true);
    expect(cleared.targetDate, isNull);
    expect(cleared.frequency, isNull);
  });

  test('归档目标不是 active 且不能转换状态', () {
    final archived = _goal('archived')
        .copyWith(archivedAt: DateTime.utc(2026, 8, 21));
    expect(archived.isArchived, isTrue);
    expect(archived.isActive, isFalse);
    expect(archived.canTransitTo(GoalStatus.achieved), isFalse);
  });

  test('每个未归档目标都可达成，达成后可重新开启', () {
    final habit = Goal(
      name: '习惯',
      goalType: GoalType.habit,
      iconKey: 'fitness',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
    );
    expect(habit.canTransitTo(GoalStatus.achieved), isTrue);
    expect(
      habit
          .copyWith(status: GoalStatus.achieved)
          .canTransitTo(GoalStatus.active),
      isTrue,
    );
  });

  test('仓储允许超过五个进行中目标', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepository(db);
    for (var i = 0; i < 8; i++) {
      await repo.create(_goal('$i'));
    }
    expect((await repo.getGoals()).length, 8);
  });

  test('仓储往返统一字段并派生 legacy 兼容列', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepository(db);
    final archivedAt = DateTime.utc(2026, 8, 21);
    await repo.create(
      _goal('roundtrip').copyWith(
        status: GoalStatus.achieved,
        achievedAt: DateTime.utc(2026, 8, 20),
        archivedAt: archivedAt,
      ),
    );

    final restored = (await repo.getGoals()).single;
    expect(restored.frequency, const WeeklyFrequency(3));
    expect(restored.archivedAt, archivedAt);
    expect(restored.status, GoalStatus.achieved);

    final row = (await db.select(db.goals).get()).single;
    expect(row.goalType, GoalType.shortTerm);
    expect(row.progressCadenceDays, 7);
    expect(row.deadline, const LocalDate(2026, 12, 31));
    expect(row.habitTargetPerWeek, 3);
    expect(row.status, GoalStatus.achieved);
  });

  test('legacy archived 状态只读解码且仓储不再写入', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepository(db);
    final archivedAt = DateTime.utc(2026, 8, 21);

    await repo.create(
      _goal('normalized-write')
          .copyWith(status: GoalStatus.archived, archivedAt: archivedAt),
    );
    expect((await db.select(db.goals).get()).single.status, GoalStatus.paused);

    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            id: 'legacy-read',
            name: '旧归档',
            goalType: GoalType.longTerm,
            iconKey: 'explore',
            status: GoalStatus.archived,
            createdAt: const LocalDate(2026, 8, 1),
            archivedAt: Value(archivedAt),
          ),
        );
    final restored = (await repo.getGoals()).singleWhere(
      (goal) => goal.id == 'legacy-read',
    );
    expect(restored.status, GoalStatus.paused);
    expect(restored.archivedAt, archivedAt);
  });

  test('active 流排除已归档目标', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepository(db);
    await repo.create(_goal('visible'));
    await repo.create(
      _goal('hidden').copyWith(archivedAt: DateTime.utc(2026, 8, 21)),
    );

    expect((await repo.watchActiveGoals().first).map((goal) => goal.id), [
      'visible',
    ]);
  });

  testWidgets('归档、取消归档和重新开启保留并清理正确状态', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: Consumer(
          builder: (context, widgetRef, child) {
            ref = widgetRef;
            return const SizedBox();
          },
        ),
      ),
    );
    final repo = GoalRepository(db);
    final achievedAt = DateTime.utc(2026, 8, 20);
    final achieved = _goal('lifecycle')
        .copyWith(status: GoalStatus.achieved, achievedAt: achievedAt);
    await repo.create(achieved);

    await archiveGoal(ref, achieved);
    var saved = (await repo.getGoals()).single;
    expect(saved.status, GoalStatus.achieved);
    expect(saved.achievedAt, achievedAt);
    expect(saved.archivedAt?.isUtc, isTrue);

    await unarchiveGoal(ref, saved);
    saved = (await repo.getGoals()).single;
    expect(saved.status, GoalStatus.achieved);
    expect(saved.archivedAt, isNull);

    await archiveGoal(ref, saved);
    saved = (await repo.getGoals()).single;
    await reopenGoal(ref, saved);
    saved = (await repo.getGoals()).single;
    expect(saved.status, GoalStatus.active);
    expect(saved.achievedAt, isNull);
    expect(saved.archivedAt, isNull);
  });

  testWidgets('达成动作适用于 legacy 习惯并写入 UTC', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: Consumer(
          builder: (context, widgetRef, child) {
            ref = widgetRef;
            return const SizedBox();
          },
        ),
      ),
    );
    final repo = GoalRepository(db);
    final habit = Goal(
      id: 'habit',
      name: '习惯',
      goalType: GoalType.habit,
      iconKey: 'fitness',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
    );
    await repo.create(habit);

    await achieveGoal(ref, habit);

    final saved = (await repo.getGoals()).single;
    expect(saved.status, GoalStatus.achieved);
    expect(saved.achievedAt?.isUtc, isTrue);
  });
}
