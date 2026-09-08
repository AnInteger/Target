/// v3 编辑置顶模式（R2 定稿：健康「编辑列表」参照）。
///
/// 置顶行 = 「−」移出 + 名称 + 「≡」拖拽；其他目标行 = 图钉加入；
/// 顶部居中标题 + 右上蓝 ✓ 完成。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

Future<void> showEditPinned(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
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
    final text = Theme.of(context).textTheme;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final order = _pinnedOrder ??
        goals.where((g) => g.pinned).map((g) => g.id).toList();
    final pinned = [
      for (final id in order)
        goals.where((g) => g.id == id).firstOrNull,
    ].whereType<Goal>().toList();
    final others = goals.where((g) => !g.pinned).toList(growable: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: p.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Center(
                    child: Text(Copy.editPinnedTitle, style: text.titleM),
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    onPressed: _save,
                    child: const Icon(Icons.check, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String s) {
    final text = Theme.of(context).textTheme;
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
    final text = Theme.of(context).textTheme;
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
            Icons.remove,
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
              child: Icon(Icons.drag_indicator,
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
    final text = Theme.of(context).textTheme;
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
          _circleButton(Icons.push_pin_outlined, p.accent, onPin),
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
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Theme.of(context).extension<TargetPalette>()!.surfaceAlt,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
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
