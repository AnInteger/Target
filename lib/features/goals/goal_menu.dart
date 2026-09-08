/// 目标管理菜单（长按卡片 / 详情 ⋯）：三组——推进/管理/危险，
/// 按状态显隐（phase 1 状态机语义；R2 裁定入口=长按）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../shared/record_sheet.dart';

Future<void> showGoalMenu(
  BuildContext context,
  WidgetRef ref,
  Goal goal,
) {
  void close() => Navigator.of(context, rootNavigator: true).pop();

  void transit(GoalStatus to) => ref
      .read(goalRepoProvider)
      .transit(goal.id, to, DateTime.now().toUtc());

  final menu = <_MenuEntry>[
    if (goal.status == GoalStatus.active)
      _MenuEntry(Copy.menuRecord, Icons.add, () {
        close();
        showRecordSheet(context, goalId: goal.id);
      }),
    _MenuEntry(Copy.menuEdit, Icons.edit_outlined, () {
      close();
      context.push('/goal-editor?id=${goal.id}');
    }),
    if (goal.status != GoalStatus.archived)
      _MenuEntry(
        goal.pinned ? Copy.menuUnpin : Copy.menuPin,
        goal.pinned ? Icons.push_pin : Icons.push_pin_outlined,
        () {
          close();
          ref.read(goalRepoProvider).setPinned(goal.id, !goal.pinned);
        },
      ),
    switch (goal.status) {
      GoalStatus.active => _MenuEntry(Copy.menuPause, Icons.pause, () {
          close();
          transit(GoalStatus.paused);
        }),
      GoalStatus.paused => _MenuEntry(Copy.menuResume, Icons.play_arrow, () {
          close();
          transit(GoalStatus.active);
        }),
      _ => const _MenuEntry('', Icons.hide_source, null),
    },
    if (goal.status == GoalStatus.active || goal.status == GoalStatus.paused)
      _MenuEntry(Copy.menuAchieve, Icons.check, () {
        close();
        transit(GoalStatus.achieved);
      }),
    if (goal.status == GoalStatus.achieved)
      _MenuEntry(Copy.menuReopen, Icons.restart_alt, () {
        close();
        transit(GoalStatus.active);
      }),
    if (goal.status != GoalStatus.archived)
      _MenuEntry(Copy.menuArchive, Icons.archive_outlined, () {
        close();
        transit(GoalStatus.archived);
      }),
    if (goal.status == GoalStatus.archived)
      _MenuEntry(Copy.menuUnarchive, Icons.unarchive_outlined, () {
        close();
        transit(GoalStatus.active);
      }),
  ].where((e) => e.onTap != null && e.label.isNotEmpty).toList();

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _GoalMenuSheet(
      menu: menu,
      danger: _MenuEntry(Copy.menuDelete, Icons.delete_outline, () async {
        Navigator.of(sheetContext).pop();
        final confirmed = await _confirmDelete(context, goal);
        if (confirmed) await ref.read(goalRepoProvider).deleteGoal(goal.id);
      }),
    ),
  );
}

class _MenuEntry {
  const _MenuEntry(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class _GoalMenuSheet extends StatelessWidget {
  const _GoalMenuSheet({required this.menu, required this.danger});

  final List<_MenuEntry> menu;
  final _MenuEntry danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in menu)
            ListTile(
              leading: Icon(e.icon, size: 20),
              title: Text(e.label),
              onTap: e.onTap,
            ),
          const Divider(height: 1),
          ListTile(
            leading:
                Icon(danger.icon, size: 20, color: theme.colorScheme.error),
            title: Text(
              danger.label,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: danger.onTap,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, Goal goal) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(Copy.deleteConfirmTitle(goal.name)),
      content: const Text(Copy.deleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(Copy.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(Copy.menuDelete),
        ),
      ],
    ),
  );
  return ok ?? false;
}
