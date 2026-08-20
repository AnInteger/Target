/// 目标详情页（002 T018：里程碑专属视图并入统一呈现，FR-011/013）。
///
/// 单一「目标」详情：这一诺卡（为什么/怎样算做到/提醒场景——空维度
/// 渐进补全入口）；一次性目标 = 倒计时 + 进度 + 步骤（增删改/勾选回退）
/// + 过期温和处理（顺延/先放下）+ 一键达成；习惯目标显示当前频率。
/// 编辑统一走 GoalEditor（步骤管理原 milestone_editor 并入本页）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';
import '../../core/stats/versioning.dart';
import 'goal_lifecycle.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Copy.goalsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final steps =
        ref.watch(stepsProvider(goalId)).value ?? const <MilestoneStep>[];
    final versions = ref.watch(versionsProvider).value ?? const [];
    final today = ref.watch(todayProvider);
    final pattern = effectivePattern(
        versions.where((v) => v.goalId == goal.id).toList(), today);
    final days = goal.deadline?.differenceInDays(today) ?? 0;
    final done = steps.where((s) => s.isDone).length;
    final allDone = steps.isNotEmpty && done == steps.length;
    final color = GoalColor.byKey(goal.colorKey).of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: Copy.goalEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/goal-editor?id=$goalId'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _vowCard(context, goal, pattern),
          if (goal.isMilestone) ...[
            const SizedBox(height: 12),
            _progressCard(context, goal, days, done, steps.length, color),
            if (days < 0 && goal.status == GoalStatus.active)
              _overdueCard(context, ref, goal),
            const SizedBox(height: 16),
            _stepsSection(context, ref, steps),
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
        ],
      ),
    );
  }

  /// 这一诺卡（T014 B 案 envelope 的统一呈现；空维度 → 渐进补全入口）。
  Widget _vowCard(
      BuildContext context, Goal goal, FrequencyPattern? pattern) {
    final theme = Theme.of(context);
    final hasWhy = goal.motivation != null && goal.motivation!.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Copy.goalVowLabel,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            if (hasWhy)
              Text(goal.motivation!, style: theme.textTheme.titleMedium)
            else
              // 点卡片即渐进补全：与列表第二行的邀请同语言。
              InkWell(
                onTap: () => context.push('/goal-editor?id=${goal.id}'),
                child: Text(
                  Copy.goalsInviteWhy,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted),
                ),
              ),
            if (goal.successCriterion != null) ...[
              const SizedBox(height: 12),
              _vowRow(context, Copy.editorCriterionLabel,
                  goal.successCriterion!),
            ],
            if (goal.cueScene != null && goal.cueScene != '不打扰') ...[
              const SizedBox(height: 6),
              _vowRow(context, Copy.editorCueLabel, goal.cueScene!),
            ],
            if (!goal.isMilestone) ...[
              const SizedBox(height: 6),
              _vowRow(context, Copy.editorFrequencyLabel, pattern?.toString() ?? ''),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vowRow(BuildContext context, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );

  /// 倒计时 + 进度（一次性目标；达成态换祝贺语）。
  Widget _progressCard(BuildContext context, Goal goal, int days, int done,
      int total, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              goal.status == GoalStatus.achieved
                  ? Copy.milestoneDone
                  : Copy.milestoneCountdown(days),
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: days < 0 ? theme.colorScheme.tertiary : null),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
                '${Copy.milestoneProgress(done, total)} · ${goal.deadline?.isoString ?? ''}',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// 过期温和处理（FR-013：顺延或先放下，不指责）。
  Widget _overdueCard(BuildContext context, WidgetRef ref, Goal goal) {
    return Card(
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
    );
  }

  /// 步骤清单：勾选（可回退，误点友好）+ 改名 + 删除 + 加一步。
  Widget _stepsSection(
      BuildContext context, WidgetRef ref, List<MilestoneStep> steps) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (steps.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(Copy.milestoneStepHint,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(Copy.milestoneStepsHeader,
                style: theme.textTheme.titleSmall),
          ),
        for (final s in steps)
          Card(
            key: ValueKey(s.id),
            child: CheckboxListTile(
              value: s.isDone,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.only(left: 4),
              title: TextFormField(
                key: ValueKey('step-${s.id}'),
                initialValue: s.title,
                maxLength: 50,
                decoration: const InputDecoration(
                    border: InputBorder.none, counterText: ''),
                style: s.isDone
                    ? theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough)
                    : theme.textTheme.bodyLarge,
                onFieldSubmitted: (value) {
                  final t = value.trim();
                  if (t.isEmpty || t == s.title) return;
                  ref.read(goalRepoProvider).updateStep(MilestoneStep(
                        id: s.id,
                        goalId: s.goalId,
                        title: t,
                        isDone: s.isDone,
                        doneAt: s.doneAt,
                      ));
                },
              ),
              // 勾选/回退：toggled 幂等保留首次完成时刻、回退清空。
              onChanged: (_) => ref
                  .read(goalRepoProvider)
                  .updateStep(s.toggled(now: DateTime.now(), done: !s.isDone)),
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: Copy.milestoneDeleteStep,
                onPressed: () =>
                    ref.read(goalRepoProvider).removeStep(s.id),
              ),
            ),
          ),
        _StepInputCard(goalId: goalId),
      ],
    );
  }

  /// 温和顺延：新截止日自选，立即生效。
  Future<void> _postpone(
      BuildContext context, WidgetRef ref, Goal goal) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: goal.deadline?.atStartOfDay ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    await ref
        .read(goalRepoProvider)
        .update(goal.copyWith(deadline: LocalDate.fromDateTime(picked)));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(Copy.milestonePostponed)));
    }
  }
}

/// 「加一步」输入卡：回车或按钮提交。
class _StepInputCard extends ConsumerStatefulWidget {
  const _StepInputCard({required this.goalId});

  final String goalId;

  @override
  ConsumerState<_StepInputCard> createState() => _StepInputCardState();
}

class _StepInputCardState extends ConsumerState<_StepInputCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    ref.read(goalRepoProvider).addStep(
        MilestoneStep(goalId: widget.goalId, title: title));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.add)),
          Expanded(
            child: TextFormField(
              controller: _controller,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: Copy.milestoneStepHint,
                border: InputBorder.none,
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onFieldSubmitted: (_) => _add(),
            ),
          ),
          TextButton(
              onPressed: _add, child: const Text(Copy.milestoneAddStep)),
        ],
      ),
    );
  }
}
