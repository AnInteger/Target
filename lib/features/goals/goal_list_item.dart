/// 紧凑目标行（2026-08-26 phase 1 · Task 6）。
///
/// 数据面：`GoalListFilter` 状态筛选 + `GoalListItemData`（摘要与
/// 排序所需的最小快照：里程碑计数、最近有效进展日）。
/// 视觉面：40–44dp 图标格 + 单行名称 + 状态徽章 + 单行摘要 +
/// 可见 overflow 钮——整行进详情，禁用 Today 焦点卡式大卡。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';

/// 状态筛选（单选；all 含归档但归档沉底）。
enum GoalListFilter { all, active, paused, achieved, archived }

extension GoalListFilterX on GoalListFilter {
  String get label => switch (this) {
    GoalListFilter.all => Copy.goalsFilterAll,
    GoalListFilter.active => Copy.goalsFilterActive,
    GoalListFilter.paused => Copy.goalsFilterPaused,
    GoalListFilter.achieved => Copy.goalsFilterAchieved,
    GoalListFilter.archived => Copy.goalsFilterArchived,
  };

  bool matches(Goal goal) => switch (this) {
    GoalListFilter.all => true,
    GoalListFilter.active => goal.isActive,
    GoalListFilter.paused =>
      goal.status == GoalStatus.paused && !goal.isArchived,
    GoalListFilter.achieved =>
      goal.status == GoalStatus.achieved && !goal.isArchived,
    GoalListFilter.archived => goal.isArchived,
  };
}

/// 行数据快照：goal + 摘要素材（列表页一次组装，行内零流订阅）。
class GoalListItemData {
  const GoalListItemData({
    required this.goal,
    required this.summary,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.lastActivity,
  });

  final Goal goal;

  /// 单行摘要（组装规则见 [summarize]）。
  final String summary;
  final int completedMilestones;
  final int totalMilestones;

  /// 最近一次有效进展日（打卡或里程碑完成；无则 null）。
  final LocalDate? lastActivity;
}

/// 摘要优先级（Task 6 Step 3）：
/// 1. 第一个未完成里程碑「当前：<题> · <完成>/<总数>」；
/// 2. 最新有效进展日「最近进展：M月D日」；
/// 3. 「尚无进展记录」。
String summarizeGoal({
  required List<MilestoneStep> milestones,
  required int latestValidRecordMonth,
  required int latestValidRecordDay,
  required bool hasValidRecord,
}) {
  MilestoneStep? firstPending;
  var done = 0;
  for (final m in milestones) {
    if (m.isDone) {
      done++;
    } else {
      firstPending ??= m;
    }
  }
  if (firstPending != null) {
    return Copy.goalSummaryCurrent(firstPending.title, done, milestones.length);
  }
  if (hasValidRecord) {
    return Copy.goalSummaryRecent(latestValidRecordMonth, latestValidRecordDay);
  }
  return Copy.goalSummaryEmpty;
}

/// 紧凑管理行：整行进详情（push /goal/:id），overflow 钮由父层注入回调。
class GoalListItem extends StatelessWidget {
  const GoalListItem({
    super.key,
    required this.data,
    required this.onOverflow,
  });

  final GoalListItemData data;

  /// overflow 钮回调（打开状态感知管理菜单）。
  final VoidCallback onOverflow;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final goal = data.goal;
    final icon = GoalIconCatalog.byKey(goal.iconKey);
    final majorColor = MajorColors.byKey(icon.domain.major.name).of(context);

    final (badgeLabel, badgeColor) = goal.isArchived
        ? (Copy.goalStatusArchivedSuffix, palette.onSurfaceVariant)
        : switch (goal.status) {
            GoalStatus.paused => (
              Copy.goalStatusPausedSuffix,
              palette.warning,
            ),
            GoalStatus.achieved => (
              Copy.goalStatusAchievedSuffix,
              palette.positive,
            ),
            GoalStatus.active ||
            GoalStatus.archived => (null, palette.onSurfaceVariant),
          };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('goalListRow-${goal.id}'),
        onTap: () => context.push('/goal/${goal.id}'),
        borderRadius: AppRadius.rLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: AppRadius.rMd,
                ),
                child: Icon(icon.icon, size: 22, color: majorColor),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyM.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (badgeLabel != null) ...[
                          const SizedBox(width: AppSpace.s2),
                          _Badge(label: badgeLabel, color: badgeColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyS.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s1),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  key: ValueKey('goalOverflow-${goal.id}'),
                  onPressed: onOverflow,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: palette.onSurfaceVariant,
                  ),
                  tooltip: Copy.goalMoreActions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: 1),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelS.copyWith(color: color),
      ),
    );
  }
}
