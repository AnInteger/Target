/// 003 T013：FrequencyVersions 停写 + 存量保全。
///
/// 版本选择纯函数保留（编辑器/详情回显消费 effectivePattern）；
/// 仓储只读（versionsOf/watchAllVersions）；写入 API 已删除——
/// 新目标不产生版本行，忙碌/决策/编辑路径均不再触表；
/// 存量行（仿真 v2 旧库直插）照读、随备份往返。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/stats/versioning.dart';

import 'version_seed.dart';

WeekStart _week(int y, int m, int d) => WeekStart.of(LocalDate(y, m, d));

void main() {
  group('R2 版本选择（纯函数，回显供货）', () {
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

  group('停写 + 保全（内存库）', () {
    late AppDatabase db;
    late GoalRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = GoalRepository(db);
    });

    tearDown(() async => db.close());

    test('新目标不产生版本行（创建路径零触表）', () async {
      await repo.create(Goal(
        name: '锻炼',
        goalType: GoalType.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: const LocalDate(2026, 8, 10),
      ));
      expect(await repo.watchAllVersions().first, isEmpty);
    });

    test('存量行只读保全：直插（仿真旧库）→ versionsOf/watch 照读', () async {
      final goal = await repo.create(Goal(
        name: '锻炼',
        goalType: GoalType.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: const LocalDate(2026, 8, 10),
      ));
      await seedVersion(db, goal.id, const WeekdaysFrequency(
          {Weekday.mon, Weekday.wed}, 1), _week(2026, 8, 10));
      await seedVersion(db, goal.id, const WeeklyFrequency(1),
          _week(2026, 8, 17), FrequencySource.busyMode);

      final versions = await repo.versionsOf(goal.id);
      expect(versions, hasLength(2));
      expect(versions.map((v) => v.source), containsAll([
        FrequencySource.initial,
        FrequencySource.busyMode,
      ]));
      // 回显：目标当周取 busyMode 降档口径。
      expect(
          effectivePattern(versions, LocalDate(2026, 8, 18)),
          const WeeklyFrequency(1));
    });

    test('活跃上限 5：第 6 个 active 创建被拒', () async {
      for (var i = 0; i < 5; i++) {
        await repo.create(Goal(
          name: '目标$i',
          goalType: GoalType.habit,
          iconKey: 'star',
          colorKey: 'teal',
          createdAt: const LocalDate(2026, 8, 18),
        ));
      }
      expect(
        () => repo.create(Goal(
          name: '第六个',
          goalType: GoalType.habit,
          iconKey: 'star',
          colorKey: 'teal',
          createdAt: const LocalDate(2026, 8, 18),
        )),
        throwsA(isA<ActiveGoalLimitException>()),
      );
      // paused 不占名额。
      await repo.create(Goal(
        name: '暂停的不算',
        goalType: GoalType.habit,
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
