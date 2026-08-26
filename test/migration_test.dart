// T015：v1 → v2 迁移（B 案 envelope 可空列）——既有数据零丢失 + 新列可写。
// 003 T009：schemaVersion 升 3 后同库直迁 v3——goalType/iconKey/colorKey
// 断言改按 research D3 重映射口径（完整四分支对账见 T010 用例）。
import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy, Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/app_database.dart'
    as app_db
    show GoalsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart' show WeeklyFrequency;
import 'package:target/core/models/goal_icon_catalog.dart' show GoalIconDomain;
import 'package:target/core/stats/stats_engine.dart';
import 'package:target/features/settings/reminder_service.dart';

/// v1 的 goals 建表语句（drift v1 生成形态：snake_case 列、无 envelope 列）。
const _v1GoalsDdl =
    'CREATE TABLE IF NOT EXISTS "goals" ('
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
        '"is_enabled" INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
        'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
        '"onboarding_completed" INTEGER NOT NULL, '
        '"notification_denied_acknowledged" INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "frequency_versions" ("id" TEXT NOT '
        'NULL PRIMARY KEY, "goal_id" TEXT NOT NULL, '
        '"effective_from_week" TEXT NOT NULL, "pattern" TEXT NOT NULL, '
        '"source" TEXT NOT NULL)',
      );
      // v4 迁移（T044）触碰 check_ins（ADD COLUMN note）——一并建。
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "check_ins" ("id" TEXT NOT NULL '
        'PRIMARY KEY, "goal_id" TEXT NOT NULL, "day" TEXT NOT NULL, '
        '"created_at" TEXT NOT NULL, "is_backfill" INTEGER NOT NULL, '
        '"status" TEXT NOT NULL)',
      );
      await customStatement(_v5MilestoneStepsDdl);
    },
  );
}

/// v2 的 goals 建表语句（v1 形态 + B 案 envelope 三可空列）。
const _v2GoalsDdl =
    'CREATE TABLE IF NOT EXISTS "goals" ('
    '"id" TEXT NOT NULL PRIMARY KEY, "name" TEXT NOT NULL, '
    '"kind" TEXT NOT NULL, "icon_key" TEXT NOT NULL, '
    '"color_key" TEXT NOT NULL, "status" TEXT NOT NULL, '
    '"created_at" TEXT NOT NULL, "deadline" TEXT NULL, '
    '"motivation" TEXT NULL, "success_criterion" TEXT NULL, '
    '"cue_scene" TEXT NULL);';

const _v5GoalsDdl =
    'CREATE TABLE IF NOT EXISTS "goals" ('
    '"id" TEXT NOT NULL PRIMARY KEY, "name" TEXT NOT NULL, '
    '"goal_type" TEXT NOT NULL, "icon_key" TEXT NOT NULL, '
    '"color_key" TEXT NULL, "status" TEXT NOT NULL, '
    '"created_at" TEXT NOT NULL, "deadline" TEXT NULL, '
    '"motivation" TEXT NULL, "success_criterion" TEXT NULL, '
    '"cue_scene" TEXT NULL, "achieved_at" TEXT NULL);';

const _v5MilestoneStepsDdl =
    'CREATE TABLE IF NOT EXISTS "milestone_steps" ('
    '"id" TEXT NOT NULL PRIMARY KEY, "goal_id" TEXT NOT NULL, '
    '"title" TEXT NOT NULL, "is_done" INTEGER NOT NULL, '
    '"done_at" TEXT NULL);';

const _frequencyVersionsDdl =
    'CREATE TABLE IF NOT EXISTS "frequency_versions" ('
    '"id" TEXT NOT NULL PRIMARY KEY, "goal_id" TEXT NOT NULL, '
    '"effective_from_week" TEXT NOT NULL, "pattern" TEXT NOT NULL, '
    '"source" TEXT NOT NULL)';

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
        '"is_enabled" INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
        'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
        '"onboarding_completed" INTEGER NOT NULL, '
        '"notification_denied_acknowledged" INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "frequency_versions" ("id" TEXT NOT '
        'NULL PRIMARY KEY, "goal_id" TEXT NOT NULL, '
        '"effective_from_week" TEXT NOT NULL, "pattern" TEXT NOT NULL, '
        '"source" TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "check_ins" ("id" TEXT NOT NULL '
        'PRIMARY KEY, "goal_id" TEXT NOT NULL, "day" TEXT NOT NULL, '
        '"created_at" TEXT NOT NULL, "is_backfill" INTEGER NOT NULL, '
        '"status" TEXT NOT NULL)',
      );
      await customStatement(_v5MilestoneStepsDdl);
    },
  );
}

