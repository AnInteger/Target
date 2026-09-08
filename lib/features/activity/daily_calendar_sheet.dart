/// 日历每日投入 sheet（R2 定稿：点「日历」直达；范围所有日期，
/// 月导航；每格环 = 当日投入 / 当月峰值，参考 iOS 健康）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/stats/stats_engine.dart';

Future<void> showDailyCalendarSheet(
  BuildContext context,
  List<ProgressRecord> records,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DailyCalendarSheet(),
  );
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
    final text = Theme.of(context).textTheme;
    final today = LocalDate.fromDateTime(DateTime.now());
    final records =
        ref.watch(recordsProvider).value ?? const <ProgressRecord>[];
    final days = StatsEngine.dailyInvestment(
      records,
      _month.year,
      _month.month,
    );
    final peak = StatsEngine.monthPeak(days);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: p.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    Copy.cancel,
                    style: text.bodyL.copyWith(color: p.accentText),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(Copy.dailyInvestmentTitle,
                        style: text.titleM),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 18),
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                    ),
                    Text('${_month.year}年${_month.month}月',
                        style: text.titleM),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18),
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: p.shadowLow,
                  ),
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
                                      color: p.onSurfaceTertiary),
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
                            color: p.divider, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(Copy.calendarLegendNone,
                        style: text.bodyS
                            .copyWith(color: p.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: p.accent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(Copy.calendarLegendRing,
                        style: text.bodyS
                            .copyWith(color: p.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
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
                    child: Builder(builder: (_) {
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
                                ? Border.all(color: Theme.of(context)
                                    .extension<TargetPalette>()!
                                    .accent, width: 1.5)
                                : null,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: _Ring(
                            progress:
                                d == null || peak == 0 ? 0 : d.minutes / peak,
                            minutes: d?.minutes ?? 0,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

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
          CircularProgressIndicator(
            value: progress == 0 ? 0 : progress.clamp(0.08, 1),
            strokeWidth: 3.5,
            backgroundColor: p.divider,
            valueColor: AlwaysStoppedAnimation(p.accent),
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
