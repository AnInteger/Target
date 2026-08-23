/// 周回顾页 v2（004 US5 · v2-review.html 冻结稿）。
///
/// 纯回看实时派生（不读 WeeklyReviews 快照，T027 引擎三法）：本周概览
/// = 周平均完成率（活跃池 Σ留痕日/Σ应记日）+ 上周环比 + 72px 均分环；
/// 顶部 ‹ 周 › 切换（前瞻钳制在包含今日的周——未来周无可回看）；
/// 右上日历钮为「选择周期」占位（后续版本）。每日活动七天点阵与
/// 本周目标卡随 T029 落地；空周引导暂沿 003 形态（T029 换 v2 画板）。
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

    // 该周存在应记目标（守护面）→ 概览出数；否则让位空态引导
    //（003 形态过渡，T029 换 v2 空周画板）。
    final hasGuarded = goals.any(
      (g) => stats.weekRateOf(g.id, week).expectedDays > 0,
    );

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
            if (!hasGuarded)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s8),
                child: _EmptyState(
                  onCreate: () => context.push('/goal-editor'),
                ),
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
      child: InkWell(
        key: ValueKey(key),
        onTap: onTap,
        customBorder: const CircleBorder(),
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

/// 空态（003 形态过渡，T029 换 v2 空周画板）：七格空圈节奏条
///（末格虚线 accent = 将开始的那天）+ 引导文案 + 「新建目标」CTA
/// 直达编辑器（≤1 交互，today 分支页签不退场）。
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
                        foregroundPainter: _DashedCirclePainter(
                          color: palette.accent,
                        ),
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
      ..addOval(
        Rect.fromCircle(
          center: size.center(Offset.zero),
          radius: size.width / 2 - strokeWidth / 2,
        ),
      );
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
