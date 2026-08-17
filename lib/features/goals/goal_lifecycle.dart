/// 目标生命周期动作（T021，FR-009/010/011）。
///
/// 状态机规则在 Goal.canTransitTo（领域层）；本文件只做 UI 编排：
/// 动作面板（暂停/恢复/达成/归档）与活跃上限聚焦引导弹层。
/// 归档不物理删除，历史与统计保留（SC 一致性）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/db/repositories.dart';
import '../../core/models/entities.dart';

/// FR-011 聚焦引导弹层：上限触发时各处复用（编辑器/恢复/今日视图）。
Future<void> showFocusLimitDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(Copy.focusLimitTitle),
        content: const Text(Copy.focusLimitBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了')),
        ],
      ),
    );

/// 暂停（FR-009）：连击保留口径由统计引擎按打卡历史决定，暂停不清记录。
Future<void> pauseGoal(WidgetRef ref, Goal goal) async {
  await ref.read(goalRepoProvider).update(goal.copyWith(status: GoalStatus.paused));
}

/// 恢复（FR-009）：受活跃上限约束，超限弹聚焦引导。
Future<void> resumeGoal(BuildContext context, WidgetRef ref, Goal goal) async {
  try {
    await ref
        .read(goalRepoProvider)
        .update(goal.copyWith(status: GoalStatus.active));
  } on ActiveGoalLimitException {
    if (context.mounted) await showFocusLimitDialog(context);
  }
}

/// 达成关闭（FR-010，仅里程碑）。
Future<void> achieveGoal(WidgetRef ref, Goal goal) =>
    ref.read(goalRepoProvider).update(goal.copyWith(status: GoalStatus.achieved));

/// 归档（FR-010）：终态但历史保留。
Future<void> archiveGoal(WidgetRef ref, Goal goal) async {
  await ref.read(goalRepoProvider).update(goal.copyWith(status: GoalStatus.archived));
}

/// 目标卡片的长按/菜单动作面板：按状态机可选动作渲染。
Future<void> showGoalActions(BuildContext context, WidgetRef ref, Goal goal) {
  final actions = <Widget>[
    if (goal.canTransitTo(GoalStatus.paused))
      ListTile(
        leading: const Icon(Icons.pause_circle_outline),
        title: const Text('暂停'),
        subtitle: const Text(Copy.busySubtitle),
        onTap: () {
          Navigator.of(context).pop();
          pauseGoal(ref, goal);
        },
      ),
    if (goal.canTransitTo(GoalStatus.active))
      ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: const Text('恢复'),
        onTap: () {
          Navigator.of(context).pop();
          resumeGoal(context, ref, goal);
        },
      ),
    if (goal.canTransitTo(GoalStatus.achieved))
      ListTile(
        leading: const Icon(Icons.emoji_events_outlined),
        title: const Text(Copy.milestoneDone),
        onTap: () {
          Navigator.of(context).pop();
          achieveGoal(ref, goal);
        },
      ),
    if (goal.canTransitTo(GoalStatus.archived))
      ListTile(
        leading: const Icon(Icons.archive_outlined),
        title: const Text('归档'),
        subtitle: const Text(Copy.goalArchived),
        onTap: () {
          Navigator.of(context).pop();
          archiveGoal(ref, goal);
        },
      ),
  ];
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: actions)),
  );
}