/// v3 旧库（schemaVersion=3）：check_ins 尚无 note 列——T044 的 v4 存量形态。
/// v4/v5 迁移触碰 check_ins 与 settings_rows（均纯 ADD COLUMN），其余
/// 表从简不建（FK 未开 pragma，插入不受影响）。
class _V3Database extends AppDatabase {
  _V3Database(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(_v5GoalsDdl);
      await customStatement(_v5MilestoneStepsDdl);
      await customStatement(_frequencyVersionsDdl);
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "check_ins" ("id" TEXT NOT NULL '
        'PRIMARY KEY, "goal_id" TEXT NOT NULL, "day" TEXT NOT NULL, '
        '"created_at" TEXT NOT NULL, "is_backfill" INTEGER NOT NULL, '
        '"status" TEXT NOT NULL)',
      );
      // v5 迁移（004 T003）触碰 settings_rows——v3 形态
      //（_migrateV3 已加 nickname/avatar_key 两可空列）。
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
        'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
        '"nickname" TEXT NULL, "avatar_key" TEXT NULL, '
        '"onboarding_completed" INTEGER NOT NULL, '
        '"notification_denied_acknowledged" INTEGER NOT NULL)',
      );
    },
  );
}

/// v4 旧库（schemaVersion=4）：settings_rows 尚无 theme_mode 列——
/// 004 T003 的 v5 存量形态。v5 迁移只触碰 settings（纯 ADD COLUMN），
/// 他表从简不建（沿 _V3Database 先例）。
class _V4Database extends AppDatabase {
  _V4Database(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(_v5GoalsDdl);
      await customStatement(_v5MilestoneStepsDdl);
      await customStatement(_frequencyVersionsDdl);
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
        'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
        '"nickname" TEXT NULL, "avatar_key" TEXT NULL, '
        '"onboarding_completed" INTEGER NOT NULL, '
        '"notification_denied_acknowledged" INTEGER NOT NULL)',
      );
    },
  );
}

/// v5 旧库：尚无目标规划、里程碑排序与评分算法边界字段。
class _V5Database extends AppDatabase {
  _V5Database(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(_v5GoalsDdl);
      await customStatement(_v5MilestoneStepsDdl);
      await customStatement(_frequencyVersionsDdl);
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
        'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
        '"nickname" TEXT NULL, "avatar_key" TEXT NULL, '
        '"onboarding_completed" INTEGER NOT NULL, '
        '"notification_denied_acknowledged" INTEGER NOT NULL, '
        '"theme_mode" TEXT NULL)',
      );
    },
  );
}

