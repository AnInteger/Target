import 'package:flutter/material.dart';

class TargetRingGlyphPainter extends CustomPainter {
  const TargetRingGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * .09;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .31;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawCircle(
      Offset(center.dx + radius, center.dy),
      stroke * .85,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant TargetRingGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

class ProgressTrendGlyphPainter extends CustomPainter {
  const ProgressTrendGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * .09;
    final path = Path()
      ..moveTo(size.width * .17, size.height * .70)
      ..lineTo(size.width * .39, size.height * .49)
      ..lineTo(size.width * .58, size.height * .60)
      ..lineTo(size.width * .82, size.height * .28);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .28),
      stroke * .8,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressTrendGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 目标页签字形（2026-08-26 phase 1 · Task 7）：旗杆 + 缺角横幅——
/// 「立目标、扛起它」的紧凑隐喻；与另两枚同款 22px 线稿（stroke .09）。
class GoalFlagGlyphPainter extends CustomPainter {
  const GoalFlagGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * .09;
    // 旗杆（左缘竖线，上出旗幅 2 单位）。
    final pole = Path()
      ..moveTo(size.width * .30, size.height * .16)
      ..lineTo(size.width * .30, size.height * .84);
    canvas.drawPath(
      pole,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    // 横幅：右上角内收的缺角矩形（旗面迎风感）。
    final banner = Path()
      ..moveTo(size.width * .30, size.height * .22)
      ..lineTo(size.width * .74, size.height * .22)
      ..lineTo(size.width * .74, size.height * .44)
      ..lineTo(size.width * .54, size.height * .44)
      ..lineTo(size.width * .46, size.height * .56)
      ..lineTo(size.width * .30, size.height * .56)
      ..close();
    canvas.drawPath(
      banner,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant GoalFlagGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
