import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/goal_icon_catalog.dart';

void main() {
  test('goal cadence defaults follow unified planning settings', () {
    final short = Goal(
      name: '拿到 OW 潜水证',
      iconKey: GoalIconCatalog.pool.key,
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 25),
      targetDate: const LocalDate(2026, 10, 2),
    );
    final long = Goal(
      name: '完成个人作品集',
      iconKey: GoalIconCatalog.palette.key,
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 25),
    );

    expect(short.progressCadenceDays, 7);
    expect(long.progressCadenceDays, 14);
  });

  test('manual category override wins over icon inference', () {
    final goal = Goal(
      name: '学习水下摄影',
      goalType: GoalType.longTerm,
      iconKey: GoalIconCatalog.camera.key,
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 25),
      categoryOverride: GoalIconDomain.travel,
    );

    expect(goal.effectiveDomain, GoalIconDomain.travel);
    final corrected = goal.copyWith(categoryOverride: GoalIconDomain.health);
    expect(corrected.effectiveDomain, GoalIconDomain.health);
    expect(corrected.major, MajorCategory.health);
  });

  test('milestones retain a stable manual order', () {
    final step = MilestoneStep(
      goalId: 'goal-1',
      title: '完成 DSD 体验潜水',
      position: 20,
    );

    expect(step.position, 20);
    expect(
      step.toggled(now: DateTime.utc(2026, 8, 25), done: true).position,
      20,
    );
  });

  test('type-specific planning fields preserve long and habit rules', () {
    final long = Goal(
      name: '完成个人作品集',
      goalType: GoalType.longTerm,
      iconKey: GoalIconCatalog.palette.key,
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 25),
      targetDate: const LocalDate(2027, 2, 1),
    );
    final habit = Goal(
      name: '饭后散步 20 分钟',
      goalType: GoalType.habit,
      iconKey: GoalIconCatalog.directionsRun.key,
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 25),
      habitTargetPerWeek: 5,
    );

    expect(long.targetDate, const LocalDate(2027, 2, 1));
    expect(habit.habitTargetPerWeek, 5);
  });

  test('settings expose cadence defaults and score algorithm boundary', () {
    const settings = Settings(
      defaultShortCadenceDays: 7,
      defaultLongCadenceDays: 14,
      scoreAlgorithmStartedOn: LocalDate(2026, 8, 25),
    );

    expect(settings.defaultShortCadenceDays, 7);
    expect(settings.defaultLongCadenceDays, 14);
    expect(settings.scoreAlgorithmStartedOn, const LocalDate(2026, 8, 25));
  });

  test(
    'unified planning fields round trip and legacy cadence is derived',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final goals = GoalRepository(db);
      final settings = SettingsRepository(db);
      final goal = Goal(
        id: 'goal-1',
        name: '完成个人作品集',
        goalType: GoalType.longTerm,
        iconKey: GoalIconCatalog.palette.key,
        colorKey: '',
        categoryOverride: GoalIconDomain.learning,
        progressCadenceDays: 21,
        targetDate: const LocalDate(2027, 2, 1),
        createdAt: const LocalDate(2026, 8, 25),
      );

      await goals.create(goal);
      await goals.addStep(
        MilestoneStep(
          id: 'step-1',
          goalId: goal.id,
          title: '完成信息架构',
          position: 20,
        ),
      );
      await settings.update(
        const Settings(
          defaultShortCadenceDays: 9,
          defaultLongCadenceDays: 21,
          scoreAlgorithmStartedOn: LocalDate(2026, 8, 25),
        ),
      );

      final savedGoal = (await goals.getGoals()).single;
      expect(savedGoal.categoryOverride, GoalIconDomain.learning);
      expect(savedGoal.progressCadenceDays, 7);
      expect(savedGoal.targetDate, const LocalDate(2027, 2, 1));
      expect((await goals.stepsOf(goal.id)).single.position, 20);
      final savedSettings = await settings.get();
      expect(savedSettings.defaultShortCadenceDays, 9);
      expect(savedSettings.defaultLongCadenceDays, 21);
      expect(
        savedSettings.scoreAlgorithmStartedOn,
        const LocalDate(2026, 8, 25),
      );
    },
  );
}
