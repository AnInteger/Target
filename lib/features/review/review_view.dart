/// 周回顾页（US4 · T021 R3 重写 · 2026-08-21 screen-review.html 定稿）。
///
/// 纯回看：周摘要（日期区间 + 留下 N 次记录 · M 个目标）+ 三态图例 +
/// 逐目标左右滑卡（签名元素 = 周节奏条：每天一格，实心有勾 / 空圈没
/// 记录 / 小点不适用）+ 近 4 周走势柱 + 一句观察语（只描述不建议）。
/// 决策动线（继续/调频/暂停/一句话/保存）按 R3 裁决全拆——结算与
/// WeeklyReview 实体保留在服务层做历史留痕，本屏不再写库。
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
import '../../core/stats/stats_engine.dart';

class ReviewView extends ConsumerStatefulWidget {
  const ReviewView({super.key});

  @override
  ConsumerState<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<ReviewView> {
  PageController? _pager;

  @override
  void dispose() {
    _pager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final week = today.weekStart.previous;
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

    // 上周已存在的习惯目标 + 有适用日的周统计。
    final cards = <_CardData>[];
    for (final g in goals) {
      if (g.createdAt.isAfter(week.sunday)) continue;
      final w = stats.weekStatOf(g.id, week);
      if (w.totalChecks == 0) continue; // 整周未动
      cards.add(_CardData(
        goal: g,
        stat: w,
        days: [for (var i = 0; i < 7; i++) stats.dayStatusOf(g.id, week.monday.addDays(i))],
        // 003 口径：四周留痕趋势（周留痕天数）。
        rates: [
          for (var i = 3; i >= 0; i--)
            stats.weekStatOf(g.id, week.addWeeks(-i)).metDays / 7,
        ],
      ));
    }
    final records = cards.fold<int>(0, (sum, c) => sum + c.stat.totalChecks);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FR-008 三屏标题带同构：左缘 padX、顶垫 titleTop、44px 带
            //（今日屏 st-top 基准，标题在带内垂直居中）。
            ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: AppScreen.titleBand),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppScreen.padX, AppScreen.titleTop, AppScreen.padX, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(Copy.reviewTitle,
                      key: const ValueKey('screenTitle'),
                      style: Theme.of(context).textTheme.displayS),
                ),
              ),
            ),
            if (cards.isEmpty)
              // 空态竖直居中（FR-007：非偏上卡框，标题以下导航以上取中）。
              Expanded(
                child: Center(
                  child: _EmptyState(
                      onCreate: () => context.go('/goal-editor')),
                ),
              )
            else
              Expanded(
                // 水平零内边距：pager 出血滑到屏缘，其余各行自带 s6。
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, AppSpace.s2, 0, AppSpace.s12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s6),
                      child: _WeekSummary(
                          week: week, records: records, goals: cards.length),
                    ),
                    const _Legend(),
                    SizedBox(
                      height: 204,
                      child: PageView.builder(
                        controller: _pager ??= PageController(),
                        itemCount: cards.length,
                        onPageChanged: (i) => setState(() {}),
                        itemBuilder: (_, i) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: AppSpace.s6),
                          child: _GoalReviewCard(cards[i]),
                        ),
                      ),
                    ),
                    _Dots(
                      cards: cards,
                      index:
                          _pager?.hasClients == true ? _pager!.page?.round() ?? 0 : 0,
                      onTap: (i) => _pager?.animateToPage(i,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 一张回顾卡的数据：目标 + 周统计 + 七天状态 + 近 4 周走势。
class _CardData {
  const _CardData({
    required this.goal,
    required this.stat,
    required this.days,
    required this.rates,
  });

  final Goal goal;
  final GoalWeekStat stat;
  final List<DayStatus> days;
  final List<double> rates;
}

/// 周摘要：日期区间 + 「留下 N 次记录 · M 个目标」。
class _WeekSummary extends StatelessWidget {
  const _WeekSummary({
    required this.week,
    required this.records,
    required this.goals,
  });

  final WeekStart week;
  final int records;
  final int goals;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${week.monday.month}月${week.monday.day}日'
            ' – ${week.sunday.month}月${week.sunday.day}日',
            style: Theme.of(context).textTheme.titleL,
          ),
          const SizedBox(height: 2),
          Text(
            Copy.reviewWeekSum(records, goals),
            style: Theme.of(context).textTheme.bodyM.copyWith(
                color: palette.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// 三态图例：实心 = 有记录 / 空圈 = 没记录 / 小点 = 不适用。
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final style = Theme.of(context)
        .textTheme
        .labelS
        .copyWith(color: palette.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s6 + AppSpace.s1, AppSpace.s2, AppSpace.s6, 0),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: palette.onSurface)),
          const SizedBox(width: 5),
          Text(Copy.reviewLegendRecorded, style: style),
          const SizedBox(width: AppSpace.s3),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.divider, width: 2)),
          ),
          const SizedBox(width: 5),
          Text(Copy.reviewLegendMissed, style: style),
          const SizedBox(width: AppSpace.s3),
          Container(
              width: 4,
              height: 4,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: palette.divider)),
          const SizedBox(width: 5),
          Text(Copy.reviewLegendNa, style: style),
        ],
      ),
    );
  }
}

/// 目标回顾卡：头行 + 周节奏条 + 近 4 周走势 + 观察语。
class _GoalReviewCard extends ConsumerWidget {
  const _GoalReviewCard(this.data);

