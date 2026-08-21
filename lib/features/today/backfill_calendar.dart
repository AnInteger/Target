/// 补签日历（T023 新视觉 · FR-004）：过去两周逐日补卡，断链回接。
///
/// 只展示过去日期（今天在今日列表里打）；已有有效打卡的日不可重复；
/// 补签后 isBackfill 自动标记，周统计如实呈现（R6）。弹层走定稿设计
/// 语言：surface 面板 + 目标色已成格（白勾）/ 描边待补格（＋邀请）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import 'undo_toast.dart';

Future<void> showBackfillCalendar(BuildContext context, WidgetRef ref, Goal goal) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
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
    final palette = TargetPalette.of(context);
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final today = ref.watch(todayProvider);
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];
    final mine = checkIns
        .where((c) => c.goalId == goal.id && c.isValid && c.day.isBefore(today))
        .map((c) => c.day)
        .toSet();

    // 过去 14 天（含昨天），按周分行。
    final days = List.generate(14, (i) => today.addDays(-(i + 1)));

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border.all(color: palette.divider),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.s6, AppSpace.s2, AppSpace.s6, AppSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s3),
              Text(Copy.backfillCalendarTitle,
                  style: Theme.of(context).textTheme.titleS),
              const SizedBox(height: 2),
              Text(
                Copy.backfillHint,
                style: Theme.of(context)
                    .textTheme
                    .bodyS
                    .copyWith(color: palette.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpace.s4),
              for (var row = 0; row < 2; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final day in days.skip(row * 7).take(7))
                        _DayCell(
                          day: day,
                          color: color,
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
      ),
    );
  }
}

/// 单日格：已成 = 目标色实心 + 白勾；待补 = 描边 + ＋ 邀请。
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.color,
    required this.done,
    required this.onTap,
  });

  final LocalDate day;
  final Color color;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final ink = done ? Colors.white : palette.onSurfaceVariant;
    return GestureDetector(
      onTap: done ? null : onTap,
      child: Container(
        width: 42,
        height: 56,
        decoration: BoxDecoration(
          color: done ? color : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: done ? null : Border.all(color: palette.divider),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '周${day.weekday.zhLabel}',
                style: Theme.of(context)
                    .textTheme
                    .labelS
                    .copyWith(color: done ? ink : palette.onSurfaceVariant),
              ),
              Text(
                '${day.day}',
                style: Theme.of(context)
                    .textTheme
                    .titleM
                    .copyWith(color: ink, height: 1),
              ),
              const SizedBox(height: 2),
              Icon(
                done ? Icons.check : Icons.add,
                size: 14,
                color: ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
