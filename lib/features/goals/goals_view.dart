/// GoalsView · 目标管理页（2026-08-26 phase 1 · Task 6/7）。
///
/// dock 主页签之一：标题「目标」+ 新建钮、状态筛选 chips
/// （全部/进行中/已暂停/已达成/已归档）、紧凑管理行列表。
/// 排序：非归档在前 → active/paused/achieved → 最近进展（无则创建日）
/// 降序。行进详情；overflow 出状态感知菜单（编辑/生命周期/删除）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/page_top_bar.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import 'goal_list_item.dart';
import 'goal_management_menu.dart';

class GoalsView extends ConsumerStatefulWidget {
  const GoalsView({super.key});

  @override
  ConsumerState<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends ConsumerState<GoalsView> {
  GoalListFilter _filter = GoalListFilter.all;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final goals = ref.watch(goalsProvider).value;
    final checkIns = ref.watch(checkInsProvider).value;
    final steps = ref.watch(allStepsProvider).value;

    if (goals == null || checkIns == null || steps == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: CircularProgressIndicator(color: palette.accent)),
      );
    }

    final rows = _assemble(goals, checkIns, steps);
    final shown = rows.where((row) => _filter.matches(row.goal)).toList();

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTopBar(
              // dock 页签页：无上层可回，不渲染返回钮。
              showBack: false,
              title: Copy.goalsTitle,
              titleKey: const ValueKey('goalsTitle'),
              titleAccessory: Text(
                '${shown.length}',
                key: const ValueKey('goalsCount'),
                style: theme.textTheme.bodyS.copyWith(
                  color: palette.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              trailing: _NewButton(onTap: () => context.push('/goal-editor')),
            ),
            _FilterRow(
              selected: _filter,
              onSelect: (next) => setState(() => _filter = next),
            ),
            Expanded(
              child: shown.isEmpty
                  ? _Empty(filter: _filter)
                  : ListView.builder(
                      key: const ValueKey('goalsList'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.s4,
                        0,
                        AppSpace.s4,
                        AppSpace.s6,
                      ),
                      itemCount: shown.length,
                      itemBuilder: (context, index) => GoalListItem(
                        data: shown[index],
                        onOverflow: () => showGoalManagementMenu(
                          context,
                          ref,
                          shown[index].goal,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 行快照组装 + 全局排序（Task 6 Step 3）。
  List<GoalListItemData> _assemble(
    List<Goal> goals,
    List<CheckIn> checkIns,
    List<MilestoneStep> steps,
  ) {
    final stepsByGoal = <String, List<MilestoneStep>>{};
    for (final step in steps) {
      stepsByGoal.putIfAbsent(step.goalId, () => []).add(step);
    }
    for (final list in stepsByGoal.values) {
      list.sort((a, b) => a.position.compareTo(b.position));
    }

    final lastValidByGoal = <String, LocalDate>{};
    for (final c in checkIns) {
      if (!c.isValid) continue;
      final known = lastValidByGoal[c.goalId];
      if (known == null || c.day.isAfter(known)) {
        lastValidByGoal[c.goalId] = c.day;
      }
    }

    final rows = <GoalListItemData>[];
    for (final goal in goals) {
      final goalSteps = stepsByGoal[goal.id] ?? const <MilestoneStep>[];
      final last = lastValidByGoal[goal.id];
      var summary = summarizeGoal(
        milestones: goalSteps,
        latestValidRecordMonth: last?.month ?? 0,
        latestValidRecordDay: last?.day ?? 0,
        hasValidRecord: last != null,
      );
      // 里程碑全完成（无待办）时优先展示最近进展日。
      if (goalSteps.isNotEmpty &&
          goalSteps.every((s) => s.isDone) &&
          last != null) {
        summary = Copy.goalSummaryRecent(last.month, last.day);
      }
      rows.add(
        GoalListItemData(
          goal: goal,
          summary: summary,
          completedMilestones: goalSteps.where((s) => s.isDone).length,
          totalMilestones: goalSteps.length,
          lastActivity: last,
        ),
      );
    }

    int lifecycleRank(Goal g) => g.isArchived
        ? 3
        : switch (g.status) {
            GoalStatus.active => 0,
            GoalStatus.paused => 1,
            GoalStatus.achieved || GoalStatus.archived => 2,
          };
    rows.sort((a, b) {
      final byLifecycle = lifecycleRank(a.goal).compareTo(
        lifecycleRank(b.goal),
      );
      if (byLifecycle != 0) return byLifecycle;
      final aKey = a.lastActivity ?? a.goal.createdAt;
      final bKey = b.lastActivity ?? b.goal.createdAt;
      return bKey.compareTo(aKey);
    });
    return rows;
  }
}

/// 新建钮（右缘；44dp 命中区）。
class _NewButton extends StatelessWidget {
  const _NewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        key: const ValueKey('goalsNewButton'),
        onPressed: onTap,
        icon: Icon(Icons.add_rounded, color: palette.onSurface),
        tooltip: Copy.goalsNewButtonLabel,
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelect});

  final GoalListFilter selected;
  final ValueChanged<GoalListFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
        children: [
          for (final filter in GoalListFilter.values) ...[
            ActionChip(
              key: ValueKey('goalFilter-${filter.name}'),
              label: Text(filter.label),
              visualDensity: VisualDensity.compact,
              backgroundColor: filter == selected
                  ? palette.onSurface
                  : palette.surfaceAlt,
              labelStyle: Theme.of(context).textTheme.labelS.copyWith(
                color: filter == selected
                    ? palette.background
                    : palette.onSurface,
              ),
              onPressed: () => onSelect(filter),
            ),
            const SizedBox(width: AppSpace.s2),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filter});

  final GoalListFilter filter;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '「${filter.label}」暂无目标',
            key: const ValueKey('goalsEmptyTitle'),
            style: theme.textTheme.bodyM.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
