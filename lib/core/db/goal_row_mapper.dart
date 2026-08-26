/// Goals table ⇄ domain compatibility mapping for schema v7.
library;

import 'package:drift/drift.dart';

import '../models/entities.dart';
import '../models/frequency_pattern.dart';
import '../models/goal_icon_catalog.dart';
import 'app_database.dart' as db;

abstract final class GoalRowMapper {
  static Goal fromRow(db.Goal row) => Goal(
    id: row.id,
    name: row.name,
    goalType: row.goalType,
    iconKey: row.iconKey,
    colorKey: row.colorKey ?? '',
    categoryOverride: row.categoryOverride == null
        ? null
        : GoalIconDomain.values.firstWhere(
            (domain) => domain.name == row.categoryOverride,
            orElse: () => GoalIconDomain.travel,
          ),
    progressCadenceDays: row.progressCadenceDays,
    status: row.status == GoalStatus.archived ? GoalStatus.paused : row.status,
    createdAt: row.createdAt,
    deadline: row.deadline,
    targetDate: row.targetDate,
    habitTargetPerWeek: row.habitTargetPerWeek,
    frequency: row.frequencyPattern,
    achievedAt: row.achievedAt,
    archivedAt: row.archivedAt,
    motivation: row.motivation,
    successCriterion: row.successCriterion,
    cueScene: row.cueScene,
  );

  static db.GoalsCompanion toCompanion(Goal goal) => db.GoalsCompanion.insert(
    id: goal.id,
    name: goal.name,
    goalType: legacyTypeOf(goal),
    iconKey: goal.iconKey,
    progressCadenceDays: Value(legacyCadenceOf(goal)),
    categoryOverride: Value(goal.categoryOverride?.name),
    targetDate: Value(goal.targetDate),
    habitTargetPerWeek: Value(legacyWeeklyTargetOf(goal)),
    frequencyPattern: Value(goal.frequency),
    archivedAt: Value(goal.archivedAt),
    colorKey: Value(goal.colorKey.isEmpty ? null : goal.colorKey),
    status: goal.status == GoalStatus.archived
        ? GoalStatus.paused
        : goal.status,
    createdAt: goal.createdAt,
    deadline: Value(goal.targetDate),
    achievedAt: Value(goal.achievedAt),
    motivation: Value(goal.motivation),
    successCriterion: Value(goal.successCriterion),
    cueScene: Value(goal.cueScene),
  );

  static GoalType legacyTypeOf(Goal goal) {
    if (goal.targetDate != null) return GoalType.shortTerm;
    if (goal.frequency != null) return GoalType.habit;
    return GoalType.longTerm;
  }

  static int legacyCadenceOf(Goal goal) =>
      goal.targetDate == null && goal.frequency == null ? 14 : 7;

  static int? legacyWeeklyTargetOf(Goal goal) => switch (goal.frequency) {
    WeeklyFrequency(:final timesPerWeek) => timesPerWeek,
    DailyFrequency() => 7,
    WeekdaysFrequency(:final days) => days.length,
    null => null,
  };
}
