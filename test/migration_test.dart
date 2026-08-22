// T015：v1 → v2 迁移（B 案 envelope 可空列）——既有数据零丢失 + 新列可写。
// 003 T009：schemaVersion 升 3 后同库直迁 v3——goalType/iconKey/colorKey
// 断言改按 research D3 重映射口径（完整四分支对账见 T010 用例）。
import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';

/// v1 的 goals 建表语句（drift v1 生成形态：snake_case 列、无 envelope 列）。
const _v1GoalsDdl = 'CREATE TABLE IF NOT EXISTS "goals" ('
    '"id" TEXT NOT NULL PRIMARY KEY, "name" TEXT NOT NULL, '
    '"kind" TEXT NOT NULL, "icon_key" TEXT NOT NULL, '
    '"color_key" TEXT NOT NULL, "status" TEXT NOT NULL, '
    '"created_at" TEXT NOT NULL, "deadline" TEXT NULL);';

/// 只含 v1 goals 表 + 迁移会触碰的三张关联表的旧库（schemaVersion=1；
/// 真实用户库 onCreate 起九表齐全，此处按需最小化）。
class _V1Database extends AppDatabase {
  _V1Database(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // Migrator 无 customStatement；建 v1 表直接走库级语句。
        onCreate: (m) async {
          await customStatement(_v1GoalsDdl);
          // v3 迁移触碰的关联表（003 T009）：reminders/settings_rows 被
          // ALTER、frequency_versions 被类型化读取。
          await customStatement(
              'CREATE TABLE IF NOT EXISTS "reminders" ("id" TEXT NOT NULL '
              'PRIMARY KEY, "goal_id" TEXT NULL, "time" TEXT NOT NULL, '
              '"is_enabled" INTEGER NOT NULL)');
          await customStatement(
              'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
              'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
              '"onboarding_completed" INTEGER NOT NULL, '
              '"notification_denied_acknowledged" INTEGER NOT NULL)');
          await customStatement(
              'CREATE TABLE IF NOT EXISTS "frequency_versions" ("id" TEXT NOT '
              'NULL PRIMARY KEY, "goal_id" TEXT NOT NULL, '
              '"effective_from_week" TEXT NOT NULL, "pattern" TEXT NOT NULL, '
              '"source" TEXT NOT NULL)');
        },
      );
}

/// v2 的 goals 建表语句（v1 形态 + B 案 envelope 三可空列）。
const _v2GoalsDdl = 'CREATE TABLE IF NOT EXISTS "goals" ('
    '"id" TEXT NOT NULL PRIMARY KEY, "name" TEXT NOT NULL, '
    '"kind" TEXT NOT NULL, "icon_key" TEXT NOT NULL, '
    '"color_key" TEXT NOT NULL, "status" TEXT NOT NULL, '
    '"created_at" TEXT NOT NULL, "deadline" TEXT NULL, '
    '"motivation" TEXT NULL, "success_criterion" TEXT NULL, '
    '"cue_scene" TEXT NULL);';

/// v2 旧库（schemaVersion=2）：goals 带 envelope 列，关联表齐全——
/// 003 T010 四分支对账的存量形态（升级只走 v2→v3 分支）。
class _V2Database extends AppDatabase {
  _V2Database(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement(_v2GoalsDdl);
          await customStatement(
              'CREATE TABLE IF NOT EXISTS "reminders" ("id" TEXT NOT NULL '
              'PRIMARY KEY, "goal_id" TEXT NULL, "time" TEXT NOT NULL, '
              '"is_enabled" INTEGER NOT NULL)');
          await customStatement(
              'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
              'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
              '"onboarding_completed" INTEGER NOT NULL, '
              '"notification_denied_acknowledged" INTEGER NOT NULL)');
          await customStatement(
              'CREATE TABLE IF NOT EXISTS "frequency_versions" ("id" TEXT NOT '
              'NULL PRIMARY KEY, "goal_id" TEXT NOT NULL, '
              '"effective_from_week" TEXT NOT NULL, "pattern" TEXT NOT NULL, '
              '"source" TEXT NOT NULL)');
          await customStatement(
              'CREATE TABLE IF NOT EXISTS "check_ins" ("id" TEXT NOT NULL '
              'PRIMARY KEY, "goal_id" TEXT NOT NULL, "day" TEXT NOT NULL, '
              '"created_at" TEXT NOT NULL, "is_backfill" INTEGER NOT NULL, '
              '"status" TEXT NOT NULL)');
        },
      );
}

