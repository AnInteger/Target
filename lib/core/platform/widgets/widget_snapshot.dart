/// 小组件快照（T028/T044，contracts/widget-intent.md）：纯构建 + 经网关落
/// App Group。
///
/// schema：battery / updatedAt / goals[{id,name,colorKey,iconKey,
/// targetCount,doneCount,met,kind?,stepsDone?,stepsTotal?,
/// deadline?}]（T044 里程碑扩展，可选键兼容旧快照）/ weekProgress{weekStart,
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
  List<MilestoneStep> Function(String goalId)? stepsOf,
}) {
  final active =
      goals.where((g) => g.isActive).toList();
  final rows = <Map<String, Object?>>[];
  var metGoals = 0;
  for (final g in active) {
    if (g.isHabit) {
      final st = stats.dayStatusOf(g.id);
      if (st.done) metGoals++;
      rows.add({
        'id': g.id,
        'name': g.name,
        'colorKey': g.colorKey,
        'iconKey': g.iconKey,
        'doneCount': st.doneCount,
        'met': st.done,
      });
    } else {
      // 里程碑（T044）：medium 家族只读行 — 步骤进度 + 倒计时。
      final steps = stepsOf?.call(g.id) ?? const <MilestoneStep>[];
      rows.add({
        'id': g.id,
        'name': g.name,
        'colorKey': g.colorKey,
        'iconKey': g.iconKey,
        'kind': 'milestone',
        'stepsDone': steps.where((s) => s.isDone).length,
        'stepsTotal': steps.length,
        if (g.deadline != null) 'deadline': g.deadline!.isoString,
      });
    }
  }
  return {
    'battery': stats.battery.percent,
    'updatedAt': now.toUtc().toIso8601String(),
    'goals': rows,
    'weekProgress': {
      'weekStart': today.weekStart.isoString,
      'metGoals': metGoals,
      'totalGoals': active.where((g) => g.isHabit).length,
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
  List<MilestoneStep> Function(String goalId)? stepsOf,
}) =>
    gateway.saveSnapshot(buildTodaySnapshot(
        goals: goals,
        stats: stats,
        today: today,
        now: now,
        stepsOf: stepsOf));
