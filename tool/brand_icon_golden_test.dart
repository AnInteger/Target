import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders opaque white marketing icon', (tester) async {
    await _pumpIcon(tester, background: true);
    await expectLater(
      find.byKey(const ValueKey('brandIcon')),
      matchesGoldenFile('../design/brand/icon-progress-white-1024.png'),
    );
  });

  testWidgets('renders transparent adaptive foreground', (tester) async {
    await _pumpIcon(tester, background: false);
    await expectLater(
      find.byKey(const ValueKey('brandIcon')),
      matchesGoldenFile('../design/brand/icon-progress-foreground-1024.png'),
    );
  });
}

Future<void> _pumpIcon(WidgetTester tester, {required bool background}) async {
  tester.view.physicalSize = const Size.square(1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('brandIcon'),
      child: CustomPaint(
        size: const Size.square(1024),
        painter: _BrandIconPainter(background: background),
      ),
    ),
  );
  await tester.pump();
}

class _BrandIconPainter extends CustomPainter {
  const _BrandIconPainter({required this.background});

  final bool background;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 1024;
    canvas.scale(scale, scale);
    if (background) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1024, 1024),
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
    final path = Path()
      ..moveTo(250, 748)
      ..cubicTo(350, 702, 386, 598, 476, 604)
      ..cubicTo(566, 610, 594, 546, 654, 460)
      ..cubicTo(700, 394, 748, 324, 790, 276);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF248CF0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 68
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      const Offset(250, 748),
      72,
      Paint()..color = const Color(0xFF202126),
    );
    canvas.drawCircle(
      const Offset(790, 276),
      82,
      Paint()..color = const Color(0xFF30B36B),
    );
  }

  @override
  bool shouldRepaint(covariant _BrandIconPainter oldDelegate) =>
      oldDelegate.background != background;
}
