/// 成就时刻覆盖层（T010，screen-today.html R4 定稿）：
/// 每个习惯目标今天都有记录时全屏绽放——positive 辉光 + 墨色徽章 +
/// 14 枚目标色迸点（1000ms）；点按任意处退场。
///
/// 重臂（re-arm）语义与原型一致：只在「非全完成 → 全完成」的上升沿
/// 出现；点按关闭后不重复弹，直到先离开全完成态再回来。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/copy.dart';

class Celebration extends StatefulWidget {
  const Celebration({super.key, required this.active, required this.actions});

  /// 是否处于「每个目标都有进展」状态（外部按数据计算）。
  final bool active;

  /// 今日总记录次数（徽章副文）。
  final int actions;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with TickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: AppMotion.celebration,
  );

  /// 本次全完成期内是否已放过（含被点按关闭后）。
  bool _fired = false;
  bool _visible = false;

  /// 内容是否挂树：隐藏时不构建（透明文本仍会被 find/语义树看到），
  /// 退场的 150ms 淡出期保留，淡出完成经 onEnd 摘除。
  bool _built = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _fired = true;
      _visible = true;
      _built = true;
      _burst.forward();
    }
  }

  @override
  void didUpdateWidget(Celebration old) {
    super.didUpdateWidget(old);
    if (!widget.active) {
      // 离开全完成态：退场并重臂。
      _fired = false;
      if (_visible) setState(() => _visible = false);
      _burst.stop();
    } else if (!_fired) {
      // 上升沿：绽放。
      _fired = true;
      setState(() {
        _visible = true;
        _built = true;
      });
      _burst
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_visible) setState(() => _visible = false);
    _burst.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_built) return const SizedBox.shrink();
    final palette = TargetPalette.of(context);
    // 降级：系统关动效 → 静态辉光 + 徽章（无迸点），仍可点按关闭。
    final reduced = MediaQuery.disableAnimationsOf(context);

    // 徽章：锚在 38% 高度，scale .6→1 走满全程，淡入压缩在前 base 段。
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s5,
        vertical: AppSpace.s4,
      ),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: palette.shadowMid,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Copy.celebrationTitle,
            style: Theme.of(context).textTheme.titleM
                .copyWith(color: palette.accentOn),
          ),
          const SizedBox(height: AppSpace.s1),
          Text(
            Copy.celebrationNote(widget.actions),
            style: Theme.of(context).textTheme.bodyS
                .copyWith(color: palette.accentOn.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
    if (!reduced) {
      badge = FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _burst,
            curve: const Interval(0, 0.25, curve: AppMotion.easeStandard),
          ),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1).animate(
            CurvedAnimation(parent: _burst, curve: AppMotion.easeStandard),
          ),
          child: badge,
        ),
      );
    }

    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 0.45 : 0,
        duration: reduced ? Duration.zero : AppMotion.fast,
        onEnd: () {
          if (!_visible) setState(() => _built = false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 辉光：closest-side at 50% 38% → Alignment(0, -0.24)。
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.24),
                    radius: 0.62,
                    colors: [
                      palette.positiveFill,
                      palette.positiveFill.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
              // 14 枚迸点：dx/dy = 100+(i%3)*26 半径环（纵向压扁 .7）。
              if (!reduced)
                AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) => Stack(
                    fit: StackFit.expand,
                    children: [
                      for (var i = 0; i < 14; i++)
                        _BurstDot(
                          t: _burst.value,
                          delay: (i % 5) * 40 / 1000,
                          index: i,
                          color: kCelebrationDotPalette[i % 7]
                              .of(context),
                        ),
                    ],
                  ),
                ),
              Align(alignment: const Alignment(0, -0.24), child: badge),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单枚迸点：平移 (0,0)→(dx,dy)，scale 1→.4，rotate 0→240°，opacity 1→0。
class _BurstDot extends StatelessWidget {
  const _BurstDot({
    required this.t,
    required this.delay,
    required this.index,
    required this.color,
  });

  /// 全局进度 [0,1]（未计入自身延迟）。
  final double t;
  final double delay;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
    final ang = math.pi * 2 * index / 14 + 0.4;
    final r = 100.0 + (index % 3) * 26;
    final dx = math.cos(ang) * r;
    final dy = math.sin(ang) * r * 0.7;
    final eased = Curves.easeOut.transform(local);
    return Align(
      alignment: const Alignment(0, -0.24),
      child: Opacity(
        opacity: 1 - eased,
        child: Transform.translate(
          offset: Offset(dx * eased, dy * eased),
          child: Transform.rotate(
            angle: 240 * math.pi / 180 * eased,
            child: Transform.scale(
              scale: 1 - 0.6 * eased,
              child: Container(
                width: AppSpace.s2,
                height: AppSpace.s2,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
