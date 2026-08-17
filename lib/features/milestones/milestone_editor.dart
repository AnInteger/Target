/// 里程碑编辑（US5 T041）：步骤增删改 + 截止日调整。
/// 创建与基础字段复用 GoalEditor 的里程碑分支（kind/deadline）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';

class MilestoneEditorPage extends ConsumerStatefulWidget {
  const MilestoneEditorPage({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<MilestoneEditorPage> createState() =>
      _MilestoneEditorPageState();
}

class _MilestoneEditorPageState extends ConsumerState<MilestoneEditorPage> {
  final _newStep = TextEditingController();

  @override
  void dispose() {
    _newStep.dispose();
    super.dispose();
  }

  Goal? get _goal {
    final goals = ref.read(goalsProvider).value ?? const <Goal>[];
    return goals.where((g) => g.id == widget.goalId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final steps = ref.watch(stepsProvider(widget.goalId)).value ?? const [];
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Copy.editorNewGoal)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- 截止日（顺延）----
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(Copy.editorDeadline),
              subtitle: Text(goal.deadline?.isoString ?? Copy.editorDeadlineRequired),
              onTap: () => _pickDeadline(context, goal),
            ),
          ),
          const SizedBox(height: 12),
          // ---- 步骤清单 ----
          Text(Copy.milestoneStepsHeader,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final s in steps)
            Card(
              key: ValueKey(s.id),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: Copy.milestoneDeleteStep,
                    onPressed: () =>
                        ref.read(goalRepoProvider).removeStep(s.id),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: s.title,
                      maxLength: 50,
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                      onFieldSubmitted: (value) {
                        final t = value.trim();
                        if (t.isEmpty || t == s.title) return;
                        ref
                            .read(goalRepoProvider)
                            .updateStep(MilestoneStep(
                              id: s.id,
                              goalId: s.goalId,
                              title: t,
                              isDone: s.isDone,
                              doneAt: s.doneAt,
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Card(
            child: Row(
              children: [
                const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.add)),
                Expanded(
                  child: TextFormField(
                    controller: _newStep,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: Copy.milestoneAddStep,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onFieldSubmitted: (_) => _addStep(),
                  ),
                ),
                TextButton(onPressed: _addStep, child: Text(Copy.milestoneAddStep)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addStep() {
    final title = _newStep.text.trim();
    if (title.isEmpty) return;
    ref
        .read(goalRepoProvider)
        .addStep(MilestoneStep(goalId: widget.goalId, title: title));
    _newStep.clear();
  }

  Future<void> _pickDeadline(BuildContext context, Goal goal) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          goal.deadline?.atStartOfDay ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    await ref
        .read(goalRepoProvider)
        .update(goal.copyWith(deadline: LocalDate.fromDateTime(picked)));
    if (!mounted) return;
    ScaffoldMessenger.of(this.context)
        .showSnackBar(const SnackBar(content: Text(Copy.milestonePostponed)));
  }
}
