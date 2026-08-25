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
