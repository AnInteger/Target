library;

import 'package:drift/drift.dart';

import '../models/entities.dart';
import '../models/goal_plan.dart';
import 'app_database.dart' as db;
import 'goal_row_mapper.dart';

class GoalPlanRepository {
  GoalPlanRepository(this._db);

  final db.AppDatabase _db;

  Future<GoalPlanSnapshot?> load(String goalId) async {
    final goalRow = await (_db.select(
      _db.goals,
    )..where((t) => t.id.equals(goalId))).getSingleOrNull();
    if (goalRow == null) return null;

    final milestones =
        await (_db.select(_db.milestoneSteps)
              ..where((t) => t.goalId.equals(goalId))
              ..orderBy([
                (t) => OrderingTerm.asc(t.position),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .map(_toStep)
            .get();
    final reminder =
        await (_db.select(_db.reminders)
              ..where((t) => t.goalId.equals(goalId))
              ..limit(1))
            .map(_toReminder)
            .getSingleOrNull();

    return GoalPlanSnapshot(
      goal: GoalRowMapper.fromRow(goalRow),
      milestones: milestones,
      reminder: reminder,
    );
  }

  Future<Goal> create(GoalPlanInput input) async {
    final normalized = _normalize(input);
    await _rejectExistingMilestoneIds(normalized.milestones);
    await _db.transaction(() async {
      await _db
          .into(_db.goals)
          .insert(GoalRowMapper.toCompanion(normalized.goal));
      await _replaceMilestones(normalized.goal.id, normalized.milestones);
      await _replaceReminder(normalized.goal.id, normalized.reminder);
    });
    return normalized.goal;
  }

  Future<void> update(GoalPlanInput input) async {
    final normalized = _normalize(input);
    final existing = await _milestonesOf(normalized.goal.id);
    _rejectNonRetainedMilestoneIds(normalized.milestones, existing);

    await _db.transaction(() async {
      await (_db.update(_db.goals)
            ..where((t) => t.id.equals(normalized.goal.id)))
          .write(GoalRowMapper.toCompanion(normalized.goal));

      final existingById = {for (final step in existing) step.id: step};
      final retainedIds = normalized.milestones
          .map((draft) => draft.id)
          .nonNulls
          .toSet();

      await _deleteOmittedMilestones(normalized.goal.id, retainedIds);

      for (final (position, draft) in normalized.milestones.indexed) {
        final existingStep = draft.id == null ? null : existingById[draft.id];
        final step = _stepFromDraft(
          goalId: normalized.goal.id,
          draft: draft,
          position: position,
          existing: existingStep,
        );
        if (existingStep == null) {
          await _insertMilestone(step);
        } else {
          await _updateMilestone(step);
        }
      }

      await _replaceReminder(normalized.goal.id, normalized.reminder);
    });
  }

  static GoalPlanInput _normalize(GoalPlanInput input) {
    final goalName = input.goal.name.trim();
    if (goalName.isEmpty) {
      throw ArgumentError.value(input.goal.name, 'goal.name', '目标名不能为空');
    }

    final seenMilestoneIds = <String>{};
    final milestones = <MilestoneDraft>[];
    for (final draft in input.milestones) {
      final id = draft.id;
      if (id != null && !seenMilestoneIds.add(id)) {
        throw ArgumentError.value(id, 'milestones', '里程碑 id 不能重复');
      }

      final title = draft.title.trim();
      if (title.isEmpty) {
        throw ArgumentError.value(draft.title, 'milestones.title', '步骤名不能为空');
      }
      if (title.length > 50) {
        throw ArgumentError.value(
          draft.title,
          'milestones.title',
          '步骤名不能超过 50 字',
        );
      }
      if (draft.isDone && draft.doneAt == null) {
        throw ArgumentError.value(draft.id, 'milestones.doneAt', '完成步骤须带完成时刻');
      }

      milestones.add(
        MilestoneDraft(
          id: id,
          title: title,
          isDone: draft.isDone,
          doneAt: draft.doneAt,
        ),
      );
    }

    return GoalPlanInput(
      goal: input.goal.copyWith(name: goalName),
      milestones: milestones,
      reminder: input.reminder,
    );
  }

  Future<void> _replaceMilestones(
    String goalId,
    List<MilestoneDraft> milestones,
  ) async {
    for (final (position, draft) in milestones.indexed) {
      await _insertMilestone(
        _stepFromDraft(goalId: goalId, draft: draft, position: position),
      );
    }
  }

  Future<void> _rejectExistingMilestoneIds(
    List<MilestoneDraft> milestones,
  ) async {
    final explicitIds = milestones.map((draft) => draft.id).nonNulls.toList();
    if (explicitIds.isEmpty) return;

    final collisions =
        await (_db.select(_db.milestoneSteps)
              ..where((t) => t.id.isIn(explicitIds))
              ..limit(1))
            .get();
    if (collisions.isNotEmpty) {
      throw ArgumentError.value(
        collisions.single.id,
        'milestones.id',
        '里程碑 id 已被其他目标使用',
      );
    }
  }

  void _rejectNonRetainedMilestoneIds(
    List<MilestoneDraft> milestones,
    List<MilestoneStep> existing,
  ) {
    final existingIds = existing.map((step) => step.id).toSet();
    for (final id in milestones.map((draft) => draft.id).nonNulls) {
      if (!existingIds.contains(id)) {
        throw ArgumentError.value(id, 'milestones.id', '里程碑 id 不属于当前目标');
      }
    }
  }

  Future<List<MilestoneStep>> _milestonesOf(String goalId) => (_db.select(
    _db.milestoneSteps,
  )..where((t) => t.goalId.equals(goalId))).map(_toStep).get();

  Future<void> _deleteOmittedMilestones(
    String goalId,
    Set<String> retainedIds,
  ) {
    final deletion = _db.delete(_db.milestoneSteps)
      ..where((t) => t.goalId.equals(goalId));
    if (retainedIds.isEmpty) return deletion.go();
    return (deletion..where((t) => t.id.isNotIn(retainedIds))).go();
  }

  Future<void> _insertMilestone(MilestoneStep step) => _db
      .into(_db.milestoneSteps)
      .insert(
        db.MilestoneStepsCompanion.insert(
          id: step.id,
          goalId: step.goalId,
          title: step.title,
          position: Value(step.position),
          isDone: step.isDone,
          doneAt: Value(step.doneAt),
        ),
      );

  Future<void> _updateMilestone(MilestoneStep step) =>
      (_db.update(_db.milestoneSteps)
            ..where((t) => t.id.equals(step.id) & t.goalId.equals(step.goalId)))
          .write(
            db.MilestoneStepsCompanion(
              title: Value(step.title),
              position: Value(step.position),
              isDone: Value(step.isDone),
              doneAt: Value(step.doneAt),
            ),
          );

  Future<void> _replaceReminder(String goalId, ReminderDraft? draft) async {
    await (_db.delete(
      _db.reminders,
    )..where((t) => t.goalId.equals(goalId))).go();
    if (draft == null) return;

    await _db
        .into(_db.reminders)
        .insert(
          db.RemindersCompanion.insert(
            id: draft.id ?? newId(),
            goalId: Value(goalId),
            time: draft.time,
            isEnabled: draft.enabled,
            cadence: Value(draft.cadence),
          ),
        );
  }

  static MilestoneStep _stepFromDraft({
    required String goalId,
    required MilestoneDraft draft,
    required int position,
    MilestoneStep? existing,
  }) => MilestoneStep(
    id: draft.id ?? newId(),
    goalId: goalId,
    title: draft.title,
    position: position,
    isDone: existing == null ? draft.isDone : existing.isDone,
    doneAt: existing == null ? draft.doneAt : existing.doneAt,
  );

  static MilestoneStep _toStep(db.MilestoneStep row) => MilestoneStep(
    id: row.id,
    goalId: row.goalId,
    title: row.title,
    position: row.position,
    isDone: row.isDone,
    doneAt: row.doneAt,
  );

  static Reminder _toReminder(db.Reminder row) => Reminder(
    id: row.id,
    goalId: row.goalId,
    time: row.time,
    isEnabled: row.isEnabled,
    cadence: row.cadence,
  );
}
