/// 仓储层：drift 表 ⇄ 领域实体映射 + 流式查询（tasks.md T011）。
///
/// UI/业务只面向这里与领域模型，不触碰 drift 行类型（故 db 导入用别名，
/// 领域类不加前缀直接使用）。业务规则（活跃上限、频率版本唯一性、
/// 撤销不删除）在本层把关；"今天/下周"由服务层按注入时钟算好传入。
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';
import 'app_database.dart' as db;

/// 活跃目标已达上限（FR-011，UI 捕获后触发聚焦引导）。
class ActiveGoalLimitException implements Exception {
  const ActiveGoalLimitException(this.limit);

  final int limit;

  @override
  String toString() => '活跃目标已达上限 $limit 个';
}

// ---------------------------------------------------------------------------
// GoalRepository（含 FrequencyVersion / BusyModeSession 管理）
// ---------------------------------------------------------------------------

class GoalRepository {
  GoalRepository(this._db);

  final db.AppDatabase _db;

  // ---- Goal ----

  Stream<List<Goal>> watchGoals() => _db.select(_db.goals).map(_toGoal).watch();

  /// active 目标（habit+milestone 合计，今日视图/上限校验用）。
  Stream<List<Goal>> watchActiveGoals() => (_db.select(_db.goals)
        ..where((t) => t.status.equalsValue(GoalStatus.active)))
      .map(_toGoal)
      .watch();

  Future<List<Goal>> getGoals() =>
      _db.select(_db.goals).map(_toGoal).get();

  /// 创建；active 数（两类合计）≥ 5 时拒绝（FR-011）。
  Future<Goal> create(Goal goal) async {
    if (goal.status == GoalStatus.active) {
      final active = await (_db.select(_db.goals)
            ..where((t) => t.status.equalsValue(GoalStatus.active)))
          .get();
      if (active.length >= kMaxActiveGoals) {
        throw const ActiveGoalLimitException(kMaxActiveGoals);
      }
    }
    await _db.into(_db.goals).insert(_fromGoal(goal));
    return goal;
  }

  Future<void> update(Goal goal) =>
      (_db.update(_db.goals)..where((t) => t.id.equals(goal.id)))
          .write(_fromGoal(goal));

  static Goal _toGoal(db.Goal r) => Goal(
        id: r.id,
        name: r.name,
        kind: r.kind,
        iconKey: r.iconKey,
        colorKey: r.colorKey,
        status: r.status,
        createdAt: r.createdAt,
        deadline: r.deadline,
      );

  static db.GoalsCompanion _fromGoal(Goal g) => db.GoalsCompanion.insert(
        id: g.id,
        name: g.name,
        kind: g.kind,
        iconKey: g.iconKey,
        colorKey: g.colorKey,
        status: g.status,
        createdAt: g.createdAt,
        deadline: Value(g.deadline),
      );

  // ---- FrequencyVersion ----

