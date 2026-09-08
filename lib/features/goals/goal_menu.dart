/// 目标管理菜单（长按卡片 / 详情 ⋯）：三组——推进/管理/危险，
/// 按状态显隐（phase 1 状态机语义；R2 裁定入口=长按）。
/// v3.1：CupertinoActionSheet（危险项 destructive）+ CupertinoAlertDialog
/// 删除确认。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
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
      _MenuEntry(Copy.menuRecord, () {
        close();
        showRecordSheet(context, goalId: goal.id);
      }),
    _MenuEntry(Copy.menuEdit, () {
      close();
      context.push('/goal-editor?id=${goal.id}');
    }),
    if (goal.status != GoalStatus.archived)
      _MenuEntry(
        goal.pinned ? Copy.menuUnpin : Copy.menuPin,
        () {
          close();
          ref.read(goalRepoProvider).setPinned(goal.id, !goal.pinned);
        },
      ),
    switch (goal.status) {
      GoalStatus.active => _MenuEntry(Copy.menuPause, () {
          close();
          transit(GoalStatus.paused);
        }),
      GoalStatus.paused => _MenuEntry(Copy.menuResume, () {
          close();
          transit(GoalStatus.active);
        }),
      _ => const _MenuEntry('', null),
    },
    if (goal.status == GoalStatus.active || goal.status == GoalStatus.paused)
      _MenuEntry(Copy.menuAchieve, () {
        close();
        transit(GoalStatus.achieved);
      }),
    if (goal.status == GoalStatus.achieved)
      _MenuEntry(Copy.menuReopen, () {
        close();
        transit(GoalStatus.active);
      }),
    if (goal.status != GoalStatus.archived)
      _MenuEntry(Copy.menuArchive, () {
        close();
        transit(GoalStatus.archived);
      }),
    if (goal.status == GoalStatus.archived)
      _MenuEntry(Copy.menuUnarchive, () {
        close();
        transit(GoalStatus.active);
      }),
  ].where((e) => e.onTap != null && e.label.isNotEmpty).toList();

  return showCupertinoModalPopup<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text(goal.name, maxLines: 1),
      actions: [
        for (final e in menu)
          CupertinoActionSheetAction(
            onPressed: e.onTap!,
            child: Text(e.label),
          ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(sheetContext).pop();
            final confirmed = await _confirmDelete(context, goal);
            if (confirmed) {
              await ref.read(goalRepoProvider).deleteGoal(goal.id);
            }
          },
          child: const Text(Copy.menuDelete),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text(Copy.cancel),
      ),
    ),
  );
}

class _MenuEntry {
  const _MenuEntry(this.label, this.onTap);

  final String label;
  final VoidCallback? onTap;
}

Future<bool> _confirmDelete(BuildContext context, Goal goal) async {
  final p = TargetPalette.of(context);
  final ok = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(Copy.deleteConfirmTitle(goal.name)),
      content: const Text(Copy.deleteConfirmBody),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            Copy.cancel,
            style: TextStyle(color: p.onSurface),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(Copy.menuDelete),
        ),
      ],
    ),
  );
  return ok ?? false;
}
