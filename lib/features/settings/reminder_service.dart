/// 提醒调度（US3/US5，FR-006/SC-005/FR-012）。
///
/// [planReminders] 纯函数计算"此刻应存在的通知集合"；
/// [ReminderService.replan] 在数据/设置变化后全量重建 pending
/// 请求（先 cancelAll 再逐条调度）——已达标、不适用、非活跃
/// 目标自然被剔除。权限被拒 → 仅清空、不报错（FR-007 降级）。
///
/// FR-012：逐目标提醒由目标 cueScene 场景档驱动（空值回落默认档
/// 20:00、同档多目标合并成一条、「不打扰」不提醒）；001 的逐目标
/// Reminder 行不再参与调度，自然失效。
library;

import '../../core/copy.dart';
import '../../core/db/repositories.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/platform/gateways.dart';
import '../../core/stats/stats_engine.dart';

/// dailyBrief 固定通知 id；场景档从 2 起。
const int kDailyBriefNotificationId = 1;

/// 场景档 → 提醒时刻（FR-012 定稿：没选 20:00 轻提醒；时刻为本轮
/// 调度口径，原型只钉了默认 20:00 与「睡前 21:30」两处锚点）。
const Map<String, LocalTime> kCueSceneTimes = {
  Copy.cueEarly: LocalTime(7, 30),
  Copy.cueMidday: LocalTime(12, 30),
  Copy.cueEvening: LocalTime(19, 30),
  Copy.cueNight: LocalTime(21, 30),
};

/// 未选场景（或场景值已不在档）的回落时刻。
const LocalTime kDefaultCueTime = LocalTime(20, 0);

/// 档位（场景名，空串 = 默认档）→ 稳定通知 id（跨进程一致，供 cancel/覆盖）。
int cueSlotNotificationId(String slot) => switch (slot) {
      Copy.cueEarly => 2,
      Copy.cueMidday => 3,
      Copy.cueEvening => 4,
      Copy.cueNight => 5,
      _ => 6, // 默认档
    };

/// 一条计划内通知。
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.time,
    required this.title,
    required this.body,
    this.goalIds = const [],
  });

  final int id;
  final LocalTime time;
  final String title;
  final String body;

  /// 关联目标（T019 通知列表 tap 跳转）：dailyBrief 空；cue 档 =
  /// 该档全部目标（单目标可直达，多目标合并档不跳）。
  final List<String> goalIds;
}

/// 计算应调度的通知集合（纯函数，注入时刻便于测试）。
///
/// - dailyBrief：无行 → [defaultBriefTime] 且默认启用；有行 → 行生效。
///   正文为各目标当日概览；下一次触发日为周一时附周回顾行（FR-008 联动）。
/// - 逐目标提醒（FR-012）：仅活跃习惯目标、今日适用且未达标（SC-005）；
///   按目标 cueScene 归档——「不打扰」跳过，空值/未知值回落默认档，
///   同档多目标合并成一条通知（不连环打扰）。
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

  // ---- 逐目标提醒：cueScene 归档（空串键 = 默认档）----
  final slots = <String, List<Goal>>{};
  for (final g in goals) {
    if (!g.isHabit || g.status != GoalStatus.active) continue;
    final day = stats.dayStatusOf(g.id);
    if (day.done) continue; // 当日已留痕不打扰（SC-005 新口径）
    final scene = g.cueScene?.trim();
    if (scene == Copy.cueNone) continue; // 「不打扰」= 该目标不提醒
    final slot =
        (scene == null || !kCueSceneTimes.containsKey(scene)) ? '' : scene;
    slots.putIfAbsent(slot, () => []).add(g);
  }
  slots.forEach((slot, list) {
    final isDefault = slot.isEmpty;
    final time = isDefault ? kDefaultCueTime : kCueSceneTimes[slot]!;
    final String title;
    final String body;
    if (list.length == 1) {
      final g = list.first;
      title = isDefault ? g.name : Copy.reminderTitleScene(slot, g.name);
      body = _goalBody(g);
    } else {
      title = isDefault
          ? Copy.reminderTitleDefaultMany(list.length)
          : Copy.reminderTitleSceneMany(slot, list.length);
      body = Copy.reminderNames([for (final g in list) g.name]);
    }
    plan.add(PlannedNotification(
        id: cueSlotNotificationId(slot),
        time: time,
        title: title,
        body: body,
        goalIds: [for (final g in list) g.id]));
  });
  return plan;
}

/// 单目标档正文：写了「为什么」带上为什么（编辑器预览承诺），否则轻推一句。
String _goalBody(Goal g) {
  final why = g.motivation?.trim();
  if (why != null && why.isNotEmpty) return Copy.reminderAsk(why, g.name);
  return Copy.reminderNudge;
}

String _briefBody(
  List<Goal> goals,
  StatsEvaluation stats, {
  required bool monday,
}) {
  final unmet = goals
      .where((g) =>
          g.status == GoalStatus.active &&
          !stats.dayStatusOf(g.id).done)
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
