/// TodayView（003 T017，按 screen-today.html R7 定稿落地）。
///
/// 三 Tab 收敛后今日页 = 目标浏览与记录的单一主页：
/// 头部带（账号区 | 日期语 | 铃铛角标＋新建）与内容同连续图层
/// （FR-003）；「今日目标」节 + 统一目标卡（图标 + 一句话 + 类型
/// 徽章 + 最新记录行，整卡可点进详情，卡上无按钮——FR-020 今日之
/// 环/周节奏微条/状态胶囊退役）；空态邀请卡（正式语域）；成就时刻
/// 覆盖层保留。补签仍走卡长按。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../goals/goal_type_badge.dart';
import '../notifications/notification_list.dart';
import '../profile/profile.dart';
import 'backfill_calendar.dart';
import 'celebration.dart';

class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final stats = ref.watch(statsProvider);
    if (!goalsAsync.hasValue || stats == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: TargetPalette.of(context).accent,
          ),
        ),
      );
    }
    final today = ref.watch(todayProvider);
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];

    final active = goalsAsync.value!
        .where((g) => g.status == GoalStatus.active)
        .toList();
    final doneGoals =
        active.where((g) => stats.dayStatusOf(g.id).done).length;
    final actions = active.fold<int>(
      0,
      (sum, g) => sum + stats.dayStatusOf(g.id).doneCount,
    );
    final allProgress = active.isNotEmpty && doneGoals == active.length;
    final isEmpty = active.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 成就覆盖层铺满全屏（不进 SafeArea，状态栏也要被辉光盖住）。
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.s6),
                children: [
                  const _HeaderBand(),
                  if (!isEmpty) ...[
                    _SectionHeader(note: Copy.todayRecordedNote(doneGoals, active.length)),
                    for (final g in active)
                      _GoalCard(
                        goal: g,
                        done: stats.dayStatusOf(g.id).done,
                        latest: _latestLine(
                          checkIns.where((c) => c.goalId == g.id).toList(),
                          today,
                        ),
                        today: today,
                      ),
                  ],
                  if (isEmpty)
                    _EmptyCard(onTap: () => context.push('/goal-editor')),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Celebration(active: allProgress, actions: actions),
          ),
        ],
      ),
    );
  }

  /// 最新记录行（T007 R2 裁决 2）：「相对时间 - 该次描述」；
  /// 未填描述兜底「完成打卡」（FR-019）；无任何记录 → 还没有记录。
  String _latestLine(List<CheckIn> mine, LocalDate today) {
    final valid = mine.where((c) => c.isValid).toList();
    if (valid.isEmpty) return Copy.todayLatestNone;
    valid.sort(
      (a, b) => a.day != b.day
          ? a.day.compareTo(b.day)
          : a.createdAt.compareTo(b.createdAt),
    );
    final last = valid.last;
    final gap = today.differenceInDays(last.day);
    final rel = gap <= 0
        ? Copy.notifDayToday
        : gap == 1
            ? Copy.notifDayYesterday
            : Copy.todayLatestDaysAgo(gap);
    final note = (last.note ?? '').trim();
    return '$rel - ${note.isEmpty ? Copy.checkInDefaultNote : note}';
  }
}

/// 头部带（FR-003 同图层 / FR-008 三屏对齐基准）：44px 单行——
/// 左 = 账号区（头像环 + 昵称，tap → 资料编辑 sheet）；中 = 日期语；
/// 右 = 铃铛（角标 = 今日推导条目数，tap → 通知列表 sheet）+ ＋ 新建。
class _HeaderBand extends ConsumerWidget {
  const _HeaderBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final profile = ref.watch(profileProvider).value;
    final today = ref.watch(todayProvider);
    final badge = todayBadgeCount(
        ref.watch(notificationItemsProvider), today);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s2),
      child: Row(
        children: [
          // 账号区：头像外缘 surface 描一圈环（原型 box-shadow 语义）。
          InkWell(
            onTap: () => showProfileSheet(context),
            borderRadius: AppRadius.rFull,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                ),
                padding: const EdgeInsets.all(2),
                child: ProfileAvatar(profile: profile, size: 32),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          Expanded(
            child: Text(
              profileNicknameOf(profile),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleS
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            Copy.todayDateLine(
                today.month, today.day, '周${today.weekday.zhLabel}'),
            style: Theme.of(context)
                .textTheme
                .bodyM
                .copyWith(color: palette.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpace.s3),
          _CircleButton(
            ghost: true,
            tooltip: Copy.notificationTitle,
            icon: Icons.notifications_outlined,
            badge: badge,
            onTap: () => showNotificationSheet(context),
          ),
          const SizedBox(width: AppSpace.s2),
          _CircleButton(
            ghost: false,
            tooltip: Copy.todayNewGoal,
            icon: Icons.add,
            onTap: () => context.push('/goal-editor'),
          ),
        ],
      ),
    );
  }
}

