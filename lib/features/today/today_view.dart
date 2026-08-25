library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_advice.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../../core/models/goal_progress.dart';
import '../goals/progress_record_sheet.dart';
import '../notifications/notification_list.dart';
import '../profile/profile.dart';
import 'celebration.dart';
import 'focus_carousel.dart';

class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value;
    final checks = ref.watch(checkInsProvider).value;
    final allSteps = ref.watch(allStepsProvider).value;
    final snapshot = ref.watch(goalProgressProvider);
    final stats = ref.watch(statsProvider);
    if (goals == null ||
        checks == null ||
        allSteps == null ||
        snapshot == null ||
        stats == null) {
      return Scaffold(
        backgroundColor: TargetPalette.of(context).background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final today = ref.watch(todayProvider);
    final active = goals
        .where((goal) => goal.status == GoalStatus.active)
        .toList();
    final steps = <String, List<MilestoneStep>>{};
    for (final step in allSteps) {
      steps.putIfAbsent(step.goalId, () => []).add(step);
    }
    final doneGoals = active.where((g) => stats.dayStatusOf(g.id).done).length;
    final actions = active.fold<int>(
      0,
      (sum, goal) => sum + stats.dayStatusOf(goal.id).doneCount,
    );

    Future<void> record(Goal goal, MilestoneStep? currentStep) async {
      final saved = await showProgressRecordSheet(
        context,
        goal: goal,
        currentStep: currentStep,
      );
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('进展已记录')));
      }
    }

    return Scaffold(
      backgroundColor: TargetPalette.of(context).background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _Head()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _GoalStatusCard(evaluation: snapshot.evaluation),
                    ),
                  ),
                  if (active.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: '关注',
                        trailing: '查看全部',
                        route: '/goals-all',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FocusCarousel(
                        goals: goals,
                        checkIns: checks,
                        milestones: steps,
                        scores: snapshot.evaluation.byGoal,
                        today: today,
                        onRecord: record,
                        onOpenGoal: (goal) => context.push('/goal/${goal.id}'),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ProgressCard(snapshot: snapshot),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _AttentionSection(
                          evaluation: snapshot.evaluation,
                          goals: goals,
                          onOpen: (goal) => context.push('/goal/${goal.id}'),
                        ),
                      ),
                    ),
                  ] else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _EmptyCTA(
                          onTap: () => context.push('/goal-editor'),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Celebration(
              active: active.isNotEmpty && doneGoals == active.length,
              actions: actions,
            ),
          ),
        ],
      ),
    );
  }
}

class _Head extends ConsumerWidget {
  const _Head();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final today = ref.watch(todayProvider);
    final profile = ref.watch(profileProvider).value;
    final badge = todayBadgeCount(ref.watch(notificationItemsProvider), today);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Copy.todayHeadDate(today.weekday.zhLabel, today.month, today.day),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.onSurfaceVariant, letterSpacing: .6),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text('今日', style: Theme.of(context).textTheme.displayLarge),
              const Spacer(),
              _HeaderButton(
                icon: Icons.notifications_none_rounded,
                badge: badge,
                onTap: () => showNotificationSheet(context),
                tooltip: '通知',
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => context.push('/profile'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                    boxShadow: palette.shadowLow,
                  ),
                  child: ProfileAvatar(profile: profile, size: 38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.badge,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return IconButton(
      key: const ValueKey('todayBell'),
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: palette.surface,
        side: BorderSide(color: palette.divider),
      ),
      icon: Badge(
        isLabelVisible: badge > 0,
        label: Text('$badge'),
        child: Icon(icon),
      ),
    );
  }
}

class _GoalStatusCard extends StatelessWidget {
  const _GoalStatusCard({required this.evaluation});

  final GoalProgressEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      key: const ValueKey('goalStatusCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadowLow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 300;
          final ring = SizedBox(
            width: compact ? 104 : 120,
            height: compact ? 104 : 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StatusRingPainter(
                      dimensions: evaluation.dimensions,
                      track: palette.surfaceAlt,
                      colors: _dimensionColors(context),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '目标状态',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          );
          final legend = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final dimension in ProgressDimension.values)
                _StatusLegendRow(
                  dimension: dimension,
                  progress: evaluation.dimensions[dimension],
                  color: _dimensionColors(context)[dimension]!,
                ),
            ],
          );
          return compact
              ? Column(children: [ring, const SizedBox(height: 12), legend])
              : Row(
                  children: [
                    ring,
                    const SizedBox(width: 24),
                    Expanded(child: legend),
                  ],
                );
        },
      ),
    );
  }
}

Map<ProgressDimension, Color> _dimensionColors(BuildContext context) => {
  ProgressDimension.health: MajorColors.health.of(context),
  ProgressDimension.habit: MajorColors.habit.of(context),
  ProgressDimension.goal: MajorColors.goal.of(context),
};

class _StatusLegendRow extends StatelessWidget {
  const _StatusLegendRow({
    required this.dimension,
    required this.progress,
    required this.color,
  });

  final ProgressDimension dimension;
  final DimensionProgress? progress;
  final Color color;