/// v6 旧库：已有目标规划字段，尚无统一频率与归档时间字段。
class _V6Database extends AppDatabase {
  _V6Database(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "goals" ('
        '"id" TEXT NOT NULL PRIMARY KEY, "name" TEXT NOT NULL, '
        '"goal_type" TEXT NOT NULL, "icon_key" TEXT NOT NULL, '
        '"progress_cadence_days" INTEGER NULL, '
        '"category_override" TEXT NULL, "target_date" TEXT NULL, '
        '"habit_target_per_week" INTEGER NULL, "color_key" TEXT NULL, '
        '"status" TEXT NOT NULL, "created_at" TEXT NOT NULL, '
        '"deadline" TEXT NULL, "achieved_at" TEXT NULL, '
        '"motivation" TEXT NULL, "success_criterion" TEXT NULL, '
        '"cue_scene" TEXT NULL)',
      );
      await customStatement(_frequencyVersionsDdl);
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

  test('v5→v6：规划默认值回填且既有里程碑顺序保持', () async {
    {
      final v5 = _V5Database(NativeDatabase(file));
      await v5.customStatement(
        "INSERT INTO goals (id,name,goal_type,icon_key,status,created_at,deadline) "
        "VALUES ('long','学潜水','longTerm','scuba_diving','active','2026-08-01',NULL),"
        "('short','报名考试','shortTerm','school','active','2026-08-01','2026-09-01')",
      );
      await v5.customStatement(
        "INSERT INTO milestone_steps VALUES "
        "('m2','long','完成 DSD',1,'2026-08-20T10:00:00.000Z'),"
        "('m1','long','学习理论',0,NULL)",
      );
      await v5.customStatement(
        "INSERT INTO settings_rows VALUES "
        "(1,'08:00',NULL,NULL,0,0,'light')",
      );
      await v5.close();
    }

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final goals = await db.select(db.goals).get();
    expect(goals.firstWhere((g) => g.id == 'long').progressCadenceDays, 14);
    expect(goals.firstWhere((g) => g.id == 'short').progressCadenceDays, 7);
    expect(
      goals.firstWhere((g) => g.id == 'short').targetDate,
      const LocalDate(2026, 9, 1),
    );
    final steps = await GoalRepository(db).stepsOf('long');
    expect(steps.map((s) => s.id), ['m2', 'm1']);
    expect(steps.map((s) => s.position), [0, 1]);
    final settings = await SettingsRepository(db).get();
    expect(settings.defaultShortCadenceDays, 7);
    expect(settings.defaultLongCadenceDays, 14);
    expect(settings.scoreAlgorithmStartedOn, isNotNull);
  });

  test('v6→v7：日期、频率、分类和归档语义迁移且历史不丢失', () async {
    {
      final v6 = _V6Database(NativeDatabase(file));
      await v6.customStatement(
        "INSERT INTO goals "
        "(id,name,goal_type,icon_key,status,created_at,deadline,"
        "progress_cadence_days,habit_target_per_week) VALUES "
        "('dated','拿到潜水证','shortTerm','pool','active',"
        "'2026-08-01','2026-10-01',7,NULL),"
        "('habit','保持跑步','habit','directions_run','active',"
        "'2026-08-01',NULL,7,3),"
        "('old-archive','旧目标','longTerm','explore','archived',"
        "'2026-08-01',NULL,14,NULL)",
      );
      await v6.customStatement(
        "INSERT INTO frequency_versions "
        "(id,goal_id,effective_from_week,pattern,source) VALUES "
        "('habit-earlier','habit','2026-08-03',"
        "'{\"type\":\"weekly\",\"timesPerWeek\":2}','initial'),"
        "('habit-later','habit','2026-08-10',"
        "'{\"type\":\"weekly\",\"timesPerWeek\":4}','userEdit')",
      );
      await v6.close();
    }

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final goals = await GoalRepository(db).getGoals();
    final byId = {for (final goal in goals) goal.id: goal};

    expect(byId['dated']!.targetDate, const LocalDate(2026, 10, 1));
    expect(byId['dated']!.frequency, isNull);
    expect(byId['habit']!.frequency, const WeeklyFrequency(4));
    expect(byId['dated']!.categoryOverride, GoalIconDomain.fitness);
    expect(byId['old-archive']!.archivedAt, isNotNull);
    expect(byId['old-archive']!.status, GoalStatus.paused);
  });

  test('v7 新建库：统一频率和归档时间列可空且经 Drift 往返', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final archivedAt = DateTime.utc(2026, 8, 26, 4, 30);

    await db
        .into(db.goals)
        .insert(
          app_db.GoalsCompanion.insert(
            id: 'planned',
            name: '已有统一计划字段',
            goalType: GoalType.habit,
            iconKey: 'directions_run',
            status: GoalStatus.paused,
            createdAt: const LocalDate(2026, 8, 1),
            frequencyPattern: const Value(WeeklyFrequency(4)),
            archivedAt: Value(archivedAt),
          ),
        );
    await db
        .into(db.goals)
        .insert(
          app_db.GoalsCompanion.insert(
            id: 'empty',
            name: '允许空统一计划字段',
            goalType: GoalType.longTerm,
            iconKey: 'explore',
            status: GoalStatus.active,
            createdAt: const LocalDate(2026, 8, 1),
          ),
        );

    final byId = {
      for (final row in await db.select(db.goals).get()) row.id: row,
    };
    expect(byId['planned']!.frequencyPattern, const WeeklyFrequency(4));
    expect(byId['planned']!.archivedAt, archivedAt);
    expect(byId['empty']!.frequencyPattern, isNull);
    expect(byId['empty']!.archivedAt, isNull);
  });

