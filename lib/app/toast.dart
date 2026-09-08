/// 轻量 iOS 风格 toast（替代 Material SnackBar——CupertinoApp 无
/// ScaffoldMessenger）。
///
/// 深色胶囊悬于底部 dock 之上；支持一个可选行动钮（撤销等）；
/// 自动消失。经 root Overlay 挂载，任何 context 均可调用。
library;

import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'design_tokens.dart';

/// 在 [context] 上方显示一条 toast；[actionLabel]/[onAction] 提供可选
/// 行动钮。同屏仅保留最新一条（先入先出）。
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3600),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, dismiss);
  }

  /// 立即移除当前 toast（若存在）。
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 108,
      child: IgnorePointer(
        ignoring: _opacity < 1,
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 180),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xCC1C1C1E),
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: p.shadowMid,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyM.copyWith(color: const Color(0xFFF5F5F7)),
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: 10),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.square(28),
                      onPressed: () {
                        widget.onAction?.call();
                        AppToast.dismiss();
                      },
                      child: Text(
                        widget.actionLabel!,
                        style: text.bodyM
                            .copyWith(color: p.accentText, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