  Future<List<FrequencyVersion>> versionsOf(String goalId) =>
      (_db.select(_db.frequencyVersions)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.asc(t.effectiveFromWeek)]))
          .map(_toVersion)
          .get();

  /// 用户编辑频率：[effectiveFrom]（= 下周一，服务层按注入时钟算出）生效；
  /// 同周已有待生效非 busyMode 版本则覆盖（FR-002：当前周仍按旧口径）。
  Future<void> addUserEdit(
      String goalId, FrequencyPattern pattern, WeekStart effectiveFrom) async {
    final versions = await versionsOf(goalId);
    final clash = versions
        .where((v) =>
            v.effectiveFromWeek == effectiveFrom &&
            v.source != FrequencySource.busyMode)
        .firstOrNull;
    if (clash != null) {
      await (_db.delete(_db.frequencyVersions)
            ..where((t) => t.id.equals(clash.id)))
          .go();
    }
    await _db
        .into(_db.frequencyVersions)
        .insert(db.FrequencyVersionsCompanion.insert(
          id: newId(),
          goalId: goalId,
          effectiveFromWeek: effectiveFrom,
          pattern: pattern,
          source: FrequencySource.userEdit,
        ));
  }

  /// busyMode：插入/更新本周版本（同一目标同一周至多一个 busyMode 版本）。
  Future<void> addBusyMode(
      String goalId, WeekStart week, FrequencyPattern downgraded) async {
    final versions = await versionsOf(goalId);
    final clash = versions
        .where((v) =>
            v.effectiveFromWeek == week && v.source == FrequencySource.busyMode)
        .firstOrNull;
    if (clash != null) {
      await (_db.update(_db.frequencyVersions)
            ..where((t) => t.id.equals(clash.id)))
          .write(db.FrequencyVersionsCompanion(pattern: Value(downgraded)));
      return;
    }
    await _db
        .into(_db.frequencyVersions)
        .insert(db.FrequencyVersionsCompanion.insert(
          id: newId(),
          goalId: goalId,
          effectiveFromWeek: week,
          pattern: downgraded,
          source: FrequencySource.busyMode,
        ));
  }

  /// 恢复忙碌模式 = 移除该目标该周的 busyMode 版本（FR-018）。
  Future<void> removeBusyMode(String goalId, WeekStart week) =>
      (_db.delete(_db.frequencyVersions)
            ..where((t) =>
                t.goalId.equals(goalId) &
                t.effectiveFromWeek.equalsValue(week) &
                t.source.equalsValue(FrequencySource.busyMode)))
          .go();

  static FrequencyVersion _toVersion(db.FrequencyVersion r) =>
      FrequencyVersion(
        id: r.id,
        goalId: r.goalId,
        effectiveFromWeek: r.effectiveFromWeek,
        pattern: r.pattern,
        source: r.source,
      );

  // ---- MilestoneStep ----

  Stream<List<MilestoneStep>> watchStepsOf(String goalId) =>
      (_db.select(_db.milestoneSteps)..where((t) => t.goalId.equals(goalId)))
          .map(_toStep)
          .watch();

  Future<List<MilestoneStep>> stepsOf(String goalId) =>
      (_db.select(_db.milestoneSteps)..where((t) => t.goalId.equals(goalId)))
          .map(_toStep)
          .get();

  Future<MilestoneStep> addStep(MilestoneStep s) async {
    await _db.into(_db.milestoneSteps).insert(db.MilestoneStepsCompanion.insert(
          goalId: s.goalId,
          title: s.title,
          isDone: s.isDone,
          doneAt: Value(s.doneAt),
          id: s.id,
        ));
    return s;
  }

  Future<void> updateStep(MilestoneStep s) =>
      (_db.update(_db.milestoneSteps)..where((t) => t.id.equals(s.id)))
          .write(db.MilestoneStepsCompanion(
            title: Value(s.title),
            isDone: Value(s.isDone),
            doneAt: Value(s.doneAt),
          ));

  Future<void> removeStep(String id) =>
      (_db.delete(_db.milestoneSteps)..where((t) => t.id.equals(id))).go();

  static MilestoneStep _toStep(db.MilestoneStep r) => MilestoneStep(
        id: r.id,
        goalId: r.goalId,
        title: r.title,
        isDone: r.isDone,
        doneAt: r.doneAt,
      );

  // ---- BusyModeSession ----

  /// 会话 + 子行两表拼接：主表流式，子表随行查询（数据量小，v1 可接受）。
  Stream<List<BusyModeSession>> watchSessions() async* {
    await for (final rows in _db.select(_db.busyModeSessions).watch()) {
      final sessions = <BusyModeSession>[];
      for (final r in rows) {
        final entries = await (_db.select(_db.busyModeEntries)
              ..where((t) => t.sessionId.equals(r.id)))
            .map((e) =>
                BusyModeEntry(goalId: e.goalId, downgraded: e.downgraded))
            .get();
        sessions.add(BusyModeSession(
          id: r.id,
          weekStart: r.weekStart,
          entries: entries,
          startedAt: r.startedAt,
          endedAt: r.endedAt,
        ));
      }
      yield sessions;
    }
  }

  Future<BusyModeSession> openSession(
      WeekStart week, List<BusyModeEntry> entries, DateTime now) async {
    final session = BusyModeSession(
      weekStart: week,
      entries: entries,
      startedAt: now.toUtc(),
    );
    await _db.transaction(() async {
      await _db.into(_db.busyModeSessions).insert(
          db.BusyModeSessionsCompanion.insert(
        id: session.id,
        weekStart: week,
        startedAt: session.startedAt,
        endedAt: Value(session.endedAt),
      ));
      for (final e in entries) {
        await _db.into(_db.busyModeEntries).insert(
            db.BusyModeEntriesCompanion.insert(
          id: newId(),
          sessionId: session.id,
          goalId: e.goalId,
          downgraded: e.downgraded,
        ));
      }
    });
    return session;
  }

  Future<void> endSession(BusyModeSession session, DateTime now) =>
      (_db.update(_db.busyModeSessions)
            ..where((t) => t.id.equals(session.id)))
          .write(db.BusyModeSessionsCompanion(endedAt: Value(now.toUtc())));
}

