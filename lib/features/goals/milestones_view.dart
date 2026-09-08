/// v3 里程碑页：接下来（⋯ 菜单：标记达成/编辑/删除）+ 已达成；
/// 达成即生成达成记录（FR-003）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

class MilestonesPage extends ConsumerWidget {
  const MilestonesPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
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

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleBtn(context, Icons.chevron_left,
                      () => Navigator.of(context).pop()),
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
                  _circleBtn(context, Icons.add, () => _add(context, ref)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Copy.milestonesTitle, style: text.displayM),
                  const SizedBox(height: 4),
                  Text(
                    Copy.milestonesSubtitle,
                    style:
                        text.bodyM.copyWith(color: p.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                            if (i > 0) Divider(height: 1, color: p.divider),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
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
                              trailing: _circleBtn(
                                context,
                                Icons.more_horiz,
                                () => _menu(context, ref, m),
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
                            if (i > 0) Divider(height: 1, color: p.divider),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: p.milestoneTint,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.flag,
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
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: child,
    );
  }

  Widget _circleBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: p.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 16, color: p.onSurface),
        ),
      ),
    );
  }

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    Milestone m,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MilestoneMenu(m: m),
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
    final p = TargetPalette.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Copy.milestoneMenuDone),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '这一步的感觉（选填）',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: p.divider),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: const Text(Copy.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: const Text(Copy.done),
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
    final p = TargetPalette.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Copy.milestoneMenuEdit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(
                labelText: Copy.milestoneFieldTitle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: p.divider),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: desc,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: Copy.milestoneFieldDesc,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: p.divider),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(Copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(Copy.save),
          ),
        ],
      ),
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
    final p = TargetPalette.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Copy.milestonesAdd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: Copy.milestoneFieldTitle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: p.divider),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: desc,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: Copy.milestoneFieldDesc,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: p.divider),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(Copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(Copy.save),
          ),
        ],
      ),
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
}

class _MilestoneMenu extends StatelessWidget {
  const _MilestoneMenu({required this.m});

  final Milestone m;

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
          ListTile(
            leading: const Icon(Icons.flag_outlined, size: 20),
            title: const Text(Copy.milestoneMenuDone),
            onTap: () => Navigator.of(context).pop('done'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, size: 20),
            title: const Text(Copy.milestoneMenuEdit),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_outline,
                size: 20, color: theme.colorScheme.error),
            title: Text(
              Copy.milestoneMenuDelete,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
