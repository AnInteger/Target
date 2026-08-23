/// 周回顾页 v2（004 US5 · v2-review.html 冻结稿，三区块全量）。
///
/// 纯回看实时派生（不读 WeeklyReviews 快照，T027 引擎三法）：①本周
/// 概览 = 周平均完成率（活跃池 Σ留痕日/Σ应记日）+ 上周环比 + 72px
/// 均分环；②每日活动七天点阵（full=实底对勾 / partial=描边圈 /
/// plain=灰底 + 下标打卡数，FR-013 双编码不单靠色相）；③本周目标
/// 卡（大类色图标 + weekRateOf 线性进度 x/y → 详情）+「查看全部›」。
/// 顶部 ‹ 周 › 切换（前瞻钳制在包含今日的周——未来周无可回看）；
/// 右上日历钮为「选择周期」占位（后续版本）。零应记周：概览整卡
/// 「—」+ 点阵全灰 + 空周引导（CTA 直达编辑器，FR-007 ≤1 交互）。
/// 003 卡片轮播/三态图例/四周走势/观察语语言全数退役。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../../core/stats/stats_engine.dart';

class ReviewView extends ConsumerStatefulWidget {
  const ReviewView({super.key});

  @override
  ConsumerState<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<ReviewView> {
  /// 选中的周锚（null = 跟随本周）；入参若越界到未来周，回钳本周。
  WeekStart? _selected;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final thisWeek = today.weekStart;
    final week = (_selected == null || _selected!.compareTo(thisWeek) > 0)
        ? thisWeek
        : _selected!;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final stats = ref.watch(statsProvider);

    if (stats == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: TargetPalette.of(context).accent,
          ),
        ),
      );
    }

    // 该周存在应记目标（守护面）→ 本周目标区出卡；否则概览「—」+
    // 点阵全灰 + 空周引导（冻结稿画板③）。
    final guarded = goals
        .where((g) => stats.weekRateOf(g.id, week).expectedDays > 0)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppScreen.padX,
            0,
            AppScreen.padX,
            AppSpace.s6,
          ),
          children: [
            const _Head(),
            _WeekNav(
              week: week,
              canNext: week.compareTo(thisWeek) < 0,
              onPrev: () => setState(() => _selected = week.previous),
              onNext: () => setState(() => _selected = week.next),
            ),
            const SizedBox(height: AppSpace.s1),
            _OverviewCard(overview: stats.weekOverview(week)),
            const SizedBox(height: AppSpace.s4),
            _DaysCard(activities: stats.dayActivities(week), today: today),
            if (guarded.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s4),
                child: _EmptyState(
                  onCreate: () => context.push('/goal-editor'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s4),
                child: _GoalsSection(goals: guarded, stats: stats, week: week),
              ),
          ],
        ),
      ),
    );
  }
}

