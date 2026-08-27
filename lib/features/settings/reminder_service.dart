/// 提醒调度（003 T028 · contracts/goal-type-model「提醒排程」）。
///
/// [planReminders] 纯函数计算"此刻应存在的通知集合"；
/// [ReminderService.replan] 在数据/设置变化后全量重建 pending
/// 请求（先 cancelAll 再逐条调度）——关开关、改档、删除目标
/// 的取消都由全量重建达成（isEnabled=false 即时取消未触发排程）。
/// 权限被拒 → 仅清空、不报错（FR-007 降级）。
///
/// 逐目标提醒的真源 = Reminders 行（cadence/time/isEnabled）；
/// 002 的 cueScene 场景档体系退役（goal 列不再参与调度）。
library;

import '../../core/copy.dart';
import '../../core/db/repositories.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/platform/gateways.dart';
import '../../core/stats/stats_engine.dart';

/// dailyBrief 固定通知 id；逐目标提醒/到期询问分段在 1000/2000 起。
const int kDailyBriefNotificationId = 1;

/// 逐目标提醒通知 id（goalId 哈希分段；replan 每次 cancelAll 全量重建，
/// id 只需进程内稳定供覆盖，跨进程漂移无影响——通知列表是推导式不读系统通知）。
int goalReminderNotificationId(String goalId) =>
    1000 + (goalId.hashCode & 0x3FFFFFFF);

/// 短期到期询问通知 id（与逐目标提醒分段互异）。
int dueAskNotificationId(String goalId) =>
    2000 + (goalId.hashCode & 0x3FFFFFFF);

/// 短期到期询问时刻（D4：deadline 当日默认 09:00 单次，只提醒不判决）。
const LocalTime kDueAskTime = LocalTime(9, 0);

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

  /// 关联目标（通知列表 tap 跳转）：dailyBrief 空；逐目标/到期询问单目标。
  final List<String> goalIds;
}

/// 计算应调度的通知集合（纯函数，注入时刻便于测试）。
///
/// - dailyBrief：无行 → [defaultBriefTime] 且默认启用；有行 → 行生效。
///   正文为各目标当日概览，不额外制造回顾任务。
/// - 逐目标提醒（Reminders 行 cadence 驱动）：daily 每日 time；
///   threeDay 自启用日（最近一次打卡或创建日）起每 3 天；weekly 每周
///   同 weekday。仅活跃目标、当日适用且未达标（SC-005）。
/// - 短期到期询问：deadline 当日 09:00 单次（次日起 deadline≠today
///   自然离场，超期持续提示由通知列表条目承载）。
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
    plan.add(
      PlannedNotification(
        id: kDailyBriefNotificationId,
        time: briefTime,
        title: Copy.dailyBriefTitle,
        body: _briefBody(goals, stats),
      ),
    );
  }

  // ---- 逐目标提醒（Reminders 行 = 唯一真源）----
  final goalsById = {for (final g in goals) g.id: g};
  for (final r in reminders) {
    if (r.isDailyBrief || !r.isEnabled) continue; // 关 = 不排（即时取消）
    final g = goalsById[r.goalId];
    if (g == null || g.status != GoalStatus.active) continue;
    if (stats.dayStatusOf(g.id).done) continue; // 当日已留痕不打扰（SC-005）
    // 启用日锚：最近一次打卡，无打卡回落创建日（契约「自启用日起」）。
    final anchor = stats.lastCheckInDayOf(g.id) ?? g.createdAt;
    final applicable = switch (r.effectiveCadence) {
      Cadence.daily => true,
      Cadence.threeDay => today.differenceInDays(anchor) % 3 == 0, // 0/3/6… 天命中
      Cadence.weekly => today.weekdayIso == anchor.weekdayIso,
    };
    if (!applicable) continue;
    plan.add(
      PlannedNotification(
        id: goalReminderNotificationId(g.id),
        time: r.time,
        title: g.name,
        body: _goalBody(g),
        goalIds: [g.id],
      ),
    );
  }

  // ---- 短期到期询问（D4）----
  for (final g in goals) {
    if (g.goalType != GoalType.shortTerm || g.status != GoalStatus.active) {
      continue;
    }
    if (g.achievedAt != null) continue; // 已达成不再问
    if (g.deadline == null || g.deadline != today) continue;
    plan.add(
      PlannedNotification(
        id: dueAskNotificationId(g.id),
        time: kDueAskTime,
        title: g.name,
        body: Copy.shortTermDueAsk,
        goalIds: [g.id],
      ),
    );
  }
  return plan;
}

/// 单目标正文：存量「为什么」附上（FR-016 保全），否则轻推一句。
String _goalBody(Goal g) {
  final why = g.motivation?.trim();
  if (why != null && why.isNotEmpty) return Copy.reminderAsk(why, g.name);
  return Copy.reminderNudge;
}

String _briefBody(List<Goal> goals, StatsEvaluation stats) {
  final unmet = goals
      .where(
        (g) => g.isActive && !stats.dayStatusOf(g.id).done,
      )
      .length;
  return unmet == 0 ? Copy.dailyBriefAllDone : Copy.dailyBriefSummary(unmet);
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
    final reminders = _repo == null ? const <Reminder>[] : await _repo.all();
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
        id: p.id,
        time: p.time,
        title: p.title,
        body: p.body,
      );
    }
  }
}
