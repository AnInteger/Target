/// T016：频率版本化规则（contracts/stats-engine.md R2、research D7）。
///
/// 覆盖：版本选择（≤ 目标周取最新）、同周 tie（busyMode 优先）；
/// 仓储规则：用户编辑追加下周一、同周覆盖待生效、busyMode 并存与恢复移除。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/stats/versioning.dart';

WeekStart _week(int y, int m, int d) => WeekStart.of(LocalDate(y, m, d));

void main() {
  group('R2 版本选择（纯函数）', () {
    final goalId = 'g1';
    final versions = [
      FrequencyVersion(
        id: 'v1',
        goalId: goalId,
        effectiveFromWeek: _week(2026, 8, 10),
        pattern: const DailyFrequency(1),
        source: FrequencySource.initial,
      ),
      FrequencyVersion(
        id: 'v2',
        goalId: goalId,
        effectiveFromWeek: _week(2026, 8, 24),
        pattern: const WeeklyFrequency(3),
        source: FrequencySource.userEdit,
      ),
    ];

    test('编辑周之前 → 旧版本', () {
      final day = LocalDate(2026, 8, 20); // 周二，属 08-17 周
      expect(effectiveVersion(versions, day)!.id, 'v1');
      expect(effectivePattern(versions, day), const DailyFrequency(1));
    });

    test('生效周当日/之后 → 新版本', () {
      expect(effectiveVersion(versions, LocalDate(2026, 8, 24))!.id, 'v2');
      expect(effectiveVersion(versions, LocalDate(2026, 8, 30))!.id, 'v2');
    });

    test('早于所有版本（目标创建前）→ null', () {
      expect(effectiveVersion(versions, LocalDate(2026, 7, 1)), isNull);
    });

    test('同周 busyMode 与 userEdit 并存 → busyMode 优先（降档生效）', () {
      final busy = FrequencyVersion(
        id: 'vb',
        goalId: goalId,
        effectiveFromWeek: _week(2026, 8, 24),
        pattern: const WeeklyFrequency(1),
        source: FrequencySource.busyMode,
      );
      expect(effectiveVersion([...versions, busy], LocalDate(2026, 8, 26))!.id,
          'vb');
    });
  });

  group('仓储规则（内存库）', () {
    late AppDatabase db;
    late GoalRepository repo;
    final now = DateTime(2026, 8, 18, 12);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = GoalRepository(db);
    });

    tearDown(() async => db.close());

    Future<String> seedGoal() async {
      final goal = await repo.create(Goal(
        name: '锻炼',
        kind: GoalKind.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: const LocalDate(2026, 8, 10),
      ));
      await repo.addInitial(goal.id, const DailyFrequency(1), _week(2026, 8, 10));
      return goal.id;
    }

    test('用户编辑 → 追加下周一生效版本', () async {
      final id = await seedGoal();
      await repo.addUserEdit(
          id, const WeeklyFrequency(3), _week(2026, 8, 24));

      final versions = await repo.versionsOf(id);
      expect(versions, hasLength(2));
      final pending = versions.last;
      expect(pending.effectiveFromWeek, _week(2026, 8, 24));
      expect(pending.source, FrequencySource.userEdit);
    });

    test('同一周重复编辑 → 覆盖待生效版本（不叠加）', () async {
      final id = await seedGoal();
      await repo.addUserEdit(
          id, const WeeklyFrequency(3), _week(2026, 8, 24));
      await repo.addUserEdit(
          id, const WeeklyFrequency(5), _week(2026, 8, 24));

      final versions = await repo.versionsOf(id);
      expect(versions.where((v) => v.source == FrequencySource.userEdit),
          hasLength(1));
      expect(
          versions
              .where((v) => v.source == FrequencySource.userEdit)
              .first
              .pattern,
          const WeeklyFrequency(5));
    });

    test('busyMode 与用户版本并存于不同周；恢复 = 移除该版本', () async {
      final id = await seedGoal();
      final busyWeek = _week(2026, 8, 17);
      await repo.addBusyMode(id, busyWeek, const WeeklyFrequency(1));
      await repo.addUserEdit(id, const WeeklyFrequency(3), _week(2026, 8, 24));

      var versions = await repo.versionsOf(id);
      expect(versions.map((v) => v.source), containsAll([
        FrequencySource.initial,
        FrequencySource.busyMode,
        FrequencySource.userEdit,
      ]));

      await repo.removeBusyMode(id, busyWeek);
      versions = await repo.versionsOf(id);
      expect(
          versions.where((v) => v.source == FrequencySource.busyMode),
          isEmpty);
      // 用户版本不受恢复影响。
      expect(
          versions.where((v) => v.source == FrequencySource.userEdit),
          isNotEmpty);
    });

    test('同一周重复开启 busyMode → 更新而非叠加', () async {
      final id = await seedGoal();
      final week = _week(2026, 8, 17);
      await repo.addBusyMode(id, week, const WeeklyFrequency(1));
      await repo.addBusyMode(id, week, const WeeklyFrequency(2));

      final versions = await repo.versionsOf(id);
      final busy = versions.where((v) => v.source == FrequencySource.busyMode);
      expect(busy, hasLength(1));
      expect(busy.first.pattern, const WeeklyFrequency(2));
    });

    test('活跃上限 5：第 6 个 active 创建被拒', () async {
      for (var i = 0; i < 5; i++) {
        await repo.create(Goal(
          name: '目标$i',
          kind: GoalKind.habit,
          iconKey: 'star',
          colorKey: 'teal',
          createdAt: const LocalDate(2026, 8, 18),
        ));
      }
      expect(
        () => repo.create(Goal(
          name: '第六个',
          kind: GoalKind.habit,
          iconKey: 'star',
          colorKey: 'teal',
          createdAt: const LocalDate(2026, 8, 18),
        )),
        throwsA(isA<ActiveGoalLimitException>()),
      );
      // paused 不占名额。
      await repo.create(Goal(
        name: '暂停的不算',
        kind: GoalKind.habit,
        iconKey: 'star',
        colorKey: 'teal',
        status: GoalStatus.paused,
        createdAt: const LocalDate(2026, 8, 18),
      ));
    });
  });

  group('CheckIn isBackfill 不变量', () {
    test('day < 操作日 → 自动补签标记；当日 → 非补签', () {
      final now = DateTime(2026, 8, 18, 9);
      final today = CheckIn(goalId: 'g', day: const LocalDate(2026, 8, 18), createdAt: now);
      final past = CheckIn(goalId: 'g', day: const LocalDate(2026, 8, 15), createdAt: now);
      expect(today.isBackfill, isFalse);
      expect(past.isBackfill, isTrue);
    });
  });
}
