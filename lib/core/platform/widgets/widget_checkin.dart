/// 小组件行内打卡回调（T030，contracts/widget-intent.md）。
///
/// 仅原生侧可达（home_widget 内部用 dart:io）。AppIntent → home_widget
/// BackgroundIntent → 本顶层函数（App 进程内、无 UI 上下文）：
/// 校验 → 写 CheckIn → 重算统计 → 重写快照 → 刷新 timeline。
/// 任一校验失败：快照按当前数据原样重写，无副作用（按钮状态不变）。
library;

import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../db/app_database.dart';
import '../../db/connection.dart';
import '../../db/repositories.dart';
import '../../models/calendar_types.dart';
import '../../models/entities.dart';
import '../../stats/stats_engine.dart';
import '../widget_ios.dart';
import 'widget_snapshot.dart';

@pragma('vm:entry-point')
Future<void> widgetCheckInCallback(Uri? uri) async {
  if (uri == null || uri.host != 'checkin') return;
  final goalId = uri.queryParameters['goalId'];
  if (goalId == null) return;

  final db = AppDatabase(openConnection());
  try {
    final goalRepo = GoalRepository(db);
    final checkInRepo = CheckInRepository(db);
    final now = DateTime.now();
    final today = LocalDate.fromDateTime(now);

    final goals = await goalRepo.getGoals();
    final versions = await goalRepo.watchAllVersions().first;
    final sessions = await goalRepo.watchSessions().first;

    var checkIns = await checkInRepo.all();

    StatsEvaluation evaluate() => StatsEngine.evaluate(
        goals: goals,
        frequencyVersions: versions,
        busySessions: sessions,
        checkIns: checkIns,
        today: today);

    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    final eligible = goal != null &&
        goal.isHabit &&
        goal.status == GoalStatus.active &&
        !evaluate().dayStatusOf(goalId).met;
    if (eligible) {
      await checkInRepo.add(goalId, today, now);
      checkIns = await checkInRepo.all();
    }

    final snapshot = buildTodaySnapshot(
        goals: goals, stats: evaluate(), today: today, now: DateTime.now());
    await HomeWidget.saveWidgetData<String>(
        HomeWidgetGateway.snapshotKey, jsonEncode(snapshot));
    await HomeWidget.updateWidget(iOSName: HomeWidgetGateway.iosWidgetName);
  } finally {
    await db.close();
  }
}
