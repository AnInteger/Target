/// v3.1 通用小控件：圆形图标钮 / 胶囊选择钮 / 分组卡容器——替代
/// Material InkWell 系（无水波纹，iOS 按压淡出）。
library;

import 'package:flutter/cupertino.dart';

import 'design_tokens.dart';

/// 圆形图标钮（surface 底；44 或自定义直径）。替代原 GlassCircleButton。
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? p.surface,
          shape: BoxShape.circle,
          border: Border.all(color: p.divider, width: 0.5),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.square(size),
          borderRadius: BorderRadius.circular(size / 2),
          onPressed: onTap,
          child: Icon(
            icon,
            size: iconSize,
            color: foregroundColor ?? p.onSurface,
          ),
        ),
      ),
    );
  }
}

/// 胶囊选择钮（时长档/星期等枚举选择；选中 = accent 实底白字）。
class PillSelectButton<T> extends StatelessWidget {
  const PillSelectButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      minimumSize: Size.square(34),
      borderRadius: BorderRadius.circular(AppRadius.full),
      color: selected ? p.accent : p.surfaceAlt,
      disabledColor: p.surfaceAlt,
      onPressed: onTap,
      child: Text(
        label,
        style: (selected ? text.titleS : text.bodyM).copyWith(
          color: selected ? p.accentOn : p.onSurface,
        ),
      ),
    );
  }
}

/// 分组卡容器（surface 底 + 圆角 lg + low 阴影 + 可选内边距）。
/// 点按交互由内容层包 CupertinoButton / GestureDetector。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    Widget current = DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      child: padding == null
          ? child
          : Padding(padding: padding!, child: child),
    );
    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }
    if (onTap != null || onLongPress != null) {
      current = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: current,
      );
    }
    return current;
  }
}

/// iOS 发丝分隔线（0.5px）。
class HairlineDivider extends StatelessWidget {
  const HairlineDivider({super.key, this.indent});

  final double? indent;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    return Container(
      margin: indent == null ? null : EdgeInsets.only(left: indent!),
      height: 0.5,
      color: p.divider,
    );
  }
}
