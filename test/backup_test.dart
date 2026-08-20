/// T047：备份往返 / 冲突拒绝 / 损坏文件拒绝（contracts/backup-format.md）。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/backup/backup_exporter.dart';
import 'package:target/core/backup/backup_importer.dart';
import 'package:target/core/db/app_database.dart' as db;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:drift/native.dart';

/// 填充一个"什么都有"的库：goal×2 + 版本 + 步骤 + 打卡（含补签/撤销）
/// + 提醒 + 周回顾 + 忙碌会话 + 设置。
Future<db.AppDatabase> _seededDb() async {
  final database = db.AppDatabase(NativeDatabase.memory());
  final goals = GoalRepository(database);
  final checkIns = CheckInRepository(database);
  final reminders = ReminderRepository(database);
  final reviews = ReviewRepository(database);
  final settings = SettingsRepository(database);

  final habit = await goals.create(Goal(
    id: 'g-habit',
    name: '好好吃饭',
    kind: GoalKind.habit,
    iconKey: 'restaurant',
    colorKey: 'coral',
    createdAt: const LocalDate(2026, 8, 3),
    motivation: '为了晚上不胃胀',
    successCriterion: '晚饭吃八分饱',
    cueScene: '晚饭后',
  ));
  await goals.addInitial(
      habit.id, const WeekdaysFrequency({Weekday.mon, Weekday.wed}, 1),
      WeekStart.containing(const LocalDate(2026, 8, 3)));
  final milestone = await goals.create(Goal(
    id: 'g-ms',
    name: '发布 v1',
    kind: GoalKind.milestone,
    iconKey: 'flag',
    colorKey: 'teal',
    createdAt: const LocalDate(2026, 8, 5),
    deadline: const LocalDate(2026, 12, 31),
  ));
  await goals.addStep(MilestoneStep(
      id: 's1', goalId: milestone.id, title: '定稿', isDone: true,
      doneAt: DateTime.utc(2026, 8, 10)));
  await goals.addStep(MilestoneStep(id: 's2', goalId: milestone.id, title: '上架'));

  final c1 = await checkIns.add(habit.id, const LocalDate(2026, 8, 12),
      DateTime(2026, 8, 13, 9)); // 13 号补 12 号 → isBackfill
  await checkIns.revoke(c1.id);

  await reminders.upsert(
      Reminder(id: 'r-brief', time: const LocalTime(8, 0), isEnabled: true));
  await reminders.upsert(Reminder(
      id: 'r-goal', goalId: habit.id, time: const LocalTime(20, 30), isEnabled: false));

  await reviews.save(WeeklyReview(
    id: 'wr-1',
    weekStart: WeekStart.containing(const LocalDate(2026, 8, 10)),
    settledAt: DateTime.utc(2026, 8, 17, 1),
    snapshot: [
      const GoalWeekStat(
          goalId: 'g-habit',
          applicableDays: 2,
          metDays: 1,
          completionRate: 0.5,
          backfillCount: 1,
          busyModeApplied: true),
    ],
    note: '忙碌但稳住了',
    decision: const AdjustDecision(WeeklyFrequency(2)),
  ));

  final busyWeek = WeekStart.containing(const LocalDate(2026, 8, 17));
  await goals.addBusyMode(habit.id, busyWeek, const WeeklyFrequency(1));
  await goals.openSession(busyWeek,
      [BusyModeEntry(goalId: habit.id, downgraded: const WeeklyFrequency(1))],
      DateTime(2026, 8, 17, 20));
  final session =
      (await goals.watchSessions().first).single;
  await goals.endSession(session, DateTime(2026, 8, 21, 9));

  await settings.update(const Settings(
    dailyBriefTime: LocalTime(9, 30),
    onboardingCompleted: true,
    notificationDeniedAcknowledged: true,
  ));
  return database;
}

