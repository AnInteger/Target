/// v3.1 底部导航（iOS 健康 floating tab bar 参照；官方 Cupertino 组件）。
///
/// 左：双 tab 不透明胶囊（30px 近胶囊圆角；选中 = 蓝色着色）。
/// 右：记录钮（同材质，笔形图标）。
/// v3.1 裁定：放弃 Liquid Glass 手绘仿制（效果差且模糊有性能隐患），
/// 改为 surface 实底 + 发丝描边 + 既有 shadowMid——视觉层级不变。
library;

import 'package:flutter/cupertino.dart';

import 'design_tokens.dart';

/// 底部导航：[tabs] = (路由路径, 标签, 图标)；[activePath] 当前分支；
/// [onTapTab]/[onRecord] 回调。
class AppDock extends StatelessWidget {
  const AppDock({
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: p.divider, width: 0.5),
                boxShadow: p.shadowMid,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
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
          const SizedBox(width: 10),
          _RecordButton(onTap: onRecord),
        ],
      ),
    );
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.square(48),
      borderRadius: BorderRadius.circular(26),
      onPressed: onTap,
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: p.divider, width: 0.5),
          boxShadow: p.shadowMid,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.square(62),
          borderRadius: BorderRadius.circular(30),
          onPressed: onTap,
          child: Icon(
            CupertinoIcons.square_pencil,
            size: 20,
            color: p.onSurface,
          ),
        ),
      ),
    );
  }
}
