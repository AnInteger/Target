// T015：v1 → v2 迁移（B 案 envelope 可空列）——既有数据零丢失 + 新列可写。
// 手法：临时文件库先用 v1 schema（仅旧列的 goals 表）写入两行真实形态的
// 旧数据，再用 v2 的 AppDatabase 打开同一文件触发 onUpgrade。
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

/// 只含 v1 goals 表的旧库（schemaVersion=1；Settings 等表与本测试无关）。
class _V1Database extends AppDatabase {
  _V1Database(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // Migrator 无 customStatement；建 v1 表直接走库级语句。
        onCreate: (m) async => customStatement(_v1GoalsDdl),
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

  test('v1→v2：既有目标零丢失（habit/milestone×deadline），新列 NULL 可读写',
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
    expect(meal.kind, GoalKind.habit);
    expect(meal.colorKey, 'coral');
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
}
