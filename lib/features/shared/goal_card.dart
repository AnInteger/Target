/// 目标卡片组件：置顶大卡（R13 单栏定稿）与其他目标行。
/// v3.1：Material+InkWell → AppCard（DecoratedBox + 手势）。
library;

import 'package:flutter/cupertino.dart';

import '../../../app/controls.dart';
import '../../../app/design_tokens.dart';
import '../../../core/copy.dart';
import '../../../core/models/entities.dart';
import '../../../core/models/goal_icon_catalog.dart';
import '../../../core/models/calendar_types.dart';
import '../../../core/models/relative_time.dart';

/// 目标图标（iconKey → 目录自带图形；未知键回退靶心）。
/// 注：域图形目录（38 枚）沿用内置 Material Rounded 字形——内容图形
/// 而非 UI 骨架，Cupertino 图标库无对应域覆盖面。
IconData goalIconData(String iconKey) => GoalIconCatalog.byKey(iconKey).icon;

/// 置顶大卡（R13 单栏定稿：顶行图标+分类 → 全宽目标名 → 最近记录
/// （标签/相对日两端对齐）→ 正文 → 分隔线 → 里程碑分区）。
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
    final text = AppText.of(context);
    final color = GoalPalette.byKey(
      goal.colorKey,
      brightness: TargetPalette.brightnessOf(context),
    );
    final latest = records.where((r) => r.goalId == goal.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final next =
        milestones.where((m) => m.goalId == goal.id && !m.isDone).toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶行：目标图标（保留目标色）+ 分类（中灰）+ 右缘箭头。
          Row(
            children: [
              Icon(goalIconData(goal.iconKey), size: 28, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.categoryKey == null
                      ? Copy.categoryUncategorized
                      : Copy.categoryOf(goal.categoryKey!.name),
                  style: text.bodyM.copyWith(color: p.onSurfaceTertiary),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: p.onSurfaceTertiary.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(goal.name, style: text.titleL),
          if (latest.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                Copy.noRecordYet,
                style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
              ),
            )
          else ...[
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Copy.recentRecordLabel,
                  style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
                ),
                Text(
                  relativeDayLabel(latest.first.day, today),
                  style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              latest.first.title,
              style: text.bodyM.copyWith(
                color: p.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (latest.first.body != null &&
                latest.first.body!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                latest.first.body!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyM.copyWith(color: p.onSurfaceVariant),
              ),
            ],
          ],
          if (next.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HairlineDivider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.flag,
                          size: 16,
                          color: p.onSurfaceTertiary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Copy.nextMilestoneLabel, style: text.labelS),
                              const SizedBox(height: 2),
                              Text(next.first.title, style: text.titleS),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
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
    final text = AppText.of(context);
    final color = GoalPalette.byKey(
      goal.colorKey,
      brightness: TargetPalette.brightnessOf(context),
    );
    final latest = records.where((r) => r.goalId == goal.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpace.s3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s4,
        vertical: 13,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(goalIconData(goal.iconKey), size: 18, color: color),
          ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyL.copyWith(fontWeight: FontWeight.w500),
                ),
                if (latest.isNotEmpty)
                  Text(
                    Copy.hasRecordAt(relativeDayLabel(latest.first.day, today)),
                    style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
                  ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 14,
            color: p.onSurfaceTertiary.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
