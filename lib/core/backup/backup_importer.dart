/// 备份导入（006 · 格式 v7，FR-010）。
///
/// 仅接受 version == 7（旧版本明确拒绝，D10 不做宽容链）；
/// 覆盖式恢复：单事务内清空全表 → 全量重放（冲突确认由 UI 层先行）。
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../db/app_database.dart' as db;
import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';
import 'backup_exporter.dart';

/// 导入结果计数。
class ImportSummary {
  const ImportSummary({
    required this.goals,
    required this.milestones,
    required this.reminders,
    required this.records,
  });

  final int goals;
  final int milestones;
  final int reminders;
  final int records;
}

/// 格式不符（旧版本 / 非本格式文件 / 必填字段缺失）。
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => '备份文件无法导入：$message';
}

class BackupImporter {
  BackupImporter(this._db);

  final db.AppDatabase _db;

  /// 解析并覆盖恢复。抛 [BackupFormatException] 当版本不受支持。
  Future<ImportSummary> importString(String content) async {
    final Map<String, Object?> json;
    try {
      json = jsonDecode(content) as Map<String, Object?>;
    } catch (_) {
      throw const BackupFormatException('无法识别的备份文件');
    }
    if (json['format'] != kBackupFormat) {
      throw const BackupFormatException('无法识别的备份文件');
    }
    final version = json['version'];
    if (version != kBackupVersion) {
      throw BackupFormatException(
        '不支持的备份版本（v$version），仅支持 v$kBackupVersion',
      );
    }
    final goalsJson = (json['goals'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    final settingsJson =
        json['settings'] as Map<String, Object?>? ?? const {};

    var milestones = 0, reminders = 0, records = 0;

    await _db.transaction(() async {
      // 覆盖恢复：清空全表（调用方已做显式确认）。
      await _db.delete(_db.progressRecords).go();
      await _db.delete(_db.milestones).go();
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.goals).go();
      await _db.delete(_db.settingsRows).go();

      await _db.into(_db.settingsRows).insert(
            db.SettingsRowsCompanion.insert(
              id: const Value(1),
              nickname: Value(_s(settingsJson, 'nickname')),
              avatarKey: Value(_s(settingsJson, 'avatarKey')),
              themeMode: Value(_s(settingsJson, 'themeMode')),
              remindersEnabled: Value(
                settingsJson['remindersEnabled'] as bool? ?? true,
              ),
            ),
          );

      for (final g in goalsJson) {
        await _db.into(_db.goals).insert(
              db.GoalsCompanion.insert(
                id: _req(g, 'id'),
                name: _req(g, 'name'),
                why: Value(_s(g, 'why')),
                categoryKey: Value(_category(_s(g, 'categoryKey'))),
                iconKey: g['iconKey'] as String? ?? 'target',
                colorKey: g['colorKey'] as String? ?? 'gray',
                pinned: Value(g['pinned'] as bool? ?? false),
                pinnedOrder: Value(g['pinnedOrder'] as int?),
                targetDate: Value(_date(_s(g, 'targetDate'))),
                frequency: Value(_frequency(g['frequencyPattern'])),
                status: _status(_s(g, 'status')),
                createdAt: _date(_req(g, 'createdAt'))!,
                achievedAt: Value(_instant(_s(g, 'achievedAt'))),
                archivedAt: Value(_instant(_s(g, 'archivedAt'))),
              ),
            );

        for (final m in (g['milestones'] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>()) {
          await _db.into(_db.milestones).insert(
                db.MilestonesCompanion.insert(
                  id: _req(m, 'id'),
                  goalId: _req(g, 'id'),
                  title: _req(m, 'title'),
                  description: Value(_s(m, 'description')),
                  position: Value(m['position'] as int? ?? 0),
                  isDone: Value(m['isDone'] as bool? ?? false),
                  doneAt: Value(_instant(_s(m, 'doneAt'))),
                ),
              );
          milestones++;
        }

        for (final r in (g['reminders'] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>()) {
          await _db.into(_db.reminders).insert(
                db.RemindersCompanion.insert(
                  id: _req(r, 'id'),
                  goalId: _req(g, 'id'),
                  time: LocalTime.parse(_req(r, 'time')),
                  isEnabled: Value(r['isEnabled'] as bool? ?? false),
                  cadence: _cadence(_s(r, 'cadence')),
                ),
              );
          reminders++;
        }

        for (final r in (g['records'] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>()) {
          await _db.into(_db.progressRecords).insert(
                db.ProgressRecordsCompanion.insert(
                  id: _req(r, 'id'),
                  goalId: _req(g, 'id'),
                  title: _req(r, 'title'),
                  body: Value(_s(r, 'body')),
                  durationMinutes: Value(r['durationMinutes'] as int?),
                  day: _date(_req(r, 'day'))!,
                  createdAt: _instant(_req(r, 'createdAt'))!,
                  isBackfill: Value(r['isBackfill'] as bool? ?? false),
                  kind: _kind(_s(r, 'kind')),
                  milestoneId: Value(_s(r, 'milestoneId')),
                ),
              );
          records++;
        }
      }
    });

    return ImportSummary(
      goals: goalsJson.length,
      milestones: milestones,
      reminders: reminders,
      records: records,
    );
  }

  // ---- 解析助手（宽容：可空字段缺省/类型不符 → null/默认） ----

  static String _req(Map<String, Object?> m, String key) {
    final v = m[key];
    if (v is! String || v.isEmpty) {
      throw BackupFormatException('备份文件缺少必填字段 "$key"');
    }
    return v;
  }

  static String? _s(Map<String, Object?> m, String key) =>
      m[key] as String?;

  static LocalDate? _date(String? iso) =>
      iso == null ? null : LocalDate.parse(iso);

  static DateTime? _instant(String? iso) =>
      iso == null ? null : DateTime.parse(iso).toUtc();

  static GoalStatus _status(String? name) => GoalStatus.values.firstWhere(
        (v) => v.name == name,
        orElse: () => GoalStatus.active,
      );

  static Cadence _cadence(String? name) => Cadence.values.firstWhere(
        (v) => v.name == name,
        orElse: () => Cadence.daily,
      );

  static RecordKind _kind(String? name) => RecordKind.values.firstWhere(
        (v) => v.name == name,
        orElse: () => RecordKind.normal,
      );

  static GoalCategory? _category(String? name) {
    if (name == null) return null;
    for (final v in GoalCategory.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static FrequencyPattern? _frequency(Object? json) {
    if (json is! Map<String, Object?>) return null;
    try {
      return FrequencyPattern.fromJsonString(jsonEncode(json));
    } catch (_) {
      return null;
    }
  }
}
