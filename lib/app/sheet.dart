/// v3.1 共享 sheet 基建：弹层容器（grabber + 圆角顶 + 可选头部行）与
/// 常用选择器（日期 / 时间 / 单选列表）——全部基于官方 Cupertino 弹层
/// （showCupertinoModalPopup / CupertinoActionSheet / CupertinoDatePicker）。
library;

import 'package:flutter/cupertino.dart';

import '../core/models/calendar_types.dart';
import 'design_tokens.dart';

/// 拉起底部 sheet（替代 showModalBottomSheet）。
///
/// [builder] 返回内容；内容自定高度（Column mainAxisSize.min 或显式
/// height）。键盘场景由内容自行包 viewInsets padding。
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    useRootNavigator: true,
    builder: builder,
  );
}

/// sheet 外壳：圆角 24 顶 + 背景 + grabber + 可选头部导航行。
///
/// [title] 头部居中标题；[leading]/[trailing] 头部两侧（通常为文本钮）；
/// 不需要头部时仅渲染 grabber。
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.leading,
    this.trailing,
    this.maxHeightFactor,
    this.backgroundColor,
    this.resizeForKeyboard = false,
  });

  final Widget child;
  final String? title;
  final Widget? leading;
  final Widget? trailing;

  /// 相对屏高的最大高度（0–1）；null = 不限（内容自适应）。
  final double? maxHeightFactor;

  /// 覆盖默认底色（默认 palette.background）。
  final Color? backgroundColor;

  /// 键盘弹起时是否随 viewInsets 上移（含输入框的 sheet 置 true）。
  final bool resizeForKeyboard;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    Widget current = Container(
      constraints: maxHeightFactor == null
          ? null
          : BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * maxHeightFactor!,
            ),
      decoration: BoxDecoration(
        color: backgroundColor ?? p.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          if (title != null)
            SheetHeader(title: title!, leading: leading, trailing: trailing),
          Flexible(child: child),
        ],
      ),
    );
    if (resizeForKeyboard) {
      current = Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: current,
      );
    }
    return current;
  }
}

/// iOS sheet 抓手（40×5 圆角胶囊）。
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: p.divider,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// sheet 头部导航行：左 / 居中标题 / 右。
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 64, child: leading),
          Expanded(
            child: Center(child: Text(title, style: text.titleM, maxLines: 1)),
          ),
          SizedBox(
            width: 64,
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

/// 头部文本钮（取消/保存等）。
class HeaderTextButton extends StatelessWidget {
  const HeaderTextButton({
    super.key,
    required this.label,
    this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final enabled = onTap != null;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.square(36),
      onPressed: onTap,
      child: Text(
        label,
        maxLines: 1,
        style: text.bodyL.copyWith(
          color: enabled ? p.accentText : p.onSurfaceTertiary,
          fontWeight: emphasized && enabled ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 常用选择器
// ---------------------------------------------------------------------------

/// iOS 日期滚轮（底部弹层 + 完成钮）。
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) {
  var picked = initial;
  return showAppSheet<DateTime>(
    context,
    builder: (sheetContext) {
      final p = TargetPalette.of(sheetContext);
      return Container(
        color: p.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(sheetContext).pop(picked),
                  child: const Text('完成'),
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: first,
                maximumDate: last,
                use24hFormat: true,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// iOS 时间滚轮（24 小时制；LocalTime 为项目自有类型）。
Future<LocalTime?> showAppTimePicker(
  BuildContext context, {
  required LocalTime initial,
}) {
  var picked = initial;
  return showAppSheet<LocalTime>(
    context,
    builder: (sheetContext) {
      final p = TargetPalette.of(sheetContext);
      return Container(
        color: p.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(sheetContext).pop(picked),
                  child: const Text('完成'),
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  initial.hour,
                  initial.minute,
                ),
                onDateTimeChanged: (d) => picked = LocalTime(d.hour, d.minute),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// iOS 单选 action sheet：[options] = (值, 标签)；返回选中值或 null。
Future<T?> showAppChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  T? selected,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    useRootNavigator: true,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        for (final (value, label) in options)
          CupertinoActionSheetAction(
            isDefaultAction: value == selected,
            onPressed: () => Navigator.of(sheetContext).pop(value),
            child: Text(label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text('取消'),
      ),
    ),
  );
}
