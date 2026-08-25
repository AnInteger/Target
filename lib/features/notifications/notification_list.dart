/// 应用内通知列表（003 T019 · FR-005 · research D6：纯推导、无新表）。
///
/// 四源合成：① 提醒时刻表（与 [planReminders] 单一事实源——列表
/// 即当前 pending 通知的镜像，今日/明日两档）② 近 7 天成就（目标
/// 达成事件 + 全完成日）③ streak 里程碑（总连击命中的档位）
/// ④ 短期目标到期询问（deadline ≤ 今天且未达成）。
/// 时间倒序、无已读态、不持久化；tap → /goal/:id。
///
/// 004 T015 按冻结稿 v2-notifications 换装：分组头退役 → 行尾相对
/// 时刻（[notificationRelTime]）；行 = 38px rMd 语义色格图标（蓝=
/// 提醒 / 青柠=达成·全部完成 / 琥珀=连续·临近截止，图标形状+色格
/// 双通道辨识 FR-013）+ 标题/副题 + 时刻，行间 1px 分隔；空态 =
/// 88px 圆环图形 + 标题 + 一句引导。原型「未读点/全部已读」为演示
/// 交互（需已读持久化），不在任务域（倒序/类型图标/空态），D6
/// 推导式无已读态保留。
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
      items.add(
        NotificationItem(
          kind: NotificationKind.reminder,
          at: p.time.on(day),
          title: p.title,
          subtitle: subtitle,
          goalId: goalId,
        ),
      );
    }
  }

  // ---- ② 近 7 天成就：达成事件 + 全完成日 ----

  for (var i = 0; i < 7; i++) {
    final day = today.addDays(-i);
    // 全完成日：当日已存在的全部活跃目标均留痕。
    final active = goals
        .where(
          (g) => g.status == GoalStatus.active && !g.createdAt.isAfter(day),
        )
        .toList();
    if (active.isNotEmpty &&
        active.every((g) => stats.dayStatusOf(g.id, day).done)) {
      items.add(
        NotificationItem(
          kind: NotificationKind.allDone,
          at: _at(day, 21, 0),
          title: Copy.notifAllDoneDay,
          subtitle: Copy.notifSubAchievement,
        ),
      );
    }
    // 达成事件（achievedAt 按本地日归属）。
    for (final g in goals) {
      final achievedAt = g.achievedAt;
      if (achievedAt == null) continue;
      if (LocalDate.fromDateTime(achievedAt) != day) continue;
      items.add(
        NotificationItem(
          kind: NotificationKind.achieved,
          at: achievedAt,
          title: Copy.notifAchieved(g.name),
          subtitle: Copy.notifSubAchievement,
          goalId: g.id,
        ),
      );
    }
  }

  // ---- ③ streak 里程碑：总连击命中的最大档位 ----

  final streak = stats.totalStreak;
  final hitMilestone = kStreakMilestones.lastWhere(
    (m) => streak >= m,
    orElse: () => -1,
  );
  if (hitMilestone > 0) {
    // 锚定末日：今日已有任一留痕则含今日，否则自昨天回溯。
    final anyToday = checkIns.any((c) => c.isValid && c.day == today);
    final endDay = anyToday ? today : today.addDays(-1);
    final reachDay = endDay.addDays(-(streak - hitMilestone));
    items.add(
      NotificationItem(
        kind: NotificationKind.streak,
        at: _at(reachDay, 21, 0),
        title: Copy.notifStreak(hitMilestone),
        subtitle: Copy.notifSubMilestone,
      ),
    );
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
    items.add(
      NotificationItem(
        kind: NotificationKind.due,
        at: _at(deadline, 9, 0),
        title: Copy.notifDueTitle(g.name),
        subtitle: Copy.notifDueSub(today.differenceInDays(deadline)),
        goalId: g.id,
      ),
    );
  }

  items.sort((a, b) => b.at.compareTo(a.at));
  return items;
}

