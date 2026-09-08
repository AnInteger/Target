/// v3 图标与颜色选择器（sheet）：38 枚目录图标 + 9 色板单选。
/// v3.1：Cupertino 重写（AppSheet 容器；网格/色板点选为手势格子，
/// 选中态样式不变）。
library;

import 'package:flutter/cupertino.dart';

import '../../app/design_tokens.dart';
import '../../app/sheet.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../shared/goal_card.dart' show goalIconData;

/// 返回 (iconKey, colorKey)；取消返回 null。
Future<(String, String)?> showGoalIconPicker(
  BuildContext context, {
  required String initialIconKey,
  required String initialColorKey,
}) {
  return showAppSheet<(String, String)>(
    context,
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
    final brightness = TargetPalette.brightnessOf(context);
    final color = GoalPalette.byKey(_colorKey, brightness: brightness);

    return AppSheet(
      maxHeightFactor: 0.8,
      title: '图标与颜色',
      leading: HeaderTextButton(
        label: '取消',
        onTap: () => Navigator.of(context).pop(),
      ),
      trailing: HeaderTextButton(
        label: '完成',
        emphasized: true,
        onTap: () => Navigator.of(context).pop((_iconKey, _colorKey)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
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
                return GestureDetector(
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
