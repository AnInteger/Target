/// 提醒调度（US3，FR-006/SC-005）。
///
/// [planReminders] 纯函数计算"此刻应存在的通知集合"；
/// [ReminderService.replan] 在数据/设置变化后全量重建 pending
/// 请求（先 cancelAll 再逐条调度）——已达标、不适用、非活跃
/// 目标自然被剔除。权限被拒 → 仅清空、不报错（FR-007 降级）。
library;

import '../../core/copy.dart';
import '../../core/db/repositories.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/platform/gateways.dart';
import '../../core/stats/stats_engine.dart';

/// dailyBrief 固定通知 id；目标提醒从 2 起哈希避免冲突。
const int kDailyBriefNotificationId = 1;

/// goalId → 稳定通知 id（跨进程一致，供 cancel/覆盖）。
int goalReminderId(String goalId) =>
    2 + goalId.codeUnits.fold(0, (a, b) => (a * 31 + b) % 1000000);

/// 一条计划内通知。
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.time,
    required this.title,
    required this.body,
  });

  final int id;
  final LocalTime time;
  final String title;
  final String body;
}

/// 计算应调度的通知集合（纯函数，注入时刻便于测试）。
///
/// - dailyBrief：无行 → [defaultBriefTime] 且默认启用；有行 → 行生效。
///   正文为各目标当日概览；下一次触发日为周一时附周回顾行（FR-008 联动）。
/// - 目标催促：仅活跃习惯目标、今日适用且未达标（SC-005）。
List<PlannedNotification> planReminders({
  required List<Reminder> reminders,
  required LocalTime defaultBriefTime,
  required List<Goal> goals,
  required StatsEvaluation stats,
  required LocalDate today,
  required LocalTime nowTime,
}) {
  final plan = <PlannedNotification>[];

  // ---- dailyBrief ----
  final brief = reminders.where((r) => r.isDailyBrief).firstOrNull;
  final briefTime = brief?.time ?? defaultBriefTime;
  if (brief == null || brief.isEnabled) {
    final fireDate =
        nowTime.compareTo(briefTime) < 0 ? today : today.addDays(1);
    plan.add(PlannedNotification(
      id: kDailyBriefNotificationId,
      time: briefTime,
      title: Copy.dailyBriefTitle,
      body: _briefBody(goals, stats, monday: fireDate.weekdayIso == 1),
    ));
  }

  // ---- 逐目标催促 ----
  final byId = {for (final g in goals) g.id: g};
  for (final r in reminders) {
    if (r.isDailyBrief || !r.isEnabled) continue;
    final goal = byId[r.goalId];
    if (goal == null || !goal.isHabit || goal.status != GoalStatus.active) {
      continue;
    }
    final day = stats.dayStatusOf(r.goalId!);
    if (!day.applicable || day.met) continue; // SC-005
    plan.add(PlannedNotification(
      id: goalReminderId(r.goalId!),
      time: r.time,
      title: goal.name,
      body: Copy.goalReminderBody(day.doneCount, day.targetCount),
    ));
  }
  return plan;
}

String _briefBody(
  List<Goal> goals,
  StatsEvaluation stats, {
  required bool monday,
}) {
  final unmet = goals
      .where((g) =>
          g.isHabit &&
          g.status == GoalStatus.active &&
          stats.dayStatusOf(g.id).applicable &&
          !stats.dayStatusOf(g.id).met)
      .length;
  final buffer = StringBuffer(
      unmet == 0 ? Copy.dailyBriefAllDone : Copy.dailyBriefSummary(unmet));
  if (monday) buffer.write('\n${Copy.dailyBriefReviewLine}');
  return buffer.toString();
}

/// 应用层入口：全量重建 pending 通知（数据/设置变化后调用）。
class ReminderService {
  ReminderService(this._gateway, this._repo);

  final NotificationGateway _gateway;
  final ReminderRepository? _repo;

  Future<void> replan({
    required Settings settings,
    required List<Goal> goals,
    required StatsEvaluation stats,
    required LocalDate today,
    required LocalTime nowTime,
  }) async {
    await _gateway.cancelAll();
    if (!await _gateway.isPermissionGranted) return; // FR-007
    final reminders =
        _repo == null ? const <Reminder>[] : await _repo.all();
    final plan = planReminders(
      reminders: reminders,
      defaultBriefTime: settings.dailyBriefTime,
      goals: goals,
      stats: stats,
      today: today,
      nowTime: nowTime,
    );
    for (final p in plan) {
      await _gateway.scheduleDaily(
          id: p.id, time: p.time, title: p.title, body: p.body);
    }
  }
}
