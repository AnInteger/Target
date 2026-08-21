/// GoalsView（002 T017 重写，FR-005/009/010/011 · screen-goals.html 列表语言）。
///
/// 卡片两行语言：名称 + 第二行「为什么」（无则虚线邀请「补一句为什么」，
/// 点卡片即渐进补全入口 T014 B 案）；元行 = 频率/倒计时/一次性。
/// 暂停区 = 虚线行 + 恢复按钮；空态 = 虚线邀请卡（模板一句话 + 写一句自己的）。
/// 长按/菜单进生命周期动作（goal_lifecycle.dart）。
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
import 'goal_lifecycle.dart';
import 'goal_templates.dart';

class GoalsView extends ConsumerWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final stats = ref.watch(statsProvider);
    if (!goalsAsync.hasValue || stats == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final goals = goalsAsync.value!;
    final active = goals.where((g) => g.status == GoalStatus.active).toList();
    final paused = goals.where((g) => g.status == GoalStatus.paused).toList();
    final closed = goals
        .where((g) =>
            g.status == GoalStatus.archived || g.status == GoalStatus.achieved)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(Copy.goalsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: Copy.editorNewGoal,
            onPressed: () => context.push('/goal-editor'),
          ),
        ],
      ),
      body: goals.isEmpty
          ? _empty(context)
          : ListView(
              children: [
                _header(context, Copy.goalsActiveHeader(active.length)),
                for (final g in active) _GoalCard(goal: g),
                if (paused.isNotEmpty) ...[
                  _header(context, Copy.goalsPausedHeader),
                  for (final g in paused) _PausedRow(goal: g),
                ],
                if (closed.isNotEmpty)
                  ExpansionTile(
                    title: Text(Copy.goalsClosedHeader,
                        style: Theme.of(context).textTheme.titleSmall),
                    initiallyExpanded: false,
                    children: [for (final g in closed) _GoalCard(goal: g)],
                  ),
                const SizedBox(height: 88),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );

  /// 空态：虚线邀请卡（screen-goals.html ②）——模板一句话 + 写一句自己的。
  Widget _empty(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 48),
          _DashedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Copy.goalsEmptyTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(Copy.goalsEmptySub,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in kAllTemplates)
                      ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor:
                              GoalColor.byKey(t.colorKey).of(context),
                          radius: 9,
                          child: Icon(GoalIcon.byKey(t.iconKey).icon,
                              size: 11, color: Colors.white),
                        ),
                        label: Text(t.name),
                        onPressed: () => context.push('/goal-editor', extra: t),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => context.push('/goal-editor'),
                  child: const Text(Copy.goalsEmptyOwn),
                ),
              ],
            ),
          ),
        ],
      );
}

/// 单张目标卡片：图标 + 名称 + 「为什么」第二行 + 元行徽标 + 连击/周完成率。
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final today = ref.watch(todayProvider);
    final versions = ref.watch(versionsProvider).value ?? const [];
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final pattern = effectivePattern(
        versions.where((v) => v.goalId == goal.id).toList(), today);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // 点卡片 = 编辑/渐进补全（旧目标空维度由此补一句为什么）。
        onTap: () => context.push('/goal-editor?id=${goal.id}'),
        onLongPress: () => showGoalActions(context, ref, goal),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
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
                    ]),
                    const SizedBox(height: 2),
                    _whyLine(context),
                    const SizedBox(height: 4),
                    Text(
                      _metaLine(ref, today, pattern),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _trailing(context, ref, stats),
            ],
          ),
        ),
      ),
    );
  }

  /// 第二行「为什么」：有则一句带出；无则虚线邀请（渐进补全，T014 B 案）。
  Widget _whyLine(BuildContext context) {
    final why = goal.motivation;
    if (why == null || why.isEmpty) {
      return Text(
        Copy.goalsInviteWhy,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted),
      );
    }
    return Text(why,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant));
  }

  /// 元行：habit = 频率；milestone = 倒计时·步骤 + 「一次性 · 截止」。
  String _metaLine(
      WidgetRef ref, LocalDate today, FrequencyPattern? pattern) {
    if (goal.isMilestone) {
      final short = _shortDeadline(goal.deadline, today);
      return '${Copy.goalsOnceBadge(short ?? '')} · ${_milestoneLine(ref, today)}';
    }
    return pattern?.toString() ?? '';
  }

  String? _shortDeadline(LocalDate? d, LocalDate today) => d == null
      ? null
      : d.year == today.year
          ? '${d.month}/${d.day}'
          : '${d.year}/${d.month}/${d.day}';

  String _milestoneLine(WidgetRef ref, LocalDate today) {
    final days = goal.deadline?.differenceInDays(today) ?? 0;
    final steps = ref.watch(stepsProvider(goal.id)).value;
    final suffix = steps == null || steps.isEmpty
        ? ''
        : ' · ${Copy.milestoneProgress(steps.where((s) => s.isDone).length, steps.length)}';
    return '${Copy.milestoneCountdown(days)}$suffix';
  }


  /// 右侧数字：habit = 连击 + 本周完成率；里程碑留白。
  Widget _trailing(BuildContext context, WidgetRef ref, StatsEvaluation? stats) {
    if (goal.isMilestone || stats == null) return const SizedBox.shrink();
    final streak = stats.streakOf(goal.id);
    final rate = stats.weekStatOf(goal.id, ref.watch(todayProvider).weekStart);
    final rateLabel = rate.completionRate == null
        ? Copy.reviewNoApplicableDays
        : Copy.reviewCompletion(rate.completionRate!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(Copy.streakDays(streak),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: GoalColor.byKey(goal.colorKey).of(context))),
        Text('${Copy.goalsWeekRate} $rateLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// 暂停行：虚线包裹 + 恢复按钮（screen-goals.html ① 暂停区语言）。
class _PausedRow extends ConsumerWidget {
  const _PausedRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: _DashedCard(
        child: Row(
          children: [
            Icon(GoalIcon.byKey(goal.iconKey).icon,
                size: 20, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${goal.name} · ${Copy.goalsPausedNote}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => resumeGoal(context, ref, goal),
              child: const Text(Copy.goalsResume),
            ),
          ],
        ),
      ),
    );
  }
}

/// 虚线圆角容器（暂停行/空态邀请卡的「未完成」视觉语言）。
class _DashedCard extends StatelessWidget {
  const _DashedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: scheme.outline.withValues(alpha: 0.6),
        radius: 14,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
