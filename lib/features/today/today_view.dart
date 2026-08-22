/// TodayView（US2 T009，按 screen-today.html R4 定稿落地）。
///
/// 努力记录模型：目标无「完成度」，只记录为它做过的努力。
/// 结构：顶栏（问候/新建/提醒）→ display 大标题 → 今日进展主卡（圆环 +
/// 竖排统计）→ 今日目标（状态胶囊 + 目标卡）。空/全部进展态按
/// 原型切换；壳层底幕渐变由 router 壳层负责，本页透明叠画。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';
import '../../core/stats/stats_engine.dart';
import '../../core/stats/versioning.dart';
import '../goals/goal_lifecycle.dart';
import 'backfill_calendar.dart';
import 'celebration.dart';
import 'undo_toast.dart';

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
    final versions = ref.watch(versionsProvider).value ?? const [];
    final settings = ref.watch(settingsProvider).value;

    final active = goalsAsync.value!
        .where((g) => g.status == GoalStatus.active)
        .toList();
    final habits = active
        .where((g) => g.isHabit && stats.dayStatusOf(g.id).applicable)
        .toList();
    final milestones = active.where((g) => !g.isHabit).toList();
    final progressed = habits
        .where((g) => stats.dayStatusOf(g.id).doneCount > 0)
        .length;
    final actions = habits.fold<int>(
      0,
      (sum, g) => sum + stats.dayStatusOf(g.id).doneCount,
    );
    final streak = _recordStreak(checkIns, today);
    final allProgress = habits.isNotEmpty && progressed == habits.length;
    final isEmpty = active.isEmpty;

    // display 大标题四态。
    final String display;
    if (isEmpty) {
      display = Copy.todayDisplayEmpty;
    } else if (allProgress) {
      display = Copy.todayDisplayAllProgress;
    } else {
      display = Copy.todayDisplayTypical;
    }

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
                  _TopBar(settings: settings),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpace.s6,
                      bottom: AppSpace.s12,
                    ),
                    child: Text(
                      display,
                      style: Theme.of(context).textTheme.displayL,
                    ),
                  ),
                  if (habits.isNotEmpty) ...[
                    _HeroCard(
                      progressed: progressed,
                      total: habits.length,
                      actions: actions,
                      streak: streak,
                      goals: active.length,
                    ),
                    _SectionHeader(onViewAll: () => context.go('/goals')),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s6),
                      child: Row(
                        children: [
                          _Pill(
                            hot: true,
                            label: Copy.todayPillActions(actions),
                          ),
                          const SizedBox(width: AppSpace.s2),
                          _Pill(
                            hot: false,
                            label: Copy.todayPillGoals(habits.length),
                          ),
                        ],
                      ),
                    ),
                  ],
                  for (final g in habits)
                    _HabitCard(
                      goal: g,
                      status: stats.dayStatusOf(g.id),
                      latest: _latestLabel(
                        checkIns.where((c) => c.goalId == g.id).toList(),
                        today,
                      ),
                      pattern: effectivePattern(
                        versions.where((v) => v.goalId == g.id).toList(),
                        today,
                      ),
                    ),
                  for (final g in milestones)
                    _MilestoneCard(goal: g, today: today),
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

  /// 连续记录天数：从今天（或昨天）往回，任何有效打卡都算不断。
  int _recordStreak(List<CheckIn> checkIns, LocalDate today) {
    final days = {for (final c in checkIns.where((c) => c.isValid)) c.day};
    var day = days.contains(today) ? today : today.addDays(-1);
    var n = 0;
    while (days.contains(day)) {
      n++;
      day = day.addDays(-1);
    }
    return n;
  }

  /// 「最近 · 今天 / 昨天 / N 天前」：最后一次有效记录的归属日。
  String _latestLabel(List<CheckIn> mine, LocalDate today) {
    final valid = mine.where((c) => c.isValid).toList();
    if (valid.isEmpty) return Copy.todayLatestNone;
    valid.sort(
      (a, b) => a.day != b.day
          ? a.day.compareTo(b.day)
          : a.createdAt.compareTo(b.createdAt),
    );
    final gap = today.differenceInDays(valid.last.day);
    if (gap <= 0) return Copy.todayLatestToday;
    if (gap == 1) return Copy.todayLatestYesterday;
    return Copy.todayLatestDaysAgo(gap);
  }
}