// ---------------------------------------------------------------------------
// CheckInRepository
// ---------------------------------------------------------------------------

class CheckInRepository {
  CheckInRepository(this._db);

  final db.AppDatabase _db;

  Stream<List<CheckIn>> watchOf(String goalId) =>
      (_db.select(_db.checkIns)..where((t) => t.goalId.equals(goalId)))
          .map(_to)
          .watch();

  Stream<List<CheckIn>> watchAll() =>
      _db.select(_db.checkIns).map(_to).watch();

  Future<List<CheckIn>> all() =>
      _db.select(_db.checkIns).map(_to).get();

  /// 打卡（当日/补签统一入口）；isBackfill 由实体构造自动判定。
  Future<CheckIn> add(String goalId, LocalDate day, DateTime now) async {
    final c = CheckIn(goalId: goalId, day: day, createdAt: now.toUtc());
    await _db.into(_db.checkIns).insert(db.CheckInsCompanion.insert(
          id: c.id,
          goalId: c.goalId,
          day: c.day,
          createdAt: c.createdAt,
          isBackfill: c.isBackfill,
          status: c.status,
        ));
    return c;
  }

  /// 撤销 = 置 revoked，不物理删除（SC-003）。
  Future<void> revoke(String checkInId) =>
      (_db.update(_db.checkIns)..where((t) => t.id.equals(checkInId)))
          .write(const db.CheckInsCompanion(
              status: Value(CheckInStatus.revoked)));

  static CheckIn _to(db.CheckIn r) => CheckIn(
        id: r.id,
        goalId: r.goalId,
        day: r.day,
        createdAt: r.createdAt,
        status: r.status,
      );
}

// ---------------------------------------------------------------------------
// ReminderRepository
// ---------------------------------------------------------------------------

class ReminderRepository {
  ReminderRepository(this._db);

  final db.AppDatabase _db;

  Stream<List<Reminder>> watchAll() =>
      _db.select(_db.reminders).map(_to).watch();

  Future<List<Reminder>> all() =>
      _db.select(_db.reminders).map(_to).get();

  Future<Reminder> upsert(Reminder r) async {
    await _db.into(_db.reminders).insert(
        db.RemindersCompanion.insert(
          id: r.id,
          goalId: Value(r.goalId),
          time: r.time,
          isEnabled: r.isEnabled,
        ),
        mode: InsertMode.insertOrReplace);
    return r;
  }

  Future<void> remove(String id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();

  Future<void> removeByGoal(String goalId) =>
      (_db.delete(_db.reminders)..where((t) => t.goalId.equals(goalId))).go();

  static Reminder _to(db.Reminder r) => Reminder(
        id: r.id,
        goalId: r.goalId,
        time: r.time,
        isEnabled: r.isEnabled,
      );
}

// ---------------------------------------------------------------------------
// ReviewRepository（含 GoalWeekStat / decision 的 JSON 编解码）
// ---------------------------------------------------------------------------

class ReviewRepository {
  ReviewRepository(this._db);

  final db.AppDatabase _db;

  Stream<List<WeeklyReview>> watchAll() =>
      _db.select(_db.weeklyReviews).map(_to).watch();

