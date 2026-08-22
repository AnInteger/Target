/// 应用内通知列表（003 T019 · FR-005 · research D6：纯推导、无新表）。
///
/// 四源合成：① 提醒时刻表（与 [planReminders] 单一事实源——列表
/// 即当前 pending 通知的镜像，今日/明日两档）② 近 7 天成就（目标
/// 达成事件 + 全完成日）③ streak 里程碑（总连击命中的档位）
/// ④ 短期目标到期询问（deadline ≤ 今天且未达成）。
/// 时间倒序、按天分组、无已读态、不持久化；tap → /goal/:id。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/stats/stats_engine.dart';
import '../settings/reminder_service.dart';

/// 条目类型（决定图标与跳转语义）。
enum NotificationKind { reminder, achieved, allDone, streak, due }

/// streak 里程碑档位（连击达到即立此档）。
const List<int> kStreakMilestones = [3, 7, 14, 30, 60, 100];

class NotificationItem {
  const NotificationItem({
    required this.kind,
    required this.at,
    required this.title,
    required this.subtitle,
    this.goalId,
  });

  final NotificationKind kind;

  /// 归属时刻（排序与分组锚；日粒度事件取当日代表时刻）。
  final DateTime at;
  final String title;
  final String subtitle;

  /// 可跳转目标（null = 无处可去：简报/合并档/全完成日）。
  final String? goalId;
}

DateTime _at(LocalDate day, int hour, int minute) =>
    DateTime(day.year, day.month, day.day, hour, minute);

/// 四源合成 + 时间倒序（纯函数，注入时刻便于测试）。
///
/// 提醒源直接复用 [planReminders]：列表展示的时刻集合 ≡ 当前
/// pending 推送集合（数据/打卡状态变化即重推导，无落库残缺问题）。
List<NotificationItem> deriveNotifications({
  required List<Goal> goals,
  required List<CheckIn> checkIns,
  required List<Reminder> reminders,
  required StatsEvaluation stats,
  required LocalDate today,
  required LocalTime nowTime,
  required LocalTime defaultBriefTime,
}) {
  final items = <NotificationItem>[];

  // ---- ① 提醒时刻表（今日 + 明日；今日含已过时刻，时刻表语义）----

  final plan = planReminders(
    reminders: reminders,
    defaultBriefTime: defaultBriefTime,
    goals: goals,
    stats: stats,
    today: today,
    nowTime: nowTime,
  );
  for (final p in plan) {
    final goalId = p.goalIds.length == 1 ? p.goalIds.first : null;
    final subtitle = p.id == kDailyBriefNotificationId
        ? Copy.notifSubBrief
        : Copy.notifSubGoalReminder;
    for (final day in [today, today.addDays(1)]) {
      items.add(NotificationItem(
        kind: NotificationKind.reminder,
        at: p.time.on(day),
        title: p.title,
        subtitle: subtitle,
        goalId: goalId,
      ));
    }
  }

  // ---- ② 近 7 天成就：达成事件 + 全完成日 ----

  for (var i = 0; i < 7; i++) {
    final day = today.addDays(-i);
    // 全完成日：当日已存在的全部活跃目标均留痕。
    final active = goals
        .where((g) =>
            g.status == GoalStatus.active && !g.createdAt.isAfter(day))
        .toList();
    if (active.isNotEmpty &&
        active.every((g) => stats.dayStatusOf(g.id, day).done)) {
      items.add(NotificationItem(
        kind: NotificationKind.allDone,
        at: _at(day, 21, 0),
        title: Copy.notifAllDoneDay,
        subtitle: Copy.notifSubAchievement,
      ));
    }
    // 达成事件（achievedAt 按本地日归属）。
    for (final g in goals) {
      final achievedAt = g.achievedAt;
      if (achievedAt == null) continue;
      if (LocalDate.fromDateTime(achievedAt) != day) continue;
      items.add(NotificationItem(
        kind: NotificationKind.achieved,
        at: achievedAt,
        title: Copy.notifAchieved(g.name),
        subtitle: Copy.notifSubAchievement,
        goalId: g.id,
      ));
    }
  }

  // ---- ③ streak 里程碑：总连击命中的最大档位 ----

  final streak = stats.totalStreak;
  final hitMilestone = kStreakMilestones
      .lastWhere((m) => streak >= m, orElse: () => -1);
  if (hitMilestone > 0) {
    // 锚定末日：今日已有任一留痕则含今日，否则自昨天回溯。
    final anyToday = checkIns.any((c) => c.isValid && c.day == today);
    final endDay = anyToday ? today : today.addDays(-1);
    final reachDay = endDay.addDays(-(streak - hitMilestone));
    items.add(NotificationItem(
      kind: NotificationKind.streak,
      at: _at(reachDay, 21, 0),
      title: Copy.notifStreak(hitMilestone),
      subtitle: Copy.notifSubMilestone,
    ));
  }

  // ---- ④ 短期到期询问（deadline ≤ 今天且未处理，D4：只提醒不判决）----

  for (final g in goals) {
    final deadline = g.deadline;
    if (!g.isShortTerm ||
        g.status != GoalStatus.active ||
        deadline == null ||
        deadline.isAfter(today)) {
      continue;
    }
    items.add(NotificationItem(
      kind: NotificationKind.due,
      at: _at(deadline, 9, 0),
      title: Copy.notifDueTitle(g.name),
      subtitle: Copy.notifDueSub(today.differenceInDays(deadline)),
      goalId: g.id,
    ));
  }

  items.sort((a, b) => b.at.compareTo(a.at));
  return items;
}