void main() {
  late db.AppDatabase source;
  late db.AppDatabase target;

  setUp(() async {
    source = await _seededDb();
    target = db.AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('往返：全实体 + 设置逐字段还原（先拒绝冲突，覆盖后一致）', () async {
    final exporter = BackupExporter(source);
    final json = await exporter.exportString(now: DateTime.utc(2026, 8, 22, 8));
    final importer = BackupImporter(target);

    // 目标库已有数据且未选择覆盖 → 拒绝，绝不静默合并。
    await GoalRepository(target).create(Goal(
        id: 'local',
        name: '本地目标',
        kind: GoalKind.habit,
        iconKey: 'star',
        colorKey: 'teal',
        createdAt: const LocalDate(2026, 8, 20)));
    final data = importer.parse(json);
    expect(() => importer.apply(data, overwriteLocal: false),
        throwsA(isA<BackupConflictException>()));
    expect((await GoalRepository(target).getGoals()).length, 1,
        reason: '拒绝后本地原样，无部分导入');

    // 覆盖导入 → 与源库逐实体一致。
    final summary = await importer.apply(data, overwriteLocal: true);
    final goals = await GoalRepository(target).getGoals();
    expect(goals.length, 2);
    expect(goals.firstWhere((g) => g.id == 'g-ms').deadline,
        const LocalDate(2026, 12, 31));
    // 002 B 案 envelope 三字段随备份往返（T016）。
    final restoredHabit = goals.firstWhere((g) => g.id == 'g-habit');
    expect(restoredHabit.motivation, '为了晚上不胃胀');
    expect(restoredHabit.successCriterion, '晚饭吃八分饱');
    expect(restoredHabit.cueScene, '晚饭后');
    // NULL 不导出键 → milestone 目标（未填 envelope）无这些键。
    final msMap = ((await BackupExporter(source).exportMap(
            now: DateTime.utc(2026, 8, 22)))['data'] as Map)['goals'] as List;
    expect(msMap.firstWhere((g) => g['id'] == 'g-ms'),
        isNot(containsPair('motivation', anything)));

    final versions = await GoalRepository(target).watchAllVersions().first;
    expect(versions.length, 2); // initial ×1 + busyMode ×1（addBusyMode 开启）
    expect(
        versions.where((v) => v.source == FrequencySource.busyMode).single
            .pattern,
        const WeeklyFrequency(1));

    final sessions = await GoalRepository(target).watchSessions().first;
    expect(sessions.single.entries.single.downgraded, const WeeklyFrequency(1));
    expect(sessions.single.endedAt, isNotNull);

    final steps =
        await GoalRepository(target).stepsOf('g-ms');
    expect(steps.length, 2);
    expect(steps.firstWhere((s) => s.id == 's1').doneAt, DateTime.utc(2026, 8, 10));

    final checkIns = await CheckInRepository(target).all();
    expect(checkIns.where((c) => c.status == CheckInStatus.revoked).length, 1);
    expect(
        checkIns
            .firstWhere((c) => c.day == const LocalDate(2026, 8, 12))
            .isBackfill,
        isTrue);

    final reminderRows = await ReminderRepository(target).all();
    expect(reminderRows.length, 2);
    expect(reminderRows.firstWhere((r) => r.id == 'r-goal').time,
        const LocalTime(20, 30));

    final reviewRows = await ReviewRepository(target).all();
    expect(reviewRows.single.note, '忙碌但稳住了');
    expect(reviewRows.single.decision, isA<AdjustDecision>());
    expect(reviewRows.single.snapshot.single.busyModeApplied, true);

    final settings = await SettingsRepository(target).get();
    expect(settings.dailyBriefTime, const LocalTime(9, 30));
    expect(settings.onboardingCompleted, true);

    // 摘要：各实体记录数。
    expect(summary.counts['goals'], 2);
    expect(summary.counts['checkIns'], checkIns.length);
    expect(summary.counts['weeklyReviews'], 1);
  });

  test('损坏文件：缺 data 键 / 缺实体键 / 字段类型错 → 明确报错不导入', () async {
    final importer = BackupImporter(target);
    final exporter = BackupExporter(source);
    final map = await exporter.exportMap(now: DateTime.utc(2026, 8, 22));

    map.remove('data');
    expect(() => BackupImporter(target).parse(exporter.encode(map)),
        throwsA(isA<BackupFormatException>()));

    final map2 = await exporter.exportMap(now: DateTime.utc(2026, 8, 22));
    (map2['data'] as Map).remove('checkIns');
    expect(() => importer.parse(exporter.encode(map2)),
        throwsA(isA<BackupFormatException>()));

    final map3 = await exporter.exportMap(now: DateTime.utc(2026, 8, 22));
    ((map3['data'] as Map)['goals'] as List).first['name'] = 123;
    expect(() => importer.parse(exporter.encode(map3)),
        throwsA(isA<BackupFormatException>()));
  });

  test('更高版本 → 拒绝并提示升级', () async {
    final exporter = BackupExporter(source);
    final map = await exporter.exportMap(now: DateTime.utc(2026, 8, 22));
    map['version'] = 99;
    expect(
        () => BackupImporter(target).parse(exporter.encode(map)),
        throwsA(isA<BackupFormatException>().having(
            (e) => e.message, 'message', contains('升级'))));
  });

  test('format 头不对 / 非 JSON → 拒绝', () async {
    expect(() => BackupImporter(target).parse('not json'),
        throwsA(isA<BackupFormatException>()));
    expect(
        () => BackupImporter(target).parse('{"format":"other","version":1,"data":{}}'),
        throwsA(isA<BackupFormatException>()));
  });

  test('导出文件头：format/version/exportedAt + 文件名（FR-015）', () async {
    final map = await BackupExporter(source)
        .exportMap(now: DateTime(2026, 8, 22, 8, 30));
    expect(map['format'], 'target-backup');
    expect(map['version'], 1);
    expect(map['exportedAt'], contains('2026-08-22'));
    expect(backupFileName(DateTime(2026, 8, 22)), 'Target-备份-20260822.targetbackup');
  });

  test('001 备份（goals 无 envelope 键）→ 导入成功，新字段为 NULL（T016）', () async {
    // 手工构造 001 形态的备份：goals 只有旧键。
    const v1Json = '''
    {
      "format": "target-backup",
      "version": 1,
      "exportedAt": "2026-08-20T00:00:00.000Z",
      "data": {
        "goals": [
          {"id": "g-old", "name": "好好吃饭", "kind": "habit",
           "iconKey": "restaurant", "colorKey": "coral",
           "status": "active", "createdAt": "2026-08-03"}
        ],
        "frequencyVersions": [], "busySessions": [], "checkIns": [],
        "milestoneSteps": [], "reminders": [], "weeklyReviews": [],
        "settings": {"dailyBriefTime": "08:00",
          "onboardingCompleted": true,
          "notificationDeniedAcknowledged": false}
      }
    }''';
    final importer = BackupImporter(target);
    final summary = await importer.apply(importer.parse(v1Json),
        overwriteLocal: true);
    expect(summary.counts['goals'], 1);
    final goal = (await GoalRepository(target).getGoals()).single;
    expect(goal.name, '好好吃饭');
    expect(goal.motivation, isNull);
    expect(goal.successCriterion, isNull);
    expect(goal.cueScene, isNull);
  });
}