  test('v1→v3：既有目标零丢失（值域按 D3 重映射），新列 NULL 可读写', () async {
    // 1) v1 schema 建库 + 两行旧数据（普通习惯 / 带截止日的里程碑）。
    {
      final v1 = _V1Database(NativeDatabase(file));
      await v1.customStatement(
        "INSERT INTO goals VALUES ('g1','好好吃饭','habit','meal','coral',"
        "'active','2026-08-01',NULL)",
      );
      await v1.customStatement(
        "INSERT INTO goals VALUES ('g2','冈仁波齐徒步','milestone','travel',"
        "'indigo','active','2026-08-01','2026-10-01')",
      );
      await v1.close();
    }

    // 2) v2 打开同一文件 → drift 按 PRAGMA user_version=1 走 onUpgrade。
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final rows = await db.select(db.goals).get();
    expect(rows, hasLength(2));

    final meal = rows.firstWhere((g) => g.id == 'g1');
    expect(meal.name, '好好吃饭');
    // v3 重映射（D3）：无截止无频率的 habit → longTerm；
    // iconKey meal→restaurant；colorKey 退役置 NULL（实体 ''）。
    expect(meal.goalType, GoalType.longTerm);
    expect(meal.colorKey, isNull);
    expect(meal.deadline, isNull);
    // 新列默认 NULL —— 即「补一句为什么」渐进补全入口的语义（T014）。
    expect(meal.motivation, isNull);
    expect(meal.successCriterion, isNull);
    expect(meal.cueScene, isNull);

    final trek = rows.firstWhere((g) => g.id == 'g2');
    // 里程碑+截止 → shortTerm（D3 决策树第一支）。
    expect(trek.goalType, GoalType.shortTerm);
    expect(trek.deadline, LocalDate.parse('2026-10-01')); // 截止日不丢
    expect(trek.targetDate, LocalDate.parse('2026-10-01'));

    // 3) 旧目标渐进补全：补写三字段 → 回读持久化。
    await db.customUpdate(
      'UPDATE goals SET motivation = ?, success_criterion = ?, cue_scene = ? '
      'WHERE id = ?',
      variables: const [
        Variable('为了晚上不胃胀'),
        Variable('晚饭吃八分饱'),
        Variable('晚饭后'),
        Variable('g1'),
      ],
      updates: {db.goals},
    );
    final updated = (await db.select(db.goals).get()).firstWhere(
      (g) => g.id == 'g1',
    );
    expect(updated.motivation, '为了晚上不胃胀');
    expect(updated.successCriterion, '晚饭吃八分饱');
    expect(updated.cueScene, '晚饭后');
  });

