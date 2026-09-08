/// v3 仓库层（schema v8）：目标 / 里程碑（达成流）/ 富记录 / 提醒 / 设置。
///
/// 业务事务边界（specs/006 spec FR-003/004/010）：
/// - 目标创建 = goal + milestones + reminder 原子落库；
/// - 里程碑达成 = isDone/doneAt + 达成记录同事务（撤销同步撤除）；
/// - 置顶 = pinnedOrder 序维护（置顶=追加至末位，取消=压缩序号）。
/// UI/业务只面向这里与领域模型，不触碰 drift 行类型。
library;

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart';
import 'app_database.dart';

// ---------------------------------------------------------------------------
// 行 ⇄ 实体映射（库内顶层共享）
// ---------------------------------------------------------------------------

GoalsCompanion goalCompanion(Goal g) => GoalsCompanion.insert(
      id: g.id,
      name: g.name,
      why: Value(g.why),
      categoryKey: Value(g.categoryKey),
      iconKey: g.iconKey,
      colorKey: g.colorKey,
      pinned: Value(g.pinned),
      pinnedOrder: Value(g.pinnedOrder),
      targetDate: Value(g.targetDate),
      frequency: Value(g.frequency),
      status: g.status,
      createdAt: g.createdAt,
      achievedAt: Value(g.achievedAt),
      archivedAt: Value(g.archivedAt),
    );

Goal goalFromRow(GoalRow r) => Goal(
      id: r.id,
      name: r.name,
      why: r.why,
      categoryKey: r.categoryKey,
      iconKey: r.iconKey,
      colorKey: r.colorKey,
      pinned: r.pinned,
      pinnedOrder: r.pinnedOrder,
      targetDate: r.targetDate,
      frequency: r.frequency,
      status: r.status,
      achievedAt: r.achievedAt,
      archivedAt: r.archivedAt,
      createdAt: r.createdAt,
    );

MilestonesCompanion milestoneCompanion(Milestone m, {int? position}) =>
    MilestonesCompanion.insert(
      id: m.id,
      goalId: m.goalId,
      title: m.title,
      description: Value(m.description),
      position: Value(position ?? m.position),
      isDone: Value(m.isDone),
      doneAt: Value(m.doneAt),
    );

Milestone milestoneFromRow(MilestoneRow r) => Milestone(
      id: r.id,
      goalId: r.goalId,
      title: r.title,
      description: r.description,
      position: r.position,
      isDone: r.isDone,
      doneAt: r.doneAt,
    );

ProgressRecordsCompanion recordCompanion(ProgressRecord r) =>
    ProgressRecordsCompanion.insert(
      id: r.id,
      goalId: r.goalId,
      title: r.title,
      body: Value(r.body),
      durationMinutes: Value(r.durationMinutes),
      day: r.day,
      createdAt: r.createdAt,
      isBackfill: Value(r.isBackfill),
      kind: r.kind,
      milestoneId: Value(r.milestoneId),
    );

ProgressRecord recordFromRow(RecordRow r) => ProgressRecord(
      id: r.id,
      goalId: r.goalId,
      title: r.title,
      body: r.body,
      durationMinutes: r.durationMinutes,
      day: r.day,
      createdAt: r.createdAt,
      isBackfill: r.isBackfill,
      kind: r.kind,
      milestoneId: r.milestoneId,
    );

RemindersCompanion reminderCompanion(Reminder r, {String? id}) =>
    RemindersCompanion.insert(
      id: id ?? r.id,
      goalId: r.goalId,
      time: r.time,
      isEnabled: Value(r.isEnabled),
      cadence: r.cadence,
    );

Reminder reminderFromRow(ReminderRow r) => Reminder(
      id: r.id,
      goalId: r.goalId,
      time: r.time,
      isEnabled: r.isEnabled,
      cadence: r.cadence,
    );

// ---------------------------------------------------------------------------
// GoalRepository
// ---------------------------------------------------------------------------

class GoalRepository {
  GoalRepository(this._db);

  final AppDatabase _db;

  Stream<List<Goal>> watchGoals() =>
      (_db.select(_db.goals)
            ..orderBy([
              (g) => OrderingTerm.desc(g.pinned),
              (g) => OrderingTerm.asc(g.pinnedOrder),
              (g) => OrderingTerm.desc(g.createdAt),
            ]))
          .map(goalFromRow)
          .watch();

