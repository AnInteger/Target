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

import 'version_seed.dart';

WeekStart _week(int y, int m, int d) => WeekStart.of(LocalDate(y, m, d));

void main() {
  group('停写 + 保全（内存库）', () {
    late AppDatabase db;
    late GoalRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = GoalRepository(db);
    });

    tearDown(() async => db.close());

    test('新目标不产生版本行（创建路径零触表）', () async {
      await repo.create(
        Goal(
          name: '锻炼',
          goalType: GoalType.habit,
          iconKey: 'fitness',
          colorKey: 'sage',
          createdAt: const LocalDate(2026, 8, 10),
        ),
      );
      expect(await repo.watchAllVersions().first, isEmpty);
    });

    test('存量行只读保全：直插（仿真旧库）→ versionsOf/watch 照读', () async {
      final goal = await repo.create(
        Goal(
          name: '锻炼',
          goalType: GoalType.habit,
          iconKey: 'fitness',
          colorKey: 'sage',
          createdAt: const LocalDate(2026, 8, 10),
        ),
      );
      await seedVersion(
        db,
        goal.id,
        const WeekdaysFrequency({Weekday.mon, Weekday.wed}, 1),
        _week(2026, 8, 10),
      );
      await seedVersion(
        db,
        goal.id,
        const WeeklyFrequency(1),
        _week(2026, 8, 17),
        FrequencySource.busyMode,
      );

      final versions = await repo.versionsOf(goal.id);
      expect(versions, hasLength(2));
      expect(
        versions.map((v) => v.source),
        containsAll([FrequencySource.initial, FrequencySource.busyMode]),
      );
      expect(versions.last.pattern, const WeeklyFrequency(1));
    });

    test('仓储允许创建超过 5 个 active 目标', () async {
      for (var i = 0; i < 8; i++) {
        await repo.create(
          Goal(
            name: '目标$i',
            goalType: GoalType.habit,
            iconKey: 'star',
            colorKey: 'teal',
            createdAt: const LocalDate(2026, 8, 18),
          ),
        );
      }
      expect(await repo.getGoals(), hasLength(8));
    });
  });

  group('CheckIn isBackfill 不变量', () {
    test('day < 操作日 → 自动补签标记；当日 → 非补签', () {
      final now = DateTime(2026, 8, 18, 9);
      final today = CheckIn(
        goalId: 'g',
        day: const LocalDate(2026, 8, 18),
        createdAt: now,
      );
      final past = CheckIn(
        goalId: 'g',
        day: const LocalDate(2026, 8, 15),
        createdAt: now,
      );
      expect(today.isBackfill, isFalse);
      expect(past.isBackfill, isTrue);
    });
  });
}