void main() {
  late Directory tmp;
  late File file;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('target_migration');
    file = File('${tmp.path}/db.sqlite');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('v1→v3：既有目标零丢失（值域按 D3 重映射），新列 NULL 可读写',
      () async {
    // 1) v1 schema 建库 + 两行旧数据（普通习惯 / 带截止日的里程碑）。
    {
      final v1 = _V1Database(NativeDatabase(file));
      await v1.customStatement(
          "INSERT INTO goals VALUES ('g1','好好吃饭','habit','meal','coral',"
          "'active','2026-08-01',NULL)");
      await v1.customStatement(
          "INSERT INTO goals VALUES ('g2','冈仁波齐徒步','milestone','travel',"
          "'indigo','active','2026-08-01','2026-10-01')");
      await v1.close();
    }

    // 2) v2 打开同一文件 → drift 按 PRAGMA user_version=1 走 onUpgrade。
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final repo = GoalRepository(db);

    final goals = await repo.getGoals();
    expect(goals, hasLength(2));

    final meal = goals.firstWhere((g) => g.id == 'g1');
    expect(meal.name, '好好吃饭');
    // v3 重映射（D3）：无截止无频率的 habit → longTerm（实体桥接为
    // milestone）；iconKey meal→restaurant；colorKey 退役置 NULL（''）。
    expect(meal.kind, GoalKind.milestone);
    expect(meal.colorKey, '');
    expect(meal.deadline, isNull);
    // 新列默认 NULL —— 即「补一句为什么」渐进补全入口的语义（T014）。
    expect(meal.motivation, isNull);
    expect(meal.successCriterion, isNull);
    expect(meal.cueScene, isNull);

    final trek = goals.firstWhere((g) => g.id == 'g2');
    expect(trek.kind, GoalKind.milestone);
    expect(trek.deadline, LocalDate.parse('2026-10-01')); // 截止日不丢

    // 3) 旧目标渐进补全：补写三字段 → 回读持久化。
    await repo.update(meal.copyWith(
      motivation: '为了晚上不胃胀',
      successCriterion: '晚饭吃八分饱',
      cueScene: '晚饭后',
    ));
    final updated = (await repo.getGoals()).firstWhere((g) => g.id == 'g1');
    expect(updated.motivation, '为了晚上不胃胀');
    expect(updated.successCriterion, '晚饭吃八分饱');
    expect(updated.cueScene, '晚饭后');
  });

  test('v2 新建：B 案字段一次落库（envelope 全填 + 全空两形态）', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepository(db);
    final today = LocalDate.fromDateTime(DateTime.now());

    await repo.create(Goal(
      name: '每天散步 20 分钟',
      kind: GoalKind.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      createdAt: today,
      motivation: '为了身体轻一点',
      successCriterion: '散步 20 分钟',
      cueScene: '不打扰',
    ));
    await repo.create(Goal(
      name: '好好吃饭',
      kind: GoalKind.habit,
      iconKey: 'meal',
      colorKey: 'coral',
      createdAt: today,
    ));

    final goals = await repo.getGoals();
    final walk = goals.firstWhere((g) => g.name.startsWith('每天散步'));
    expect(walk.motivation, '为了身体轻一点');
    expect(walk.successCriterion, '散步 20 分钟');
    expect(walk.cueScene, '不打扰');
    final meal = goals.firstWhere((g) => g.name == '好好吃饭');
    expect(meal.motivation, isNull);
    expect(meal.successCriterion, isNull);
    expect(meal.cueScene, isNull);
  });

  test('v1→v2：check-ins 等关联数据随库完整保留', () async {
    // v1 库里再放一行打卡，验证迁移不动其他表的数据。
    {
      final v1 = _V1Database(NativeDatabase(file));
      await v1.customStatement(
          "INSERT INTO goals VALUES ('g1','好好吃饭','habit','meal','coral',"
          "'active','2026-08-01',NULL)");
      await v1.customStatement(
          'CREATE TABLE IF NOT EXISTS "check_ins" ("id" TEXT NOT NULL PRIMARY KEY, '
          '"goal_id" TEXT NOT NULL, "day" TEXT NOT NULL, "created_at" TEXT NOT NULL, '
          '"is_backfill" INTEGER NOT NULL, "status" TEXT NOT NULL)');
      await v1.customStatement(
          "INSERT INTO check_ins VALUES ('c1','g1','2026-08-19',"
          "'2026-08-19T12:00:00.000Z',0,'valid')");
      await v1.close();
    }

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final rows = await db.customSelect('SELECT * FROM check_ins').get();
    expect(rows, hasLength(1));
    expect(rows.first.read<String>('goal_id'), 'g1');
    expect(rows.first.read<String>('status'), 'valid');
  });

  // 003 T010：v2→v3 四分支存量对账——升级前后目标/打卡/记录逐项一致，
  // goalType/iconKey/colorKey/cadence 按 research D3 口径落位。
  test('v2→v3：四分支对账（shortTerm/habit×daily/habit×weekly/paused→longTerm）',
      () async {
    // 1) v2 存量：四分支各一目标 + 频率版本/提醒/打卡/每日概要。
    {
      final v2 = _V2Database(NativeDatabase(file));
      // gs：milestone+截止 → shortTerm（icon travel→flight）。
      await v2.customStatement(
          "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
          "created_at,deadline) VALUES ('gs','冈仁波齐徒步','milestone',"
          "'travel','indigo','active','2026-08-01','2026-10-01')");
      // gd：habit+daily 版本，已有提醒 → cadence=daily 补档。
      await v2.customStatement(
          "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
          "created_at) VALUES ('gd','好好吃饭','habit','meal','coral',"
          "'active','2026-08-01')");
      await v2.customStatement(
          "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
          "pattern,source) VALUES ('fv-d','gd','2026-08-03',"
          "'{\"type\":\"daily\",\"targetPerDay\":1}','initial')");
      await v2.customStatement(
          "INSERT INTO reminders (id,goal_id,time,is_enabled) VALUES "
          "('r-d','gd','08:30',1)");
      // gw：habit+weekly 版本，无提醒 → cadence=weekly + 补默认行 09:00 关。
      await v2.customStatement(
          "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
          "created_at) VALUES ('gw','每周跑三次','habit','fitness','sage',"
          "'active','2026-08-01')");
      await v2.customStatement(
          "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
          "pattern,source) VALUES ('fv-w','gw','2026-08-03',"
          "'{\"type\":\"weekly\",\"timesPerWeek\":3}','initial')");
      // gp：暂停 milestone，无截止无频率 → longTerm（icon star→explore）。
      await v2.customStatement(
          "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
          "created_at) VALUES ('gp','学钢琴','milestone','star','amber',"
          "'paused','2026-07-01')");
      // 打卡：gs 2 条（valid+revoked，各含补签）、gd 2 条 valid（1 补签）。
      await v2.customStatement(
          "INSERT INTO check_ins (id,goal_id,day,created_at,is_backfill,"
          "status) VALUES ('c1','gs','2026-08-19',"
          "'2026-08-19T12:00:00.000Z',0,'valid'),('c2','gs','2026-08-10',"
          "'2026-08-19T12:00:00.000Z',1,'revoked'),('c3','gd','2026-08-19',"
          "'2026-08-19T12:00:00.000Z',0,'valid'),('c4','gd','2026-08-18',"
          "'2026-08-19T12:00:00.000Z',1,'valid')");
      // 全局每日概要（goal_id NULL）：不参与 cadence 补档。
      await v2.customStatement(
          "INSERT INTO reminders (id,goal_id,time,is_enabled) VALUES "
          "('r-brief',NULL,'08:00',1)");
      await v2.close();
    }

    // 2) v3 打开同一文件 → onUpgrade 走 _migrateV3。
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    // goalType 四分支映射 + iconKey 换域 + colorKey 退役置 NULL。
    final goals = await db.customSelect(
        'SELECT id, goal_type, icon_key, color_key, status, deadline '
        'FROM goals ORDER BY id',
    ).get();
    expect(goals, hasLength(4));
    String cell(row, String c) => row.read<String>(c);
    final byId = {
      for (final g in goals) cell(g, 'id'): g,
    };
    expect(cell(byId['gs']!, 'goal_type'), 'shortTerm');
    expect(cell(byId['gs']!, 'icon_key'), 'flight');
    expect(byId['gs']!.readNullable<String>('deadline'), '2026-10-01');
    expect(cell(byId['gd']!, 'goal_type'), 'habit');
    expect(cell(byId['gd']!, 'icon_key'), 'restaurant');
    expect(cell(byId['gw']!, 'goal_type'), 'habit');
    expect(cell(byId['gw']!, 'icon_key'), 'directions_run');
    expect(cell(byId['gp']!, 'goal_type'), 'longTerm');
    expect(cell(byId['gp']!, 'icon_key'), 'explore');
    expect(cell(byId['gp']!, 'status'), 'paused'); // 状态机不动
    for (final g in goals) {
      expect(g.readNullable<String>('color_key'), isNull,
          reason: '${cell(g, 'id')} colorKey 应退役置 NULL');
    }

    // 打卡逐项一致：计数/状态/补签/归属原样。
    final checkIns = await db.customSelect(
        'SELECT goal_id, status, is_backfill, day FROM check_ins ORDER BY id',
    ).get();
    expect(checkIns, hasLength(4));
    expect(checkIns.where((c) => c.read<String>('goal_id') == 'gs'),
        hasLength(2));
    expect(
        checkIns.where((c) =>
            c.read<String>('goal_id') == 'gs' &&
            c.read<String>('status') == 'revoked'),
        hasLength(1));
    expect(checkIns.where((c) => c.read<bool>('is_backfill')), hasLength(2));
    expect(
        checkIns.map((c) => c.read<String>('day')).toSet(), contains('2026-08-10'));

    // FrequencyVersions 原样保全（停写整表，存量不动）。
    final versions = await db.customSelect(
        'SELECT goal_id, pattern, source, effective_from_week '
        'FROM frequency_versions ORDER BY id',
    ).get();
    expect(versions, hasLength(2));
    expect(versions.first.read<String>('pattern'),
        '{"type":"daily","targetPerDay":1}');
    expect(versions.first.read<String>('source'), 'initial');
    expect(versions.first.read<String>('effective_from_week'), '2026-08-03');

    // 提醒：gd 补档 daily；gw 补默认行（09:00 关 weekly）；
    // 每日概要不参与；gs/gp（非 habit）无提醒行——不补默认行（D3）。
    final reminders = await db.customSelect(
        'SELECT goal_id, time, is_enabled, cadence FROM reminders',
    ).get();
    expect(reminders, hasLength(3));
    final gd = reminders
        .firstWhere((r) => r.readNullable<String>('goal_id') == 'gd');
    expect(gd.read<String>('time'), '08:30');
    expect(gd.read<bool>('is_enabled'), true);
    expect(gd.readNullable<String>('cadence'), 'daily');
    final gw = reminders
        .firstWhere((r) => r.readNullable<String>('goal_id') == 'gw');
    expect(gw.read<String>('time'), '09:00');
    expect(gw.read<bool>('is_enabled'), false);
    expect(gw.readNullable<String>('cadence'), 'weekly');
    final brief =
        reminders.firstWhere((r) => r.readNullable<String>('goal_id') == null);
    expect(brief.readNullable<String>('cadence'), isNull);
  });
}