/// v2 顶栏（.top）：大标题「回顾」displayL + 右上 38px 日历钮
///（「选择周期」占位——后续版本，Tooltip 明示、无动作）。
class _Head extends StatelessWidget {
  const _Head();

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Copy.reviewTitle,
              key: const ValueKey('screenTitle'),
              style: Theme.of(context).textTheme.displayL,
            ),
          ),
          Tooltip(
            message: Copy.reviewPickWeek,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface,
                border: Border.all(color: palette.divider),
                boxShadow: palette.shadowLow,
              ),
              child: Icon(
                Icons.calendar_month,
                size: 18,
                color: palette.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 周切换行（.wknav）：‹ 30px 圆钮 + 居中周区间（tabular）+ ›。
/// 前瞻钳制：已在本周时 › 置灰不可点（未来周无可回看）。
class _WeekNav extends StatelessWidget {
  const _WeekNav({
    required this.week,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final WeekStart week;

  /// › 可用（当前选中的是过去的周）。
  final bool canNext;

  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    Widget btn(String key, IconData icon, VoidCallback? onTap) => Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: SizedBox(
        // 005 D6（FR-009）：触达外扩 44×44——30 视觉钮居中不变。
        width: 44,
        height: 44,
        child: InkWell(
          key: ValueKey(key),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface,
                boxShadow: palette.shadowLow,
              ),
              child: Icon(icon, size: 18, color: palette.onSurface),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s3, bottom: AppSpace.s1),
      child: Row(
        children: [
          btn('weekPrev', Icons.chevron_left, onPrev),
          Expanded(
            child: Center(
              child: Text(
                '${week.monday.month} 月 ${week.monday.day} 日'
                ' – ${week.sunday.month} 月 ${week.sunday.day} 日',
                key: const ValueKey('weekRange'),
                style: Theme.of(context).textTheme.bodyM.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          btn('weekNext', Icons.chevron_right, canNext ? onNext : null),
        ],
      ),
    );
  }
}

/// 区块 1 · 本周概览（.sec-t + .ov）：周平均完成率大数字（displayL）
/// + 环比胶囊（↑ positive-fill/↓ 弱底警示字，FR-013 双编码）+ 副行
/// 「周平均完成率 · 上周 N%」+ 72px 均分环。零应记周整卡示「—」
///（该周暂无记录，环空轨）；环比任一周零应记 → 不出胶囊（无可比较）。
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.overview});

  final WeekOverview overview;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final delta = overview.delta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Copy.reviewOverviewTitle, style: theme.textTheme.titleS),
        const SizedBox(height: AppSpace.s2),
        Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: palette.shadowLow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            overview.rate == null ? '—' : '${overview.rate}%',
                            key: const ValueKey('weekAvgNum'),
                            style: theme.textTheme.displayL.copyWith(
                              color: overview.rate == null
                                  ? palette.onSurfaceVariant
                                  : null,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (delta != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpace.s2,
                              bottom: AppSpace.s2,
                            ),
                            child: Container(
                              key: const ValueKey('weekAvgDelta'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.s2,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: delta >= 0
                                    ? palette.positiveFill
                                    : palette.surfaceAlt,
                              ),
                              child: Text(
                                '${delta >= 0 ? '↑' : '↓'} ${delta.abs()}%',
                                style: theme.textTheme.bodyS.copyWith(
                                  color: delta >= 0
                                      ? palette.positiveOn
                                      : palette.warning,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      overview.rate == null
                          ? Copy.reviewAvgEmpty
                          : Copy.reviewAvgSub(overview.lastRate),
                      key: const ValueKey('weekAvgSub'),
                      style: theme.textTheme.labelS.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s5),
              _AvgRing(rate: overview.rate),
            ],
          ),
        ),
      ],
    );
  }
}

/// 72px 均分环（.ov .wk）：r30 描边 7，track=divider，弧=positive
/// 圆头帽、弧长 = 完成率；中心 titleS 数字 + labelS「均分」。
class _AvgRing extends StatelessWidget {
  const _AvgRing({required this.rate});

  final int? rate;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingPainter(
                sweep: rate == null ? 0 : rate! / 100,
                track: palette.divider,
                arc: palette.positive,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rate == null ? '—' : '$rate',
                  style: theme.textTheme.titleS.copyWith(
                    color: rate == null ? palette.onSurfaceVariant : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  Copy.reviewAvgScore,
                  style: theme.textTheme.labelS.copyWith(
                    color: palette.onSurfaceVariant,
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.sweep, required this.track, required this.arc});

  final double sweep;
  final Color track;
  final Color arc;

  static const double _center = 36, _radius = 30, _stroke = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = const Offset(_center, _center);
    final rect = Rect.fromCircle(center: center, radius: _radius);
    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = track,
    );
    if (sweep <= 0) return; // 零应记/0% → 只余底轨
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.sweep != sweep || old.track != track || old.arc != arc;
}

/// 区块 2 · 每日活动（.days）：周一→周日 7 列（lbl 星期简称 / 36px
/// 点 / 下标打卡数 n）。着色三档（引擎 fill）：full=positiveFill 实底
/// + 对勾 16、partial=surfaceAlt 底 + 3px positiveFill 描边圈、
/// none=surfaceAlt 灰底（FR-013 对勾/描边双编码，不单靠色相）；今日
/// lbl accent 加粗；n=当日全量打卡次数（0 → 「·」；未来日引擎恒零
/// ——着色与计数永不落在未到的日子）。
class _DaysCard extends StatelessWidget {
  const _DaysCard({required this.activities, required this.today});

  final List<DayActivity> activities;

  final LocalDate today;

