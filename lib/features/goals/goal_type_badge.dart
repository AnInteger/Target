/// 目标类型徽章（004 T013 v2 换装）：「类型 · 域 · 大类」胶囊
/// （v2-goal-detail .badge 同款）——surfaceAlt 底、无描边、文字随
/// 三大类常驻色；003 的节律点/∞/「短期 · 还剩 N 天」倒计时语言退役
/// （倒计时移交详情 meta 行，见 goal_detail）。
library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';

class GoalTypeBadge extends StatelessWidget {
  const GoalTypeBadge({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final icon = GoalIconCatalog.byKey(goal.iconKey);
    final color = MajorColors.byKey(icon.domain.major.name).of(context);
    final type = goal.isHabit
        ? Copy.typeBadgeHabit
        : goal.isShortTerm
            ? Copy.typeBadgeShortTerm
            : Copy.typeBadgeLongTerm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        color: palette.surfaceAlt,
      ),
      child: Text(
        '$type · ${icon.domain.zhLabel} · ${icon.domain.major.zhLabel}',
        style: Theme.of(context)
            .textTheme
            .labelS
            .copyWith(color: color, height: 1),
      ),
    );
  }
}
