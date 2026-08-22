/// AppDatabase：drift 生成入口。
///
/// 执行器由 connection.dart 按平台注入（Web=WasmDatabase/IndexedDB、
/// iOS/Android=NativeDatabase、测试=NativeDatabase.memory()），
/// 因此构造函数只收 QueryExecutor。schemaVersion 见下方 getter
/// （v2：goals 增 B 案 envelope 三可空列；v3：003 三类型/提醒档/
/// 资料列 + 存量重映射，见 _migrateV3）。
library;

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart'
    show Cadence, CheckInStatus, FrequencySource, GoalStatus, GoalType, newId;
import '../models/frequency_pattern.dart' show FrequencyPattern;
import '../models/goal_icon_catalog.dart' show legacyIconKeyMap;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Goals,
  FrequencyVersions,
  BusyModeSessions,
  BusyModeEntries,
  CheckIns,
  MilestoneSteps,
  Reminders,
  WeeklyReviews,
  SettingsRows,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Settings 单例行（默认 08:00 每日概要）。
          await into(settingsRows).insert(SettingsRowsCompanion.insert(
            dailyBriefTime: const LocalTime(8, 0),
          ));
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2（002 US3，B 案 envelope）：三个可空列，旧数据零丢失。
          if (from < 2) {
            await m.addColumn(goals, goals.motivation);
            await m.addColumn(goals, goals.successCriterion);
            await m.addColumn(goals, goals.cueScene);
          }
          // v2 → v3（003 T009，research D3 一次性重映射）。
          if (from < 3) {
            await _migrateV3();
          }
        },
      );

  /// v2 → v3 一次性迁移（003 T009 · research D3 / data-model.md）。
  ///
  /// 1. 表结构：`kind` 改名 `goal_type`（值域暂为旧两值，第 2 步重映射）；
  ///    goals.achieved_at、reminders.cadence、settings 两资料列新增；
  ///    colorKey 退役需弛豫 NOT NULL——SQLite 无法 ALTER 弛豫约束，
  ///    第 3 步走整表重建（外键 pragma 未开、goals 无二级索引，安全）。
  /// 2. goalType 重映射决策树：deadline≠NULL→shortTerm；存在 daily/
  ///    weekdays 频率版本→habit（cadence=daily）；存在 weekly 版本→habit
  ///    （cadence=weekly）；其余（无截止里程碑/无频率习惯/暂停中）→longTerm。
  /// 3. iconKey 旧 12 键按 [legacyIconKeyMap] 换域（未知兜底 explore）；
  ///    colorKey 置 NULL 退役。
  /// 4. habit 目标提醒：现存的补 cadence 档；没有的按 D3 补一条默认行
  ///    （09:00、开关关）。
  ///
  /// goals 全程走裸 SQL 读写——改名后值域仍是旧两值，过类型转换器会
  /// FormatException；frequency_versions 未动、可安全类型化读取。
  Future<void> _migrateV3() async {
    // ---- 1) 表结构 ----
    await customStatement('ALTER TABLE goals RENAME COLUMN kind TO goal_type');
    await customStatement('ALTER TABLE goals ADD COLUMN achieved_at TEXT');
    await customStatement('ALTER TABLE reminders ADD COLUMN cadence TEXT');
    await customStatement(
        'ALTER TABLE settings_rows ADD COLUMN nickname TEXT');
    await customStatement(
        'ALTER TABLE settings_rows ADD COLUMN avatar_key TEXT');

    // ---- 2) goalType 重映射（先读裸行再改写）----
    final rawGoals = await customSelect(
      'SELECT id, goal_type, deadline FROM goals',
      readsFrom: {goals},
    ).get();
    final freqTypes = <String, Set<String>>{};
    for (final v in await select(frequencyVersions).get()) {
      freqTypes.putIfAbsent(v.goalId, () => {}).add(
          v.pattern.toJson()['type'] as String? ?? '');
    }

    String goalTypeOf(String rawKind, String? deadline, Set<String> types) {
      if (deadline != null) return 'shortTerm';
      if (types.contains('daily') || types.contains('weekdays')) {
        return 'habit';
      }
      if (types.contains('weekly')) return 'habit';
      return 'longTerm'; // 无截止里程碑 / 无频率习惯 / 暂停中（data-model）
    }

    // 仅 habit 目标入表（goalId → 是否 weekly 档）——第 4 步只对 habit
    // 补提醒；shortTerm/longTerm 即便无提醒行也不补（D3）。
    final habitGoals = <String, bool>{};
    for (final g in rawGoals) {
      final id = g.read<String>('id');
      final deadline = g.readNullable<String>('deadline');
      final types = freqTypes[id] ?? const <String>{};
      final goalType = goalTypeOf(g.read<String>('goal_type'), deadline, types);
      if (goalType == 'habit') habitGoals[id] = types.contains('weekly');
      await customUpdate(
        'UPDATE goals SET goal_type = ? WHERE id = ?',
        variables: [Variable(goalType), Variable(id)],
        updates: {goals},
      );
    }

    // ---- 3) iconKey 换域 + colorKey 退役（整表重建弛豫 NOT NULL）----
    final iconCases = legacyIconKeyMap.entries
        .map((e) => "WHEN '${e.key}' THEN '${e.value}'")
        .join(' ');
    await customUpdate(
      "UPDATE goals SET icon_key = CASE icon_key $iconCases ELSE 'explore' END",
        variables: [],
        updates: {goals},
    );
    // v3 DDL 与 tables.dart Goals 列一一对应；color_key 可空、存量置 NULL。
    // 子表 REFERENCES goals (id) 按名解析，重命名后自动指回。
    await customStatement(
        'CREATE TABLE goals_rebuild ('
        '"id" TEXT NOT NULL PRIMARY KEY, '
        '"name" TEXT NOT NULL, '
        '"goal_type" TEXT NOT NULL, '
        '"icon_key" TEXT NOT NULL, '
        '"color_key" TEXT NULL, '
        '"status" TEXT NOT NULL, '
        '"created_at" TEXT NOT NULL, '
        '"deadline" TEXT NULL, '
        '"achieved_at" TEXT NULL, '
        '"motivation" TEXT NULL, '
        '"success_criterion" TEXT NULL, '
        '"cue_scene" TEXT NULL)');
    await customStatement(
        'INSERT INTO goals_rebuild (id, name, goal_type, icon_key, color_key, '
        'status, created_at, deadline, achieved_at, motivation, '
        'success_criterion, cue_scene) '
        'SELECT id, name, goal_type, icon_key, NULL, status, created_at, '
        'deadline, achieved_at, motivation, success_criterion, cue_scene '
        'FROM goals');
    await customStatement('DROP TABLE goals');
    await customStatement('ALTER TABLE goals_rebuild RENAME TO goals');

    // ---- 4) habit 提醒：补 cadence 档 / 补默认行（D3）----
    final rawReminders = await customSelect(
      'SELECT goal_id FROM reminders WHERE goal_id IS NOT NULL',
      readsFrom: {reminders},
    ).get();
    final reminderGoalIds =
        rawReminders.map((r) => r.read<String>('goal_id')).toSet();
    for (final entry in habitGoals.entries) {
      final cadence = entry.value ? Cadence.weekly.name : Cadence.daily.name;
      if (reminderGoalIds.contains(entry.key)) {
        await customUpdate(
          'UPDATE reminders SET cadence = ? WHERE goal_id = ?',
          variables: [Variable(cadence), Variable(entry.key)],
          updates: {reminders},
        );
      } else {
        // 无现存提醒的 habit：补默认行 09:00、开关关（research D3）。
        await customInsert(
          'INSERT INTO reminders (id, goal_id, time, is_enabled, cadence) '
          'VALUES (?, ?, ?, 0, ?)',
          variables: [
            Variable(newId()),
            Variable(entry.key),
            const Variable('09:00'),
            Variable(cadence),
          ],
          updates: {reminders},
        );
      }
    }
  }
}
