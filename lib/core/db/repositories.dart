/// 仓储层：drift 表 ⇄ 领域实体映射 + 流式查询（tasks.md T011）。
///
/// UI/业务只面向这里与领域模型，不触碰 drift 行类型（故 db 导入用别名，
/// 领域类不加前缀直接使用）。业务规则（频率版本唯一性、
/// 撤销不删除）在本层把关；"今天/下周"由服务层按注入时钟算好传入。
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';
import 'app_database.dart' as db;
import 'goal_row_mapper.dart';

// ---------------------------------------------------------------------------
// GoalRepository（含 FrequencyVersion / BusyModeSession 管理）
// ---------------------------------------------------------------------------

class GoalRepository {
  GoalRepository(this._db);

  final db.AppDatabase _db;

  // ---- Goal ----

  Stream<List<Goal>> watchGoals() =>
      _db.select(_db.goals).map(GoalRowMapper.fromRow).watch();

  /// 未归档的 active 目标。
  Stream<List<Goal>> watchActiveGoals() =>
      (_db.select(_db.goals)..where(
            (t) =>
                t.status.equalsValue(GoalStatus.active) & t.archivedAt.isNull(),
          ))
          .map(GoalRowMapper.fromRow)
          .watch();

  Future<List<Goal>> getGoals() =>
      _db.select(_db.goals).map(GoalRowMapper.fromRow).get();

  Future<Goal> create(Goal goal) async {
    await _db.into(_db.goals).insert(GoalRowMapper.toCompanion(goal));
    return goal;
  }

  Future<void> update(Goal goal) => (_db.update(
    _db.goals,
  )..where((t) => t.id.equals(goal.id))).write(GoalRowMapper.toCompanion(goal));

  /// 物理删除（004 v2 详情「删除目标」）：连带打卡/步骤/提醒/频率版本
  /// 全部级联清行，事务保证不留悬空外键；周回顾快照自含 JSON 不受影响
  /// （spec 边界：往周统计按历史记录口径呈现，不因删除崩坏）。
  Future<void> deleteGoal(String goalId) => _db.transaction(() async {
    await (_db.delete(
      _db.checkIns,
    )..where((t) => t.goalId.equals(goalId))).go();
    await (_db.delete(
      _db.milestoneSteps,
    )..where((t) => t.goalId.equals(goalId))).go();
    await (_db.delete(
      _db.reminders,
    )..where((t) => t.goalId.equals(goalId))).go();
    await (_db.delete(
      _db.frequencyVersions,
    )..where((t) => t.goalId.equals(goalId))).go();
    await (_db.delete(_db.goals)..where((t) => t.id.equals(goalId))).go();
  });

  // ---- FrequencyVersion（003 T013 停写：整表只读保全）----
  // 003 起频率概念退役为提醒 cadence，App 不再创建/修改/删除版本行；
  // 存量行保留供编辑器回显（effectivePattern）与备份往返（importer
  // 直插还原，不走本仓储）。写入 API（addInitial/addUserEdit/
  // addBusyMode/removeBusyMode）已删除。

