/// v3 小组件快照（006 FR/T408）：纯构建 + 经网关落 App Group。
///
/// schema v4：{ updatedAt, todayRecordCount, todayMinutes,
/// latestTitle?, latestGoalName?, latestGoalColorKey?,
/// goals?: [ { id, name, colorKey, iconKey, category?, latestTitle?,
///             latestLabel?, nextMilestone? } ] }
/// —— v3 今日聚合 + 目标卡片小组件（R13c：AppIntent 可配置，每实例
/// 展示一个目标；多个实例在桌面叠放后由系统原生上下翻页。展示串
/// 全部预计算，Swift 侧零业务逻辑）；深链 target://record。
/// 本文件 Web 可达（无 home_widget 依赖）；原生写盘由 WidgetGateway 完成。
library;

import '../../copy.dart';
import '../../models/calendar_types.dart';
import '../../models/entities.dart';
import '../../models/relative_time.dart';

/// 翻页小组件每时间线的最大目标页数（防 timeline 膨胀）。
const int widgetGoalPagesLimit = 6;

Map<String, Object?> buildTodaySnapshot({
  required List<Goal> goals,
  required List<ProgressRecord> records,
  required List<Milestone> milestones,
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
    'goals': buildGoalPages(
      // 与目标页同序（置顶优先），归档目标按契约从小组件隐去。
      goals: [
        for (final g in goals)
          if (g.archivedAt == null) g,
      ],
      records: records,
      milestones: milestones,
      today: today,
    ),
  };
}

/// 翻页小组件的数据页（R13）：每目标一页，展示串（相对日标签、
/// 分类名）在此预计算——Swift 侧纯渲染。
List<Map<String, Object?>> buildGoalPages({
  required List<Goal> goals,
  required List<ProgressRecord> records,
  required List<Milestone> milestones,
  required LocalDate today,
}) {
  final pages = <Map<String, Object?>>[];
  for (final g in goals.take(widgetGoalPagesLimit)) {
    final latest = records.where((r) => r.goalId == g.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final next = milestones.where((m) => m.goalId == g.id && !m.isDone).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    pages.add({
      'id': g.id,
      'name': g.name,
      'colorKey': g.colorKey,
      'iconKey': g.iconKey,
      if (g.categoryKey != null)
        'category': Copy.categoryOf(g.categoryKey!.name),
      if (latest.isNotEmpty) 'latestTitle': latest.first.title,
      if (latest.isNotEmpty)
        'latestLabel': relativeDayLabel(latest.first.day, today),
      if (next.isNotEmpty) 'nextMilestone': next.first.title,
    });
  }
  return pages;
}
