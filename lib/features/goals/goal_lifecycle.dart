/// 目标生命周期动作（T021，FR-009/010/011）。
///
/// 状态机规则在 Goal.canTransitTo（领域层）；本文件只做 UI 编排：
/// 暂停/恢复/达成/归档原语。
/// 004 T014：动作面板（showGoalActions）与归档退役——动作收纳进
/// 详情「⋯」菜单（编辑/暂停/恢复/删除），删除走物理级联（FR-016）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/entities.dart';

/// 暂停（FR-009）：连击保留口径由统计引擎按打卡历史决定，暂停不清记录。
Future<void> pauseGoal(WidgetRef ref, Goal goal) async {
  await ref
      .read(goalRepoProvider)
      .update(goal.copyWith(status: GoalStatus.paused));
}

/// 恢复（FR-009）。
Future<void> resumeGoal(WidgetRef ref, Goal goal) =>
    ref.read(goalRepoProvider).update(goal.copyWith(status: GoalStatus.active));

/// 达成关闭：所有未归档目标均可达成。
Future<void> achieveGoal(WidgetRef ref, Goal goal) => ref
    .read(goalRepoProvider)
    .update(
      goal.copyWith(
        status: GoalStatus.achieved,
        achievedAt: DateTime.now().toUtc(),
      ),
    );

Future<void> archiveGoal(WidgetRef ref, Goal goal) => ref
    .read(goalRepoProvider)
    .update(goal.copyWith(archivedAt: DateTime.now().toUtc()));

Future<void> unarchiveGoal(WidgetRef ref, Goal goal) =>
    ref.read(goalRepoProvider).update(goal.copyWith(clearArchivedAt: true));

Future<void> reopenGoal(WidgetRef ref, Goal goal) => ref
    .read(goalRepoProvider)
    .update(
      goal.copyWith(
        status: GoalStatus.active,
        clearAchievedAt: true,
        clearArchivedAt: true,
      ),
    );
