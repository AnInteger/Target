/// 目标类型徽章（003 D2 三类型域，T021 抽公共）：今日卡与详情页
/// 同语言——习惯 = 双节律点 + 「习惯」；短期 = 「短期 · 还剩 N 天」
/// （≤3 天转 warning 色）；长期 = 「∞ 长期」。
library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';

class GoalTypeBadge extends StatelessWidget {
  const GoalTypeBadge({super.key, required this.goal, required this.today});

  final Goal goal;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final due = goal.deadline?.differenceInDays(today);
    final soon = due != null && due >= 0 && due <= 3;
    final color = soon ? palette.warning : palette.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        color: palette.surface,
        border: Border.all(
          color: soon
              ? Color.lerp(palette.warning, Colors.transparent, 0.6)!
              : palette.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (goal.isHabit) ...[
            // 节律点：两个青柠小点。
            for (var i = 0; i < 2; i++) ...[
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.positiveFill,
                  shape: BoxShape.circle,
                ),
              ),
              if (i == 0) const SizedBox(width: 3),
            ],
            const SizedBox(width: 5),
          ] else if (goal.isLongTerm)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Text(
                '∞',
                style: Theme.of(context)
                    .textTheme
                    .labelS
                    .copyWith(color: color, height: 1),
              ),
            ),
          Text(
            goal.isHabit
                ? Copy.typeBadgeHabit
                : goal.isShortTerm
                    ? '${Copy.typeBadgeShortTerm} · ${Copy.milestoneCountdown(due ?? 0)}'
                    : Copy.typeBadgeLongTerm,
            style: Theme.of(context)
                .textTheme
                .labelS
                .copyWith(color: color, height: 1),
          ),
        ],
      ),
    );
  }
}