  Future<List<Goal>> getGoals() async =>
      (await (_db.select(_db.goals)
            ..orderBy([
              (g) => OrderingTerm.desc(g.pinned),
              (g) => OrderingTerm.asc(g.pinnedOrder),
              (g) => OrderingTerm.desc(g.createdAt),
            ]))
          .get())
          .map(goalFromRow)
          .toList();

  Future<Goal> goalById(String id) async =>
      goalFromRow(await (_db.select(_db.goals)..where((g) => g.id.equals(id)))
          .getSingle());

  /// 完整目标创建（编辑器保存）：goal + 里程碑 + 提醒原子落库。
  Future<Goal> createPlan(
    Goal goal,
    List<Milestone> milestones, {
    Reminder? reminder,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.goals).insert(goalCompanion(goal));
        for (final (i, m) in milestones.indexed) {
          await _db
              .into(_db.milestones)
              .insert(milestoneCompanion(m, position: i));
        }
        if (reminder != null) {
          await _db.into(_db.reminders).insert(reminderCompanion(reminder));
        }
        return goal;
      });

  Future<void> update(Goal goal) =>
      (_db.update(_db.goals)..where((g) => g.id.equals(goal.id)))
          .write(goalCompanion(goal));

  /// 删除为独立破坏性操作：级联清记录/里程碑/提醒（UI 层二次确认）。
  Future<void> deleteGoal(String goalId) => _db.transaction(() async {
        await (_db.delete(_db.progressRecords)
              ..where((r) => r.goalId.equals(goalId)))
            .go();
        await (_db.delete(_db.milestones)
              ..where((m) => m.goalId.equals(goalId)))
            .go();
        await (_db.delete(_db.reminders)
              ..where((r) => r.goalId.equals(goalId)))
            .go();
        await (_db.delete(_db.goals)..where((g) => g.id.equals(goalId))).go();
      });

  /// 置顶：pinnedOrder 追加至末位；取消置顶：置空并压缩其余序号。
  Future<void> setPinned(String goalId, bool pinned) =>
      _db.transaction(() async {
        if (pinned) {
          final max = _db.selectOnly(_db.goals)
            ..addColumns([_db.goals.pinnedOrder.max()])
            ..where(_db.goals.pinned.equals(true));
          final current =
              (await max.getSingle()).read(_db.goals.pinnedOrder.max()) ?? -1;
          await (_db.update(_db.goals)..where((g) => g.id.equals(goalId)))
              .write(GoalsCompanion(
                pinned: const Value(true),
                pinnedOrder: Value(current + 1),
              ));
        } else {
          await (_db.update(_db.goals)..where((g) => g.id.equals(goalId)))
              .write(const GoalsCompanion(
                pinned: Value(false),
                pinnedOrder: Value(null),
              ));
          await _compactPinnedOrder();
        }
      });

  Future<void> _compactPinnedOrder() async {
    final pinned = await (_db.select(_db.goals)
          ..where((g) => g.pinned.equals(true))
          ..orderBy([(g) => OrderingTerm.asc(g.pinnedOrder)]))
        .get();
    for (final (i, row) in pinned.indexed) {
      if (row.pinnedOrder != i) {
        await (_db.update(_db.goals)..where((g) => g.id.equals(row.id)))
            .write(GoalsCompanion(pinnedOrder: Value(i)));
      }
    }
  }

  /// 编辑置顶模式：按拖拽结果重写置顶序（0..n）。
  Future<void> reorderPinned(List<String> orderedGoalIds) =>
      _db.transaction(() async {
        for (final (i, id) in orderedGoalIds.indexed) {
          await (_db.update(_db.goals)
                ..where((g) => g.id.equals(id) & g.pinned.equals(true)))
              .write(GoalsCompanion(pinnedOrder: Value(i)));
        }
      });

  /// 生命周期流转（状态机校验；达成/归档落时间戳）。
  Future<void> transit(String goalId, GoalStatus to, DateTime now) async {
    final goal = await goalById(goalId);
    if (!goal.canTransitTo(to)) {
      throw StateError('${goal.status.name} → ${to.name} 非法流转');
    }
    await (_db.update(_db.goals)..where((g) => g.id.equals(goalId))).write(
          GoalsCompanion(
            status: Value(to),
            achievedAt: Value(
              to == GoalStatus.achieved
                  ? now
                  : to == GoalStatus.active
                      ? null
                      : goal.achievedAt,
            ),
            archivedAt: Value(
              to == GoalStatus.archived
                  ? now
                  : to == GoalStatus.active
                      ? null
                      : goal.archivedAt,
            ),
          ),
        );
  }
}

