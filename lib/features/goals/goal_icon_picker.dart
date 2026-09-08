/// v3 图标与颜色选择器（sheet）：38 枚目录图标 + 9 色板单选。
library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../shared/goal_card.dart' show goalIconData;

/// 返回 (iconKey, colorKey)；取消返回 null。
Future<(String, String)?> showGoalIconPicker(
  BuildContext context, {
  required String initialIconKey,
  required String initialColorKey,
}) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _IconPickerSheet(
      initialIconKey: initialIconKey,
      initialColorKey: initialColorKey,
    ),
  );
}

class _IconPickerSheet extends StatefulWidget {
  const _IconPickerSheet({
    required this.initialIconKey,
    required this.initialColorKey,
  });

  final String initialIconKey;
  final String initialColorKey;

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  late String _iconKey = widget.initialIconKey;
  late String _colorKey = widget.initialColorKey;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final color = GoalPalette.byKey(_colorKey, brightness: brightness);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    '取消',
                    style: text.bodyL.copyWith(color: p.accentText),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('图标与颜色', style: text.titleM),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop((_iconKey, _colorKey)),
                  child: Text(
                    '完成',
                    style: text.bodyL
                        .copyWith(color: p.accentText, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: GoalIconCatalog.values.length,
              itemBuilder: (_, i) {
                final entry = GoalIconCatalog.values[i];
                final selected = entry.key == _iconKey;
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => setState(() => _iconKey = entry.key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.14)
                          : p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: selected
                          ? Border.all(color: color, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      goalIconData(entry.key),
                      size: 22,
                      color: selected ? color : p.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final key in GoalPalette.light.keys)
                  GestureDetector(
                    onTap: () => setState(() => _colorKey = key),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: GoalPalette.byKey(key, brightness: brightness),
                        shape: BoxShape.circle,
                        border: _colorKey == key
                            ? Border.all(
                                color: p.onSurface, width: 2.5, strokeAlign: BorderSide.strokeAlignOutside)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
