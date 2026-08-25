/// 将一次进展记录、当前里程碑完成和下一步计划作为一个原子命令保存。
library;

import 'package:drift/drift.dart';

import '../models/entities.dart';
import '../models/progress_record.dart';
import 'app_database.dart' as db;

class ProgressRepository {
  ProgressRepository(this._db);

  final db.AppDatabase _db;

  Future<void> record(ProgressRecordInput input) async {
    final nextTitle = input.nextMilestoneTitle?.trim() ?? '';
    if (nextTitle.length > 50) {
      throw ArgumentError.value(nextTitle, 'nextMilestoneTitle', '最多 50 字');
    }
    final note = input.note?.trim();
    await _db.transaction(() async {
      final checkIn = CheckIn(
        goalId: input.goalId,
        day: input.day,
        createdAt: input.createdAt,
        note: note == null || note.isEmpty ? null : note,
      );
      await _db
          .into(_db.checkIns)
          .insert(
            db.CheckInsCompanion.insert(
              id: checkIn.id,
              goalId: checkIn.goalId,
              day: checkIn.day,
              createdAt: checkIn.createdAt,
              isBackfill: checkIn.isBackfill,
              status: checkIn.status,
              note: Value(checkIn.note),
            ),
          );

      final completedId = input.completedMilestoneId;
      if (completedId != null) {
        final row = await (_db.select(
          _db.milestoneSteps,
        )..where((step) => step.id.equals(completedId))).getSingleOrNull();
        if (row == null || row.goalId != input.goalId) {
          throw StateError('待完成里程碑不存在或不属于当前目标');
        }
        await (_db.update(
          _db.milestoneSteps,
        )..where((step) => step.id.equals(completedId))).write(
          db.MilestoneStepsCompanion(
            isDone: const Value(true),
            doneAt: Value(row.doneAt ?? input.createdAt),
          ),
        );
      }

      if (nextTitle.isNotEmpty) {
        final existing = await (_db.select(
          _db.milestoneSteps,
        )..where((step) => step.goalId.equals(input.goalId))).get();
        final nextPosition = existing.isEmpty
            ? 0
            : existing
                      .map((step) => step.position)
                      .reduce((a, b) => a > b ? a : b) +
                  1;
        final next = MilestoneStep(
          goalId: input.goalId,
          title: nextTitle,
          position: nextPosition,
        );
        await _db
            .into(_db.milestoneSteps)
            .insert(
              db.MilestoneStepsCompanion.insert(
                id: next.id,
                goalId: next.goalId,
                title: next.title,
                position: Value(next.position),
                isDone: next.isDone,
                doneAt: Value(next.doneAt),
              ),
            );
      }
    });
  }
}
