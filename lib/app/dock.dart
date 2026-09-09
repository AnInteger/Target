/// v3.1 底部导航（iOS 健康 floating tab bar 参照；官方 Cupertino 组件）。
///
/// 左：双 tab 不透明胶囊（28px 全圆角；选中 = 蓝色着色）。
/// 右：记录钮（同材质，56×56 正圆，笔形图标）。
/// v3.1 裁定：放弃 Liquid Glass 手绘仿制（效果差且模糊有性能隐患），
/// 改为 surface 实底 + 发丝描边——平贴无阴影（R9：条形组件去投影）。
/// R9 几何：整体高度压至 56（tab 图标 20 + 标签 10 + 内距收紧）。
/// R12b：底边距 0，直接贴 SafeArea 底缘（真机裁定）。
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
      // R12b：真机裁定 dock 偏高——底边距降一个页缘宽（20 → 0），
      // 贴住 Home 指示条安全区上缘（同原生 tab 栏落位）。
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: p.divider, width: 0.5),
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
      minimumSize: Size.square(44),
      borderRadius: BorderRadius.circular(22),
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          border: Border.all(color: p.divider, width: 0.5),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.square(56),
          borderRadius: BorderRadius.circular(28),
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