  static const List<String> _labels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Copy.reviewDaysTitle, style: Theme.of(context).textTheme.titleS),
        const SizedBox(height: AppSpace.s2),
        Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: palette.shadowLow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < activities.length; i++)
                _DayCol(
                  key: ValueKey('dayCol-$i'),
                  activity: activities[i],
                  label: _labels[i],
                  isToday: activities[i].day == today,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCol extends StatelessWidget {
  const _DayCol({
    super.key,
    required this.activity,
    required this.label,
    required this.isToday,
  });

  final DayActivity activity;

  final String label;

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final lblStyle = isToday
        ? theme.textTheme.labelS.copyWith(
            color: palette.accent,
            fontWeight: FontWeight.w700,
          )
        : theme.textTheme.labelS.copyWith(color: palette.onSurfaceVariant);
    return SizedBox(
      width: 36,
      child: Column(
        children: [
          Text(label, style: lblStyle),
          const SizedBox(height: AppSpace.s2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activity.fill == DayFill.full
                  ? palette.positiveFill
                  : palette.surfaceAlt,
              border: activity.fill == DayFill.partial
                  ? Border.all(color: palette.positiveFill, width: 3)
                  : null,
            ),
            child: activity.fill == DayFill.full
                ? Icon(Icons.check, size: 16, color: palette.positiveOn)
                : null,
          ),
          const SizedBox(height: AppSpace.s2),
          Text(
            activity.checks == 0 ? '·' : '${activity.checks}',
            style: theme.textTheme.labelS.copyWith(
              color: palette.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 区块 3 · 本周目标（.sec-t + .gcard×N）：题款行带「查看全部 ›」
///（→ /goals-all）；卡 = 42px 大类色图标格 + bodyL 目标名 + 6px 大类
/// 色线性进度（weekRateOf.fraction）+ x/y（bodyS tabular）+ chev，
/// 整卡 → /goal/{id}。只列该周有应记的目标（状态不滤，回看口径）。
class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.goals,
    required this.stats,
    required this.week,
  });

  final List<Goal> goals;

  final StatsEvaluation stats;

  final WeekStart week;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              Copy.reviewGoalsTitle,
              style: Theme.of(context).textTheme.titleS,
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.push('/goals-all'),
              child: Text(
                Copy.focusSeeAll,
                style: Theme.of(context).textTheme.bodyM
                    .copyWith(color: palette.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s2),
        for (var i = 0; i < goals.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.s3),
          _GoalWeekCard(
            key: ValueKey('reviewGoal-${goals[i].id}'),
            goal: goals[i],
            rate: stats.weekRateOf(goals[i].id, week),
          ),
        ],
      ],
    );
  }
}

class _GoalWeekCard extends StatelessWidget {
  const _GoalWeekCard({super.key, required this.goal, required this.rate});

  final Goal goal;

  final GoalWeekRate rate;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final majorColor = MajorColors.byKey(goal.major.name).of(context);
    final icon = GoalIconCatalog.byKey(goal.iconKey).icon;
    return InkWell(
      onTap: () => context.push('/goal/${goal.id}'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: palette.shadowLow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 22, color: majorColor),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name, style: theme.textTheme.bodyL),
                  const SizedBox(height: AppSpace.s2),
                  Container(
                    height: 6,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: rate.fraction ?? 0,
                      child: Container(color: majorColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Text(
              '${rate.metDays}/${rate.expectedDays}',
              style: theme.textTheme.bodyS.copyWith(
                color: palette.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// 空周引导（冻结稿画板③ .empty）：96px surfaceAlt 圆底图形 + 标题
/// + 双行引导语；叠加「新建目标」CTA 直达编辑器（FR-007/SC-004
/// ≤1 交互——冻结稿文案不带钮，验收契约要求保留动线）。
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Column(
      key: const ValueKey('reviewEmptyState'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpace.s8),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surfaceAlt,
          ),
          child: Icon(
            Icons.history_edu,
            size: 40,
            color: palette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.s3),
        Text(Copy.reviewEmptyTitle, style: Theme.of(context).textTheme.titleM),
        const SizedBox(height: AppSpace.s3),
        Text(
          Copy.reviewEmptySub,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyM
              .copyWith(color: palette.onSurfaceVariant, height: 1.7),
        ),
        const SizedBox(height: AppSpace.s3),
        FilledButton.icon(
          key: const ValueKey('reviewEmptyCta'),
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: palette.accentOn,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s6,
              vertical: AppSpace.s2,
            ),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            Copy.todayNewGoal,
            style: Theme.of(context).textTheme.titleS,
          ),
        ),
      ],
    );
  }
}
