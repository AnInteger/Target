/// v3 动态页（tab 2）：周切换 + 本周投入柱状卡 + 里程碑汇总 +
/// feed（记录/达成混排）+「日历」直达每日投入（所有日期，R2/R3 定稿）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/relative_time.dart';
import '../../core/stats/stats_engine.dart';
import '../goals/goals_view.dart' show GlassCircleButton;
import 'daily_calendar_sheet.dart';

class ActivityView extends ConsumerStatefulWidget {
  const ActivityView({super.key});

  @override
  ConsumerState<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends ConsumerState<ActivityView> {
  late WeekStart _week = WeekStart.containing(
    ref.read(todayProvider),
  );

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
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
          stops: const [0, 0.18, 0.42, 1],
          colors: p.headerGrad,
        ),
      ),
      child: SafeArea(
        bottom: false,
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
                          Text(Copy.activityTitle,
                              style:
                                  Theme.of(context).textTheme.displayL),
                          const SizedBox(height: 2),
                          Text(
                            Copy.activitySubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyM
                                .copyWith(color: p.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    // R3 定稿：双玻璃圆钮（日历直达 + 设置）。
                    Row(
                      children: [
                        GlassCircleButton(
                          icon: Icons.calendar_today_outlined,
                          tooltip: Copy.calendarEntry,
                          onTap: () =>
                              showDailyCalendarSheet(context, records),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(height: 8),
                        GlassCircleButton(
                          icon: Icons.person_outline,
                          tooltip: Copy.settingsTitle,
                          onTap: () =>
                              _goSettings(),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _WeekCard(
                    week: week, weekStart: _week, today: today),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _MilestoneCard(summary: summary),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(Copy.recentFeed,
                          style: Theme.of(context).textTheme.titleM),
                    ),
                    GestureDetector(
                      onTap: () =>
                          showDailyCalendarSheet(context, records),
                      child: Text(
                        Copy.calendarEntry,
                        style: Theme.of(context)
                            .textTheme
                            .bodyM
                            .copyWith(color: p.accentText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (feed.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.builder(
                  itemCount: feed.length,
                  itemBuilder: (_, i) => _FeedRow(
                    item: feed[i],
                    goals: goals,
                    today: today,
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
    Navigator.of(context, rootNavigator: false);
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({required this.week, required this.onChange});

  final WeekStart week;
  final ValueChanged<WeekStart> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navBtn(context, Icons.chevron_left, () => onChange(week.previous)),
          const SizedBox(width: 16),
          Text(
            '${week.monday.month}月${week.monday.day}日 — '
            '${week.sunday.month}月${week.sunday.day}日',
            style: Theme.of(context)
                .textTheme
                .bodyM
                .copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          _navBtn(context, Icons.chevron_right, () => onChange(week.next)),
        ],
      ),
    );
  }

  Widget _navBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: p.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 14, color: p.onSurfaceTertiary),
        ),
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
    final text = Theme.of(context).textTheme;
    final maxMin = week.perDayMinutes.fold<int>(0, (m, v) => v > m ? v : m);
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Copy.weekInvestment,
              style: text.bodyS.copyWith(color: p.onSurfaceTertiary)),
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
          SizedBox(
            height: 88,
            child: Row(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  if (d > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${week.perDayMinutes[d]}',
                          style: TextStyle(
                            fontSize: 10,
                            color: week.perDayMinutes[d] == 0
                                ? p.onSurfaceTertiary
                                    .withValues(alpha: 0.6)
                                : p.onSurfaceTertiary,
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
                        const SizedBox(height: 3),
                        Text(
                          _dayLabels[d],
                          style: TextStyle(
                              fontSize: 11, color: p.onSurfaceTertiary),
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
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.summary});

  final MilestoneSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.milestoneTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flag, size: 22, color: p.milestone),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(Copy.milestoneCardTitle, style: text.titleM)),
          _stat(context, Copy.milestoneAchievedThisWeek,
              Copy.milestoneCount(summary.achievedThisWeek)),
          Container(
              width: 0.5, height: 28, color: p.divider, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _stat(context, Copy.milestonePending,
              Copy.milestoneCount(summary.pendingAll)),
          Icon(Icons.chevron_right,
              size: 14,
              color: p.onSurfaceTertiary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String k, String v) {
    final text = Theme.of(context).textTheme;
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
  });

  final FeedItem item;
  final List<Goal> goals;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    final goal =
        goals.where((g) => g.id == item.goalId).firstOrNull;
    final color = goal == null
        ? p.onSurfaceVariant
        : GoalPalette.byKey(goal.colorKey,
            brightness: Theme.of(context).brightness);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: item.isMilestone
                  ? p.milestoneTint
                  : color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              item.isMilestone ? Icons.flag : Icons.edit_outlined,
              size: 17,
              color: item.isMilestone ? p.milestone : color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isMilestone
                      ? Copy.feedMilestone(item.record.title)
                      : item.goalName,
                  style: text.bodyL
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  relativeDayLabel(item.record.day, today),
                  style:
                      text.bodyS.copyWith(color: p.onSurfaceTertiary),
                ),
                if (!item.isMilestone) ...[
                  const SizedBox(height: 3),
                  Text(item.record.title, style: text.bodyM),
                  if (item.record.durationMinutes != null)
                    Text(
                      Copy.feedDuration(item.record.durationMinutes!),
                      style: text.bodyS.copyWith(
                          color: p.onSurfaceTertiary),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      child: Column(
        children: [
          Text(title,
              style: text.titleM.copyWith(color: p.onSurface)),
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
