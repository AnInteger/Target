/// 目标管理菜单（2026-08-26 phase 1 · Task 6）。
///
/// 显式按钮面板（替代长按发现）：按目标状态给出合法动作——
/// active：编辑/暂停/达成/归档/删除；paused：恢复/编辑/达成/归档/删除；
/// achieved：重开/归档/删除；archived：取消归档/删除。
/// 先关菜单再执行动作；删除走物理级联 + 二次确认（goalDeleteDialog）。
/// 记录进展动作属 phase 2 简化记录流，此处有意缺席。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import 'goal_lifecycle.dart';

class _MenuAction {
  const _MenuAction(this.actionKey, this.icon, this.label, this.run);

  final String actionKey;
  final IconData icon;
  final String label;
  final Future<void> Function() run;
}

Future<void> showGoalManagementMenu(
  BuildContext context,
  WidgetRef ref,
  Goal goal,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final palette = TargetPalette.of(context);
      final theme = Theme.of(context);

      Future<void> runAfterClose(_MenuAction action) async {
        Navigator.of(sheetContext).pop();
        await action.run();
      }

      final actions = _actionsFor(context, ref, goal);
      return Material(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s5,
                  AppSpace.s4,
                  AppSpace.s5,
                  AppSpace.s2,
                ),
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleS,
                ),
              ),
              for (final action in actions)
                ListTile(
                  key: ValueKey('goalAction-${action.actionKey}-${goal.id}'),
                  minTileHeight: 44,
                  leading: Icon(action.icon, size: 22),
                  title: Text(action.label),
                  onTap: () => runAfterClose(action),
                ),
              const SizedBox(height: AppSpace.s2),
            ],
          ),
        ),
      );
    },
  );
}

List<_MenuAction> _actionsFor(
  BuildContext context,
  WidgetRef ref,
  Goal goal,
) {
  final edit = _MenuAction('edit', Icons.edit_outlined, Copy.goalEdit, () async {
    if (context.mounted) await context.push('/goal-editor?id=${goal.id}');
  });

  Future<void> confirmDelete() async {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const ValueKey('goalDeleteDialog'),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.rXl,
            boxShadow: palette.shadowHigh,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Copy.deleteConfirmTitle, style: theme.textTheme.titleS),
              const SizedBox(height: AppSpace.s3),
              Text(
                Copy.deleteConfirmBody(goal.name),
                style: theme.textTheme.bodyM.copyWith(
                  color: palette.onSurfaceVariant,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: AppSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text(Copy.dialogCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.badge,
                        foregroundColor: palette.badgeOn,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text(Copy.deleteConfirmYes),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    await ref.read(goalRepoProvider).deleteGoal(goal.id);
  }

  if (goal.isArchived) {
    return [
      _MenuAction(
        'unarchive',
        Icons.unarchive_outlined,
        Copy.menuUnarchiveGoal,
        () => unarchiveGoal(ref, goal),
      ),
      _MenuAction(
        'delete',
        Icons.delete_outline,
        Copy.menuDeleteGoal,
        confirmDelete,
      ),
    ];
  }
  return switch (goal.status) {
    GoalStatus.active => [
      edit,
      _MenuAction(
        'pause',
        Icons.pause_circle_outline,
        Copy.menuPauseGoal,
        () => pauseGoal(ref, goal),
      ),
      _MenuAction(
        'achieve',
        Icons.emoji_events_outlined,
        Copy.menuAchieveGoal,
        () => achieveGoal(ref, goal),
      ),
      _MenuAction(
        'archive',
        Icons.inventory_2_outlined,
        Copy.menuArchiveGoal,
        () => archiveGoal(ref, goal),
      ),
      _MenuAction(
        'delete',
        Icons.delete_outline,
        Copy.menuDeleteGoal,
        confirmDelete,
      ),
    ],
    GoalStatus.paused => [
      _MenuAction(
        'resume',
        Icons.play_circle_outline,
        Copy.menuResumeGoal,
        () => resumeGoal(ref, goal),
      ),
      edit,
      _MenuAction(
        'achieve',
        Icons.emoji_events_outlined,
        Copy.menuAchieveGoal,
        () => achieveGoal(ref, goal),
      ),
      _MenuAction(
        'archive',
        Icons.inventory_2_outlined,
        Copy.menuArchiveGoal,
        () => archiveGoal(ref, goal),
      ),
      _MenuAction(
        'delete',
        Icons.delete_outline,
        Copy.menuDeleteGoal,
        confirmDelete,
      ),
    ],
    GoalStatus.achieved => [
      _MenuAction(
        'reopen',
        Icons.restart_alt_outlined,
        Copy.menuReopenGoal,
        () => reopenGoal(ref, goal),
      ),
      _MenuAction(
        'archive',
        Icons.inventory_2_outlined,
        Copy.menuArchiveGoal,
        () => archiveGoal(ref, goal),
      ),
      _MenuAction(
        'delete',
        Icons.delete_outline,
        Copy.menuDeleteGoal,
        confirmDelete,
      ),
    ],
    GoalStatus.archived => [
      _MenuAction(
        'unarchive',
        Icons.unarchive_outlined,
        Copy.menuUnarchiveGoal,
        () => unarchiveGoal(ref, goal),
      ),
      _MenuAction(
        'delete',
        Icons.delete_outline,
        Copy.menuDeleteGoal,
        confirmDelete,
      ),
    ],
  };
}