/// 行尾相对时刻（冻结稿 .tm）：日桶优先——当日内按 刚刚 → N 分钟前
/// → N 小时前 收敛（未到时刻报「今天 HH:mm」），跨日给 昨天/明天 +
/// HH:mm，2–6 天前只报天数，更远报「M月d日」；未来仅今日/明日两档
/// （提醒时刻表窗口之外不会出现，兜底同走日期语）。
String notificationRelTime(DateTime at, LocalDate today, LocalTime now) {
  final hm = notificationTimeLabel(at);
  final day = LocalDate.fromDateTime(at);
  final diffDays = today.differenceInDays(day); // >0 过去，<0 未来
  if (diffDays == 0) {
    final delta = now.sinceMidnight - LocalTime.fromDateTime(at).sinceMidnight;
    if (delta.isNegative) return Copy.notifTodayAt(hm); // 今日未到
    if (delta.inMinutes < 1) return Copy.notifJustNow;
    if (delta.inMinutes < 60) return Copy.notifMinutesAgo(delta.inMinutes);
    return Copy.notifHoursAgo(delta.inHours);
  }
  if (diffDays == 1) return Copy.notifYesterdayAt(hm);
  if (diffDays == -1) return Copy.notifTomorrowAt(hm);
  if (diffDays > 1 && diffDays <= 6) return Copy.notifDaysAgo(diffDays);
  return Copy.notifDateAt(day.month, day.day);
}

/// 具体时刻：HH:mm（相对桶语的补充段）。
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
    items.where((i) => LocalDate.fromDateTime(i.at) == today).length;

/// 弹起通知列表 sheet（今日页铃铛；冻结稿 .sheet = surface 圆角顶 +
/// 抓手条 + 72% 屏高上限）。今日页为壳层分支页——弹层挂分支导航器，
/// 真正「不遮底部导航」（2026-08-25：useRootNavigator 缺省 true 实为
/// 整屏盖 dock，与本注释原意相悖，一并修正）。
Future<void> showNotificationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final palette = TargetPalette.of(sheetContext);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
        ),
        child: Container(
          key: const ValueKey('notificationSheet'),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
            boxShadow: palette.shadowHigh,
          ),
          // 底距 s4 + 安全区（分支内 inset 恒 0 → 紧贴 dock 顶）。
          padding: EdgeInsets.fromLTRB(
            AppSpace.s5,
            AppSpace.s3,
            AppSpace.s5,
            AppSpace.s4 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: const _NotificationBody(),
        ),
      );
    },
  );
}

class _NotificationBody extends ConsumerWidget {
  const _NotificationBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final items = ref.watch(notificationItemsProvider);
    final today = ref.watch(todayProvider);
    final now = LocalTime.fromDateTime(ref.watch(dateProviderProvider).now());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 抓手条（冻结稿 .grab）。
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: AppSpace.s3),
          decoration: BoxDecoration(
            color: palette.divider,
            borderRadius: AppRadius.rFull,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s2),
          child: Text(Copy.notificationTitle, style: theme.textTheme.titleM),
        ),
        Flexible(
          child: items.isEmpty
              ? _EmptyState()
              : ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final (i, item) in items.indexed) ...[
                      if (i > 0)
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: palette.divider,
                        ),
                      _NotificationRow(item: item, today: today, now: now),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// 空态（冻结稿 .empty）：88px 圆环图形 + 标题 + 一句引导，非空白。
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpace.s12),
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.history_rounded,
            size: 38,
            color: palette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.s3),
        Text(
          Copy.notifEmptyTitle,
          style: theme.textTheme.titleM.copyWith(color: palette.onSurface),
        ),
        const SizedBox(height: AppSpace.s1),
        Text(
          Copy.notificationEmptyHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyM.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
      ],
    );
  }
}

/// 行（冻结稿 .nrow）：38px rMd 语义色格 + 标题/副题 + 相对时刻。
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.today,
    required this.now,
  });

  final NotificationItem item;
  final LocalDate today;
  final LocalTime now;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final (color, icon) = _kindStyle(palette, item.kind);
    return InkWell(
      onTap: item.goalId == null
          ? null
          : () => context.go('/goal/${item.goalId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.rMd,
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyL.copyWith(
                      color: palette.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyS.copyWith(
                      color: palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s2),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                notificationRelTime(item.at, today, now),
                style: theme.textTheme.bodyS.copyWith(
                  color: palette.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 五类类型色格（冻结稿 .k：蓝=提醒 / 青柠=达成·全部完成 /
  /// 琥珀=连续·临近截止；图标形状 + 色相双通道辨识 FR-013）。
  static (Color, IconData) _kindStyle(
    TargetPalette palette,
    NotificationKind kind,
  ) => switch (kind) {
    NotificationKind.reminder => (palette.accent, Icons.event_rounded),
    NotificationKind.allDone => (palette.positive, Icons.check_circle_rounded),
    NotificationKind.achieved => (palette.positive, Icons.verified_rounded),
    NotificationKind.streak => (
      palette.warning,
      Icons.local_fire_department_rounded,
    ),
    NotificationKind.due => (palette.warning, Icons.alarm_rounded),
  };
}
