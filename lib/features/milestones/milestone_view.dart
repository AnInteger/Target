/// 里程碑详情页（US5 T042，FR-013）：步骤勾选（可回退，误点友好）、
/// 进度 done/total、倒计时；过期温和提示 = 顺延或先放下（不指责）；
/// 步骤全勾 + 一键达成。编辑入口 → 里程碑编辑器（T041）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../goals/goal_lifecycle.dart';

class MilestoneView extends ConsumerWidget {
  const MilestoneView({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Copy.editorKindMilestone)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final steps = ref.watch(stepsProvider(goalId)).value ?? const <MilestoneStep>[];
    final today = ref.watch(todayProvider);
    final days = goal.deadline?.differenceInDays(today) ?? 0;
    final done = steps.where((s) => s.isDone).length;
    final allDone = steps.isNotEmpty && done == steps.length;
    final color = GoalColor.byKey(goal.colorKey).of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: Copy.editorDeadline,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/milestone-editor?id=$goalId'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- 倒计时 + 进度 ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    goal.status == GoalStatus.achieved
                        ? Copy.milestoneDone
                        : Copy.milestoneCountdown(days),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: days < 0
                            ? Theme.of(context).colorScheme.tertiary
                            : null),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: steps.isEmpty ? 0 : done / steps.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: color,
                  ),
                  const SizedBox(height: 6),
                  Text('${Copy.milestoneProgress(done, steps.length)} · ${goal.deadline?.isoString ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          // ---- 过期温和处理（FR-013：顺延或先放下，不指责）----
          if (days < 0 && goal.status == GoalStatus.active) ...[
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Copy.milestoneOverdue,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Row(children: [
                      FilledButton.tonal(
                        onPressed: () => _postpone(context, ref, goal),
                        child: const Text(Copy.editorDeadline),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          await archiveGoal(ref, goal);
                          if (context.mounted) context.pop();
                        },
                        child: const Text(Copy.milestoneCloseTitle),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // ---- 步骤清单 ----
          if (steps.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(Copy.milestoneStepHint,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.push('/milestone-editor?id=$goalId'),
                      child: const Text(Copy.milestoneStepsHeader),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final s in steps)
              Card(
                key: ValueKey(s.id),
                child: CheckboxListTile(
                  value: s.isDone,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    s.title,
                    style: s.isDone
                        ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough)
                        : Theme.of(context).textTheme.bodyLarge,
                  ),
                  onChanged: (_) => _toggle(ref, s),
                ),
              ),
          // ---- 全部勾完 → 一键达成（FR-010）----
          if (allDone && goal.status == GoalStatus.active) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await achieveGoal(ref, goal);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(Copy.milestoneDone)));
                  context.pop();
                }
              },
              child: const Text(Copy.milestoneDone),
            ),
          ],
        ],
      ),
    );
  }

  /// 勾选/回退（误点友好）：toggled 幂等保留首次完成时刻、回退清空。
  void _toggle(WidgetRef ref, MilestoneStep s) {
    ref.read(goalRepoProvider).updateStep(
        s.toggled(now: DateTime.now(), done: !s.isDone));
  }

  /// 温和顺延：新截止日自选，立即生效。
  Future<void> _postpone(BuildContext context, WidgetRef ref, Goal goal) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          goal.deadline?.atStartOfDay ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    await ref.read(goalRepoProvider).update(
        goal.copyWith(deadline: LocalDate.fromDateTime(picked)));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(Copy.milestonePostponed)));
    }
  }
}
