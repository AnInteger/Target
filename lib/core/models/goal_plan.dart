library;

import 'calendar_types.dart';
import 'entities.dart';

class MilestoneDraft {
  const MilestoneDraft({
    this.id,
    required this.title,
    this.isDone = false,
    this.doneAt,
  });

  final String? id;
  final String title;
  final bool isDone;
  final DateTime? doneAt;
}

class ReminderDraft {
  const ReminderDraft({
    this.id,
    required this.enabled,
    required this.time,
    required this.cadence,
  });

  final String? id;
  final bool enabled;
  final LocalTime time;
  final Cadence cadence;
}

class GoalPlanInput {
  const GoalPlanInput({
    required this.goal,
    required this.milestones,
    this.reminder,
  });

  final Goal goal;
  final List<MilestoneDraft> milestones;
  final ReminderDraft? reminder;
}

class GoalPlanSnapshot {
  const GoalPlanSnapshot({
    required this.goal,
    required this.milestones,
    this.reminder,
  });

  final Goal goal;
  final List<MilestoneStep> milestones;
  final Reminder? reminder;
}
