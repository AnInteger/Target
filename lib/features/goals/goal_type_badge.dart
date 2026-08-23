/// 目标类型徽章（004 T013 v2 换装）：「类型 · 域 · 大类」胶囊
/// （v2-goal-detail .badge 同款）——surfaceAlt 底、无描边、文字随
/// 三大类常驻色；003 的节律点/∞/「短期 · 还剩 N 天」倒计时语言退役
/// （倒计时移交详情 meta 行，见 goal_detail）。
/// [suffix] = 非活跃状态尾缀（冻结稿板 5：「… · 已暂停」）。
library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';

class GoalTypeBadge extends StatelessWidget {
  const GoalTypeBadge({super.key, required this.goal, this.suffix});

  final Goal goal;
  final String? suffix;

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
    final label = suffix == null
        ? '$type · ${icon.domain.zhLabel} · ${icon.domain.major.zhLabel}'
        : '$type · ${icon.domain.zhLabel} · ${icon.domain.major.zhLabel} · $suffix';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        color: palette.surfaceAlt,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelS
            .copyWith(color: color, height: 1),
      ),
    );
  }
}
