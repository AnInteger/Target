/// 006 v3 数据层精简测试套件（开发期随写留关键口径；全量回归在 Phase 4）。
///
/// 口径优先：富记录 schema、里程碑达成流事务性、置顶序维护、备份 v7
/// 往返、统计投入口径。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/backup/backup_exporter.dart';
import 'package:target/core/backup/backup_importer.dart';
import 'package:target/core/db/app_database.dart';
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/stats/stats_engine.dart';

AppDatabase _db() => AppDatabase(NativeDatabase.memory());

Goal _goal({String? id, bool pinned = false}) => Goal(
  id: id,
  name: '自在地游泳',
  createdAt: const LocalDate(2026, 9, 1),
  pinned: pinned,
);

void main() {
  group('schema v8 基础', () {
    test('settings 单例自动就位', () async {
      final db = _db();
      final settings = await SettingsRepository(db).get();
      expect(settings.remindersEnabled, true);
      expect(settings.themeMode, isNull);
      await db.close();
    });

    test('目标计划原子创建（goal+里程碑+提醒）', () async {
      final db = _db();
      final repo = GoalRepository(db);
      final goal = _goal();
      await repo.createPlan(
        goal,
        [
          Milestone(
            goalId: goal.id,
            title: '连续游完 500 米',
            description: '不扶池边',
            position: 0,
          ),
        ],
        reminder: Reminder(
          goalId: goal.id,
          time: const LocalTime(8, 30),
          isEnabled: true,
          cadence: Cadence.weekly,
        ),
      );
      final goals = await repo.getGoals();
      expect(goals, hasLength(1));
      expect(goals.first.name, '自在地游泳');
      final ms = await MilestoneRepository(db).of(goal.id);
      expect(ms, hasLength(1));
      expect(ms.first.description, '不扶池边');
      final r = await ReminderRepository(db).of(goal.id);
      expect(r?.cadence, Cadence.weekly);
      await db.close();
    });
  });

  group('里程碑达成流（FR-003）', () {
    test('markDone 同事务生成达成记录；undoDone 撤除', () async {
      final db = _db();
      final goals = GoalRepository(db);
      final ms = MilestoneRepository(db);
      final records = RecordRepository(db);
      final goal = _goal();
      await goals.createPlan(goal, [
        Milestone(goalId: goal.id, title: '独立游完 25 米', position: 0),
      ]);
      final m = (await ms.of(goal.id)).first;

      await ms.markDone(
        m.id,
        note: '比想象中从容。',
        now: DateTime.utc(2026, 9, 6, 10),
      );
      var all = await records.watchOf(goal.id).first;
      expect(all, hasLength(1));
      expect(all.first.kind, RecordKind.milestoneAchievement);
      expect(all.first.milestoneId, m.id);
      expect(all.first.body, '比想象中从容。');

      await ms.undoDone(m.id);
      all = await records.watchOf(goal.id).first;
      expect(all, isEmpty);
      final after = (await ms.of(goal.id)).first;
      expect(after.isDone, false);
      expect(after.doneAt, isNull);
      await db.close();
    });
  });

  group('置顶序维护（FR-004）', () {
    test('置顶追加末位；取消压缩序号；reorderPinned 重写', () async {
      final db = _db();
      final repo = GoalRepository(db);
      final a = _goal(id: 'a');
      final b = _goal(id: 'b');
      final c = _goal(id: 'c');
      for (final g in [a, b, c]) {
        await repo.createPlan(g, []);
      }
      await repo.setPinned('a', true);
      await repo.setPinned('b', true);
      var goals = await repo.getGoals();
      expect(goals.where((g) => g.pinned).map((g) => g.pinnedOrder), [0, 1]);

      await repo.setPinned('a', false); // 取消 → b 压缩至 0
      goals = await repo.getGoals();
      final pinned = goals.where((g) => g.pinned).toList();
      expect(pinned.map((g) => g.id), ['b']);
      expect(pinned.first.pinnedOrder, 0);

      await repo.setPinned('c', true);
      await repo.reorderPinned(['c', 'b']); // 拖拽 c 到首位
      goals = await repo.getGoals();
      expect(
        goals.where((g) => g.pinned).map((g) => '${g.id}:${g.pinnedOrder}'),
        ['c:0', 'b:1'],
      );
      await db.close();
    });
  });

  group('富记录（FR-002）', () {
    test('补记自动判 isBackfill', () async {
      final db = _db();
      final goals = GoalRepository(db);
      final records = RecordRepository(db);
      final goal = _goal();
      await goals.createPlan(goal, []);

      final today = const LocalDate(2026, 9, 7);
      final backfill = await records.add(
        ProgressRecord(
          goalId: goal.id,
          title: '补昨天',
          day: const LocalDate(2026, 9, 6),
          createdAt: DateTime.utc(2026, 9, 7, 12),
        ),
        today: today,
      );
      expect(backfill.isBackfill, true);

      final sameDay = await records.add(
        ProgressRecord(
          goalId: goal.id,
          title: '今天',
          day: today,
          createdAt: DateTime.utc(2026, 9, 7, 14),
        ),
        today: today,
      );
      expect(sameDay.isBackfill, false);
      await db.close();
    });
  });

  group('备份 v7（FR-010）', () {
    test('导出→清库→恢复 全字段往返', () async {
      final db = _db();
      final goals = GoalRepository(db);
      final ms = MilestoneRepository(db);
      final records = RecordRepository(db);
      final g = Goal(
        name: '让阅读成为日常',
        why: '安静的时间里慢下来',
        categoryKey: GoalCategory.learning,
        iconKey: 'menu_book',
        colorKey: 'orange',
        pinned: true,
        createdAt: const LocalDate(2026, 9, 1),
      );
      await goals.createPlan(
        g,
        [Milestone(goalId: g.id, title: '连续 30 天', position: 0)],
        reminder: Reminder(
          goalId: g.id,
          time: const LocalTime(20, 0),
          isEnabled: true,
        ),
      );
      await ms.markDone(
        (await ms.of(g.id)).first.id,
        note: '第一步',
        now: DateTime.utc(2026, 9, 6),
      );
      await records.add(
        ProgressRecord(
          goalId: g.id,
          title: '读完《悉达多》',
          body: '记下 3 段感想',
          durationMinutes: 60,
          day: const LocalDate(2026, 9, 6),
          createdAt: DateTime.utc(2026, 9, 6, 21),
        ),
        today: const LocalDate(2026, 9, 6),
      );
      await SettingsRepository(db).update(
        (await SettingsRepository(
          db,
        ).get()).copyWith(nickname: '星行', themeMode: 'dark'),
      );

      final exporter = BackupExporter(db);
      final content = await exporter.exportString(
        now: DateTime.utc(2026, 9, 8),
      );

      // 覆盖恢复（v3 D10：全新库模拟清库重建后导入）
      final db2 = AppDatabase(NativeDatabase.memory());
      final summary = await BackupImporter(db2).importString(content);
      expect(summary.goals, 1);
      expect(summary.milestones, 1);
      expect(summary.records, 2); // 达成记录 + 普通记录
      final restored = await GoalRepository(db2).getGoals();
      expect(restored.first.name, '让阅读成为日常');
      expect(restored.first.pinned, true);
      expect(restored.first.categoryKey, GoalCategory.learning);
      final settings = await SettingsRepository(db2).get();
      expect(settings.nickname, '星行');
      expect(settings.themeMode, 'dark');
      final msRestored = await MilestoneRepository(db2).of(restored.first.id);
      expect(msRestored.first.isDone, true);
      await db.close();
      await db2.close();
    });

    test('旧版本（v6）明确拒绝', () async {
      final db = _db();
      const legacy =
          '{"format":"target-backup","version":6,"exportedAt":"2026-08-01T00:00:00Z","data":{}}';
      await expectLater(
        BackupImporter(db).importString(legacy),
        throwsA(isA<BackupFormatException>()),
      );
      await db.close();
    });
  });

  group('统计 v3（FR-005/007）', () {
    test('周投入：分钟只计带时长记录；记录数全计', () {
      final week = WeekStart.of(const LocalDate(2026, 8, 31)); // 周一
      List<ProgressRecord> r(String id, String day, int? minutes) => [
        ProgressRecord(
          id: id,
          goalId: 'g',
          title: 't',
          durationMinutes: minutes,
          day: LocalDate.parse(day),
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      ];
      final records = [
        ...r('1', '2026-08-31', 30), // 周一 30
        ...r('2', '2026-09-03', null), // 周四无时长（计条不计分）
        ...r('3', '2026-09-05', 90), // 周六 90
        ...r('4', '2026-09-07', 30), // 下周一（不入本周）
      ];
      final weekInvestment = StatsEngine.weekInvestment(records, week);
      expect(weekInvestment.totalMinutes, 120);
      expect(weekInvestment.recordCount, 3);
      expect(weekInvestment.hours, 2);
      expect(weekInvestment.perDayMinutes[0], 30); // 周一
      expect(weekInvestment.perDayMinutes[3], 0); // 周四无时长
      expect(weekInvestment.perDayMinutes[5], 90); // 周六
    });

    test('日历：逐日 + 月峰值', () {
      final records = [
        ProgressRecord(
          id: '1',
          goalId: 'g',
          title: 'a',
          durationMinutes: 30,
          day: const LocalDate(2026, 9, 1),
          createdAt: DateTime.utc(2026, 9, 1),
        ),
        ProgressRecord(
          id: '2',
          goalId: 'g',
          title: 'b',
          durationMinutes: 90,
          day: const LocalDate(2026, 9, 3),
          createdAt: DateTime.utc(2026, 9, 3),
        ),
        ProgressRecord(
          id: '3',
          goalId: 'g',
          title: 'c',
          durationMinutes: 45,
          day: const LocalDate(2026, 9, 3),
          createdAt: DateTime.utc(2026, 9, 3),
        ),
      ];
      final days = StatsEngine.dailyInvestment(records, 2026, 9);
      expect(days, hasLength(2));
      expect(days[1].minutes, 135);
      expect(days[1].recordCount, 2);
      expect(StatsEngine.monthPeak(days), 135);
    });
  });
}
