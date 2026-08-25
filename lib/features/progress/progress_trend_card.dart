import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/goal_advice.dart';
import '../../core/models/goal_progress.dart';

class ProgressTrendCard extends StatefulWidget {
  const ProgressTrendCard({super.key, required this.snapshot});

  final GoalProgressSnapshot snapshot;

  @override
  State<ProgressTrendCard> createState() => _ProgressTrendCardState();
}

class _ProgressTrendCardState extends State<ProgressTrendCard> {
  final Set<ProgressDimension> _expanded = {};

  bool get _hasTrend => widget.snapshot.evaluation.dailyPoints.any(
    (point) => point.dimensions.isNotEmpty,
  );

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      key: const ValueKey('progressTrendCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('近 7 天', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '目标管理状态',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          if (_hasTrend)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  points: widget.snapshot.evaluation.dailyPoints,
                  colors: _dimensionColors(context),
                  guide: palette.divider,
                  labelStyle: Theme.of(context).textTheme.labelS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ),
            )
          else
            Container(
              key: const ValueKey('progressNoTrend'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Text(
                '记录第一次进展后，这里会显示最近 7 天的变化。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: palette.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 8),
          for (final dimension in ProgressDimension.values)
            if (widget.snapshot.advice[dimension] case final advice?)
              _AdviceSection(
                advice: advice,
                expanded: _expanded.contains(dimension),
                onToggle: () => setState(() {
                  if (!_expanded.add(dimension)) _expanded.remove(dimension);
                }),
              ),
        ],
      ),
    );
  }
}

Map<ProgressDimension, Color> _dimensionColors(BuildContext context) => {
  ProgressDimension.health: MajorColors.health.of(context),
  ProgressDimension.habit: MajorColors.habit.of(context),
  ProgressDimension.goal: MajorColors.goal.of(context),
};

class _AdviceSection extends StatelessWidget {
  const _AdviceSection({
    required this.advice,
    required this.expanded,
    required this.onToggle,
  });

  final GoalAdvice advice;
  final bool expanded;
  final VoidCallback onToggle;

  String get title => switch (advice.dimension) {
    ProgressDimension.health => '健康类目标',
    ProgressDimension.habit => '习惯类目标',
    ProgressDimension.goal => '成长类目标',
  };

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: '$title建议',
            child: InkWell(
              key: ValueKey('adviceToggle-${advice.dimension.name}'),
              onTap: onToggle,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.info_outline_rounded,
                        color: palette.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('指标原理｜${advice.principle}'),
                  const SizedBox(height: 6),
                  Text('当前解读｜${advice.currentInterpretation}'),
                  const SizedBox(height: 6),
                  Text('行动建议｜${advice.action}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.colors,
    required this.guide,
    required this.labelStyle,
  });

  final List<DailyProgressPoint> points;
  final Map<ProgressDimension, Color> colors;
  final Color guide;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 4.0, right = 28.0, top = 8.0, bottom = 26.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (final score in [0, 50, 100]) {
      final y = chart.bottom - chart.height * score / 100;
      canvas.drawLine(
        Offset(chart.left, y),
        Offset(chart.right, y),
        guidePaint,
      );
    }
    if (points.isEmpty) return;
    double xAt(int index) => points.length == 1
        ? chart.left
        : chart.left + chart.width * index / (points.length - 1);
    for (final dimension in ProgressDimension.values) {
      final paint = Paint()
        ..color = colors[dimension]!
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      Path? path;
      var started = false;
      for (final (index, point) in points.indexed) {
        final value = point.dimensions[dimension];
        if (value == null) {
          if (path != null) canvas.drawPath(path, paint);
          path = null;
          started = false;
          continue;
        }
        final offset = Offset(
          xAt(index),
          chart.bottom - chart.height * value / 100,
        );
        if (!started) {
          path = Path()..moveTo(offset.dx, offset.dy);
          started = true;
        } else {
          path!.lineTo(offset.dx, offset.dy);
        }
        canvas.drawCircle(offset, 2.6, Paint()..color = colors[dimension]!);
      }
      if (path != null) canvas.drawPath(path, paint);
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final index in [0, points.length - 1]) {
      final day = points[index].day;
      textPainter.text = TextSpan(
        text: '${day.month}/${day.day}',
        style: labelStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xAt(index) - textPainter.width / 2, chart.bottom + 7),
      );
    }
    for (final dimension in ProgressDimension.values) {
      final value = points.last.dimensions[dimension];
      if (value == null) continue;
      textPainter.text = TextSpan(
        text: '$value',
        style: labelStyle.copyWith(
          color: colors[dimension],
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          chart.right + 5,
          chart.bottom - chart.height * value / 100 - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
