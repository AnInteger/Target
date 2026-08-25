library;

import 'calendar_types.dart';

class ProgressRecordInput {
  ProgressRecordInput({
    required this.goalId,
    required this.day,
    required this.createdAt,
    this.note,
    this.completedMilestoneId,
    this.nextMilestoneTitle,
  }) : assert(goalId.isNotEmpty),
       assert(nextMilestoneTitle == null || nextMilestoneTitle.length <= 50);

  final String goalId;
  final LocalDate day;
  final DateTime createdAt;
  final String? note;
  final String? completedMilestoneId;
  final String? nextMilestoneTitle;
}
