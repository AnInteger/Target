/// v2 点阵字形（品牌语言唯一源，004 T030 提自 dock）：960 画布，两列
///（x 233/730）各三枚 r73 大点（y 153/480/807）+ 中列（x 480）上段
/// 两枚 r33 小点（y 226/387）。dock 今日页签（22px 槽）与初始屏品牌
/// 图形（accent 圆内点阵）同源复刻，绘制尺寸取正方形槽。
library;

import 'package:flutter/material.dart';

class TodayGlyphPainter extends CustomPainter {
  const TodayGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 960;
    final paint = Paint()..color = color;
    void dot(double x, double y, double r) =>
        canvas.drawCircle(Offset(x * scale, y * scale), r * scale, paint);
    for (final x in [233.0, 730.0]) {
      for (final y in [153.0, 480.0, 807.0]) {
        dot(x, y, 73);
      }
    }
    dot(480, 226, 33);
    dot(480, 387, 33);
  }

  @override
  bool shouldRepaint(TodayGlyphPainter old) => old.color != color;
}
