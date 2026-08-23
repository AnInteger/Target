/// 目标生命周期动作（T021，FR-009/010/011）。
///
/// 状态机规则在 Goal.canTransitTo（领域层）；本文件只做 UI 编排：
/// 暂停/恢复/达成原语与活跃上限聚焦引导弹层。
/// 004 T014：动作面板（showGoalActions）与归档退役——动作收纳进
/// 详情「⋯」菜单（编辑/暂停/恢复/删除），删除走物理级联（FR-016）。
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
        child: const Text(Copy.notifAck),
      ),
    ],
  ),
);

/// 暂停（FR-009）：连击保留口径由统计引擎按打卡历史决定，暂停不清记录。
Future<void> pauseGoal(WidgetRef ref, Goal goal) async {
  await ref
      .read(goalRepoProvider)
      .update(goal.copyWith(status: GoalStatus.paused));
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

/// 达成关闭（FR-010；003 D4：写 achievedAt——通知列表达成事件源）。
Future<void> achieveGoal(WidgetRef ref, Goal goal) => ref
    .read(goalRepoProvider)
    .update(
      goal.copyWith(status: GoalStatus.achieved, achievedAt: DateTime.now()),
    );
