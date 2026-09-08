/// v3 小组件快照（006 FR/T408）：纯构建 + 经网关落 App Group。
///
/// schema v3：{ updatedAt, todayRecordCount, todayMinutes,
/// latestTitle?, latestGoalName?, latestGoalColorKey? }
/// —— 今日记录数 + 最近记录标题；tap 深链 target://record。
/// 本文件 Web 可达（无 home_widget 依赖）；原生写盘由 WidgetGateway 完成。
library;

import '../../models/calendar_types.dart';
import '../../models/entities.dart';

Map<String, Object?> buildTodaySnapshot({
  required List<Goal> goals,
  required List<ProgressRecord> records,
  required LocalDate today,
  required DateTime now,
}) {
  final todayRecords = records.where((r) => r.day == today).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final goalsById = {for (final g in goals) g.id: g};
  final latest = todayRecords.isEmpty ? null : todayRecords.first;
  final latestGoal = latest == null ? null : goalsById[latest.goalId];

  return {
    'updatedAt': now.toUtc().toIso8601String(),
    'todayRecordCount': todayRecords.length,
    'todayMinutes': todayRecords.fold<int>(
      0,
      (sum, r) => sum + (r.durationMinutes ?? 0),
    ),
    if (latest != null) 'latestTitle': latest.title,
    if (latestGoal != null) 'latestGoalName': latestGoal.name,
    if (latestGoal != null) 'latestGoalColorKey': latestGoal.colorKey,
  };
}
