/// 目标详情页（003 T021：管理动线补全）。
///
/// goals_view 退役后本页承接全部管理职能（FR-002）：编辑（AppBar）与
/// ⋯ 动作面板（暂停/恢复/达成/归档——物理删除不存在，归档即收起且
/// 历史保留）。头部块 = 图标 + 一句话描述 + 类型徽章 + 提醒行（极简
/// 目标不空，spec 边界用例 3；「为什么/怎样算做到」退役字段不再上
/// 屏）；打卡动线带选填一句话描述（FR-019）；历史记录行呈现描述
/// （未填兜底「完成打卡」）。短期目标保留倒计时/进度/步骤/过期处理。
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
import '../notifications/notification_list.dart';
import '../today/undo_toast.dart';
import 'goal_lifecycle.dart';
import 'goal_type_badge.dart';

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
    final checkIns =
        ref.watch(checkInsProvider).value ?? const <CheckIn>[];
    final today = ref.watch(todayProvider);
    final mine = checkIns
        .where((c) => c.goalId == goal.id && c.isValid)
        .toList()
      ..sort((a, b) => a.day != b.day
          ? b.day.compareTo(a.day)
          : b.createdAt.compareTo(a.createdAt));
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
          IconButton(
            tooltip: Copy.goalMoreActions,
            icon: const Icon(Icons.more_vert),
            onPressed: () => showGoalActions(context, ref, goal),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderBlock(goal: goal, today: today),
          if (goal.isShortTerm) ...[
            const SizedBox(height: 12),
            _progressCard(context, goal, days, done, steps.length, color),
            if (days <= 0 && goal.status == GoalStatus.active)
              _dueCard(context, ref, goal, days),
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
          if (goal.status == GoalStatus.active) ...[
            const SizedBox(height: 16),
            _CheckInBar(goalId: goal.id),
          ],
          if (mine.isNotEmpty) ...[
            const SizedBox(height: 20),
            _HistorySection(items: mine, today: today),
          ],
        ],
      ),
    );
  }

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

  /// 到期/超期处理（003 D4：到点只提醒不判决——标记达成 / 续期
  /// 双入口；不自动终结，超期持续提示且打卡条仍在）。
  Widget _dueCard(BuildContext context, WidgetRef ref, Goal goal, int days) {
    return Card(
      key: const ValueKey('goalDueCard'),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                days == 0
                    ? Copy.shortTermDueAsk
                    : Copy.milestoneOverdue, // 超期持续提示（温和）
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(children: [
              FilledButton.tonal(
                key: const ValueKey('goalMarkAchievedButton'),
                onPressed: () async {
                  await achieveGoal(ref, goal);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(Copy.milestoneDone)));
                    Navigator.of(context).pop(); // 与编辑器同款本地 pop
                  }
                },
                child: const Text(Copy.goalMarkAchieved),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('goalRenewButton'),
                onPressed: () => _postpone(context, ref, goal),
                child: const Text(Copy.goalRenewDeadline),
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

  /// 温和续期（D4）：新截止日自选，立即生效；超期目标锚定今天起选。
  Future<void> _postpone(
      BuildContext context, WidgetRef ref, Goal goal) async {
    final first = DateTime.now();
    final base = goal.deadline?.atStartOfDay ?? first;
    final picked = await showDatePicker(
      context: context,
      initialDate: base.isBefore(first) ? first : base,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365 * 5)),
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

/// 头部块：图标 + 一句话描述 + 类型徽章 + 提醒行 + 状态行。
/// 极简目标（仅名称）也呈现完整骨架（spec 边界用例 3）。
class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({required this.goal, required this.today});

  final Goal goal;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final hasCue = goal.cueScene != null && goal.cueScene != Copy.cueNone;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: palette.divider),
          ),
          child: Icon(GoalIconCatalog.byKey(goal.iconKey).icon,
              size: 28, color: palette.onSurface),
        ),
        const SizedBox(width: AppSpace.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: theme.textTheme.titleL),
              const SizedBox(height: AppSpace.s2),
              GoalTypeBadge(goal: goal, today: today),
              if (goal.status != GoalStatus.active) ...[
                const SizedBox(height: AppSpace.s2),
                Text(
                  goal.status == GoalStatus.paused
                      ? Copy.goalsPausedNote
                      : goal.status == GoalStatus.archived
                          ? Copy.goalArchived
                          : Copy.milestoneDone,
                  style: theme.textTheme.bodyS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ],
              if (hasCue) ...[
                const SizedBox(height: AppSpace.s1),
                Text(
                  Copy.goalReminderLine(goal.cueScene!),
                  style: theme.textTheme.bodyS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 打卡动线：选填一句话描述（FR-019）+ 记录按钮。
class _CheckInBar extends ConsumerStatefulWidget {
  const _CheckInBar({required this.goalId});

  final String goalId;

  @override
  ConsumerState<_CheckInBar> createState() => _CheckInBarState();
}

class _CheckInBarState extends ConsumerState<_CheckInBar> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    final text = _note.text.trim();
    final ci = await ref.read(checkInServiceProvider).checkInToday(
          widget.goalId,
          note: text.isEmpty ? null : text,
        );
    _note.clear();
    if (mounted) showCheckInToast(context, ref, ci);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('checkInNoteField'),
            controller: _note,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: Copy.checkInNoteHint,
              counterText: '',
              isDense: true,
            ),
            onSubmitted: (_) => _checkIn(),
          ),
        ),
        const SizedBox(width: AppSpace.s3),
        FilledButton(
          onPressed: _checkIn,
          child: const Text(Copy.todayCheckAction),
        ),
      ],
    );
  }
}

/// 历史记录（新→旧）：「相对日期 - 描述」+ 时刻，与今日卡同语言。
class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.items, required this.today});

  final List<CheckIn> items;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Copy.goalHistoryTitle, style: theme.textTheme.titleS),
        const SizedBox(height: AppSpace.s2),
        for (final c in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${notificationDayLabel(c.day, today)} - '
                    '${(c.note ?? '').trim().isEmpty ? Copy.checkInDefaultNote : c.note!.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyM,
                  ),
                ),
                const SizedBox(width: AppSpace.s2),
                Text(
                  notificationTimeLabel(c.createdAt),
                  style: theme.textTheme.labelS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
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
