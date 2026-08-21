/// 补签日历（T025，FR-004）：过去两周逐日补卡，断链回接。
///
/// 只展示过去日期（今天在今日列表里打）；已有有效打卡的日不可重复；
/// 补签后 isBackfill 自动标记，周统计如实呈现（R6）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import 'undo_toast.dart';

Future<void> showBackfillCalendar(BuildContext context, WidgetRef ref, Goal goal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _BackfillSheet(goal: goal),
    ),
  );
}

class _BackfillSheet extends ConsumerWidget {
  const _BackfillSheet({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final checkIns = ref.watch(checkInsProvider).value ?? const [];
    final mine = checkIns
        .where((c) => c.goalId == goal.id && c.isValid && c.day.isBefore(today))
        .map((c) => c.day)
        .toSet();

    // 过去 14 天（含昨天），按周分行。
    final days = List.generate(14, (i) => today.addDays(-(i + 1)));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Copy.backfillCalendarTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(Copy.backfillHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            for (var row = 0; row < 2; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final day in days.skip(row * 7).take(7))
                      _DayCell(
                        day: day,
                        done: mine.contains(day),
                        onTap: () async {
                          final c = await ref
                              .read(checkInServiceProvider)
                              .backfill(goal.id, day);
                          if (context.mounted) {
                            showCheckInToast(context, ref, c);
                          }
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.done,
    required this.onTap,
  });

  final LocalDate day;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: done ? null : onTap,
      child: Container(
        width: 42,
        height: 52,
        decoration: BoxDecoration(
          color: done ? theme.colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(10),
          border: done ? null : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('周${day.weekday.zhLabel}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text('${day.day}', style: theme.textTheme.titleSmall),
              Icon(
                done ? Icons.check : Icons.add,
                size: 16,
                color: done
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