/// 分组头：今天/昨天/明天，更早按「M月d日」。
String notificationDayLabel(LocalDate day, LocalDate today) {
  final diff = today.differenceInDays(day);
  if (diff == 0) return Copy.notifDayToday;
  if (diff == 1) return Copy.notifDayYesterday;
  if (diff == -1) return Copy.notifDayTomorrow;
  return Copy.notifDayDate(day.month, day.day);
}

/// 行尾时刻：HH:mm（与分组头互补——相对语在组头，行内给具体时刻）。
String notificationTimeLabel(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Riverpod：四源数据就绪前为空列表（sheet 呈现空态）。
// ---------------------------------------------------------------------------

final notificationItemsProvider = Provider<List<NotificationItem>>((ref) {
  final goals = ref.watch(goalsProvider).value;
  final checkIns = ref.watch(checkInsProvider).value;
  final reminders = ref.watch(remindersProvider).value;
  final settings = ref.watch(settingsProvider).value;
  final stats = ref.watch(statsProvider);
  if (goals == null ||
      checkIns == null ||
      reminders == null ||
      settings == null ||
      stats == null) {
    return const [];
  }
  final clock = ref.watch(dateProviderProvider);
  final now = clock.now();
  return deriveNotifications(
    goals: goals,
    checkIns: checkIns,
    reminders: reminders,
    stats: stats,
    today: LocalDate.fromDateTime(now),
    nowTime: LocalTime.fromDateTime(now),
    defaultBriefTime: settings.dailyBriefTime,
  );
});

/// 今日日期归属条目数（铃铛角标，T020 消费；推导式列表无已读态）。
int todayBadgeCount(List<NotificationItem> items, LocalDate today) =>
    items
        .where((i) => LocalDate.fromDateTime(i.at) == today)
        .length;

/// 弹起通知列表 sheet（今日页铃铛，不遮底部导航）。
Future<void> showNotificationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _NotificationSheet(),
  );
}

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final items = ref.watch(notificationItemsProvider);
    final today =
        ref.watch(todayProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.s2),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.divider,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s6, AppSpace.s4, AppSpace.s6, 0),
            child: Text(Copy.notificationTitle,
                style: Theme.of(context).textTheme.titleM),
          ),
          Flexible(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.s8),
                    child: Text(
                      Copy.notificationEmptyHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyM
                          .copyWith(color: palette.onSurfaceVariant),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.s6, 0, AppSpace.s6, AppSpace.s6),
                    children: [
                      for (final widget in _groupByDay(context, items, today))
                        widget,
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 按天分组（已倒序）：组头 + 行。
  List<Widget> _groupByDay(
      BuildContext context, List<NotificationItem> items, LocalDate today) {
    final widgets = <Widget>[];
    LocalDate? current;
    for (final item in items) {
      final day = LocalDate.fromDateTime(item.at);
      if (day != current) {
        current = day;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: AppSpace.s3, bottom: AppSpace.s1),
          child: Text(
            notificationDayLabel(day, today),
            style: Theme.of(context)
                .textTheme
                .labelS
                .copyWith(color: TargetPalette.of(context).onSurfaceVariant),
          ),
        ));
      }
      widgets.add(_NotificationRow(item: item));
    }
    return widgets;
  }
}

/// 行：图标圆底 + 标题/副题 + 时刻（原型 .nt-item 三段式）。
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return InkWell(
      onTap: item.goalId == null ? null : () => context.go('/goal/${item.goalId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: palette.divider),
              ),
              child: Icon(_iconOf(item.kind),
                  size: 16, color: palette.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyM
                          .copyWith(color: palette.onSurface)),
                  Text(item.subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyS
                          .copyWith(color: palette.onSurfaceVariant)),
                ],
              ),
            ),
            Text(notificationTimeLabel(item.at),
                style: Theme.of(context)
                    .textTheme
                    .bodyS
                    .copyWith(color: palette.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // 图标三枚对齐原型 NT_ICONS（铃铛/问询/庆祝）。
  static IconData _iconOf(NotificationKind kind) => switch (kind) {
        NotificationKind.reminder => Icons.notifications_rounded,
        NotificationKind.due => Icons.help_rounded,
        _ => Icons.celebration_rounded,
      };
}
