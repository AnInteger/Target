/// 备份导入（T046，FR-015，contracts/backup-format.md）。
///
/// 校验 → 冲突确认 → 单事务原子替换（先清后写，绝不静默合并）。
/// 校验失败抛 [BackupFormatException]（明确指出损坏位置，零副作用）。
library;

import 'dart:convert';

import 'package:drift/drift.dart' show InsertMode, Value;

import '../db/app_database.dart' as db;
import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';
import '../models/goal_icon_catalog.dart' show GoalIconDomain;
import 'backup_exporter.dart' show kBackupFormat, kBackupVersion;

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  /// 面向用户的错误说明（含损坏位置）。
  final String message;

  @override
  String toString() => '备份文件无法导入：$message';
}

/// 本地已有数据且用户未选择覆盖。
class BackupConflictException implements Exception {
  const BackupConflictException();
}

class BackupData {
  const BackupData({
    required this.goals,
    required this.frequencyVersions,
    required this.busySessions,
    required this.checkIns,
    required this.milestoneSteps,
    required this.reminders,
    required this.weeklyReviews,
    required this.settings,
  });

  final List<Map<String, Object?>> goals;
  final List<Map<String, Object?>> frequencyVersions;
  final List<Map<String, Object?>> busySessions;
  final List<Map<String, Object?>> checkIns;
  final List<Map<String, Object?>> milestoneSteps;
  final List<Map<String, Object?>> reminders;
  final List<Map<String, Object?>> weeklyReviews;
  final Map<String, Object?> settings;
}

class ImportSummary {
  const ImportSummary(this.counts);

  /// 实体名 → 导入行数（核对摘要展示用）。
  final Map<String, int> counts;

  @override
  String toString() =>
      counts.entries.map((e) => '${e.key} ${e.value}').join(' · ');
}

class BackupImporter {
  BackupImporter(this._db);

  final db.AppDatabase _db;

