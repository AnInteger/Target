/// 小组件快照（T028，contracts/widget-intent.md）：纯构建 + 经网关落 App Group。
///
/// schema：battery / updatedAt / goals[{id,name,colorKey,iconKey,
/// targetCount,doneCount,met,busyMode}] / weekProgress{weekStart,
/// metGoals,totalGoals}。本文件 Web 可达（无 home_widget 依赖）；
/// 原生写盘由 WidgetGateway 完成，Web 网关为 no-op。
library;

import '../../models/calendar_types.dart';
import '../../models/entities.dart';
import '../../stats/stats_engine.dart';
import '../gateways.dart';

Map<String, Object?> buildTodaySnapshot({
  required List<Goal> goals,
  required StatsEvaluation stats,
  required LocalDate today,
  required DateTime now,
}) {
  final habits =
      goals.where((g) => g.isHabit && g.status == GoalStatus.active).toList();
  final rows = <Map<String, Object?>>[];
  var metGoals = 0;
  for (final g in habits) {
    final st = stats.dayStatusOf(g.id);
    if (st.met) metGoals++;
    rows.add({
      'id': g.id,
      'name': g.name,
      'colorKey': g.colorKey,
      'iconKey': g.iconKey,
      'targetCount': st.targetCount,
      'doneCount': st.doneCount,
      'met': st.met,
      'busyMode': st.busyMode,
    });
  }
  return {
    'battery': stats.battery.percent,
    'updatedAt': now.toUtc().toIso8601String(),
    'goals': rows,
    'weekProgress': {
      'weekStart': today.weekStart.isoString,
      'metGoals': metGoals,
      'totalGoals': rows.length,
    },
  };
}

/// 组装 + 写入（数据变更/跨天时由 app 层调用，research D13）。
Future<void> writeTodaySnapshot({
  required WidgetGateway gateway,
  required List<Goal> goals,
  required StatsEvaluation stats,
  required LocalDate today,
  required DateTime now,
}) =>
    gateway.saveSnapshot(buildTodaySnapshot(
        goals: goals, stats: stats, today: today, now: now));
