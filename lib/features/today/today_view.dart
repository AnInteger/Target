/// TodayView（T026，FR-004/017、US2）：生活电量环 + 今日打卡列表。
///
/// 电量环为视觉核心（空态"—"，R9）；打卡后连击/周进度经 statsProvider
/// 流即时刷新；全部达标呈现成就态；长按目标进补签日历。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';
import '../../core/stats/stats_engine.dart';
import '../../core/stats/versioning.dart';
import 'backfill_calendar.dart';
import 'undo_toast.dart';

class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final stats = ref.watch(statsProvider);
    if (!goalsAsync.hasValue || stats == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final today = ref.watch(todayProvider);
    final versions = ref.watch(versionsProvider).value ?? const [];
    final active = goalsAsync
        .value!
        .where((g) => g.status == GoalStatus.active)
        .toList();
    final habits =
        active.where((g) => g.isHabit && stats.dayStatusOf(g.id).applicable).toList();
    final metCount = habits.where((g) => stats.dayStatusOf(g.id).met).length;
    final milestones = active.where((g) => g.isMilestone).toList();
    final allDone = habits.isNotEmpty && metCount == habits.length;

    return Scaffold(
      appBar: AppBar(title: const Text(Copy.appName)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: BatteryRing(
              percent: stats.battery.percent,
              size: 180,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              stats.battery.percent == null
                  ? Copy.batteryEmpty
                  : (stats.battery.percent! < 30
                      ? Copy.batteryLow(stats.battery.percent!)
                      : Copy.batteryValue(stats.battery.percent!)),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          if (allDone)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(Copy.allDoneTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text(Copy.allDoneSubtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '今日 ${Copy.todayProgress(metCount, habits.length)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          const SizedBox(height: 8),
          for (final g in habits)
            _HabitRow(
              goal: g,
              status: stats.dayStatusOf(g.id),
              pattern: effectivePattern(
                  versions.where((v) => v.goalId == g.id).toList(), today),
            ),
          for (final g in milestones) _MilestoneRow(goal: g),
        ],
      ),
    );
  }
}

/// 单个习惯行：图标/名称/频率 + 进度 + 打卡按钮。
class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.goal, required this.status, this.pattern});

  final Goal goal;
  final DayStatus status;
  final FrequencyPattern? pattern;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = GoalColor.byKey(goal.colorKey).of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _checkIn(context, ref),
        onLongPress: () => showBackfillCalendar(context, ref, goal),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle),
                child: Icon(GoalIcon.byKey(goal.iconKey).icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                          child: Text(goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium)),
                      if (status.busyMode) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(Copy.busyBadge,
                              style: Theme.of(context).textTheme.labelSmall),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${pattern ?? ''} · ${status.doneCount}/${status.targetCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CheckButton(
                met: status.met,
                color: color,
                onTap: () => _checkIn(context, ref),
              ),
            ],
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

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.met, required this.color, required this.onTap});

  final bool met;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (met) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        side: BorderSide(color: color, width: 1.5),
      ),
      onPressed: onTap,
      child: Icon(Icons.add, color: color),
    );
  }
}

/// 里程碑行：倒计时 + 步骤进度，点击进里程碑详情。
class _MilestoneRow extends ConsumerWidget {
  const _MilestoneRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final steps = ref.watch(stepsProvider(goal.id)).value;
    final days = goal.deadline?.differenceInDays(today) ?? 0;
    final done = steps?.where((s) => s.isDone).length ?? 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/milestone/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle),
                child: Icon(GoalIcon.byKey(goal.iconKey).icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      days < 0
                          ? '${Copy.milestoneCountdown(days)} · ${Copy.milestoneOverdue}'
                          : Copy.milestoneCountdown(days),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (steps != null && steps.isNotEmpty)
                Text(Copy.milestoneProgress(done, steps.length),
                    style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// 生活电量环（FR-017 视觉核心）：进度弧 + 中央百分数。
class BatteryRing extends StatelessWidget {
  const BatteryRing({super.key, required this.percent, this.size = 160});

  final int? percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (percent ?? 0) / 100,
          track: scheme.surfaceContainerHighest,
          progressColor: percent == null
              ? scheme.outline
              : (percent! < 30 ? scheme.tertiary : scheme.primary),
        ),
        child: Center(
          child: Text(
            percent == null ? Copy.batteryEmpty : '$percent%',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontWeight: FontWeight.w600),
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
    required this.progressColor,
  });

  final double progress;
  final Color track;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width / 12;
    final rect = Offset.zero & size;
    final inset = stroke / 2 + 2;
    final arcRect = rect.deflate(inset);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false,
          paint..color = progressColor);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.progressColor != progressColor;
}
