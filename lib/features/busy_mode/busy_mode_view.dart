/// 忙碌模式页（US4 T039，FR-018）：选择目标 → 逐个降档预览 →
/// 一键开启（当周生效标注）；进行中会话 → 一键恢复。
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
import '../../core/stats/busy_mode_service.dart';
import '../../core/stats/versioning.dart';

class BusyModeView extends ConsumerStatefulWidget {
  const BusyModeView({super.key});

  @override
  ConsumerState<BusyModeView> createState() => _BusyModeViewState();
}

class _BusyModeViewState extends ConsumerState<BusyModeView> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final versions = ref.watch(versionsProvider).value ?? const [];
    final sessions = ref.watch(busySessionsProvider).value ?? const [];
    final service = ref.watch(busyModeServiceProvider);

    final habits = goals
        .where((g) => g.isHabit && g.status == GoalStatus.active)
        .toList();
    final activeSession =
        sessions.where((s) => s.isActive).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(Copy.busyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(Copy.busySubtitle,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (activeSession != null) ...[
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Copy.busyActiveNow,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${activeSession.entries.map((e) => e.goalId).length} 个目标已降档 · ${Copy.busyStartHint}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => _restore(activeSession),
                      child: Text(Copy.busyResume),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(Copy.busySelectHint,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final g in habits)
            _PreviewTile(
              goal: g,
              current: effectivePattern(
                  versions.where((v) => v.goalId == g.id).toList(), today),
              service: service,
              selected: _selected.contains(g.id),
              onToggle: () => setState(() {
                    _selected.contains(g.id)
                        ? _selected.remove(g.id)
                        : _selected.add(g.id);
                  }),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _selected.isEmpty || activeSession != null
                ? null
                : () => _activate(habits, versions, today),
            child: Text('${Copy.busyStart}（${Copy.busyStartHint}）'),
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BusyModeSession session) async {
    await ref.read(busyModeServiceProvider).deactivate(session, now: DateTime.now());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(Copy.busyResumed)));
    context.pop();
  }

  Future<void> _activate(List<Goal> habits, List<FrequencyVersion> versions,
      LocalDate today) async {
    final service = ref.read(busyModeServiceProvider);
    final downgrade = <String, FrequencyPattern>{};
    for (final id in _selected) {
      final p = effectivePattern(
          versions.where((v) => v.goalId == id).toList(), today);
      if (p == null) continue;
      downgrade[id] = service.suggestedDowngrade(p);
    }
    await service.activate(
      week: today.weekStart,
      downgradedByGoal: downgrade,
      now: DateTime.now(),
    );
    if (mounted) context.pop();
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.goal,
    required this.current,
    required this.service,
    required this.selected,
    required this.onToggle,
  });

  final Goal goal;
  final FrequencyPattern? current;
  final BusyModeService service;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final downgraded =
        current == null ? null : service.suggestedDowngrade(current!);
    final floor = current != null && downgraded == current;

    return Card(
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => onToggle(),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(GoalIcon.byKey(goal.iconKey).icon, color: color, size: 20),
        ),
        title: Text(goal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: current == null
            ? null
            : Text(floor
                ? Copy.busyFloorNote
                : Copy.busyPreview(current.toString(), downgraded.toString())),
      ),
    );
  }
}
