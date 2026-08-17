/// AppDatabase：drift 生成入口。
///
/// 执行器由 connection.dart 按平台注入（Web=WasmDatabase/IndexedDB、
/// iOS/Android=NativeDatabase、测试=NativeDatabase.memory()），
/// 因此构造函数只收 QueryExecutor。schemaVersion=1 起步。
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Settings 单例行（默认 08:00 每日概要）。
          await into(settingsRows).insert(SettingsRowsCompanion.insert(
            dailyBriefTime: const LocalTime(8, 0),
          ));
        },
      );
}
