/// 备份导出（006 · 格式 v7，FR-010）。
///
/// 全量实体 + Settings → 版本化 JSON（`.targetbackup`）。
/// 直接读表不走仓库写路径（导出无副作用）；编码口径与 drift
/// TypeConverter 一致（LocalDate → YYYY-MM-DD，Instant → UTC ISO-8601，
/// FrequencyPattern → JSON 对象）。
library;

import 'dart:convert';

import '../db/app_database.dart' as db;
import '../models/frequency_pattern.dart';

const String kBackupFormat = 'target-backup';

/// 备份格式 v7（006 data-model.md §3）：v8 schema 全字段；
/// v1–v6 旧文件不再支持导入（D10 存量不考虑）。
const int kBackupVersion = 7;

/// 文件名：`Target-备份-YYYYMMDD.targetbackup`。
String backupFileName(DateTime now) =>
    'Target-备份-${now.year}${_two(now.month)}${_two(now.day)}.targetbackup';

String _two(int n) => n.toString().padLeft(2, '0');

Map<String, Object?>? _frequencyJson(FrequencyPattern? f) =>
    f == null ? null : jsonDecode(f.toJsonString()) as Map<String, Object?>;

class BackupExporter {
  BackupExporter(this._db);

  final db.AppDatabase _db;

  String encode(Map<String, Object?> map) =>
      const JsonEncoder.withIndent('  ').convert(map);

  Future<String> exportString({DateTime? now}) async =>
      encode(await exportMap(now: now));

  Future<Map<String, Object?>> exportMap({DateTime? now}) async {
    final goals = await _db.select(_db.goals).get();
    final milestones = await _db.select(_db.milestones).get();
    final reminders = await _db.select(_db.reminders).get();
    final records = await _db.select(_db.progressRecords).get();
    final settingsRows = await _db.select(_db.settingsRows).get();
    final settings =
        settingsRows.isEmpty ? null : settingsRows.first;

    return {
      'format': kBackupFormat,
      'version': kBackupVersion,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'settings': {
        'nickname': settings?.nickname,
        'avatarKey': settings?.avatarKey,
        'themeMode': settings?.themeMode,
        'remindersEnabled': settings?.remindersEnabled ?? true,
      },
      'goals': [
        for (final g in goals)
          {
            'id': g.id,
            'name': g.name,
            'why': g.why,
            'categoryKey': g.categoryKey?.name,
            'iconKey': g.iconKey,
            'colorKey': g.colorKey,
            'pinned': g.pinned,
            'pinnedOrder': g.pinnedOrder,
            'targetDate': g.targetDate?.isoString,
            'frequencyPattern': _frequencyJson(g.frequency),
            'status': g.status.name,
            'achievedAt': g.achievedAt?.toUtc().toIso8601String(),
            'archivedAt': g.archivedAt?.toUtc().toIso8601String(),
            'createdAt': g.createdAt.isoString,
            'milestones': [
              for (final m in milestones.where((m) => m.goalId == g.id))
                {
                  'id': m.id,
                  'title': m.title,
                  'description': m.description,
                  'position': m.position,
                  'isDone': m.isDone,
                  'doneAt': m.doneAt?.toUtc().toIso8601String(),
                },
            ],
            'reminders': [
              for (final r in reminders.where((r) => r.goalId == g.id))
                {
                  'id': r.id,
                  'time': r.time.isoString,
                  'isEnabled': r.isEnabled,
                  'cadence': r.cadence.name,
                },
            ],
            'records': [
              for (final r in records.where((r) => r.goalId == g.id))
                {
                  'id': r.id,
                  'title': r.title,
                  'body': r.body,
                  'durationMinutes': r.durationMinutes,
                  'day': r.day.isoString,
                  'createdAt': r.createdAt.toUtc().toIso8601String(),
                  'isBackfill': r.isBackfill,
                  'kind': r.kind.name,
                  'milestoneId': r.milestoneId,
                },
            ],
          },
      ],
    };
}
}
