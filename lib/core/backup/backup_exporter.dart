/// 备份导出（T045，FR-015，contracts/backup-format.md）。
///
/// 全量实体 + Settings → 版本化 JSON（`.targetbackup`）。
/// 直接读表不走仓库写路径（导出无副作用）；编码口径与 drift
/// TypeConverter 一致（LocalDate → YYYY-MM-DD，Instant → UTC ISO-8601）。
library;

import 'dart:convert';

import '../db/app_database.dart' as db;
import '../db/repositories.dart' show ReviewRepository;
import '../models/calendar_types.dart';

const String kBackupFormat = 'target-backup';

/// 备份格式版本（003 T037 · contracts/backup-format.md 定稿 v4）：
/// v1 = 001/002 形态（kind 两值）；v4 = goals +goalType/+achievedAt、
/// reminders +cadence、settings +nickname/avatarKey、checkIns +note、
/// colorKey 导出 null（列退役）。v2/v3 未单独发版（R2 评审 note 并档直升 4）。
const int kBackupVersion = 4;

/// 文件名：`Target-备份-YYYYMMDD.targetbackup`。
String backupFileName(DateTime now) =>
    'Target-备份-${now.year}${_two(now.month)}${_two(now.day)}.targetbackup';

String _two(int n) => n.toString().padLeft(2, '0');

class BackupExporter {
  BackupExporter(this._db);

  final db.AppDatabase _db;

  String encode(Map<String, Object?> map) =>
      const JsonEncoder.withIndent('  ').convert(map);

  Future<String> exportString({DateTime? now}) async =>
      encode(await exportMap(now: now));

  Future<Map<String, Object?>> exportMap({DateTime? now}) async {
    final goals = await _db.select(_db.goals).get();
    final versions = await _db.select(_db.frequencyVersions).get();
    final sessions = await _db.select(_db.busyModeSessions).get();
    final entries = await _db.select(_db.busyModeEntries).get();
    final checkIns = await _db.select(_db.checkIns).get();
    final steps = await _db.select(_db.milestoneSteps).get();
    final reminders = await _db.select(_db.reminders).get();
    final reviews = await _db.select(_db.weeklyReviews).get();
    final settingsRows = await _db.select(_db.settingsRows).get();

    return {
      'format': kBackupFormat,
      'version': kBackupVersion,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'data': {
        'goals': [for (final g in goals) _goalJson(g)],
        'frequencyVersions': [for (final v in versions) _versionJson(v)],
        'busySessions': [
          for (final s in sessions)
            {
              'id': s.id,
              'weekStart': s.weekStart.isoString,
              'startedAt': s.startedAt.toUtc().toIso8601String(),
              if (s.endedAt != null)
                'endedAt': s.endedAt!.toUtc().toIso8601String(),
              'entries': [
                for (final e in entries.where((e) => e.sessionId == s.id))
                  {
                    'goalId': e.goalId,
                    'downgraded': e.downgraded.toJson(),
                  },
              ],
            },
        ],
        'checkIns': [for (final c in checkIns) _checkInJson(c)],
        'milestoneSteps': [for (final s in steps) _stepJson(s)],
        'reminders': [for (final r in reminders) _reminderJson(r)],
        'weeklyReviews': [for (final r in reviews) _reviewJson(r)],
        'settings': settingsRows.isEmpty
            ? _settingsJson(null)
            : _settingsJson(settingsRows.first),
      },
    };
  }

  // ---- 行 → JSON（键与 data-model.md 实体字段一一对应）----