/// 36px 圆钮：主（墨实心）/ 次（白面 + 发丝边）；铃铛带数字角标。
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.ghost,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final bool ghost;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  /// 数字角标（0 = 隐藏）：铃铛 = 今日推导条目数。
  final int badge;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rFull,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ghost ? palette.surface : palette.accent,
            border: ghost ? Border.all(color: palette.divider) : null,
            boxShadow: ghost ? palette.shadowLow : palette.shadowMid,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: ghost ? palette.onSurface : palette.accentOn,
              ),
              if (badge > 0)
                Positioned(
                  top: -5,
                  right: -7,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.rFull,
                      color: palette.badge,
                      border: Border.all(color: palette.surface, width: 2),
                    ),
                    child: Text(
                      '$badge',
                      style: Theme.of(context).textTheme.labelS.copyWith(
                            color: palette.badgeOn,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 节头：今日目标 + 节注「已记录 N/M」（今日之环卡移除后直接承接
/// 头部带，T007 R2 裁决 2）。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s5, bottom: AppSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(Copy.todaySection, style: Theme.of(context).textTheme.titleS),
          const Spacer(),
          Text(
            note,
            style: Theme.of(context)
                .textTheme
                .bodyM
                .copyWith(color: palette.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 统一目标卡（三类型一卡）：图标格 + 一句话 + 类型徽章 + 最新记录行。
/// 整卡可点进详情（卡上无按钮），长按 = 补签日历。
class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.goal,
    required this.done,
    required this.latest,
    required this.today,
  });

  final Goal goal;
  final bool done;
  final String latest;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Material(
        color: palette.glassCard,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          onTap: () => context.push('/goal/${goal.id}'),
          onLongPress: () => showBackfillCalendar(context, ref, goal),
          borderRadius: AppRadius.rLg,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s4),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: palette.divider),
              boxShadow: palette.shadowLow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: palette.divider),
                  ),
                  child: Icon(GoalIconCatalog.byKey(goal.iconKey).icon,
                      size: 22, color: palette.onSurface),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleS.copyWith(
                              color: done
                                  ? GoalColor.sky.of(context)
                                  : palette.onSurface,
                            ),
                      ),
                      const SizedBox(height: AppSpace.s1),
                      GoalTypeBadge(goal: goal, today: today),
                      const SizedBox(height: AppSpace.s1),
                      Text(
                        latest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyS.copyWith(
                              color:
                                  done ? palette.positive : palette.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 空态邀请卡（虚线边框，R3 裁决 3 正式语域）：整卡可点 → 新建目标。
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s5, bottom: AppSpace.s6),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: palette.divider,
            radius: AppRadius.lg,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s5,
              AppSpace.s6,
              AppSpace.s5,
              AppSpace.s6,
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.surface,
                    border: Border.all(color: palette.divider),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: palette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  Copy.todayEmptyTitle,
                  style: Theme.of(context).textTheme.titleM,
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  Copy.todayEmptyBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyS
                      .copyWith(color: palette.onSurfaceVariant, height: 1.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆角矩形的虚线描边（空态邀请卡）。
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    const dash = 6.0, gap = 5.0;
    var dist = 0.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    while (dist < metric.length) {
      canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
      dist += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