  /// 逐实体严格校验；任何缺失/类型错误 → [BackupFormatException]，零副作用。
  BackupData parse(String source) {
    Object? root;
    try {
      root = jsonDecode(source);
    } catch (_) {
      throw const BackupFormatException('不是有效的 JSON 文件');
    }
    if (root is! Map) _fail('文件结构');
    final m = Map<String, Object?>.from(root);

    if (m['format'] != kBackupFormat) _fail('format 头不对（非本应用备份）');
    final version = m['version'];
    if (version is! int) _fail('version 缺失或类型错误');
    if (version > kBackupVersion) {
      throw const BackupFormatException('备份来自更新版本的应用，请先升级 Target 再导入');
    }
    // v1..v4 全收（宽容解析双向）：v4 新键全部可选，v1 文件缺
    // goalType/cadence/note/nickname → 构造时按默认/映射推导（契约）。
    final data = m['data'];
    if (data is! Map) _fail('缺少 data 段');
    final d = Map<String, Object?>.from(data);

    const listKeys = [
      'goals',
      'frequencyVersions',
      'busySessions',
      'checkIns',
      'milestoneSteps',
      'reminders',
      'weeklyReviews',
    ];
    final lists = <String, List<Map<String, Object?>>>{};
    for (final k in listKeys) {
      final v = d[k];
      if (v is! List) _fail('data.$k 缺失（文件损坏）');
      lists[k] = [
        for (var i = 0; i < v.length; i++) _asMap(v[i], 'data.$k[$i]'),
      ];
    }
    final settingsRaw = d['settings'];
    if (settingsRaw is! Map) _fail('data.settings 缺失');
    final settings = _asMap(settingsRaw, 'data.settings');

    // ---- 逐实体字段校验（明确报错位置，不部分导入）----
    for (var i = 0; i < lists['goals']!.length; i++) {
      final g = lists['goals']![i];
      _str(g, 'id', 'goals[$i].id');
      _str(g, 'name', 'goals[$i].name');
      // goalType（v4）与 kind（v1）二选一：新键优先，旧键两值。
      if (g['goalType'] != null) {
        _oneOf(g, 'goalType', const [
          'longTerm',
          'shortTerm',
          'habit',
        ], 'goals[$i].goalType');
      } else {
        _oneOf(g, 'kind', const ['habit', 'milestone'], 'goals[$i].kind');
      }
      _str(g, 'iconKey', 'goals[$i].iconKey');
      // colorKey 列退役（v4 恒 null）；v1 文件可带存量字符串。
      if (g['colorKey'] != null) _str(g, 'colorKey', 'goals[$i].colorKey');
      _enum<GoalStatus>(g, 'status', GoalStatus.values, 'goals[$i].status');
      _date(g, 'createdAt', 'goals[$i].createdAt');
      _dateOpt(g, 'deadline', 'goals[$i].deadline');
      _instantOpt(g, 'achievedAt', 'goals[$i].achievedAt');
      if (g['progressCadenceDays'] != null) {
        _intRange(
          g,
          'progressCadenceDays',
          1,
          365,
          'goals[$i].progressCadenceDays',
        );
      }
      if (g['categoryOverride'] != null) {
        _oneOf(
          g,
          'categoryOverride',
          GoalIconDomain.values.map((e) => e.name).toList(),
          'goals[$i].categoryOverride',
        );
      }
      _dateOpt(g, 'targetDate', 'goals[$i].targetDate');
      if (g['habitTargetPerWeek'] != null) {
        _intRange(
          g,
          'habitTargetPerWeek',
          1,
          7,
          'goals[$i].habitTargetPerWeek',
        );
      }
    }
    for (var i = 0; i < lists['frequencyVersions']!.length; i++) {
      final v = lists['frequencyVersions']![i];
      _str(v, 'id', 'frequencyVersions[$i].id');
      _str(v, 'goalId', 'frequencyVersions[$i].goalId');
      _week(v, 'effectiveFromWeek', 'frequencyVersions[$i].effectiveFromWeek');
      _pattern(v, 'pattern', 'frequencyVersions[$i].pattern');
      _enum<FrequencySource>(
        v,
        'source',
        FrequencySource.values,
        'frequencyVersions[$i].source',
      );
    }
    for (var i = 0; i < lists['busySessions']!.length; i++) {
      final s = lists['busySessions']![i];
      _str(s, 'id', 'busySessions[$i].id');
      _week(s, 'weekStart', 'busySessions[$i].weekStart');
      _instant(s, 'startedAt', 'busySessions[$i].startedAt');
      _instantOpt(s, 'endedAt', 'busySessions[$i].endedAt');
      final entries = s['entries'];
      if (entries is! List || entries.isEmpty) {
        _fail('busySessions[$i].entries');
      }
      for (var j = 0; j < entries.length; j++) {
        final e = _asMap(entries[j], 'busySessions[$i].entries[$j]');
        _str(e, 'goalId', 'busySessions[$i].entries[$j].goalId');
        _pattern(e, 'downgraded', 'busySessions[$i].entries[$j].downgraded');
      }
    }
    for (var i = 0; i < lists['checkIns']!.length; i++) {
      final c = lists['checkIns']![i];
      _str(c, 'id', 'checkIns[$i].id');
      _str(c, 'goalId', 'checkIns[$i].goalId');
      _date(c, 'day', 'checkIns[$i].day');
      _instant(c, 'createdAt', 'checkIns[$i].createdAt');
      _bool(c, 'isBackfill', 'checkIns[$i].isBackfill');
      _enum<CheckInStatus>(
        c,
        'status',
        CheckInStatus.values,
        'checkIns[$i].status',
      );
    }
    for (var i = 0; i < lists['milestoneSteps']!.length; i++) {
      final s = lists['milestoneSteps']![i];
      _str(s, 'id', 'milestoneSteps[$i].id');
      _str(s, 'goalId', 'milestoneSteps[$i].goalId');
      _str(s, 'title', 'milestoneSteps[$i].title');
      _bool(s, 'isDone', 'milestoneSteps[$i].isDone');
      _instantOpt(s, 'doneAt', 'milestoneSteps[$i].doneAt');
      if (s['position'] != null) {
        _intRange(s, 'position', 0, 1000000, 'milestoneSteps[$i].position');
      }
    }
    for (var i = 0; i < lists['reminders']!.length; i++) {
      final r = lists['reminders']![i];
      _str(r, 'id', 'reminders[$i].id');
      if (r['goalId'] != null) _str(r, 'goalId', 'reminders[$i].goalId');
      _time(r, 'time', 'reminders[$i].time');
      _bool(r, 'isEnabled', 'reminders[$i].isEnabled');
      // v4 频率档可选：缺失/NULL = daily（契约宽容规则）。
      if (r['cadence'] != null) {
        _oneOf(r, 'cadence', const [
          'daily',
          'threeDay',
          'weekly',
        ], 'reminders[$i].cadence');
      }
    }
    for (var i = 0; i < lists['weeklyReviews']!.length; i++) {
      final r = lists['weeklyReviews']![i];
      _str(r, 'id', 'weeklyReviews[$i].id');
      _week(r, 'weekStart', 'weeklyReviews[$i].weekStart');
      _instant(r, 'settledAt', 'weeklyReviews[$i].settledAt');
      final snap = r['snapshot'];
      if (snap is! List) _fail('weeklyReviews[$i].snapshot');
      for (var j = 0; j < snap.length; j++) {
        final row = _asMap(snap[j], 'weeklyReviews[$i].snapshot[$j]');
        _str(row, 'goalId', 'weeklyReviews[$i].snapshot[$j].goalId');
        _int(row, 'metDays', 'weeklyReviews[$i].snapshot[$j]');
        // 002 及之前快照的旧键（applicableDays/completionRate）宽容放行；
        // 003 新键 totalChecks 同样可选（旧快照解码默认 0，见 repositories）。
        if (row['applicableDays'] != null && row['applicableDays'] is! int) {
          _fail('weeklyReviews[$i].snapshot[$j].applicableDays 类型错误');
        }
        if (row['totalChecks'] != null && row['totalChecks'] is! int) {
          _fail('weeklyReviews[$i].snapshot[$j].totalChecks 类型错误');
        }
        if (row['completionRate'] != null && row['completionRate'] is! num) {
          _fail('weeklyReviews[$i].snapshot[$j].completionRate 类型错误');
        }
        _int(row, 'backfillCount', 'weeklyReviews[$i].snapshot[$j]');
        _bool(row, 'busyModeApplied', 'weeklyReviews[$i].snapshot[$j]');
      }
      _decision(r, 'decision', 'weeklyReviews[$i].decision');
      if (r['note'] != null && r['note'] is! String) {
        _fail('weeklyReviews[$i].note 类型错误');
      }
    }
    _time(settings, 'dailyBriefTime', 'settings.dailyBriefTime');
    _bool(settings, 'onboardingCompleted', 'settings.onboardingCompleted');
    _bool(
      settings,
      'notificationDeniedAcknowledged',
      'settings.notificationDeniedAcknowledged',
    );
    // v3 账号资料可选：旧文件缺键 → NULL。
    if (settings['nickname'] != null) {
      _str(settings, 'nickname', 'settings.nickname');
    }
    // 004 v5（D2）：themeMode 可选键，缺键/非串不报错——归一在写入侧
    //（未知值宽容 → NULL = system）。
    if (settings['themeMode'] != null) {
      _str(settings, 'themeMode', 'settings.themeMode');
    }
    if (settings['avatarKey'] != null) {
      _str(settings, 'avatarKey', 'settings.avatarKey');
    }
    if (settings['defaultShortCadenceDays'] != null) {
      _intRange(
        settings,
        'defaultShortCadenceDays',
        1,
        365,
        'settings.defaultShortCadenceDays',
      );
    }
    if (settings['defaultLongCadenceDays'] != null) {
      _intRange(
        settings,
        'defaultLongCadenceDays',
        1,
        365,
        'settings.defaultLongCadenceDays',
      );
    }
    _dateOpt(
      settings,
      'scoreAlgorithmStartedOn',
      'settings.scoreAlgorithmStartedOn',
    );

    return BackupData(
      goals: lists['goals']!,
      frequencyVersions: lists['frequencyVersions']!,
      busySessions: lists['busySessions']!,
      checkIns: lists['checkIns']!,
      milestoneSteps: lists['milestoneSteps']!,
      reminders: lists['reminders']!,
      weeklyReviews: lists['weeklyReviews']!,
      settings: settings,
    );
  }