  static Map<String, Object?> _goalJson(db.Goal g) => {
        'id': g.id,
        'name': g.name,
        // v4：goalType 三值替代 v1 kind 两值（旧 App 读 v4 按 001 宽容
        // 策略忽略未知字段；导入侧 v1 文件走 D3 映射，见 importer）。
        'goalType': g.goalType.name,
        'iconKey': g.iconKey,
        // colorKey 列退役（003 契约）：恒导 null；v1 文件里的存量值导入侧照存。
        'colorKey': null,
        'status': g.status.name,
        'createdAt': g.createdAt.isoString,
        if (g.deadline != null) 'deadline': g.deadline!.isoString,
        // 短期达成时刻（D4）：恒导键，null = 未达成。
        'achievedAt':
            g.achievedAt?.toUtc().toIso8601String(),
        // 002 B 案 envelope（T016）：可选键，NULL 不导出——001 备份缺键可导回。
        if (g.motivation != null) 'motivation': g.motivation,
        if (g.successCriterion != null) 'successCriterion': g.successCriterion,
        if (g.cueScene != null) 'cueScene': g.cueScene,
      };

  static Map<String, Object?> _versionJson(db.FrequencyVersion v) => {
        'id': v.id,
        'goalId': v.goalId,
        'effectiveFromWeek': v.effectiveFromWeek.isoString,
        'pattern': v.pattern.toJson(),
        'source': v.source.name,
      };

  static Map<String, Object?> _checkInJson(db.CheckIn c) => {
        'id': c.id,
        'goalId': c.goalId,
        'day': c.day.isoString,
        'createdAt': c.createdAt.toUtc().toIso8601String(),
        'isBackfill': c.isBackfill,
        'status': c.status.name,
        // 一句话描述（FR-019，schema v4）：可选键，NULL 不导出——
        // 旧版备份缺键可导回（全量 v4 格式升版在 US5 T037）。
        if (c.note != null) 'note': c.note,
      };

  static Map<String, Object?> _stepJson(db.MilestoneStep s) => {
        'id': s.id,
        'goalId': s.goalId,
        'title': s.title,
        'isDone': s.isDone,
        if (s.doneAt != null) 'doneAt': s.doneAt!.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _reminderJson(db.Reminder r) => {
        'id': r.id,
        'goalId': r.goalId,
        'time': r.time.isoString,
        'isEnabled': r.isEnabled,
        // v4 提醒频率档（FR-013）：NULL = daily，不导键。
        if (r.cadence != null) 'cadence': r.cadence!.name,
      };

  static Map<String, Object?> _reviewJson(db.WeeklyReview r) => {
        'id': r.id,
        'weekStart': r.weekStart.isoString,
        'settledAt': r.settledAt.toUtc().toIso8601String(),
        // snapshot/decision 键格式与 ReviewRepository 的行内 JSON 同源。
        'snapshot': ReviewRepository.decodeSnapshot(r.snapshotJson)
            .map((s) => {
                  'goalId': s.goalId,
                  'metDays': s.metDays,
                  'totalChecks': s.totalChecks,
                  'backfillCount': s.backfillCount,
                  'busyModeApplied': s.busyModeApplied,
                })
            .toList(),
        'decision': _decisionJson(r.decisionJson),
        if (r.note != null) 'note': r.note,
      };

  static Map<String, Object?> _decisionJson(String decisionJson) {
    final m = Map<String, Object?>.from(jsonDecode(decisionJson) as Map);
    if (m['type'] == 'adjust') {
      m['pattern'] = Map<String, Object?>.from(m['pattern'] as Map);
    }
    return m;
  }

  static Map<String, Object?> _settingsJson(db.SettingsRow? r) => {
        'dailyBriefTime': (r?.dailyBriefTime ?? const LocalTime(8, 0)).isoString,
        'onboardingCompleted': r?.onboardingCompleted ?? false,
        'notificationDeniedAcknowledged':
            r?.notificationDeniedAcknowledged ?? false,
        // v3 账号资料（D7）：可选键，NULL 不导出——旧文件缺键导回为 NULL。
        if (r?.nickname != null) 'nickname': r!.nickname,
        if (r?.avatarKey != null) 'avatarKey': r!.avatarKey,
      };
}