/// 顶栏：头像 + 问候两行 + 新建（主）/ 提醒（次）双按钮。
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.settings});

  final Settings? settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final now = ref.watch(dateProviderProvider).now();
    final today = ref.watch(todayProvider);
    final greeting = now.hour < 12
        ? Copy.greetingMorning
        : now.hour < 18
        ? Copy.greetingAfternoon
        : Copy.greetingEvening;
    final dateLine = '${today.month}月${today.day}日 星期${today.weekday.zhLabel}';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s4),
      child: Row(
        children: [
          _Avatar(onTap: () => context.go('/settings')),
          const SizedBox(width: AppSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleS
                      .copyWith(height: 1.25),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyM
                      .copyWith(color: palette.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          _CircleButton(
            primary: true,
            tooltip: Copy.todayNewGoal,
            icon: Icons.add,
            onTap: () => context.push('/goal-editor'),
          ),
          const SizedBox(width: AppSpace.s2),
          _CircleButton(
            primary: false,
            tooltip: Copy.todayReminder,
            icon: Icons.notifications_outlined,
            // 未读小红点：通知权限还没有被确认过（看过一次即消）。
            dot: settings != null && !settings!.notificationDeniedAcknowledged,
            dotColor: GoalColor.coral.of(context),
            onTap: () => _showReminderSheet(context),
          ),
        ],
      ),
    );
  }

  void _showReminderSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text(Copy.todayReminderSettings),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 头像（身份装饰渐变，填充级令牌）。
class _Avatar extends StatelessWidget {
  const _Avatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rFull,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kAvatarGradA, kAvatarGradB],
          ),
        ),
        child: Icon(Icons.star_rounded, size: 22, color: palette.accentOn),
      ),
    );
  }
}

/// 36px 圆按钮：主（墨实心）/ 次（白面 + 发丝边）。
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.primary,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.dot = false,
    this.dotColor,
  });

  final bool primary;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  final Color? dotColor;

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
            color: primary ? palette.accent : palette.surface,
            border: primary ? null : Border.all(color: palette.divider),
            boxShadow: primary ? null : palette.shadowLow,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primary ? palette.accentOn : palette.onSurface,
              ),
              if (dot)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      border: Border.all(color: palette.surface, width: 1.5),
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


/// 今日进展主卡：浅色 = 墨色反色卡（卡内文本令牌就地反转）；
/// 深色 = 深底幕卡 + 玻璃描边（文本令牌不反转）。
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.progressed,
    required this.total,
    required this.actions,
    required this.streak,
    required this.goals,
  });

  final int progressed;
  final int total;
  final int actions;
  final int streak;
  final int goals;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final on = dark ? palette.onSurface : palette.accentOn;
    final variant = dark
        ? palette.onSurfaceVariant
        : palette.accentOn.withValues(alpha: 0.72);
    final titleStyle = Theme.of(context).textTheme.bodyM
        .copyWith(color: variant);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.s6),
      padding: const EdgeInsets.all(AppSpace.s5),
      decoration: BoxDecoration(
        color: dark ? palette.bgGrad[3] : palette.accent,
        borderRadius: AppRadius.rLg,
        border: dark ? Border.all(color: palette.glassBorder) : null,
        boxShadow: palette.shadowMid,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Copy.todayHeroTitle, style: titleStyle),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              _ProgressRing(
                progressed: progressed,
                total: total,
                on: on,
                variant: variant,
                track: on.withValues(alpha: 0.15),
                bar: palette.positiveFill,
              ),
              const SizedBox(width: AppSpace.s6),
              Expanded(
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.bolt_outlined,
                      value: '$actions',
                      label: Copy.todayStatActions,
                      on: on,
                      variant: variant,
                    ),
                    const SizedBox(height: AppSpace.s3),
                    _StatRow(
                      icon: Icons.schedule,
                      value: '$streak',
                      label: Copy.todayStatStreak,
                      on: on,
                      variant: variant,
                    ),
                    const SizedBox(height: AppSpace.s3),
                    _StatRow(
                      icon: Icons.adjust,
                      value: '$goals',
                      label: Copy.todayStatGoals,
                      on: on,
                      variant: variant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 圆环（130px，r=52，描边 10）：中心「N/M 目标有进展」。
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progressed,
    required this.total,
    required this.on,
    required this.variant,
    required this.track,
    required this.bar,
  });

  final int progressed;
  final int total;
  final Color on;
  final Color variant;
  final Color track;
  final Color bar;

  @override
  Widget build(BuildContext context) {
    // 扫入动效（R4）：首次出现及进度变化时按 slow+standard 扫过圆环。
    final progress = total == 0 ? 0.0 : progressed / total;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 130,
      height: 130,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: reduced ? Duration.zero : AppMotion.slow,
        curve: AppMotion.easeStandard,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(progress: value, track: track, bar: bar),
          child: child,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$progressed/$total',
                  style: Theme.of(context).textTheme.titleM
                      .copyWith(color: on, height: 1),
                ),
                const SizedBox(height: AppSpace.s1),
                Text(
                  Copy.todayRingLabel,
                  style: Theme.of(context).textTheme.labelS
                      .copyWith(color: variant, height: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.bar,
  });

  final double progress;
  final Color track;
  final Color bar;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: const Offset(65, 65), radius: 52);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(rect.center, 52, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = bar,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.bar != bar;
}

