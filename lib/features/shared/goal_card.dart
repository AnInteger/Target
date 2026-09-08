/// 目标卡片组件：置顶大卡（两栏：56 图标列 + 缩进文字列）与其他目标行。
library;

import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../core/copy.dart';
import '../../../core/models/entities.dart';
import '../../../core/models/goal_icon_catalog.dart';
import '../../../core/models/calendar_types.dart';
import '../../../core/models/relative_time.dart';

/// 目标图标（iconKey → 目录自带 Material 图形；未知键回退靶心）。
IconData goalIconData(String iconKey) =>
    GoalIconCatalog.byKey(iconKey).icon;

/// 置顶大卡（两栏；R1/R2 定稿）。
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.records,
    required this.milestones,
    required this.onTap,
    required this.onLongPress,
    required this.today,
  });

  final Goal goal;
  final List<ProgressRecord> records;
  final List<Milestone> milestones;

  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color =
        GoalPalette.byKey(goal.colorKey, brightness: Theme.of(context).brightness);
    final latest = records.where((r) => r.goalId == goal.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final next = milestones
        .where((m) => m.goalId == goal.id && !m.isDone)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: p.shadowLow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(goalIconData(goal.iconKey), size: 56, color: color),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.categoryKey == null
                                ? Copy.categoryUncategorized
                                : Copy.categoryOf(goal.categoryKey!.name),
                            style: text.titleS.copyWith(color: color),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 16,
                            color: p.onSurfaceTertiary.withValues(alpha: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(goal.name, style: text.titleL),
                    if (latest.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          Copy.noRecordYet,
                          style:
                              text.bodyS.copyWith(color: p.onSurfaceTertiary),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 10),
                      Text(
                        Copy.lastRecordAt(
                            relativeDayLabel(latest.first.day, today)),
                        style:
                            text.bodyS.copyWith(color: p.onSurfaceTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(latest.first.title, style: text.bodyM),
                      if (latest.first.body != null &&
                          latest.first.body!.trim().isNotEmpty)
                        Text(
                          latest.first.body!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyM
                              .copyWith(color: p.onSurfaceVariant),
                        ),
                    ],
                    if (next.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: p.divider, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined,
                                size: 15, color: p.onSurfaceTertiary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Copy.nextMilestoneLabel,
                                  style: text.labelS,
                                ),
                                Text(next.first.title, style: text.bodyM),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

/// 其他目标紧凑行。
class OthersRow extends StatelessWidget {
  const OthersRow({
    super.key,
    required this.goal,
    required this.records,
    required this.onTap,
    required this.onLongPress,
    required this.today,
  });

  final Goal goal;
  final List<ProgressRecord> records;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color =
        GoalPalette.byKey(goal.colorKey, brightness: Theme.of(context).brightness);
    final latest = records.where((r) => r.goalId == goal.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s4, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: p.shadowLow,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child:
                    Icon(goalIconData(goal.iconKey), size: 18, color: color),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyL.copyWith(
                            fontWeight: FontWeight.w500)),
                    if (latest.isNotEmpty)
                      Text(
                        Copy.hasRecordAt(relativeDayLabel(
                            latest.first.day, today)),
                        style:
                            text.bodyS.copyWith(color: p.onSurfaceTertiary),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 14,
                  color: p.onSurfaceTertiary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
