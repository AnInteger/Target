import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../../core/models/goal_progress.dart';

class AttentionGoalList extends StatelessWidget {
  const AttentionGoalList({
    super.key,
    required this.evaluation,
    required this.goals,
    required this.onOpen,
  });

  final GoalProgressEvaluation evaluation;
  final List<Goal> goals;
  final ValueChanged<Goal> onOpen;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final goal in goals) goal.id: goal};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('需要关注', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (evaluation.attention.isEmpty)
          const _AttentionEmpty()
        else
          for (final item in evaluation.attention)
            if (byId[item.goalId] case final goal?)
              _AttentionCard(goal: goal, item: item, onTap: () => onOpen(goal)),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.goal,
    required this.item,
    required this.onTap,
  });

  final Goal goal;
  final AttentionItem item;
  final VoidCallback onTap;

  String get reason => switch (item.reason) {
    AttentionReason.needsPlanning => '待规划下一步',
    AttentionReason.deadlineNear => '截止缓冲较少',
    AttentionReason.rhythmInterrupted => '推进节奏放缓',
  };

  String get action => switch (item.reason) {
    AttentionReason.needsPlanning => '确认一个可以开始的下一步',
    AttentionReason.deadlineNear => '检查剩余步骤与日期是否匹配',
    AttentionReason.rhythmInterrupted => '记录一次真实进展或调整节奏',
  };

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final color = MajorColors.byKey(goal.major.name).of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    GoalIconCatalog.byKey(goal.iconKey).icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              reason,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionEmpty extends StatelessWidget {
  const _AttentionEmpty();

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '当前没有需要优先处理的计划。',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: palette.onSurfaceVariant),
      ),
    );
  }
}