/// 主卡竖排统计行：图标 + 数值 + 标签。
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.value,
    required this.label,
    required this.on,
    required this.variant,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color on;
  final Color variant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: variant),
        const SizedBox(width: AppSpace.s2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyS
              .copyWith(color: on, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpace.s2),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyS.copyWith(color: variant),
          ),
        ),
      ],
    );
  }
}

/// 节头：今日目标 / 查看全部。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Copy.todaySection,
              style: Theme.of(context).textTheme.titleS,
            ),
          ),
          InkWell(
            onTap: onViewAll,
            child: Text(
              Copy.todayViewAll,
              style: Theme.of(context).textTheme.bodyM
                  .copyWith(color: palette.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态胶囊：hot（青柠实心）/ plain（白面 + 发丝边）。
class _Pill extends StatelessWidget {
  const _Pill({required this.hot, required this.label});

  final bool hot;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s4,
        vertical: AppSpace.s2,
      ),
      decoration: BoxDecoration(
        color: hot ? palette.positiveFill : palette.surface,
        borderRadius: AppRadius.rFull,
        border: hot ? null : Border.all(color: palette.divider),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyM.copyWith(
          color: hot ? palette.positiveOn : palette.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 习惯目标卡（努力记录模型）：点击 = 记录一次努力，长按 = 补签日历。
class _HabitCard extends ConsumerWidget {
  const _HabitCard({
    required this.goal,
    required this.status,
    required this.latest,
    this.pattern,
  });

  final Goal goal;
  final DayStatus status;
  final String latest;
  final FrequencyPattern? pattern;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final done = status.doneCount > 0;
    final rhythm = pattern == null ? '' : '$pattern';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Material(
        color: palette.glassCard,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          onTap: () => _checkIn(context, ref),
          onLongPress: () => showBackfillCalendar(context, ref, goal),
          borderRadius: AppRadius.rLg,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s4),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: palette.divider),
              boxShadow: palette.shadowLow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSpace.s2,
                      height: AppSpace.s2,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s1),
                    Expanded(
                      child: Text(
                        GoalIcon.byKey(goal.iconKey).zhLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    ),
                    if (rhythm.isNotEmpty)
                      Text(
                        rhythm,
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    const SizedBox(width: AppSpace.s1),
                    _DetailArrow(
                      tooltip: Copy.todayDetail,
                      onTap: () => context.push('/goal-editor?id=${goal.id}'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s2),
                Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleS.copyWith(
                    color: done ? GoalColor.sky.of(context) : palette.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpace.s2),
                Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: palette.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpace.s1),
                    Expanded(
                      child: Text(
                        latest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s2),
                    Text.rich(
                      TextSpan(
                        text: '今日 ',
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                        children: [
                          TextSpan(
                            text: '${status.doneCount}',
                            style: Theme.of(context).textTheme.bodyS.copyWith(
                              color: palette.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' 次'),
                        ],
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(width: AppSpace.s2),
                    _CheckButton(
                      done: done,
                      onTap: () => _checkIn(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final c = await ref.read(checkInServiceProvider).checkInToday(goal.id);
    if (context.mounted) showCheckInToast(context, ref, c);
  }
}

/// 记录按钮（32px 拇指热区）：未记录 = 墨底白＋，已记录 = 青柠底白对勾。
///
/// 动效（R4）：底色 base250 过渡、按压缩放 .86 fast150、完成对勾按
/// dash 描画 base250（＋号前段淡出让位）。t=0 未记录，t=1 已记录。
class _CheckButton extends StatefulWidget {
  const _CheckButton({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: AppMotion.base,
    value: widget.done ? 1 : 0,
  );
  bool _pressed = false;

  @override
  void didUpdateWidget(_CheckButton old) {
    super.didUpdateWidget(old);
    if (widget.done == old.done) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = widget.done ? 1 : 0;
    } else {
      widget.done ? _t.forward() : _t.reverse();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Semantics(
      button: true,
      label: Copy.todayCheckAction,
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.fast,
        curve: AppMotion.easeStandard,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) => Material(
            color: Color.lerp(palette.accent, palette.positiveFill, _t.value)!,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CustomPaint(
                      painter: _CheckGlyphPainter(
                        t: _t.value,
                        plus: palette.accentOn,
                        tick: palette.positiveOn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 记录钮 glyph：t<0.4 ＋号淡出；t>0.4 对勾按 path metric 描画。
class _CheckGlyphPainter extends CustomPainter {
  _CheckGlyphPainter({required this.t, required this.plus, required this.tick});

  final double t;
  final Color plus;
  final Color tick;

  Paint _stroke(Color c) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = c;

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0.4) {
      final fade = 1.0 - t / 0.4;
      final paint = _stroke(plus.withValues(alpha: fade));
      canvas.drawLine(
        Offset(size.width / 2, size.height * 0.15),
        Offset(size.width / 2, size.height * 0.85),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.15, size.height / 2),
        Offset(size.width * 0.85, size.height / 2),
        paint,
      );
    }
    if (t > 0.4) {
      final draw = (t - 0.4) / 0.6;
      final path = Path()
        ..moveTo(size.width * 0.20, size.height * 0.55)
        ..lineTo(size.width * 0.44, size.height * 0.78)
        ..lineTo(size.width * 0.80, size.height * 0.26);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * draw),
        _stroke(tick),
      );
    }
  }

  @override
  bool shouldRepaint(_CheckGlyphPainter old) =>
      old.t != t || old.plus != plus || old.tick != tick;
}

/// 右上角详情小箭头（32px 命中区，14px 图标）。
class _DetailArrow extends StatelessWidget {
  const _DetailArrow({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rFull,
        child: SizedBox(
          width: 32,
          height: 24,
          child: Icon(
            Icons.north_east,
            size: 14,
            color: palette.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 里程碑卡：倒计时 + 步骤进度；全部步骤完成 → 一键达成（FR-010）。
class _MilestoneCard extends ConsumerWidget {
  const _MilestoneCard({required this.goal, required this.today});

  final Goal goal;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final steps = ref.watch(stepsProvider(goal.id)).value;
    final days = goal.deadline?.differenceInDays(today) ?? 0;
    final done = steps?.where((s) => s.isDone).length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Material(
        color: palette.glassCard,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          onTap: () => context.push('/goal/${goal.id}'),
          borderRadius: AppRadius.rLg,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s4),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: palette.divider),
              boxShadow: palette.shadowLow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSpace.s2,
                      height: AppSpace.s2,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s1),
                    Expanded(
                      child: Text(
                        GoalIcon.byKey(goal.iconKey).zhLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    ),
                    if (days < 0)
                      Text(
                        Copy.milestoneOverdue,
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    const SizedBox(width: AppSpace.s1),
                    _DetailArrow(
                      tooltip: Copy.todayDetail,
                      onTap: () => context.push('/goal/${goal.id}'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s2),
                Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleS,
                ),
                const SizedBox(height: AppSpace.s2),
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 13,
                      color: palette.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpace.s1),
                    Expanded(
                      child: Text(
                        Copy.milestoneCountdown(days),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s2),
                    if (steps != null &&
                        steps.isNotEmpty &&
                        done == steps.length)
                      FilledButton.tonal(
                        onPressed: () async {
                          await achieveGoal(ref, goal);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(Copy.milestoneDone)),
                            );
                          }
                        },
                        child: Text(Copy.milestoneDone),
                      )
                    else if (steps != null && steps.isNotEmpty)
                      Text(
                        Copy.milestoneProgress(done, steps.length),
                        style: Theme.of(context).textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 空态邀请卡（虚线边框）：整个邀请区域可点 → 新建目标。
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s6),
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