  test('v2 新建：B 案字段一次落库（envelope 全填 + 全空两形态）', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepository(db);
    final today = LocalDate.fromDateTime(DateTime.now());

    await repo.create(
      Goal(
        name: '每天散步 20 分钟',
        goalType: GoalType.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: today,
        motivation: '为了身体轻一点',
        successCriterion: '散步 20 分钟',
        cueScene: '不打扰',
      ),
    );
    await repo.create(
      Goal(
        name: '好好吃饭',
        goalType: GoalType.habit,
        iconKey: 'meal',
        colorKey: 'coral',
        createdAt: today,
      ),
    );

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
        "'active','2026-08-01',NULL)",
      );
      await v1.customStatement(
        'CREATE TABLE IF NOT EXISTS "check_ins" ("id" TEXT NOT NULL PRIMARY KEY, '
        '"goal_id" TEXT NOT NULL, "day" TEXT NOT NULL, "created_at" TEXT NOT NULL, '
        '"is_backfill" INTEGER NOT NULL, "status" TEXT NOT NULL)',
      );
      await v1.customStatement(
        "INSERT INTO check_ins VALUES ('c1','g1','2026-08-19',"
        "'2026-08-19T12:00:00.000Z',0,'valid')",
      );
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
  test('v2→v3：四分支对账（shortTerm/habit×daily/habit×weekly/paused→longTerm）', () async {
    // 1) v2 存量：四分支各一目标 + 频率版本/提醒/打卡/每日概要。
    {
      final v2 = _V2Database(NativeDatabase(file));
      // gs：milestone+截止 → shortTerm（icon travel→flight）。
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at,deadline) VALUES ('gs','冈仁波齐徒步','milestone',"
        "'travel','indigo','active','2026-08-01','2026-10-01')",
      );
      // gd：habit+daily 版本，已有提醒 → cadence=daily 补档。
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('gd','好好吃饭','habit','meal','coral',"
        "'active','2026-08-01')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-d','gd','2026-08-03',"
        "'{\"type\":\"daily\",\"targetPerDay\":1}','initial')",
      );
      await v2.customStatement(
        "INSERT INTO reminders (id,goal_id,time,is_enabled) VALUES "
        "('r-d','gd','08:30',1)",
      );
      // gw：habit+weekly 版本，无提醒 → cadence=weekly + 补默认行 09:00 关。
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('gw','每周跑三次','habit','fitness','sage',"
        "'active','2026-08-01')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-w','gw','2026-08-03',"
        "'{\"type\":\"weekly\",\"timesPerWeek\":3}','initial')",
      );
      // gp：暂停 milestone，无截止无频率 → longTerm（icon star→explore）。
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('gp','学钢琴','milestone','star','amber',"
        "'paused','2026-07-01')",
      );
      // 打卡：gs 2 条（valid+revoked，各含补签）、gd 2 条 valid（1 补签）。
      await v2.customStatement(
        "INSERT INTO check_ins (id,goal_id,day,created_at,is_backfill,"
        "status) VALUES ('c1','gs','2026-08-19',"
        "'2026-08-19T12:00:00.000Z',0,'valid'),('c2','gs','2026-08-10',"
        "'2026-08-19T12:00:00.000Z',1,'revoked'),('c3','gd','2026-08-19',"
        "'2026-08-19T12:00:00.000Z',0,'valid'),('c4','gd','2026-08-18',"
        "'2026-08-19T12:00:00.000Z',1,'valid')",
      );
      // 全局每日概要（goal_id NULL）：不参与 cadence 补档。
      await v2.customStatement(
        "INSERT INTO reminders (id,goal_id,time,is_enabled) VALUES "
        "('r-brief',NULL,'08:00',1)",
      );
      await v2.close();
    }

    // 2) v3 打开同一文件 → onUpgrade 走 _migrateV3。
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    // goalType 四分支映射 + iconKey 换域 + colorKey 退役置 NULL。
    final goals = await db
        .customSelect(
          'SELECT id, goal_type, icon_key, color_key, status, deadline '
          'FROM goals ORDER BY id',
        )
        .get();
    expect(goals, hasLength(4));
    String cell(row, String c) => row.read<String>(c);
    final byId = {for (final g in goals) cell(g, 'id'): g};
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
      expect(
        g.readNullable<String>('color_key'),
        isNull,
        reason: '${cell(g, 'id')} colorKey 应退役置 NULL',
      );
    }

    // 打卡逐项一致：计数/状态/补签/归属原样。
    final checkIns = await db
        .customSelect(
          'SELECT goal_id, status, is_backfill, day FROM check_ins ORDER BY id',
        )
        .get();
    expect(checkIns, hasLength(4));
    expect(
      checkIns.where((c) => c.read<String>('goal_id') == 'gs'),
      hasLength(2),
    );
    expect(
      checkIns.where(
        (c) =>
            c.read<String>('goal_id') == 'gs' &&
            c.read<String>('status') == 'revoked',
      ),
      hasLength(1),
    );
    expect(checkIns.where((c) => c.read<bool>('is_backfill')), hasLength(2));
    expect(
      checkIns.map((c) => c.read<String>('day')).toSet(),
      contains('2026-08-10'),
    );

    // FrequencyVersions 原样保全（停写整表，存量不动）。
    final versions = await db
        .customSelect(
          'SELECT goal_id, pattern, source, effective_from_week '
          'FROM frequency_versions ORDER BY id',
        )
        .get();
    expect(versions, hasLength(2));
    expect(
      versions.first.read<String>('pattern'),
      '{"type":"daily","targetPerDay":1}',
    );
    expect(versions.first.read<String>('source'), 'initial');
    expect(versions.first.read<String>('effective_from_week'), '2026-08-03');