  /// 除 Settings 单例行外，任一实体表有行 = 有本地数据。
  Future<bool> hasLocalData() async {
    final goals = await _db.select(_db.goals).get();
    if (goals.isNotEmpty) return true;
    final checkIns = await _db.select(_db.checkIns).get();
    if (checkIns.isNotEmpty) return true;
    final reviews = await _db.select(_db.weeklyReviews).get();
    if (reviews.isNotEmpty) return true;
    final steps = await _db.select(_db.milestoneSteps).get();
    if (steps.isNotEmpty) return true;
    final versions = await _db.select(_db.frequencyVersions).get();
    if (versions.isNotEmpty) return true;
    final reminders = await _db.select(_db.reminders).get();
    if (reminders.isNotEmpty) return true;
    final sessions = await _db.select(_db.busyModeSessions).get();
    return sessions.isNotEmpty;
  }

  /// 原子替换整个 store：单事务先清后写；失败整体回滚。
  Future<ImportSummary> apply(
    BackupData data, {
    required bool overwriteLocal,
  }) async {
    if (!overwriteLocal && await hasLocalData()) {
      throw const BackupConflictException();
    }
    final counts = <String, int>{};
    await _db.transaction(() async {
      // 子表在前（外键引用）。
      await _db.delete(_db.busyModeEntries).go();
      await _db.delete(_db.busyModeSessions).go();
      await _db.delete(_db.frequencyVersions).go();
      await _db.delete(_db.checkIns).go();
      await _db.delete(_db.milestoneSteps).go();
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.weeklyReviews).go();
      await _db.delete(_db.goals).go();

      for (final g in data.goals) {
        await _db
            .into(_db.goals)
            .insert(
              db.GoalsCompanion.insert(
                id: g['id']! as String,
                name: g['name']! as String,
                // v4 文件直取 goalType；v1 文件 kind 两值 → D3 映射
                // （habit→habit；milestone+deadline→shortTerm；余→longTerm）。
                goalType: _goalTypeOf(g),
                iconKey: g['iconKey']! as String,
                colorKey: Value(g['colorKey'] as String?),
                status: GoalStatus.values.byName(g['status']! as String),
                createdAt: LocalDate.parse(g['createdAt']! as String),
                deadline: Value(
                  g['deadline'] == null
                      ? null
                      : LocalDate.parse(g['deadline']! as String),
                ),
                // 短期达成时刻（D4）：可选键，缺键/NULL → NULL。
                achievedAt: Value(
                  g['achievedAt'] == null
                      ? null
                      : DateTime.parse(g['achievedAt']! as String),
                ),
                // 002 B 案 envelope（T016）：可选键，缺键（001 备份）→ NULL。
                motivation: Value(g['motivation'] as String?),
                successCriterion: Value(g['successCriterion'] as String?),
                cueScene: Value(g['cueScene'] as String?),
                progressCadenceDays: Value(
                  g['progressCadenceDays'] as int? ??
                      (_goalTypeOf(g) == GoalType.longTerm ? 14 : 7),
                ),
                categoryOverride: Value(g['categoryOverride'] as String?),
                targetDate: Value(
                  g['targetDate'] == null
                      ? null
                      : LocalDate.parse(g['targetDate']! as String),
                ),
                habitTargetPerWeek: Value(g['habitTargetPerWeek'] as int?),
              ),
            );
      }
      counts['goals'] = data.goals.length;

      for (final v in data.frequencyVersions) {
        await _db
            .into(_db.frequencyVersions)
            .insert(
              db.FrequencyVersionsCompanion.insert(
                id: v['id']! as String,
                goalId: v['goalId']! as String,
                effectiveFromWeek: WeekStart.parse(
                  v['effectiveFromWeek']! as String,
                ),
                pattern: _patternOf(v, 'pattern'),
                source: FrequencySource.values.byName(v['source']! as String),
              ),
            );
      }
      counts['frequencyVersions'] = data.frequencyVersions.length;

      for (final s in data.busySessions) {
        await _db
            .into(_db.busyModeSessions)
            .insert(
              db.BusyModeSessionsCompanion.insert(
                id: s['id']! as String,
                weekStart: WeekStart.parse(s['weekStart']! as String),
                startedAt: DateTime.parse(s['startedAt']! as String),
                endedAt: Value(
                  s['endedAt'] == null
                      ? null
                      : DateTime.parse(s['endedAt']! as String),
                ),
              ),
            );
        for (final e in (s['entries']! as List)) {
          final em = Map<String, Object?>.from(e as Map);
          await _db
              .into(_db.busyModeEntries)
              .insert(
                db.BusyModeEntriesCompanion.insert(
                  id: newId(),
                  sessionId: s['id']! as String,
                  goalId: em['goalId']! as String,
                  downgraded: _patternOf(em, 'downgraded'),
                ),
              );
        }
      }
      counts['busySessions'] = data.busySessions.length;

      for (final c in data.checkIns) {
        await _db
            .into(_db.checkIns)
            .insert(
              db.CheckInsCompanion.insert(
                id: c['id']! as String,
                goalId: c['goalId']! as String,
                day: LocalDate.parse(c['day']! as String),
                createdAt: DateTime.parse(c['createdAt']! as String),
                isBackfill: c['isBackfill']! as bool,
                status: CheckInStatus.values.byName(c['status']! as String),
                // note 可选键（FR-019，v4）：旧备份缺失 → NULL，显示层兜底。
                note: Value(c['note'] as String?),
              ),
            );
      }
      counts['checkIns'] = data.checkIns.length;

      for (final s in data.milestoneSteps) {
        await _db
            .into(_db.milestoneSteps)
            .insert(
              db.MilestoneStepsCompanion.insert(
                id: s['id']! as String,
                goalId: s['goalId']! as String,
                title: s['title']! as String,
                isDone: s['isDone']! as bool,
                doneAt: Value(
                  s['doneAt'] == null
                      ? null
                      : DateTime.parse(s['doneAt']! as String),
                ),
                position: Value(s['position'] as int? ?? 0),
              ),
            );
      }
      counts['milestoneSteps'] = data.milestoneSteps.length;

      for (final r in data.reminders) {
        await _db
            .into(_db.reminders)
            .insert(
              db.RemindersCompanion.insert(
                id: r['id']! as String,
                goalId: Value(r['goalId'] as String?),
                time: LocalTime.parse(r['time']! as String),
                isEnabled: r['isEnabled']! as bool,
                // v4 频率档可选：缺键 → NULL（effectiveCadence 视为 daily）。
                cadence: Value(
                  r['cadence'] == null
                      ? null
                      : Cadence.values.byName(r['cadence']! as String),
                ),
              ),
            );
      }
      counts['reminders'] = data.reminders.length;

      for (final r in data.weeklyReviews) {
        await _db
            .into(_db.weeklyReviews)
            .insert(
              db.WeeklyReviewsCompanion.insert(
                id: r['id']! as String,
                weekStart: WeekStart.parse(r['weekStart']! as String),
                settledAt: DateTime.parse(r['settledAt']! as String),
                snapshotJson: jsonEncode(r['snapshot']),
                decisionJson: jsonEncode(r['decision']),
                note: Value(r['note'] as String?),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
      counts['weeklyReviews'] = data.weeklyReviews.length;

      // Settings：单例行整体替换（id=1 固定）。
      final s = data.settings;
      await (_db.delete(_db.settingsRows)..where((t) => t.id.equals(1))).go();
      await _db
          .into(_db.settingsRows)
          .insert(
            db.SettingsRowsCompanion.insert(
              dailyBriefTime: LocalTime.parse(s['dailyBriefTime']! as String),
              onboardingCompleted: Value(s['onboardingCompleted']! as bool),
              notificationDeniedAcknowledged: Value(
                s['notificationDeniedAcknowledged']! as bool,
              ),
              // v3 账号资料（D7）：可选键，缺键 → NULL。
              nickname: Value(s['nickname'] as String?),
              avatarKey: Value(s['avatarKey'] as String?),
              // 004 v5（D2）：可选键，缺键/未知值 → NULL（= system）。
              themeMode: Value(_normThemeMode(s['themeMode'])),
              defaultShortCadenceDays: Value(
                s['defaultShortCadenceDays'] as int? ?? 7,
              ),
              defaultLongCadenceDays: Value(
                s['defaultLongCadenceDays'] as int? ?? 14,
              ),
              scoreAlgorithmStartedOn: Value(
                s['scoreAlgorithmStartedOn'] == null
                    ? null
                    : LocalDate.parse(s['scoreAlgorithmStartedOn']! as String),
              ),
            ),
          );
    });
    return ImportSummary(counts);
  }

  // ---- 校验辅助（报错带位置，帮助用户定位损坏点）----

  /// goalType 推导：v4 文件直取；v1 文件 kind 两值走 D3 映射。
  static GoalType _goalTypeOf(Map<String, Object?> g) {
    final t = g['goalType'] as String?;
    if (t != null) return GoalType.values.byName(t);
    return (g['kind']! as String) == 'habit'
        ? GoalType.habit
        : (g['deadline'] == null ? GoalType.longTerm : GoalType.shortTerm);
  }

  static Never _fail(String where) =>
      throw BackupFormatException('$where 无法读取（文件损坏）');

  static Map<String, Object?> _asMap(Object? v, String where) {
    if (v is! Map) _fail(where);
    return Map<String, Object?>.from(v);
  }

  static void _str(Map<String, Object?> m, String key, String where) {
    if (m[key] is! String || (m[key] as String).isEmpty) _fail(where);
  }

  static void _int(Map<String, Object?> m, String key, String where) {
    if (m[key] is! int) _fail(where);
  }

  static void _intRange(
    Map<String, Object?> m,
    String key,
    int min,
    int max,
    String where,
  ) {
    final value = m[key];
    if (value is! int || value < min || value > max) _fail(where);
  }

  static void _bool(Map<String, Object?> m, String key, String where) {
    if (m[key] is! bool) _fail(where);
  }

  static void _date(Map<String, Object?> m, String key, String where) {
    final v = m[key];
    if (v is! String) _fail(where);
    try {
      LocalDate.parse(v);
    } on FormatException {
      _fail(where);
    }
  }

  static void _dateOpt(Map<String, Object?> m, String key, String where) {
    if (m[key] == null) return;
    _date(m, key, where);
  }

  static void _week(Map<String, Object?> m, String key, String where) {
    final v = m[key];
    if (v is! String) _fail(where);
    try {
      WeekStart.parse(v);
    } on FormatException {
      _fail(where);
    }
  }

  static void _time(Map<String, Object?> m, String key, String where) {
    final v = m[key];
    if (v is! String) _fail(where);
    try {
      LocalTime.parse(v);
    } on FormatException {
      _fail(where);
    }
  }

  static void _instant(Map<String, Object?> m, String key, String where) {
    final v = m[key];
    if (v is! String) _fail(where);
    try {
      DateTime.parse(v);
    } on FormatException {
      _fail(where);
    }
  }

  static void _instantOpt(Map<String, Object?> m, String key, String where) {
    if (m[key] == null) return;
    _instant(m, key, where);
  }

  static void _oneOf(
    Map<String, Object?> m,
    String key,
    List<String> allowed,
    String where,
  ) {
    final v = m[key];
    if (v is! String || !allowed.contains(v)) _fail(where);
  }

  static void _enum<T extends Enum>(
    Map<String, Object?> m,
    String key,
    List<T> values,
    String where,
  ) {
    final v = m[key];
    if (v is! String || !values.any((e) => e.name == v)) _fail(where);
  }

  static void _pattern(Map<String, Object?> m, String key, String where) {
    final v = m[key];
    if (v is! Map) _fail(where);
    try {
      FrequencyPattern.fromJson(Map<String, dynamic>.from(v));
    } catch (_) {
      _fail(where);
    }
  }

  static void _decision(Map<String, Object?> m, String key, String where) {
    final v = m[key];
    if (v is! Map) _fail(where);
    final type = v['type'];
    if (type == 'adjust') {
      _pattern(Map<String, Object?>.from(v), 'pattern', where);
    } else if (type != 'continue' && type != 'pause') {
      _fail(where);
    }
  }

  static FrequencyPattern _patternOf(Map<String, Object?> m, String key) =>
      FrequencyPattern.fromJson(Map<String, dynamic>.from(m[key]! as Map));

  /// 004 v5（D2）：themeMode 值域冻结 system|light|dark；缺键/未知值
  /// 宽容归一 NULL（= system，沿 data-model.md 值域冻结口径）。
  static String? _normThemeMode(Object? v) =>
      (v == 'system' || v == 'light' || v == 'dark') ? v as String? : null;
}
