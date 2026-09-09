/// v3 动态页（tab 2）：周切换 + 本周投入柱状卡 + 里程碑汇总 +
/// feed（记录/达成混排）+「日历」直达每日投入（所有日期，R2/R3 定稿）。
/// v3.1：Cupertino 组件重写。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/relative_time.dart';

import '../../core/stats/stats_engine.dart';
import 'daily_calendar_sheet.dart';
import '../shared/goal_card.dart' show goalIconData;

class ActivityView extends ConsumerStatefulWidget {
  const ActivityView({super.key});

  @override
  ConsumerState<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends ConsumerState<ActivityView> {
  late WeekStart _week = WeekStart.containing(ref.read(todayProvider));

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final records =
        ref.watch(recordsProvider).value ?? const <ProgressRecord>[];
    final milestones =
        ref.watch(milestonesProvider).value ?? const <Milestone>[];
    final today = ref.watch(todayProvider);
    final week = StatsEngine.weekInvestment(records, _week);
    final summary = StatsEngine.milestoneSummary(milestones, _week);
    final goalNames = {for (final g in goals) g.id: g.name};
    final feed = StatsEngine.activityFeed(records, goalNames);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.30, 0.75, 1],
          colors: p.headerGrad,
        ),
      ),
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 12),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Copy.activityTitle, style: text.displayL),
                        ],
                      ),
                    ),
                    // R3 定稿：双圆钮（日历直达 + 设置）。
                    Row(
                      children: [
                        CircleIconButton(
                          icon: CupertinoIcons.calendar,
                          onTap: () => showDailyCalendarSheet(context, records),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(height: 8),
                        CircleIconButton(
                          icon: CupertinoIcons.person,
                          onTap: _goSettings,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _WeekNav(
                week: _week,
                onChange: (w) => setState(() => _week = w),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: _WeekCard(week: week, weekStart: _week, today: today),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: _MilestoneCard(summary: summary),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Copy.recentFeed,
                        style: text.titleS.copyWith(color: p.onSurfaceVariant),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.square(32),
                      onPressed: () => showDailyCalendarSheet(context, records),
                      child: Text(
                        Copy.calendarEntry,
                        style: text.bodyM.copyWith(color: p.accentText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (feed.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _EmptyCard(
                    title: week.recordCount == 0
                        ? Copy.activityEmptyTitle
                        : Copy.recentFeed,
                    body: Copy.activityEmptyBody,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverList.builder(
                  itemCount: feed.length,
                  itemBuilder: (_, i) => _FeedRow(
                    item: feed[i],
                    goals: goals,
                    today: today,
                    linkedMilestoneTitle: milestones
                        .where((m) => m.id == feed[i].record.milestoneId)
                        .firstOrNull
                        ?.title,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _goSettings() {
    // R2/R3 定稿：设置入口在动态页头部。
    context.push('/settings');
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({required this.week, required this.onChange});

  final WeekStart week;
  final ValueChanged<WeekStart> onChange;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleIconButton(
            icon: CupertinoIcons.chevron_back,
            size: 32,
            iconSize: 14,
            foregroundColor: TargetPalette.of(context).onSurfaceTertiary,
            onTap: () => onChange(week.previous),
          ),
          const SizedBox(width: 16),
          Text(
            '${week.monday.month}月${week.monday.day}日 — '
            '${week.sunday.month}月${week.sunday.day}日',
            style: text.bodyM.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          CircleIconButton(
            icon: CupertinoIcons.chevron_forward,
            size: 32,
            iconSize: 14,
            foregroundColor: TargetPalette.of(context).onSurfaceTertiary,
            onTap: () => onChange(week.next),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
    required this.weekStart,
    required this.today,
  });

  final WeekInvestment week;
  final WeekStart weekStart;
  final LocalDate today;

  static const _dayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final maxMin = week.perDayMinutes.fold<int>(0, (m, v) => v > m ? v : m);
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Copy.weekInvestment,
            style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
          ),
          const SizedBox(height: 2),
          Text(
            Copy.weekInvestmentValue(week.hours, week.remainderMinutes),
            style: text.displayL.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 3),
          Text(
            Copy.weekRecords(week.recordCount),
            style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
          ),
          const SizedBox(height: 16),
          // 柱区（定高）：分钟数（14）+ 间距（3）+ 柱体（≤64）。
          SizedBox(
            height: 81,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var d = 0; d < 7; d++) ...[
                  if (d > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 14,
                          child: Center(
                            child: Text(
                              '${week.perDayMinutes[d]}',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1,
                                color: week.perDayMinutes[d] == 0
                                    ? p.onSurfaceTertiary.withValues(alpha: 0.6)
                                    : p.onSurfaceTertiary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: maxMin == 0
                              ? 0
                              : (week.perDayMinutes[d] / maxMin * 64)
                                    .clamp(6, 64)
                                    .toDouble(),
                          decoration: BoxDecoration(
                            color: weekStart.monday.addDays(d) == today
                                ? p.accent
                                : p.accent.withValues(alpha: 0.32),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                              bottom: Radius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          // 星期标签独立成行（定高）——与柱体底缘严格对齐。
          SizedBox(
            height: 14,
            child: Row(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  if (d > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Center(
                      child: Text(
                        _dayLabels[d],
                        style: TextStyle(
                          fontSize: 11,
                          height: 1,
                          color: p.onSurfaceTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.summary});

  final MilestoneSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.milestoneTint,
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.flag_fill, size: 22, color: p.milestone),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(Copy.milestoneCardTitle, style: text.titleM)),
          _stat(
            context,
            Copy.milestoneAchievedThisWeek,
            Copy.milestoneCount(summary.achievedThisWeek),
          ),
          Container(
            width: 0.5,
            height: 28,
            color: p.divider,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _stat(
            context,
            Copy.milestonePending,
            Copy.milestoneCount(summary.pendingAll),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String k, String v) {
    final text = AppText.of(context);
    return Column(
      children: [
        Text(k, style: text.labelS),
        Text(v, style: text.titleL.copyWith(fontSize: 22)),
      ],
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({
    required this.item,
    required this.goals,
    required this.today,
    this.linkedMilestoneTitle,
  });

  final FeedItem item;
  final List<Goal> goals;
  final LocalDate today;

  /// 关联里程碑标题（无关联为 null）。
  final String? linkedMilestoneTitle;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final record = item.record;
    final isMs = item.isMilestone;
    final linked =
        linkedMilestoneTitle != null && linkedMilestoneTitle!.isNotEmpty;
    final goal = goals.where((g) => g.id == item.goalId).firstOrNull;
    final color = goal == null
        ? p.onSurfaceVariant
        : GoalPalette.byKey(
            goal.colorKey,
            brightness: TargetPalette.brightnessOf(context),
          );

    // 图标 = 目标自身的图标与颜色（进展归属一目了然；
    // 里程碑状态由文案行承载）。
    final icon = goal == null
        ? CupertinoIcons.scope
        : goalIconData(goal.iconKey);
    final iconColor = color;
    final iconBg = color.withValues(alpha: 0.10);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 行 1：进展标题（里程碑达成 = 达成：里程碑名）。
                Text(
                  isMs ? Copy.feedMilestone(record.title) : record.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyL.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                // 行 2：所属目标（进展归属主体，独立成行）。
                Text(
                  item.goalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyS.copyWith(
                    color: p.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                // 行 3：秒级时间 · 投入 · 里程碑状态。
                Text(
                  [
                    timestampLabel(
                      record.day,
                      today,
                      record.createdAt.toLocal(),
                    ),
                    if (record.durationMinutes != null)
                      Copy.feedDuration(record.durationMinutes!),
                    if (linked) Copy.recordMilestoneLink(linkedMilestoneTitle!),
                    if (isMs) Copy.statusAchieved,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Text(title, style: text.titleM.copyWith(color: p.onSurface)),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: text.bodyM.copyWith(color: p.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
