library;

import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../../core/models/goal_plan.dart';

class GoalEditorDraft {
  GoalEditorDraft({
    required this.name,
    required this.iconKey,
    required this.category,
    required this.targetDate,
    required this.frequency,
    required this.milestones,
    required this.reminder,
  });

  String name;
  String iconKey;
  GoalIconDomain? category;
  LocalDate? targetDate;
  FrequencyPattern? frequency;
  List<MilestoneDraft> milestones;
  ReminderDraft? reminder;

  bool get canSave => name.trim().isNotEmpty;

  GoalPlanInput toInput({Goal? existing, required LocalDate today}) {
    final goal = Goal(
      id: existing?.id,
      name: name.trim(),
      iconKey: iconKey,
      colorKey: existing?.colorKey ?? '',
      categoryOverride: category,
      progressCadenceDays: existing?.progressCadenceDays,
      status: existing?.status ?? GoalStatus.active,
      createdAt: existing?.createdAt ?? today,
      targetDate: targetDate,
      frequency: frequency,
      motivation: existing?.motivation,
      successCriterion: existing?.successCriterion,
      cueScene: existing?.cueScene,
      achievedAt: existing?.achievedAt,
      archivedAt: existing?.archivedAt,
    );
    return GoalPlanInput(
      goal: goal,
      milestones: milestones,
      reminder: reminder,
    );
  }

  static GoalEditorDraft empty() => GoalEditorDraft(
    name: '',
    iconKey: GoalIconCatalog.explore.key,
    category: null,
    targetDate: null,
    frequency: null,
    milestones: const [],
    reminder: null,
  );

  static GoalEditorDraft fromSnapshot(GoalPlanSnapshot snapshot) =>
      GoalEditorDraft(
        name: snapshot.goal.name,
        iconKey: snapshot.goal.iconKey,
        category: snapshot.goal.categoryOverride,
        targetDate: snapshot.goal.targetDate,
        frequency: snapshot.goal.frequency,
        milestones: [
          for (final step in snapshot.milestones)
            MilestoneDraft(
              id: step.id,
              title: step.title,
              isDone: step.isDone,
              doneAt: step.doneAt,
            ),
        ],
        reminder: snapshot.reminder == null
            ? null
            : ReminderDraft(
                id: snapshot.reminder!.id,
                enabled: snapshot.reminder!.isEnabled,
                time: snapshot.reminder!.time,
                cadence: snapshot.reminder!.effectiveCadence,
              ),
      );
}