    // 提醒：gd 补档 daily；gw 补默认行（09:00 关 weekly）；
    // 每日概要不参与；gs/gp（非 habit）无提醒行——不补默认行（D3）。
    final reminders = await db
        .customSelect(
          'SELECT goal_id, time, is_enabled, cadence FROM reminders',
        )
        .get();
    expect(reminders, hasLength(3));
    final gd = reminders.firstWhere(
      (r) => r.readNullable<String>('goal_id') == 'gd',
    );
    expect(gd.read<String>('time'), '08:30');
    expect(gd.read<bool>('is_enabled'), true);
    expect(gd.readNullable<String>('cadence'), 'daily');
    final gw = reminders.firstWhere(
      (r) => r.readNullable<String>('goal_id') == 'gw',
    );
    expect(gw.read<String>('time'), '09:00');
    expect(gw.read<bool>('is_enabled'), false);
    expect(gw.readNullable<String>('cadence'), 'weekly');
    final brief = reminders.firstWhere(
      (r) => r.readNullable<String>('goal_id') == null,
    );
    expect(brief.readNullable<String>('cadence'), isNull);
  });

  test('v3→v4（T044）：check_ins 增 note 列，存量记录零丢失', () async {
    // 1) v3 建库 + 一行无 note 的存量打卡。
    {
      final v3 = _V3Database(NativeDatabase(file));
      await v3.customStatement(
        "INSERT INTO check_ins (id, goal_id, day, created_at, "
        "is_backfill, status) VALUES ('c1', 'g1', '2026-08-01', "
        "'2026-08-01T02:00:00.000Z', 0, 'valid')",
      );
      await v3.close();
    }

    // 2) 同库 v4 开启 → 纯 ADD COLUMN，存量照读、note 为 NULL。
    final db = AppDatabase(NativeDatabase(file));
    final repo = CheckInRepository(db);
    final legacy = await repo.all();
    expect(legacy.single.id, 'c1');
    expect(legacy.single.note, isNull);

    // 3) 新写入两形态：带描述 / 不带。
    final today = LocalDate.fromDateTime(DateTime.now());
    await repo.add('g1', today, DateTime.now(), note: '晚上十分钟');
    await repo.add('g1', today, DateTime.now());
    final after = await repo.all();
    expect(after.where((c) => c.note == '晚上十分钟'), hasLength(1));
    expect(after.where((c) => c.note == null), hasLength(2));
    await db.close();
  });

  test('v4→v5（004 T003·D2）：settings 增 themeMode 列，存量行照读、三档可写', () async {
    // 1) v4 建库 + 带资料的单例行（无 theme_mode 列）。
    {
      final v4 = _V4Database(NativeDatabase(file));
      await v4.customStatement(
        "INSERT INTO settings_rows (id, daily_brief_time, nickname, "
        "onboarding_completed, notification_denied_acknowledged) VALUES "
        "(1, '08:00', '星行', 1, 0)",
      );
      await v4.close();
    }

    // 2) 同库 v5 开启 → 纯 ADD COLUMN：存量资料照读，themeMode → system。
    final db = AppDatabase(NativeDatabase(file));
    final settings = SettingsRepository(db);
    final migrated = await settings.get();
    expect(migrated.themeMode, AppThemeMode.system);
    expect(migrated.onboardingCompleted, true);
    expect((await settings.getProfile()).nickname, '星行');

    // 3) 三档写入往返（dark → light → system 显式）。
    await settings.update(migrated.copyWith(themeMode: AppThemeMode.dark));
    expect((await settings.get()).themeMode, AppThemeMode.dark);
    await settings.update(migrated.copyWith(themeMode: AppThemeMode.light));
    expect((await settings.get()).themeMode, AppThemeMode.light);
    await settings.update(migrated.copyWith(themeMode: AppThemeMode.system));
    expect((await settings.get()).themeMode, AppThemeMode.system);
    await db.close();
  });

  // 003 T038：端到端对账——v2 存量四分支升级启动后，全部走仓库读路径
  // 逐项一致；被映射目标的提醒按原节奏（Reminders 行 cadence）继续排程。
  test('v2→v4 端到端（T038）：仓库对账 + 被映射目标按原节奏提醒', () async {
    {
      final v2 = _V2Database(NativeDatabase(file));
      // 四分支：gs（milestone+截止+envelope）/ gd（habit+daily+提醒+envelope）
      // / gw（habit+weekly 无提醒）/ gp（paused milestone 无截止）。
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at,deadline,motivation,success_criterion,cue_scene) "
        "VALUES ('gs','冈仁波齐徒步','milestone','travel','indigo',"
        "'active','2026-08-01','2026-10-01','想亲眼看到日出','走完全程',NULL)",
      );
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at,motivation,success_criterion,cue_scene) VALUES "
        "('gd','好好吃饭','habit','meal','coral','active','2026-08-01',"
        "'为了晚上不胃胀','晚饭吃八分饱','晚饭后')",
      );
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('gw','跑步锻炼','habit','fitness','sage',"
        "'active','2026-08-01')",
      );
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('gp','学钢琴','milestone','star','amber',"
        "'paused','2026-07-01')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-d','gd','2026-08-03',"
        "'{\"type\":\"daily\",\"targetPerDay\":1}','initial')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-w','gw','2026-08-03',"
        "'{\"type\":\"weekly\",\"timesPerWeek\":3}','initial')",
      );
      await v2.customStatement(
        "INSERT INTO reminders (id,goal_id,time,is_enabled) VALUES "
        "('r-d','gd','08:30',1)",
      );
      await v2.customStatement(
        "INSERT INTO reminders (id,goal_id,time,is_enabled) VALUES "
        "('r-brief',NULL,'08:00',1)",
      );
      // 打卡：gs 2（valid+revoked 补签）/ gd 2（valid+valid 补签）。
      await v2.customStatement(
        "INSERT INTO check_ins (id,goal_id,day,created_at,is_backfill,"
        "status) VALUES ('c1','gs','2026-08-19',"
        "'2026-08-19T12:00:00.000Z',0,'valid'),('c2','gs','2026-08-10',"
        "'2026-08-19T12:00:00.000Z',1,'revoked'),('c3','gd','2026-08-19',"
        "'2026-08-19T12:00:00.000Z',0,'valid'),('c4','gd','2026-08-18',"
        "'2026-08-19T12:00:00.000Z',1,'valid')",
      );
      await v2.customStatement(
        "INSERT INTO settings_rows (id,daily_brief_time,"
        "onboarding_completed,notification_denied_acknowledged) VALUES "
        "(1,'08:00',1,0)",
      );
      await v2.close();
    }

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final goals = await GoalRepository(db).getGoals();
    final checkIns = await CheckInRepository(db).all();
    final reminderRepo = ReminderRepository(db);

    // ---- 逐项对账（仓库读路径）----
    expect(goals, hasLength(4));
    final byId = {for (final g in goals) g.id: g};
    expect(byId['gs']!.goalType, GoalType.shortTerm); // 决策树第一支
    expect(byId['gs']!.deadline, LocalDate.parse('2026-10-01'));
    expect(byId['gs']!.motivation, '想亲眼看到日出'); // envelope 保全
    expect(byId['gd']!.goalType, GoalType.habit);
    expect(byId['gd']!.motivation, '为了晚上不胃胀');
    expect(byId['gd']!.successCriterion, '晚饭吃八分饱');
    expect(byId['gw']!.goalType, GoalType.habit);
    expect(byId['gp']!.goalType, GoalType.longTerm); // paused 无截止→长期
    expect(byId['gp']!.status, GoalStatus.paused); // 状态机不动
    for (final g in goals) {
      expect(g.colorKey, '', reason: '${g.id} colorKey 应退役置空');
    }
    // 打卡逐项：计数/状态/补签归属原样（SC-003）。
    expect(checkIns, hasLength(4));
    expect(checkIns.where((c) => c.goalId == 'gs'), hasLength(2));
    expect(
      checkIns.where(
        (c) => c.goalId == 'gs' && c.status == CheckInStatus.revoked,
      ),
      hasLength(1),
    );
    expect(checkIns.where((c) => c.isBackfill), hasLength(2));
    // 提醒行：daily 存量行照用；weekly 补默认行（09:00 关）。
    final rows = await reminderRepo.all();
    expect(rows, hasLength(3));
    final gdRow = rows.firstWhere((r) => r.goalId == 'gd');
    expect(gdRow.isEnabled, isTrue);
    expect(gdRow.time, const LocalTime(8, 30));
    expect(gdRow.effectiveCadence, Cadence.daily);
    final gwRow = rows.firstWhere((r) => r.goalId == 'gw');
    expect(gwRow.isEnabled, isFalse);
    expect(gwRow.effectiveCadence, Cadence.weekly); // 原节奏保留在行上
    expect(rows.any((r) => r.isDailyBrief), isTrue);

    // ---- 按原节奏继续提醒（planReminders 纯函数）----
    // 周四 8/20：gd daily 命中（08:30）；gw weekly 锚点=周六，不当日。
    final statsThu = StatsEngine.evaluate(
      goals: goals,
      checkIns: checkIns,
      today: LocalDate.parse('2026-08-20'),
    );
    final thu = planReminders(
      reminders: rows,
      defaultBriefTime: const LocalTime(8, 0),
      goals: goals,
      stats: statsThu,
      today: LocalDate.parse('2026-08-20'),
      nowTime: const LocalTime(10, 0),
    );
    final thuGoalIds = thu.expand((p) => p.goalIds).toSet();
    expect(thuGoalIds, contains('gd'));
    expect(thuGoalIds, isNot(contains('gw')));
    final gdPlan = thu.firstWhere((p) => p.goalIds.contains('gd'));
    expect(gdPlan.time, const LocalTime(8, 30));
    expect(gdPlan.body, contains('为了晚上不胃胀')); // FR-016：存量为什么保全进通知
    expect(gdPlan.body, isNot(contains('八分饱'))); // 怎样算不进通知

    // 周六 8/22：打开 gw 行 → weekly 同 weekday 命中（09:00 单次）。
    await reminderRepo.upsert(gwRow.copyWith(isEnabled: true));
    final enabledRows = await reminderRepo.all();
    final statsSat = StatsEngine.evaluate(
      goals: goals,
      checkIns: checkIns,
      today: LocalDate.parse('2026-08-22'),
    );
    final sat = planReminders(
      reminders: enabledRows,
      defaultBriefTime: const LocalTime(8, 0),
      goals: goals,
      stats: statsSat,
      today: LocalDate.parse('2026-08-22'),
      nowTime: const LocalTime(7, 0),
    );
    final satGoalIds = sat.expand((p) => p.goalIds).toSet();
    expect(satGoalIds, containsAll(<String>['gd', 'gw']));
    final gwPlan = sat.firstWhere((p) => p.goalIds.contains('gw'));
    expect(gwPlan.time, const LocalTime(9, 0));
  });

  // 003 T039：US5 验收场景 2/3——「每日 3 次」频率 → 习惯且打卡计数
  // 连续不中断；带截止 → 短期，倒计时 = deadline − today。
  test('US5 场景 2/3（T039）：每日 3 次→习惯计数连续；带截止→短期倒计时', () async {
    const todayStr = '2026-08-22';
    final today = LocalDate.parse(todayStr);
    {
      final v2 = _V2Database(NativeDatabase(file));
      // 每日 3 次频率档（高频节律）+ 截止目标。
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('g3','练声','habit','mic','coral','active',"
        "'2026-08-01')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-3','g3','2026-08-03',"
        "'{\"type\":\"daily\",\"targetPerDay\":3}','initial')",
      );
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at,deadline) VALUES ('gdl','考认证','milestone',"
        "'star','amber','active','2026-08-01','2026-10-01')",
      );
      // 迁移前连续留痕 6 天（8/16–8/21，今日 8/22 未打）。
      for (var i = 1; i <= 6; i++) {
        final d = today.addDays(-i).isoString;
        await v2.customStatement(
          "INSERT INTO check_ins (id,goal_id,day,created_at,is_backfill,"
          "status) VALUES ('c-$i','g3','$d',"
          "'2026-08-22T02:00:00.000Z',0,'valid')",
        );
      }
      await v2.close();
    }

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final goals = await GoalRepository(db).getGoals();
    final checkInRepo = CheckInRepository(db);

    // 场景 2：高频节律（每日 3 次）→ habit；既有计数连续不中断。
    final g3 = goals.firstWhere((g) => g.id == 'g3');
    expect(g3.goalType, GoalType.habit);
    StatsEvaluation statsOf(List<CheckIn> checkIns) =>
        StatsEngine.evaluate(goals: goals, checkIns: checkIns, today: today);
    var stats = statsOf(await checkInRepo.all());
    expect(stats.streakOf('g3'), 6, reason: '迁移不得重置连续计数');
    // 迁移后继续打卡：计数延续（6 → 7），无断层。
    await checkInRepo.add('g3', today, DateTime.utc(2026, 8, 22, 8));
    stats = statsOf(await checkInRepo.all());
    expect(stats.streakOf('g3'), 7);
    expect((await checkInRepo.all()).where((c) => c.goalId == 'g3').length, 7);

    // 场景 3：带截止 → shortTerm；倒计时 = deadline − today（徽章同源算式）。
    final gdl = goals.firstWhere((g) => g.id == 'gdl');
    expect(gdl.goalType, GoalType.shortTerm);
    expect(gdl.deadline!.differenceInDays(today), 40); // 8/22 → 10/1
  });
}