  Future<List<WeeklyReview>> all() =>
      _db.select(_db.weeklyReviews).map(_to).get();

  Future<void> save(WeeklyReview r) =>
      _db.into(_db.weeklyReviews).insert(
          db.WeeklyReviewsCompanion.insert(
            id: r.id,
            weekStart: r.weekStart,
            settledAt: r.settledAt,
            snapshotJson: encodeSnapshot(r.snapshot),
            decisionJson: encodeDecision(r.decision),
            note: Value(r.note),
          ),
          mode: InsertMode.insertOrReplace);

  static WeeklyReview _to(db.WeeklyReview r) => WeeklyReview(
        id: r.id,
        weekStart: r.weekStart,
        settledAt: r.settledAt,
        snapshot: decodeSnapshot(r.snapshotJson),
        note: r.note,
        decision: decodeDecision(r.decisionJson),
      );

  // ---- 编解码（备份文件复用同一格式，contracts/backup-format.md）----

  static String encodeSnapshot(List<GoalWeekStat> stats) => jsonEncode(stats
      .map((s) => {
            'goalId': s.goalId,
            'applicableDays': s.applicableDays,
            'metDays': s.metDays,
            'completionRate': s.completionRate,
            'backfillCount': s.backfillCount,
            'busyModeApplied': s.busyModeApplied,
          })
      .toList());

  static List<GoalWeekStat> decodeSnapshot(String json) =>
      (jsonDecode(json) as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return GoalWeekStat(
          goalId: m['goalId'] as String,
          applicableDays: m['applicableDays'] as int,
          metDays: m['metDays'] as int,
          completionRate: (m['completionRate'] as num?)?.toDouble(),
          backfillCount: m['backfillCount'] as int,
          busyModeApplied: m['busyModeApplied'] as bool,
        );
      }).toList();

  static String encodeDecision(ReviewDecision d) {
    switch (d) {
      case ContinueDecision():
        return jsonEncode({'type': 'continue'});
      case AdjustDecision(:final newPattern):
        return jsonEncode({'type': 'adjust', 'pattern': newPattern.toJson()});
      case PauseDecision():
        return jsonEncode({'type': 'pause'});
    }
  }

  static ReviewDecision decodeDecision(String json) {
    final m = Map<String, dynamic>.from(jsonDecode(json) as Map);
    return switch (m['type'] as String) {
      'adjust' => AdjustDecision(
          FrequencyPattern.fromJson(Map<String, dynamic>.from(m['pattern']))),
      'pause' => const PauseDecision(),
      _ => const ContinueDecision(),
    };
  }
}

// ---------------------------------------------------------------------------
// SettingsRepository
// ---------------------------------------------------------------------------

class SettingsRepository {
  SettingsRepository(this._db);

  final db.AppDatabase _db;

  /// onCreate 已插入单例行；防御性 get-or-create。
  Stream<Settings> watch() =>
      (_db.select(_db.settingsRows)..where((t) => t.id.equals(1)))
          .map(_to)
          .watchSingle();

  Future<Settings> get() async {
    final rows = await _db.select(_db.settingsRows).get();
    if (rows.isNotEmpty) return _to(rows.first);
    const fallback = Settings();
    await _db.into(_db.settingsRows)
        .insert(db.SettingsRowsCompanion.insert(
            dailyBriefTime: fallback.dailyBriefTime));
    return fallback;
  }

  Future<void> update(Settings s) =>
      (_db.update(_db.settingsRows)..where((t) => t.id.equals(1)))
          .write(db.SettingsRowsCompanion(
            dailyBriefTime: Value(s.dailyBriefTime),
            onboardingCompleted: Value(s.onboardingCompleted),
            notificationDeniedAcknowledged:
                Value(s.notificationDeniedAcknowledged),
          ));

  static Settings _to(db.SettingsRow r) => Settings(
        dailyBriefTime: r.dailyBriefTime,
        onboardingCompleted: r.onboardingCompleted,
        notificationDeniedAcknowledged: r.notificationDeniedAcknowledged,
      );
}