  final _CardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final color = palette.accent;
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];
    final today = ref.watch(todayProvider);

    return Material(
      color: palette.glassCard,
      borderRadius: AppRadius.rLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rLg,
          border: Border.all(color: palette.glassBorder),
          boxShadow: palette.shadowLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _head(context, color, checkIns, today),
            const SizedBox(height: AppSpace.s3),
            _strip(context, color),
            const SizedBox(height: AppSpace.s3),
            _trend(context, color),
            const SizedBox(height: AppSpace.s3),
            _coach(context),
          ],
        ),
      ),
    );
  }

  /// 头行：40 图标 + 名称与「最近 · ××」+ 右上 N/M 天有记录。
  Widget _head(BuildContext context, Color color,
      List<CheckIn> checkIns, LocalDate today) {
    final palette = TargetPalette.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, borderRadius: AppRadius.rMd),
          child: Icon(GoalIcon.byKey(data.goal.iconKey).icon,
              size: 19, color: Colors.white),
        ),
        const SizedBox(width: AppSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleS,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.history, size: 12, color: palette.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _latestLabel(
                          checkIns
                              .where((c) => c.goalId == data.goal.id)
                              .toList(),
                          today),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyS
                          .copyWith(color: palette.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${data.stat.metDays}/7',
              style: Theme.of(context).textTheme.titleM.copyWith(
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 1),
            Text(
              Copy.goalsDaysRecorded,
              style: Theme.of(context)
                  .textTheme
                  .labelS
                  .copyWith(color: palette.onSurfaceVariant, height: 1),
            ),
          ],
        ),
      ],
    );
  }

  /// 签名元素 · 周节奏条：每天一格，26px 圆。
  Widget _strip(BuildContext context, Color color) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final (i, st) in data.days.indexed)
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: st.done ? color : null,
                    border: st.done
                        ? null
                        : Border.all(color: palette.divider, width: 2),
                  ),
                  child: st.done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.divider),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dayLabel(i),
                  style: Theme.of(context)
                      .textTheme
                      .labelS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 近 4 周走势：透明度阶梯柱（最新一根最实）。
  Widget _trend(BuildContext context, Color color) {
    const ladder = [.35, .55, .75, 1.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            Copy.reviewTrendCap,
            style: Theme.of(context).textTheme.labelS.copyWith(
                color: TargetPalette.of(context).onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpace.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, r) in data.rates.indexed)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                child: Container(
                  width: 13,
                  height: 4 + r * 17,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: ladder[i]),
                    borderRadius: AppRadius.rSm,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 观察语：三档，低档转警示色（只描述，不建议）。
  Widget _coach(BuildContext context) {
    final palette = TargetPalette.of(context);
    // 003 口径：观察语按周留痕天数分档（0 = 无一周整满）。
    final String coach;
    if (data.stat.metDays >= 6) {
      coach = Copy.reviewCoachAll;
    } else if (data.stat.metDays >= 3) {
      coach = Copy.reviewCoachOkay;
    } else {
      coach = Copy.reviewCoachLow;
    }
    final low = coach == Copy.reviewCoachLow;
    final tint = low ? palette.warning : palette.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.auto_awesome, size: 14, color: tint),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            coach,
            style: Theme.of(context)
                .textTheme
                .bodyS
                .copyWith(color: tint, height: 1.6),
          ),
        ),
      ],
    );
  }
}

/// 圆点指示器：6px，选中转目标色并放大（点按跳卡）。
class _Dots extends StatelessWidget {
  const _Dots({required this.cards, required this.index, required this.onTap});

  final List<_CardData> cards;
  final int index;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s2, bottom: AppSpace.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (i, _) in cards.indexed)
            GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 18,
                height: 14,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    width: i == index ? 8.4 : 6,
                    height: i == index ? 8.4 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index
                          ? palette.accent
                          : palette.divider,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 空态（003 FR-007 · 原型画板②）：竖直居中——七格空圈节奏条
/// （末格虚线 accent = 将开始的那天）+ 引导文案 + 「新建目标」CTA
/// 直达编辑器（≤1 交互，落 today 分支）。
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 7; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpace.s2),
                child: i == 6
                    ? CustomPaint(
                        foregroundPainter:
                            _DashedCirclePainter(color: palette.accent),
                        child: const SizedBox(width: 22, height: 22),
                      )
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.divider, width: 2),
                        ),
                      ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        Text(Copy.reviewEmptyTitle, style: Theme.of(context).textTheme.titleL),
        const SizedBox(height: AppSpace.s2),
        Text(
          Copy.reviewEmptySub,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyM.copyWith(
              color: palette.onSurfaceVariant, height: 1.7),
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
                horizontal: AppSpace.s6, vertical: AppSpace.s2),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: Text(Copy.todayNewGoal,
              style: Theme.of(context).textTheme.titleS),
        ),
      ],
    );
  }
}

/// 「今天 / 昨天 / N 天前」：最后一次有效记录的归属日
/// （与今日页最新记录行同一语义，003 口径收敛）。
String _latestLabel(List<CheckIn> mine, LocalDate today) {
  final valid = mine.where((c) => c.isValid).toList();
  if (valid.isEmpty) return Copy.todayLatestNone;
  valid.sort((a, b) => a.day != b.day
      ? a.day.compareTo(b.day)
      : a.createdAt.compareTo(b.createdAt));
  final gap = today.differenceInDays(valid.last.day);
  if (gap <= 0) return Copy.notifDayToday;
  if (gap == 1) return Copy.notifDayYesterday;
  return Copy.todayLatestDaysAgo(gap);
}

/// 周一至周日的单字标签（节奏条列头）。
String _dayLabel(int i) =>
    const ['一', '二', '三', '四', '五', '六', '日'][i];

/// 虚线圆描边（空态末格「将开始的那天」，accent 提示而非实体）。
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addOval(Rect.fromCircle(
          center: size.center(Offset.zero),
          radius: size.width / 2 - strokeWidth / 2));
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