// ---------------------------------------------------------------------------
// MilestoneRepository
// ---------------------------------------------------------------------------

class MilestoneRepository {
  MilestoneRepository(this._db);

  final AppDatabase _db;

  Stream<List<Milestone>> watchOf(String goalId) =>
      (_db.select(_db.milestones)
            ..where((m) => m.goalId.equals(goalId))
            ..orderBy([(m) => OrderingTerm.asc(m.position)]))
          .map(milestoneFromRow)
          .watch();

  Stream<List<Milestone>> watchAll() =>
      (_db.select(_db.milestones)
            ..orderBy([(m) => OrderingTerm.asc(m.position)]))
          .map(milestoneFromRow)
          .watch();

  Future<List<Milestone>> of(String goalId) async =>
      (await (_db.select(_db.milestones)
            ..where((m) => m.goalId.equals(goalId))
            ..orderBy([(m) => OrderingTerm.asc(m.position)]))
          .get())
          .map(milestoneFromRow)
          .toList();

  Future<Milestone> add(Milestone m) async {
    final next = await _nextPosition(m.goalId);
    final row = m.copyWith(position: next);
    await _db.into(_db.milestones).insert(milestoneCompanion(row));
    return row;
  }

  Future<int> _nextPosition(String goalId) async {
    final q = _db.selectOnly(_db.milestones)
      ..addColumns([_db.milestones.position.max()])
      ..where(_db.milestones.goalId.equals(goalId));
    return ((await q.getSingle()).read(_db.milestones.position.max()) ?? -1) + 1;
  }

  Future<void> update(Milestone m) =>
      (_db.update(_db.milestones)..where((x) => x.id.equals(m.id)))
          .write(milestoneCompanion(m));

  Future<void> remove(String id) => _db.transaction(() async {
        // 普通记录的关联引用置空；达成记录随里程碑删除一并移除。
        await (_db.update(_db.progressRecords)
              ..where((r) =>
                  r.milestoneId.equals(id) &
                  r.kind.equalsValue(RecordKind.normal)))
            .write(const ProgressRecordsCompanion(milestoneId: Value(null)));
        await (_db.delete(_db.progressRecords)
              ..where((r) =>
                  r.milestoneId.equals(id) &
                  r.kind.equalsValue(RecordKind.milestoneAchievement)))
            .go();
        await (_db.delete(_db.milestones)..where((x) => x.id.equals(id))).go();
      });

  /// 编辑器保存：整组替换（按位匹配保留既有 id/达成态；多余删除、
  /// 新增补位），维护「结构编辑只在编辑器」边界。
  Future<void> reorderFromEditor(
    String goalId,
    List<Milestone> drafted,
  ) =>
      _db.transaction(() async {
        final existing = await of(goalId);
        for (final (i, m) in drafted.indexed) {
          if (i < existing.length) {
            final keep = existing[i];
            await update(
              keep.copyWith(title: m.title, description: m.description),
            );
          } else {
            await _db
                .into(_db.milestones)
                .insert(milestoneCompanion(m, position: i));
          }
        }
        for (final extra in existing.skip(drafted.length)) {
          await remove(extra.id);
        }
      });

  /// 按目标重排（编辑器拖拽）。
  Future<void> reorder(String goalId, List<String> orderedIds) =>
      _db.transaction(() async {
        for (final (i, id) in orderedIds.indexed) {
          await (_db.update(_db.milestones)
                ..where((x) => x.id.equals(id) & x.goalId.equals(goalId)))
              .write(MilestonesCompanion(position: Value(i)));
        }
      });

  /// 达成流（FR-003）：isDone/doneAt + 达成记录同事务；可附一句话。
  Future<void> markDone(String milestoneId, {String? note, DateTime? now}) =>
      _db.transaction(() async {
        final row = await (_db.select(_db.milestones)
              ..where((x) => x.id.equals(milestoneId)))
            .getSingle();
        final at = (now ?? DateTime.now()).toUtc();
        await (_db.update(_db.milestones)
              ..where((x) => x.id.equals(milestoneId)))
            .write(MilestonesCompanion(
              isDone: const Value(true),
              doneAt: Value(at),
            ));
        await _db.into(_db.progressRecords).insert(recordCompanion(
              ProgressRecord(
                goalId: row.goalId,
                title: row.title,
                body:
                    (note == null || note.trim().isEmpty) ? null : note.trim(),
                day: LocalDate.fromDateTime(DateTime.now()),
                createdAt: at,
                kind: RecordKind.milestoneAchievement,
                milestoneId: milestoneId,
              ),
            ));
      });