  String get label => switch (dimension) {
    ProgressDimension.health => '健康',
    ProgressDimension.habit => '习惯',
    ProgressDimension.goal => '目标',
  };

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(
            progress == null ? '暂无数据' : '${progress!.score}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: progress == null
                  ? palette.onSurfaceVariant
                  : palette.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (progress != null)
            Text(
              ' / 100',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _StatusRingPainter extends CustomPainter {
  _StatusRingPainter({
    required this.dimensions,
    required this.track,
    required this.colors,
  });

  final Map<ProgressDimension, DimensionProgress> dimensions;
  final Color track;
  final Map<ProgressDimension, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.butt
      ..color = track;
    canvas.drawCircle(center, radius, base);
    for (final (index, dimension) in ProgressDimension.values.indexed) {
      final value = dimensions[dimension]?.score;
      if (value == null) continue;
      final start = -math.pi / 2 + index * math.pi * 2 / 3 + .04;
      final sweep = (math.pi * 2 / 3 - .14) * value / 100;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..color = colors[dimension]!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StatusRingPainter oldDelegate) => true;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    required this.route,
  });

  final String title;
  final String trailing;
  final String route;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        TextButton(onPressed: () => context.push(route), child: Text(trailing)),
      ],
    ),
  );
}

class _ProgressCard extends StatefulWidget {
  const _ProgressCard({required this.snapshot});

  final GoalProgressSnapshot snapshot;

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      key: const ValueKey('progressCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('进展', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                key: const ValueKey('progressAdviceButton'),
                tooltip: '查看分数说明',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            '最近 7 天目标管理状态',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(
                points: widget.snapshot.evaluation.dailyPoints,
                colors: _dimensionColors(context),
                guide: palette.divider,
                label: palette.onSurfaceVariant,
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            for (final dimension in ProgressDimension.values)
              if (widget.snapshot.advice[dimension] case final advice?)
                _AdviceBlock(advice: advice),
          ],
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.colors,
    required this.guide,
    required this.label,
  });

  final List<DailyProgressPoint> points;
  final Map<ProgressDimension, Color> colors;
  final Color guide;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 4.0, right = 28.0, top = 8.0, bottom = 26.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (final score in [0, 50, 100]) {
      final y = chart.bottom - chart.height * score / 100;
      canvas.drawLine(
        Offset(chart.left, y),
        Offset(chart.right, y),
        guidePaint,
      );
    }
    if (points.isEmpty) return;
    double xAt(int index) => points.length == 1
        ? chart.left
        : chart.left + chart.width * index / (points.length - 1);
    for (final dimension in ProgressDimension.values) {
      final paint = Paint()
        ..color = colors[dimension]!
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      Path? path;
      for (final (index, point) in points.indexed) {
        final value = point.dimensions[dimension];
        if (value == null) {
          if (path != null) canvas.drawPath(path, paint);
          path = null;
          continue;
        }
        final offset = Offset(
          xAt(index),
          chart.bottom - chart.height * value / 100,
        );
        path ??= Path()..moveTo(offset.dx, offset.dy);
        if (path.getBounds().isEmpty) {
          path.moveTo(offset.dx, offset.dy);
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
        canvas.drawCircle(offset, 2.6, Paint()..color = colors[dimension]!);
      }
      if (path != null) canvas.drawPath(path, paint);
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final index in [0, points.length - 1]) {
      final day = points[index].day;
      textPainter.text = TextSpan(
        text: '${day.month}/${day.day}',
        style: TextStyle(color: label, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xAt(index) - textPainter.width / 2, chart.bottom + 7),
      );
    }
    for (final dimension in ProgressDimension.values) {
      final value = points.last.dimensions[dimension];
      if (value == null) continue;
      textPainter.text = TextSpan(
        text: '$value',
        style: TextStyle(
          color: colors[dimension],
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          chart.right + 5,
          chart.bottom - chart.height * value / 100 - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}

class _AdviceBlock extends StatelessWidget {
  const _AdviceBlock({required this.advice});

  final GoalAdvice advice;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final title = switch (advice.dimension) {
      ProgressDimension.health => '健康类目标',
      ProgressDimension.habit => '习惯类目标',
      ProgressDimension.goal => '成长类目标',
    };
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text('指标原理｜${advice.principle}'),
          const SizedBox(height: 6),
          Text('当前解读｜${advice.currentInterpretation}'),
          const SizedBox(height: 6),
          Text('行动建议｜${advice.action}'),
        ],
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({
    required this.evaluation,
    required this.goals,
    required this.onOpen,
  });

  final GoalProgressEvaluation evaluation;
  final List<Goal> goals;
  final void Function(Goal goal) onOpen;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final goal in goals) goal.id: goal};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('需要关注', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (evaluation.attention.isEmpty)
          _AttentionEmpty()
        else
          for (final item in evaluation.attention)
            if (byId[item.goalId] case final goal?)
              _AttentionCard(goal: goal, item: item, onTap: () => onOpen(goal)),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.goal,
    required this.item,
    required this.onTap,
  });

  final Goal goal;
  final AttentionItem item;
  final VoidCallback onTap;

  String get reason => switch (item.reason) {
    AttentionReason.needsPlanning => '待规划下一步',
    AttentionReason.deadlineNear => '截止缓冲较少',
    AttentionReason.rhythmInterrupted => '推进节奏放缓',
  };

  String get action => switch (item.reason) {
    AttentionReason.needsPlanning => '确认一个可以开始的下一步',
    AttentionReason.deadlineNear => '检查剩余步骤与日期是否匹配',
    AttentionReason.rhythmInterrupted => '记录一次真实进展或调整节奏',
  };

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final color = MajorColors.byKey(goal.major.name).of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    GoalIconCatalog.byKey(goal.iconKey).icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              reason,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '当前没有需要优先处理的计划。',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: palette.onSurfaceVariant),
      ),
    );
  }
}

class _EmptyCTA extends StatelessWidget {
  const _EmptyCTA({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 44, color: palette.accent),
          const SizedBox(height: 12),
          Text('还没有进行中的目标', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '创建一个目标，并先写下可开始的第一步。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: const Text('新建目标')),
        ],
      ),
    );
  }
}
