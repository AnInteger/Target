import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';

Future<void> showDayRecordsSheet(
  BuildContext context, {
  required LocalDate day,
  required List<CheckIn> records,
}) {
  final palette = TargetPalette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    // 详情分支页调用：整屏 sheet（useRootNavigator 缺省 false 会落在
    // 壳层 body 内、止于 dock 顶——3.47 起缺省变更，显式回整屏口径）。
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: palette.scrim,
    builder: (_) => _DayRecordsSheet(day: day, records: records),
  );
}

class _DayRecordsSheet extends StatelessWidget {
  const _DayRecordsSheet({required this.day, required this.records});

  final LocalDate day;
  final List<CheckIn> records;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('dayRecordsSheet'),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: palette.shadowHigh,
      ),
      // 底距 s4 + 安全区（整屏 sheet，指示区由表面承载）。
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        AppSpace.s4 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${day.month}月${day.day}日 · 星期${day.weekday.zhLabel}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          for (final (index, record) in records.indexed) ...[
            if (index > 0) Divider(color: palette.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: palette.positiveFill,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (record.note ?? '').trim().isEmpty
                          ? '完成一次记录'
                          : record.note!.trim(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (record.isBackfill)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('补记', style: theme.textTheme.labelSmall),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
