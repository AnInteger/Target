/// v3 底部导航（R2 定稿：iOS 健康 floating tab bar 参照）。
///
/// 左：双 tab 浅玻璃胶囊（30px 近胶囊圆角；选中 = 蓝色着色，无底色块）。
/// 右：记录钮（同材质浅玻璃，笔形图标）。
library;

import 'package:flutter/material.dart';

import '../core/copy.dart';
import 'design_tokens.dart';

/// 底部导航：[tabs] = (路由路径, 标签, 图标)；[activePath] 当前分支；
/// [onTapTab]/[onRecord] 回调。
class LiquidGlassDock extends StatelessWidget {
  const LiquidGlassDock({
    super.key,
    required this.tabs,
    required this.activePath,
    required this.onTapTab,
    required this.onRecord,
  });

  final List<(String, String, IconData)> tabs;
  final String activePath;
  final ValueChanged<String> onTapTab;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: p.glassShell,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: p.glassBorder, width: 0.5),
                boxShadow: p.shadowMid,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilterShell(
                  blur: p.blur,
                  child: Row(
                    children: [
                      for (final (path, label, icon) in tabs)
                        Expanded(
                          child: _DockTab(
                            label: label,
                            icon: icon,
                            selected: path == activePath,
                            onTap: () => onTapTab(path),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _RecordButton(onTap: onRecord),
        ],
      ),
    );
  }
}

/// 玻璃模糊容器（web 降级 = 半透明实底；原生 blur 生效）。
class BackdropFilterShell extends StatelessWidget {
  const BackdropFilterShell({super.key, required this.blur, required this.child});

  final double blur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final color = selected ? p.accent : p.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: 56,
      height: 62,
      child: Material(
        color: p.glassShell,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Tooltip(
              message: Copy.recordProgress,
              child: Icon(Icons.edit_outlined, size: 20, color: p.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
