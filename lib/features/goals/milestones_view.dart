/// v3 里程碑页：接下来（⋯ 菜单：标记达成/编辑/删除）+ 已达成；
/// 达成即生成达成记录（FR-003）。
/// v3.1：Cupertino 重写——CupertinoPageScaffold、CupertinoListTile、
/// CupertinoActionSheet、CupertinoAlertDialog + CupertinoTextField。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/sheet.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

class MilestonesPage extends ConsumerWidget {
  const MilestonesPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final goal = ref
        .watch(goalsProvider)
        .valueOrNull
        ?.where((g) => g.id == goalId)
        .firstOrNull;
    final milestones =
        ref.watch(milestonesOfProvider(goalId)).value ?? const <Milestone>[];
    final pending =
        milestones.where((m) => !m.isDone).toList(growable: false);
    final done = milestones.where((m) => m.isDone).toList(growable: false);

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              child: Row(
                children: [
                  HeaderTextButton(
                    label: Copy.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        goal?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleM,
                      ),
                    ),
                  ),
                  CircleIconButton(
                    size: 40,
                    iconSize: 16,
                    icon: CupertinoIcons.add,
                    onTap: () => _add(context, ref),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Copy.milestonesTitle, style: text.displayM),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (pending.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(
                        Copy.pendingGroup(pending.length),
                        style: text.labelS
                            .copyWith(color: p.onSurfaceVariant),
                      ),
                    ),
                    _card(
                      context,
                      child: Column(
                        children: [
                          for (final (i, m) in pending.indexed) ...[
                            if (i > 0) HairlineDivider(indent: 60),
                            CupertinoListTile(
                              backgroundColor: p.surface,
                              title: Text(m.title, style: text.titleM),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (m.description != null)
                                    Text(m.description!,
                                        style: text.bodyS.copyWith(
                                            color: p.onSurfaceVariant)),
                                  Text(
                                    m.position >= 0
                                        ? _relatedCount(ref, m.id)
                                        : '',
                                    style: text.bodyS.copyWith(
                                        color: p.onSurfaceTertiary),
                                  ),
                                ],
                              ),
                              trailing: CircleIconButton(
                                size: 34,
                                iconSize: 14,
                                icon: CupertinoIcons.ellipsis,
                                onTap: () => _menu(context, ref, m),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (done.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(
                        Copy.doneGroup(done.length),
                        style: text.labelS
                            .copyWith(color: p.onSurfaceVariant),
                      ),
                    ),
                    _card(
                      context,
                      child: Column(
                        children: [
                          for (final (i, m) in done.indexed) ...[
                            if (i > 0) HairlineDivider(indent: 60),
                            CupertinoListTile(
                              backgroundColor: p.surface,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: p.milestoneTint,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(CupertinoIcons.flag_fill,
                                    size: 18, color: p.milestone),
                              ),
                              title: Text(m.title, style: text.bodyL),
                              subtitle: Text(
                                '${m.doneAt?.toLocal().month ?? ''}月${m.doneAt?.toLocal().day ?? ''}日达成 · ${_relatedCount(ref, m.id)}',
                                style: text.bodyS.copyWith(
                                    color: p.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      Copy.milestonesHint,
                      style: text.bodyS
                          .copyWith(color: p.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relatedCount(WidgetRef ref, String milestoneId) {
    final records =
        ref.watch(recordsProvider).value ?? const <ProgressRecord>[];
    final n = records
        .where((r) => r.milestoneId == milestoneId)
        .length;
    return n > 0 ? Copy.relatedRecords(n) : Copy.noRelatedRecords;
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final p = TargetPalette.of(context);
    // ClipRRect：CupertinoListTile 背景为直角，需裁出容器圆角。
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: p.shadowLow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: child,
      ),
    );
  }

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    Milestone m,
  ) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('done'),
            child: Text(Copy.milestoneMenuDone),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('edit'),
            child: Text(Copy.milestoneMenuEdit),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(sheetContext).pop('delete'),
            child: Text(Copy.milestoneMenuDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text(Copy.cancel),
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case 'done':
        if (!context.mounted) return;
        final note = await _achieveNote(context);
        await ref
            .read(milestoneRepoProvider)
            .markDone(m.id, note: note, now: DateTime.now().toUtc());
      case 'undo':
        await ref.read(milestoneRepoProvider).undoDone(m.id);
      case 'edit':
        if (!context.mounted) return;
        await _edit(context, ref, m);
      case 'delete':
        await ref.read(milestoneRepoProvider).remove(m.id);
    }
  }

  Future<String?> _achieveNote(BuildContext context) async {
    final controller = TextEditingController();
    final note = await showCupertinoDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(Copy.milestoneMenuDone),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 2,
            placeholder: '这一步的感觉（选填）',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: Text(Copy.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(Copy.done),
          ),
        ],
      ),
    );
    return note?.trim();
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Milestone m,
  ) async {
    final title = TextEditingController(text: m.title);
    final desc = TextEditingController(text: m.description ?? '');
    final saved = await _showMilestoneForm(
      context,
      title: Copy.milestoneMenuEdit,
      titleController: title,
      descController: desc,
    );
    if (saved == true) {
      await ref.read(milestoneRepoProvider).update(
            m.copyWith(
              title: title.text.trim(),
              description:
                  desc.text.trim().isEmpty ? null : desc.text.trim(),
            ),
          );
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final saved = await _showMilestoneForm(
      context,
      title: Copy.milestonesAdd,
      titleController: title,
      descController: desc,
      autofocus: true,
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      await ref.read(milestoneRepoProvider).add(
            Milestone(
              goalId: goalId,
              title: title.text.trim(),
              description:
                  desc.text.trim().isEmpty ? null : desc.text.trim(),
              position: 0,
            ),
          );
    }
  }

  /// 里程碑标题/描述表单对话框（新增与编辑共用）。
  Future<bool?> _showMilestoneForm(
    BuildContext context, {
    required String title,
    required TextEditingController titleController,
    required TextEditingController descController,
    bool autofocus = false,
  }) {
    final text = AppText.of(context);
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              CupertinoTextField(
                controller: titleController,
                autofocus: autofocus,
                placeholder: Copy.milestoneFieldTitle,
                style: text.bodyM,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: descController,
                maxLines: 2,
                placeholder: Copy.milestoneFieldDesc,
                style: text.bodyM,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(Copy.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(Copy.save),
          ),
        ],
      ),
    );
  }
}
