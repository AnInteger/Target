/// GoalsView（T020，FR-005/009/010/011）：目标管理页。
///
/// 分区：进行中（≤5）/ 暂停中 / 已结束（归档+达成，折叠）。
/// 卡片数字全部来自统计引擎（连击、本周完成率）；忙碌目标带徽标。
/// 长按/菜单进生命周期动作（goal_lifecycle.dart）。
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
import '../../core/stats/versioning.dart';
import 'goal_lifecycle.dart';

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
    final closed =
        goals.where((g) => g.status == GoalStatus.archived || g.status == GoalStatus.achieved).toList();

    return Scaffold(
      appBar: AppBar(title: const Text(Copy.goalsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goal-editor'),
        child: const Icon(Icons.add),
      ),
      body: goals.isEmpty
          ? _empty(context)
          : ListView(
              children: [
                _header(context, Copy.goalsActiveHeader(active.length)),
                for (final g in active) _GoalCard(goal: g),
                if (paused.isNotEmpty) ...[
                  _header(context, Copy.goalsPausedHeader),
                  for (final g in paused) _GoalCard(goal: g),
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
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _empty(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(Copy.goalsEmpty),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/goal-editor'),
              child: const Text(Copy.goalsEmptyCta),
            ),
          ],
        ),
      );
}

/// 单张目标卡片：图标 + 名称 + 频率/倒计时 + 连击/周完成率。
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final today = ref.watch(todayProvider);
    final versions = ref.watch(versionsProvider).value ?? const [];
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final pattern =
        effectivePattern(versions.where((v) => v.goalId == goal.id).toList(), today);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/goal-editor?id=${goal.id}'),
        onLongPress: () => showGoalActions(context, ref, goal),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
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
                      if ((stats?.dayStatusOf(goal.id).busyMode ?? false)) ...[
                        const SizedBox(width: 6),
                        _badge(context, Copy.busyBadge),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      goal.isMilestone
                          ? _milestoneLine(ref, today)
                          : (pattern?.toString() ?? ''),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _badge(BuildContext context, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer)),
      );

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
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GoalColor.byKey(goal.colorKey).of(context))),
        Text('${Copy.goalsWeekRate} $rateLabel',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
