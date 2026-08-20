/// AppDatabase：drift 生成入口。
///
/// 执行器由 connection.dart 按平台注入（Web=WasmDatabase/IndexedDB、
/// iOS/Android=NativeDatabase、测试=NativeDatabase.memory()），
/// 因此构造函数只收 QueryExecutor。schemaVersion 见下方 getter（v2：
/// goals 增 B 案 envelope 三可空列）。
library;

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart'
    show CheckInStatus, FrequencySource, GoalKind, GoalStatus;
import '../models/frequency_pattern.dart' show FrequencyPattern;
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
  int get schemaVersion => 2;

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
        },
      );
}