  Future<List<FrequencyVersion>> versionsOf(String goalId) =>
      (_db.select(_db.frequencyVersions)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.asc(t.effectiveFromWeek)]))
          .map(_toVersion)
          .get();

  /// 全量版本流（编辑器/详情回显供货）。
  Stream<List<FrequencyVersion>> watchAllVersions() =>
      (_db.select(_db.frequencyVersions)
            ..orderBy([(t) => OrderingTerm.asc(t.effectiveFromWeek)]))
          .map(_toVersion)
          .watch();

  static FrequencyVersion _toVersion(db.FrequencyVersion r) => FrequencyVersion(
    id: r.id,
    goalId: r.goalId,
    effectiveFromWeek: r.effectiveFromWeek,
    pattern: r.pattern,
    source: r.source,
  );

  // ---- MilestoneStep ----

  Stream<List<MilestoneStep>> watchStepsOf(String goalId) =>
      (_db.select(_db.milestoneSteps)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .map(_toStep)
          .watch();

  /// 全量里程碑流。评分引擎一次性按 goalId 分组，避免在 Provider 中动态
  /// watch family 导致订阅数量和目标列表互相耦合。
  Stream<List<MilestoneStep>> watchAllSteps() =>
      (_db.select(_db.milestoneSteps)..orderBy([
            (t) => OrderingTerm.asc(t.goalId),
            (t) => OrderingTerm.asc(t.position),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .map(_toStep)
          .watch();

  Future<List<MilestoneStep>> stepsOf(String goalId) =>
      (_db.select(_db.milestoneSteps)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .map(_toStep)
          .get();

  Future<MilestoneStep> addStep(MilestoneStep s) async {
    await _db
        .into(_db.milestoneSteps)
        .insert(
          db.MilestoneStepsCompanion.insert(
            goalId: s.goalId,
            title: s.title,
            position: Value(s.position),
            isDone: s.isDone,
            doneAt: Value(s.doneAt),
            id: s.id,
          ),
        );
    return s;
  }

  /// 拖拽重排持久化：按传入顺序整体重写 position（0..n-1，顺带归一化
  /// 历史多步同位的脏数据）。
  Future<void> reorderSteps(String goalId, List<String> orderedIds) =>
      _db.batch((batch) {
        for (final (i, id) in orderedIds.indexed) {
          batch.update(
            _db.milestoneSteps,
            db.MilestoneStepsCompanion(position: Value(i)),
            where: (t) => t.id.equals(id) & t.goalId.equals(goalId),
          );
        }
      });

  Future<void> updateStep(MilestoneStep s) =>
      (_db.update(_db.milestoneSteps)..where((t) => t.id.equals(s.id))).write(
        db.MilestoneStepsCompanion(
          title: Value(s.title),
          position: Value(s.position),
          isDone: Value(s.isDone),
          doneAt: Value(s.doneAt),
        ),
      );

  Future<void> removeStep(String id) =>
      (_db.delete(_db.milestoneSteps)..where((t) => t.id.equals(id))).go();

  static MilestoneStep _toStep(db.MilestoneStep r) => MilestoneStep(
    id: r.id,
    goalId: r.goalId,
    title: r.title,
    position: r.position,
    isDone: r.isDone,
    doneAt: r.doneAt,
  );

  // ---- BusyModeSession ----

  /// 会话 + 子行两表拼接：主表流式，子表随行查询（数据量小，v1 可接受）。
  Stream<List<BusyModeSession>> watchSessions() async* {
    await for (final rows in _db.select(_db.busyModeSessions).watch()) {
      final sessions = <BusyModeSession>[];
      for (final r in rows) {
        final entries =
            await (_db.select(_db.busyModeEntries)
                  ..where((t) => t.sessionId.equals(r.id)))
                .map(
                  (e) =>
                      BusyModeEntry(goalId: e.goalId, downgraded: e.downgraded),
                )
                .get();
        sessions.add(
          BusyModeSession(
            id: r.id,
            weekStart: r.weekStart,
            entries: entries,
            startedAt: r.startedAt,
            endedAt: r.endedAt,
          ),
        );
      }
      yield sessions;
    }
  }

  Future<BusyModeSession> openSession(
    WeekStart week,
    List<BusyModeEntry> entries,
    DateTime now,
  ) async {
    final session = BusyModeSession(
      weekStart: week,
      entries: entries,
      startedAt: now.toUtc(),
    );
    await _db.transaction(() async {
      await _db
          .into(_db.busyModeSessions)
          .insert(
            db.BusyModeSessionsCompanion.insert(
              id: session.id,
              weekStart: week,
              startedAt: session.startedAt,
              endedAt: Value(session.endedAt),
            ),
          );
      for (final e in entries) {
        await _db
            .into(_db.busyModeEntries)
            .insert(
              db.BusyModeEntriesCompanion.insert(
                id: newId(),
                sessionId: session.id,
                goalId: e.goalId,
                downgraded: e.downgraded,
              ),
            );
      }
    });
    return session;
  }

  Future<void> endSession(BusyModeSession session, DateTime now) =>
      (_db.update(_db.busyModeSessions)..where((t) => t.id.equals(session.id)))
          .write(db.BusyModeSessionsCompanion(endedAt: Value(now.toUtc())));
}

// ---------------------------------------------------------------------------
// CheckInRepository
// ---------------------------------------------------------------------------

class CheckInRepository {
  CheckInRepository(this._db);

  final db.AppDatabase _db;

  Stream<List<CheckIn>> watchOf(String goalId) => (_db.select(
    _db.checkIns,
  )..where((t) => t.goalId.equals(goalId))).map(_to).watch();

  Stream<List<CheckIn>> watchAll() => _db.select(_db.checkIns).map(_to).watch();

  Future<List<CheckIn>> all() => _db.select(_db.checkIns).map(_to).get();

  /// 打卡（当日/补签统一入口）；isBackfill 由实体构造自动判定；
  /// note = 一句话描述（FR-019，可空，NULL 显示层兜底「完成打卡」）。
  Future<CheckIn> add(
    String goalId,
    LocalDate day,
    DateTime now, {
    String? note,
  }) async {
    final c = CheckIn(
      goalId: goalId,
      day: day,
      createdAt: now.toUtc(),
      note: note,
    );
    await _db
        .into(_db.checkIns)
        .insert(
          db.CheckInsCompanion.insert(
            id: c.id,
            goalId: c.goalId,
            day: c.day,
            createdAt: c.createdAt,
            isBackfill: c.isBackfill,
            status: c.status,
            note: Value(c.note),
          ),
        );
    return c;
  }

  /// 撤销 = 置 revoked，不物理删除（SC-003）。
  Future<void> revoke(String checkInId) =>
      (_db.update(_db.checkIns)..where((t) => t.id.equals(checkInId))).write(
        const db.CheckInsCompanion(status: Value(CheckInStatus.revoked)),
      );

  static CheckIn _to(db.CheckIn r) => CheckIn(
    id: r.id,
    goalId: r.goalId,
    day: r.day,
    createdAt: r.createdAt,
    status: r.status,
    note: r.note,
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

  Future<List<Reminder>> all() => _db.select(_db.reminders).map(_to).get();

  Future<Reminder> upsert(Reminder r) async {
    await _db
        .into(_db.reminders)
        .insert(
          db.RemindersCompanion.insert(
            id: r.id,
            goalId: Value(r.goalId),
            time: r.time,
            isEnabled: r.isEnabled,
            cadence: Value(r.cadence),
          ),
          mode: InsertMode.insertOrReplace,
        );
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
    cadence: r.cadence,
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

  Future<void> save(WeeklyReview r) => _db
      .into(_db.weeklyReviews)
      .insert(
        db.WeeklyReviewsCompanion.insert(
          id: r.id,
          weekStart: r.weekStart,
          settledAt: r.settledAt,
          snapshotJson: encodeSnapshot(r.snapshot),
          decisionJson: encodeDecision(r.decision),
          note: Value(r.note),
        ),
        mode: InsertMode.insertOrReplace,
      );

  static WeeklyReview _to(db.WeeklyReview r) => WeeklyReview(
    id: r.id,
    weekStart: r.weekStart,
    settledAt: r.settledAt,
    snapshot: decodeSnapshot(r.snapshotJson),
    note: r.note,
    decision: decodeDecision(r.decisionJson),
  );

  // ---- 编解码（备份文件复用同一格式，contracts/backup-format.md）----

  static String encodeSnapshot(List<GoalWeekStat> stats) => jsonEncode(
    stats
        .map(
          (s) => {
            'goalId': s.goalId,
            'metDays': s.metDays,
            'totalChecks': s.totalChecks,
            'backfillCount': s.backfillCount,
            'busyModeApplied': s.busyModeApplied,
          },
        )
        .toList(),
  );

  /// 003 口径收敛后的键；旧快照（applicableDays/completionRate）宽容
  /// 读取——未知键忽略、缺失键取默认（001 惯例，快照仅留痕）。
  static List<GoalWeekStat> decodeSnapshot(String json) =>
      (jsonDecode(json) as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return GoalWeekStat(
          goalId: m['goalId'] as String,
          metDays: m['metDays'] as int? ?? 0,
          totalChecks: m['totalChecks'] as int? ?? 0,
          backfillCount: m['backfillCount'] as int? ?? 0,
          busyModeApplied: m['busyModeApplied'] as bool? ?? false,
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
        FrequencyPattern.fromJson(Map<String, dynamic>.from(m['pattern'])),
      ),
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
  Stream<Settings> watch() => (_db.select(
    _db.settingsRows,
  )..where((t) => t.id.equals(1))).map(_to).watchSingle();

  Future<Settings> get() async {
    final rows = await _db.select(_db.settingsRows).get();
    if (rows.isNotEmpty) return _to(rows.first);
    const fallback = Settings();
    await _db
        .into(_db.settingsRows)
        .insert(
          db.SettingsRowsCompanion.insert(
            dailyBriefTime: fallback.dailyBriefTime,
          ),
        );
    return fallback;
  }

  Future<void> update(Settings s) =>
      (_db.update(_db.settingsRows)..where((t) => t.id.equals(1))).write(
        db.SettingsRowsCompanion(
          dailyBriefTime: Value(s.dailyBriefTime),
          onboardingCompleted: Value(s.onboardingCompleted),
          notificationDeniedAcknowledged: Value(
            s.notificationDeniedAcknowledged,
          ),
          // 004 v5（D2）：NULL 与 'system' 等价，统一落 .name。
          themeMode: Value(s.themeMode.name),
          defaultShortCadenceDays: Value(s.defaultShortCadenceDays),
          defaultLongCadenceDays: Value(s.defaultLongCadenceDays),
          scoreAlgorithmStartedOn: Value(s.scoreAlgorithmStartedOn),
        ),
      );

  static Settings _to(db.SettingsRow r) => Settings(
    dailyBriefTime: r.dailyBriefTime,
    onboardingCompleted: r.onboardingCompleted,
    notificationDeniedAcknowledged: r.notificationDeniedAcknowledged,
    themeMode: AppThemeMode.parse(r.themeMode),
    defaultShortCadenceDays: r.defaultShortCadenceDays ?? 7,
    defaultLongCadenceDays: r.defaultLongCadenceDays ?? 14,
    scoreAlgorithmStartedOn: r.scoreAlgorithmStartedOn,
  );

  /// 003 v3 账号资料（D7：单例行 nickname/avatar_key 两列）。
  Stream<Profile> watchProfile() =>
      (_db.select(_db.settingsRows)..where((t) => t.id.equals(1)))
          .map((r) => Profile(nickname: r.nickname, avatarKey: r.avatarKey))
          .watchSingle();

  Future<Profile> getProfile() async {
    final rows = await _db.select(_db.settingsRows).get();
    return rows.isEmpty
        ? Profile.empty
        : Profile(
            nickname: rows.first.nickname,
            avatarKey: rows.first.avatarKey,
          );
  }

  Future<void> updateProfile(Profile p) =>
      (_db.update(_db.settingsRows)..where((t) => t.id.equals(1))).write(
        db.SettingsRowsCompanion(
          nickname: Value(p.nickname),
          avatarKey: Value(p.avatarKey),
        ),
      );
}
