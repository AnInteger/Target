/// 日历每日投入 sheet（R2 定稿：点「日历」直达；范围所有日期，
/// 月导航；每格环 = 当日投入 / 当月峰值，参考 iOS 健康）。
/// v3.1：Cupertino 重写——AppSheet 容器、CupertinoButton 月导航、
/// 自绘进度环（CupertinoActivityIndicator 不支持进度值）。
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../app/sheet.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/stats/stats_engine.dart';

Future<void> showDailyCalendarSheet(
  BuildContext context,
  List<ProgressRecord> records,
) {
  return showAppSheet(context, builder: (_) => const _DailyCalendarSheet());
}

class _DailyCalendarSheet extends ConsumerStatefulWidget {
  const _DailyCalendarSheet();

  @override
  ConsumerState<_DailyCalendarSheet> createState() =>
      _DailyCalendarSheetState();
}

class _DailyCalendarSheetState extends ConsumerState<_DailyCalendarSheet> {
  late DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final today = LocalDate.fromDateTime(DateTime.now());
    final records =
        ref.watch(recordsProvider).value ?? const <ProgressRecord>[];
    final days = StatsEngine.dailyInvestment(
      records,
      _month.year,
      _month.month,
    );
    final peak = StatsEngine.monthPeak(days);

    return AppSheet(
      maxHeightFactor: 0.85,
      title: Copy.dailyInvestmentTitle,
      leading: HeaderTextButton(
        label: Copy.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.square(36),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                child: const Icon(CupertinoIcons.chevron_back, size: 18),
              ),
              Text('${_month.year}年${_month.month}月', style: text.titleM),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.square(36),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                child: const Icon(CupertinoIcons.chevron_forward, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final w in ['一', '二', '三', '四', '五', '六', '日'])
                      Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: TextStyle(
                              fontSize: 11,
                              color: p.onSurfaceTertiary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _monthGrid(context, days, peak, today),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: p.divider,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                Copy.calendarLegendNone,
                style: text.bodyS.copyWith(color: p.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: p.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                Copy.calendarLegendRing,
                style: text.bodyS.copyWith(color: p.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthGrid(
    BuildContext context,
    List<DailyInvestment> days,
    int peak,
    LocalDate today,
  ) {
    final first = DateTime(_month.year, _month.month, 1);
    // ISO 周一=1 … 周日=7 → 前置空格数。
    final lead = (first.weekday == 7 ? 0 : first.weekday);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final byDay = {for (final d in days) d.day: d};

    return Column(
      children: [
        for (var row = 0; row * 7 < lead + daysInMonth; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Builder(
                      builder: (_) {
                        final index = row * 7 + col - lead + 1;
                        if (index < 1 || index > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        final day = LocalDate(_month.year, _month.month, index);
                        final d = byDay[day];
                        final selected = day == today;
                        return Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: TargetPalette.of(context).accent,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: _Ring(
                              progress: d == null || peak == 0
                                  ? 0
                                  : d.minutes / peak,
                              minutes: d?.minutes ?? 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// 进度环（track+弧）——自绘替代 Material CircularProgressIndicator。
class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.minutes});

  final double progress;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(34, 34),
            painter: _RingPainter(
              progress: progress == 0 ? 0 : progress.clamp(0.08, 1),
              track: p.divider,
              arc: p.accent,
            ),
          ),
          if (minutes > 0)
            Text(
              minutes > 99 ? '··' : '$minutes',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: p.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.arc,
  });

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 3.5;
    final rect = Offset.zero & size;
    final radius = (size.shortestSide - stroke) / 2;
    final center = rect.center;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect.deflate(stroke / 2),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}