  /// 撤销达成：清 doneAt 并删除对应达成记录。
  Future<void> undoDone(String milestoneId) => _db.transaction(() async {
        await (_db.update(_db.milestones)
              ..where((x) => x.id.equals(milestoneId)))
            .write(const MilestonesCompanion(
          isDone: Value(false),
          doneAt: Value(null),
        ));
        await (_db.delete(_db.progressRecords)
              ..where((r) =>
                  r.milestoneId.equals(milestoneId) &
                  r.kind.equalsValue(RecordKind.milestoneAchievement)))
            .go();
      });
}

// ---------------------------------------------------------------------------
// RecordRepository
// ---------------------------------------------------------------------------

class RecordRepository {
  RecordRepository(this._db);

  final AppDatabase _db;

  Stream<List<ProgressRecord>> watchOf(String goalId) =>
      (_db.select(_db.progressRecords)
            ..where((r) => r.goalId.equals(goalId))
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .map(recordFromRow)
          .watch();

  Stream<List<ProgressRecord>> watchAll() =>
      (_db.select(_db.progressRecords)
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .map(recordFromRow)
          .watch();

  /// 写入：day 早于创建当日自动判 isBackfill（FR-002 补记）。
  Future<ProgressRecord> add(ProgressRecord r, {LocalDate? today}) async {
    final fallbackToday = LocalDate.fromDateTime(DateTime.now());
    final isBackfill = r.day.isBefore(today ?? fallbackToday);
    final row = ProgressRecord(
      id: r.id,
      goalId: r.goalId,
      title: r.title,
      body: r.body,
      durationMinutes: r.durationMinutes,
      day: r.day,
      createdAt: r.createdAt,
      isBackfill: isBackfill,
      kind: r.kind,
      milestoneId: r.milestoneId,
    );
    await _db.into(_db.progressRecords).insert(recordCompanion(row));
    return row;
  }

  /// 撤销/删除单条记录（保存 toast 撤销与详情删除共用）。
  Future<void> remove(String id) =>
      (_db.delete(_db.progressRecords)..where((r) => r.id.equals(id))).go();
}

// ---------------------------------------------------------------------------
// ReminderRepository / SettingsRepository
// ---------------------------------------------------------------------------

class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Stream<List<Reminder>> watchAll() =>
      _db.select(_db.reminders).map(reminderFromRow).watch();

  Future<List<Reminder>> all() async =>
      (await (_db.select(_db.reminders).get())).map(reminderFromRow).toList();

  Future<Reminder?> of(String goalId) async {
    final rows = await (_db.select(_db.reminders)
          ..where((r) => r.goalId.equals(goalId)))
        .get();
    return rows.isEmpty ? null : reminderFromRow(rows.first);
  }

  /// 每目标至多一条（v3 语义）；有则更新无则插入。
  Future<void> upsert(Reminder r) async {
    final existing = await of(r.goalId);
    if (existing == null) {
      await _db.into(_db.reminders).insert(reminderCompanion(r));
    } else {
      await (_db.update(_db.reminders)..where((x) => x.id.equals(existing.id)))
          .write(reminderCompanion(r, id: existing.id));
    }
  }

  Future<void> removeByGoal(String goalId) =>
      (_db.delete(_db.reminders)..where((r) => r.goalId.equals(goalId))).go();
}

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<AppSettings> watch() =>
      (_db.select(_db.settingsRows)..where((s) => s.id.equals(1)))
          .watchSingle()
          .map(_to);

  Future<AppSettings> get() async => _to(
        await (_db.select(_db.settingsRows)..where((s) => s.id.equals(1)))
            .getSingle(),
      );

  Future<void> update(AppSettings s) =>
      (_db.update(_db.settingsRows)..where((x) => x.id.equals(1))).write(
            SettingsRowsCompanion(
              nickname: Value(s.nickname),
              avatarKey: Value(s.avatarKey),
              themeMode: Value(s.themeMode),
              remindersEnabled: Value(s.remindersEnabled),
            ),
          );

  AppSettings _to(SettingsRow r) => AppSettings(
        nickname: r.nickname,
        avatarKey: r.avatarKey,
        themeMode: r.themeMode,
        remindersEnabled: r.remindersEnabled,
      );
}
