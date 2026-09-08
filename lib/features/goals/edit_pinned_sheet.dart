/// v3 编辑置顶模式（R2 定稿：健康「编辑列表」参照）。
/// v3.1：Cupertino 重写（AppSheet + CupertinoButton；列表拖拽沿用
/// widgets 库 ReorderableListView）。
///
/// 置顶行 = 「−」移出 + 名称 + 「≡」拖拽；其他目标行 = 图钉加入；
/// 顶部居中标题 + 右上完成。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show ReorderableDragStartListener, ReorderableListView;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../app/sheet.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

Future<void> showEditPinned(BuildContext context) {
  return showAppSheet(
    context,
    builder: (_) => const _EditPinnedSheet(),
  );
}

class _EditPinnedSheet extends ConsumerStatefulWidget {
  const _EditPinnedSheet();

  @override
  ConsumerState<_EditPinnedSheet> createState() => _EditPinnedSheetState();
}

class _EditPinnedSheetState extends ConsumerState<_EditPinnedSheet> {
  List<String>? _pinnedOrder;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final order = _pinnedOrder ??
        goals.where((g) => g.pinned).map((g) => g.id).toList();
    final pinned = [
      for (final id in order)
        goals.where((g) => g.id == id).firstOrNull,
    ].whereType<Goal>().toList();
    final others = goals.where((g) => !g.pinned).toList(growable: false);

    return AppSheet(
      maxHeightFactor: 0.92,
      title: Copy.editPinnedTitle,
      trailing: HeaderTextButton(
        label: Copy.done,
        emphasized: true,
        onTap: _save,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _sectionTitle(context, Copy.pinnedSection),
          if (pinned.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                Copy.editPinnedOthers,
                style:
                    text.bodyS.copyWith(color: p.onSurfaceVariant),
              ),
            ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final list = [...pinned.map((g) => g.id)];
                final id = list.removeAt(oldIndex);
                list.insert(newIndex, id);
                _pinnedOrder = list;
              });
            },
            children: [
              for (final (i, g) in pinned.indexed)
                _pinRow(
                  key: ValueKey(g.id),
                  goal: g,
                  index: i,
                  onRemove: () async {
                    await ref
                        .read(goalRepoProvider)
                        .setPinned(g.id, false);
                    setState(() => _pinnedOrder = null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, Copy.editPinnedOthers),
          for (final g in others)
            _pinAddRow(
              key: ValueKey('o-${g.id}'),
              goal: g,
              onPin: () async {
                await ref.read(goalRepoProvider).setPinned(g.id, true);
                setState(() => _pinnedOrder = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String s) {
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(s, style: text.titleM),
    );
  }

  Widget _pinRow({
    required Key key,
    required Goal goal,
    required int index,
    required VoidCallback onRemove,
  }) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 12),
          _circleButton(
            CupertinoIcons.minus,
            p.onSurfaceVariant,
            onRemove,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                goal.name,
                style: text.bodyL.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(CupertinoIcons.line_horizontal_3,
                  size: 22, color: p.onSurfaceTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinAddRow({
    required Key key,
    required Goal goal,
    required VoidCallback onPin,
  }) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 12),
          _circleButton(CupertinoIcons.pin, p.accent, onPin),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                goal.name,
                style: text.bodyL.copyWith(fontWeight: FontWeight.w400),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.square(28),
          borderRadius: BorderRadius.circular(14),
          onPressed: onTap,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final order = _pinnedOrder;
    if (order != null) {
      await ref.read(goalRepoProvider).reorderPinned(order);
    }
    if (mounted) Navigator.of(context).pop();
  }
}
