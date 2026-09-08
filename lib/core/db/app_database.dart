/// AppDatabase：drift 生成入口（schema v8 · 006 清库重建）。
///
/// 执行器由 connection.dart 按平台注入（Web=WasmDatabase/IndexedDB、
/// iOS/Android=NativeDatabase、测试=NativeDatabase.memory()）。
/// 006 裁定 D10：存量数据不迁移——v<8 一律破坏性重建（drop & create）。
library;

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Goals, ProgressRecords, Milestones, Reminders, SettingsRows],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureSettingsRow();
    },
    onUpgrade: (m, from, to) async {
      // D10：不考虑存量——任何 v<8 库直接清库重建（子表先删）。
      final ordered = allTables.toList().reversed;
      for (final t in ordered) {
        await m.deleteTable(t.actualTableName);
      }
      await m.createAll();
      await _ensureSettingsRow();
    },
  );

  Future<void> _ensureSettingsRow() async {
    await into(settingsRows).insert(
      SettingsRowsCompanion.insert(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
  }
}
