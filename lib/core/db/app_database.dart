/// AppDatabase：drift 生成入口。
///
/// 执行器由 connection.dart 按平台注入（Web=WasmDatabase/IndexedDB、
/// iOS/Android=NativeDatabase、测试=NativeDatabase.memory()），
/// 因此构造函数只收 QueryExecutor。schemaVersion 见下方 getter
/// （v2：goals 增 B 案 envelope 三可空列；v3：003 三类型/提醒档/
/// 资料列 + 存量重映射，见 _migrateV3；v4：check_ins 增 note 可空列，
/// 纯 ADD COLUMN，FR-019；v5：004 settings 增 themeMode 可空列，
/// 纯 ADD COLUMN，research D2；v6：目标推进规划与评分算法边界字段）。
library;

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart'
    show Cadence, CheckInStatus, FrequencySource, GoalStatus, GoalType, newId;
import '../models/frequency_pattern.dart'
    show FrequencyPattern, WeeklyFrequency;
import '../models/goal_icon_catalog.dart'
    show GoalIconCatalog, legacyIconKeyMap;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Goals,
    FrequencyVersions,
    BusyModeSessions,
    BusyModeEntries,
    CheckIns,
    MilestoneSteps,
    Reminders,
    WeeklyReviews,
    SettingsRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Settings 单例行（默认 08:00 每日概要）。
      await into(settingsRows).insert(
        SettingsRowsCompanion.insert(dailyBriefTime: const LocalTime(8, 0)),
      );
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
      // v3 → v4（003 T044，FR-019）：打卡一句话描述，纯 ADD COLUMN。
      if (from < 4) {
        await m.addColumn(checkIns, checkIns.note);
      }
      // v4 → v5（004 T003，research D2）：主题偏好可空列，
      // NULL = 跟随系统，纯 ADD COLUMN。
      if (from < 5) {
        await m.addColumn(settingsRows, settingsRows.themeMode);
      }
      if (from < 6) {
        await _migrateV6(m);
      }
      if (from < 7) {
        await _migrateV7(m);
      }
    },
  );

  Future<void> _migrateV7(Migrator m) async {
    await m.addColumn(goals, goals.frequencyPattern);
    await m.addColumn(goals, goals.archivedAt);

    await customUpdate(
      'UPDATE goals SET target_date = deadline '
      'WHERE target_date IS NULL AND deadline IS NOT NULL',
      updates: {goals},
    );

    final rows = await customSelect(
      'SELECT id, goal_type, icon_key, habit_target_per_week, status '
      'FROM goals',
      readsFrom: {goals},
    ).get();
    final versions = await select(frequencyVersions).get();

    for (final row in rows) {
      final id = row.read<String>('id');
      final latest = versions.where((v) => v.goalId == id).toList()
        ..sort((a, b) => a.effectiveFromWeek.compareTo(b.effectiveFromWeek));
      FrequencyPattern? pattern = latest.isEmpty ? null : latest.last.pattern;
      if (pattern == null && row.read<String>('goal_type') == 'habit') {
        pattern = WeeklyFrequency(
          row.readNullable<int>('habit_target_per_week') ?? 5,
        );
      }
      final category = GoalIconCatalog.byKey(row.read<String>('icon_key'))
          .domain
          .name;
      final archived = row.read<String>('status') == 'archived';
      await customUpdate(
        'UPDATE goals SET frequency_pattern = ?, '
        'category_override = COALESCE(category_override, ?), '
        'archived_at = CASE WHEN ? THEN ? ELSE archived_at END, '
        "status = CASE WHEN status = 'archived' THEN 'paused' ELSE status END "
        'WHERE id = ?',
        variables: [
          Variable(pattern?.toJsonString()),
          Variable(category),
          Variable(archived),
          Variable(archived ? DateTime.now().toUtc().toIso8601String() : null),
          Variable(id),
        ],
        updates: {goals},
      );
    }
  }

  Future<void> _migrateV6(Migrator m) async {
    await m.addColumn(goals, goals.progressCadenceDays);
    await m.addColumn(goals, goals.categoryOverride);
    await m.addColumn(goals, goals.targetDate);
    await m.addColumn(goals, goals.habitTargetPerWeek);
    await m.addColumn(milestoneSteps, milestoneSteps.position);
    await m.addColumn(settingsRows, settingsRows.defaultShortCadenceDays);
    await m.addColumn(settingsRows, settingsRows.defaultLongCadenceDays);
    await m.addColumn(settingsRows, settingsRows.scoreAlgorithmStartedOn);

    await customUpdate(
      "UPDATE goals SET progress_cadence_days = CASE "
      "WHEN goal_type = 'longTerm' THEN 14 ELSE 7 END "
      'WHERE progress_cadence_days IS NULL',
      updates: {goals},
    );
    await customUpdate(
      "UPDATE goals SET habit_target_per_week = 5 "
      "WHERE goal_type = 'habit' AND habit_target_per_week IS NULL",
      updates: {goals},
    );
    await customUpdate(
      'UPDATE settings_rows SET '
      'default_short_cadence_days = 7, '
      'default_long_cadence_days = 14, '
      "score_algorithm_started_on = date('now', 'localtime') "
      'WHERE id = 1',
      updates: {settingsRows},
    );

    final rows = await customSelect(
      'SELECT id, goal_id FROM milestone_steps ORDER BY goal_id, rowid',
      readsFrom: {milestoneSteps},
    ).get();
    final nextPosition = <String, int>{};
    for (final row in rows) {
      final goalId = row.read<String>('goal_id');
      final position = nextPosition[goalId] ?? 0;
      await customUpdate(
        'UPDATE milestone_steps SET position = ? WHERE id = ?',
        variables: [Variable(position), Variable(row.read<String>('id'))],
        updates: {milestoneSteps},
      );
      nextPosition[goalId] = position + 1;
    }
  }

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
    await customStatement('ALTER TABLE settings_rows ADD COLUMN nickname TEXT');
    await customStatement(
      'ALTER TABLE settings_rows ADD COLUMN avatar_key TEXT',
    );

    // ---- 2) goalType 重映射（先读裸行再改写）----
    final rawGoals = await customSelect(
      'SELECT id, goal_type, deadline FROM goals',
      readsFrom: {goals},
    ).get();
    final freqTypes = <String, Set<String>>{};
    for (final v in await select(frequencyVersions).get()) {
      freqTypes
          .putIfAbsent(v.goalId, () => {})
          .add(v.pattern.toJson()['type'] as String? ?? '');
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
      '"cue_scene" TEXT NULL)',
    );
    await customStatement(
      'INSERT INTO goals_rebuild (id, name, goal_type, icon_key, color_key, '
      'status, created_at, deadline, achieved_at, motivation, '
      'success_criterion, cue_scene) '
      'SELECT id, name, goal_type, icon_key, NULL, status, created_at, '
      'deadline, achieved_at, motivation, success_criterion, cue_scene '
      'FROM goals',
    );
    await customStatement('DROP TABLE goals');
    await customStatement('ALTER TABLE goals_rebuild RENAME TO goals');

    // ---- 4) habit 提醒：补 cadence 档 / 补默认行（D3）----
    final rawReminders = await customSelect(
      'SELECT goal_id FROM reminders WHERE goal_id IS NOT NULL',
      readsFrom: {reminders},
    ).get();
    final reminderGoalIds = rawReminders
        .map((r) => r.read<String>('goal_id'))
        .toSet();
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
