/// GoalsView（T017 R2 返工 · 2026-08-21 screen-goals.html R2 通过定稿）。
///
/// 列表说「这目标最近怎么样」：卡 = 图标 + 名称 + 本周节奏数
/// （N/M 天有记录，努力语言）+ 为什么第二行（无则虚线胶囊邀请）+
/// 元行（场景 chip + 最近一次记录）；每日打卡进度归今日屏。
/// 顶下小结行汇总「N 个目标 · 本周留下 M 次记录」；暂停区 = 虚线行 +
/// 恢复；空态 = 提问 + 模板一句话 + 写一句自己的。长按进生命周期动作。
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
import 'goal_lifecycle.dart';
import 'goal_templates.dart';

class GoalsView extends ConsumerWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final stats = ref.watch(statsProvider);
    if (!goalsAsync.hasValue || stats == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: TargetPalette.of(context).accent,
          ),
        ),
      );
    }
    final goals = goalsAsync.value!;
    final today = ref.watch(todayProvider);
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];
    final active = goals.where((g) => g.status == GoalStatus.active).toList();
    final paused = goals.where((g) => g.status == GoalStatus.paused).toList();
    final closed = goals
        .where((g) =>
            g.status == GoalStatus.archived || g.status == GoalStatus.achieved)
        .toList();
    // 本周全目标有效记录数（小结行）。
    final weekRecords = checkIns
        .where((c) => c.isValid && !c.day.isBefore(today.weekStart.monday))
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.s6, AppSpace.s2, AppSpace.s6, AppSpace.s12),
          children: [
            _TopBar(),
            if (goals.isEmpty) ...[
              const SizedBox(height: AppSpace.s8),
              _EmptyBoard(),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(
                    left: AppSpace.s1, top: AppSpace.s2, bottom: AppSpace.s1),
                child: Text(
                  Copy.goalsSum(active.length, weekRecords),
                  style: Theme.of(context).textTheme.bodyM.copyWith(
                      color: TargetPalette.of(context).onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              for (final g in active) _GoalCard(goal: g),
              if (paused.isNotEmpty) ...[
                _SectionHeader(text: Copy.goalsPausedHeader),
                for (final g in paused) _PausedRow(goal: g),
              ],
              if (closed.isNotEmpty)
                ExpansionTile(
                  title: Text(Copy.goalsClosedHeader,
                      style: Theme.of(context).textTheme.labelS.copyWith(
                          letterSpacing: 0.9,
                          color: TargetPalette.of(context).onSurfaceVariant)),
                  initiallyExpanded: false,
                  children: [for (final g in closed) _GoalCard(goal: g)],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 顶栏：页题「目标」+ 新建胶囊（accent 实心）。
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s2, bottom: AppSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(Copy.goalsTitle,
                style: Theme.of(context).textTheme.displayS),
          ),
          InkWell(
            onTap: () => context.push('/goal-editor'),
            borderRadius: AppRadius.rFull,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s4, vertical: AppSpace.s2),
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: AppRadius.rFull,
                boxShadow: palette.shadowMid,
              ),
              child: Row(
                children: [
                  Icon(Icons.add, size: 14, color: palette.accentOn),
                  const SizedBox(width: AppSpace.s2),
                  Text(Copy.goalsNew,
                      style: Theme.of(context).textTheme.bodyM.copyWith(
                          color: palette.accentOn,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分节小标（已暂停/已结束）：labelS + 字距。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpace.s1, top: AppSpace.s2, bottom: AppSpace.s1),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelS.copyWith(
            letterSpacing: 0.9,
            color: TargetPalette.of(context).onSurfaceVariant),
      ),
    );
  }
}

/// 目标卡：图标 + 名称 + 本周节奏数 / 为什么（或虚线邀请）/ 元行。
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final today = ref.watch(todayProvider);
    final checkIns =
        ref.watch(checkInsProvider).value ?? const <CheckIn>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Material(
        color: palette.glassCard,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          // 点卡片 = 编辑/渐进补全（空为什么由此补一句）。
          onTap: () => context.push('/goal-editor?id=${goal.id}'),
          onLongPress: () => showGoalActions(context, ref, goal),
          borderRadius: AppRadius.rLg,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s4),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: palette.divider),
              boxShadow: palette.shadowLow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: AppRadius.rMd,
                      ),
                      child: Icon(GoalIcon.byKey(goal.iconKey).icon,
                          size: 19, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleS,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s2),
                    _RatioTrailing(goal: goal),
                  ],
                ),
                const SizedBox(height: AppSpace.s2),
                _whyLine(context),
                const SizedBox(height: AppSpace.s2),
                _metaRow(
                  context,
                  latest: _latestLabel(
                      checkIns.where((c) => c.goalId == goal.id).toList(),
                      today),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 第二行「为什么」：有则一句带出；无则虚线胶囊邀请（渐进补全）。
  Widget _whyLine(BuildContext context) {
    final palette = TargetPalette.of(context);
    final why = goal.motivation;
    if (why == null || why.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: CustomPaint(
          foregroundPainter: _DashedRRectPainter(
              color: palette.divider, radius: 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s2, vertical: 2),
            child: Text(
              Copy.goalsInviteWhy,
              style: Theme.of(context)
                  .textTheme
                  .bodyS
                  .copyWith(color: palette.onSurfaceVariant),
            ),
          ),
        ),
      );
    }
    return Text(
      why,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context)
          .textTheme
          .bodyS
          .copyWith(color: palette.onSurfaceVariant),
    );
  }

  /// 元行：场景 chip（有则）+ 右侧「最近 · ×××」。
  Widget _metaRow(BuildContext context, {required String latest}) {
    final palette = TargetPalette.of(context);
    final scene = goal.cueScene;
    final hasScene = scene != null && scene.isNotEmpty;
    return Row(
      children: [
        if (hasScene) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s2, vertical: 1),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: AppRadius.rFull,
              border: Border.all(color: palette.divider),
            ),
            child: Text(
              scene,
              style: Theme.of(context)
                  .textTheme
                  .labelS
                  .copyWith(color: palette.onSurfaceVariant),
            ),
          ),
          const Spacer(),
        ],
        Flexible(
          child: Row(
            mainAxisAlignment:
                hasScene ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(Icons.history, size: 12, color: palette.onSurfaceVariant),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  latest,
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
        ),
      ],
    );
  }
}

/// 「最近 · 今天 / 昨天 / N 天前」：最后一次有效记录的归属日。
String _latestLabel(List<CheckIn> mine, LocalDate today) {
  final valid = mine.where((c) => c.isValid).toList();
  if (valid.isEmpty) return Copy.todayLatestNone;
  valid.sort((a, b) => a.day != b.day
      ? a.day.compareTo(b.day)
      : a.createdAt.compareTo(b.createdAt));
  final gap = today.differenceInDays(valid.last.day);
  if (gap <= 0) return Copy.todayLatestToday;
  if (gap == 1) return Copy.todayLatestYesterday;
  return Copy.todayLatestDaysAgo(gap);
}

/// 右上角本周节奏数：habit = N/M 天有记录（tnum）；里程碑 = 步骤或截止。
class _RatioTrailing extends ConsumerWidget {
  const _RatioTrailing({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final today = ref.watch(todayProvider);

    String big;
    String small;
    if (goal.isMilestone) {
      final steps = ref.watch(stepsProvider(goal.id)).value;
      if (steps != null && steps.isNotEmpty) {
        big = '${steps.where((s) => s.isDone).length}/${steps.length}';
        small = Copy.goalsStepsDone;
      } else if (goal.deadline
          case LocalDate d) {
        big = d.year == today.year
            ? '${d.month}/${d.day}'
            : '${d.year}/${d.month}/${d.day}';
        small = Copy.goalsDeadlineLabel;
      } else {
        big = '—';
        small = Copy.goalsOnceShort;
      }
    } else {
      final stats = ref.watch(statsProvider);
      final rate = stats?.weekStatOf(goal.id, today.weekStart);
      if (rate == null || rate.applicableDays == 0) {
        big = '—';
        small = Copy.reviewNoApplicableDays;
      } else {
        big = '${rate.metDays}/${rate.applicableDays}';
        small = Copy.goalsDaysRecorded;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          big,
          style: Theme.of(context).textTheme.titleM.copyWith(
              color: palette.onSurface,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 3),
        Text(
          small,
          style: Theme.of(context)
              .textTheme
              .labelS
              .copyWith(color: palette.onSurfaceVariant, height: 1),
        ),
      ],
    );
  }
}

/// 暂停行：虚线包裹 + 32px 图标 + 名与说明两行 + 恢复胶囊。
class _PausedRow extends ConsumerWidget {
  const _PausedRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Opacity(
        opacity: .75,
        child: CustomPaint(
          foregroundPainter: _DashedRRectPainter(
              color: palette.divider, radius: AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s4, vertical: AppSpace.s3),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GoalColor.byKey(goal.colorKey).of(context),
                    borderRadius: AppRadius.rMd,
                  ),
                  child: Icon(GoalIcon.byKey(goal.iconKey).icon,
                      size: 15, color: Colors.white),
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
                        style: Theme.of(context).textTheme.bodyL,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Copy.goalsPausedNote,
                        style: Theme.of(context)
                            .textTheme
                            .bodyS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => resumeGoal(context, ref, goal),
                  borderRadius: AppRadius.rFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s3, vertical: AppSpace.s1),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadius.rFull,
                      border: Border.all(color: palette.divider),
                    ),
                    child: Text(
                      Copy.goalsResume,
                      style: Theme.of(context).textTheme.bodyS,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 空态：提问 + 模板一句话（chip）+ 写一句自己的（screen-goals.html ②）。
class _EmptyBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
          color: palette.divider, radius: AppRadius.xl, strokeWidth: 1.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s6, vertical: AppSpace.s8),
        child: Column(
          children: [
            Text(Copy.goalsEmptyTitle,
                style: Theme.of(context).textTheme.titleM),
            const SizedBox(height: AppSpace.s3),
            Text(
              Copy.goalsEmptySub,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyM
                  .copyWith(color: palette.onSurfaceVariant, height: 1.8),
            ),
            const SizedBox(height: AppSpace.s4),
            Wrap(
              spacing: AppSpace.s2,
              runSpacing: AppSpace.s2,
              alignment: WrapAlignment.center,
              children: [
                for (final t in kAllTemplates)
                  _TemplateChip(template: t),
              ],
            ),
            const SizedBox(height: AppSpace.s4),
            InkWell(
              onTap: () => context.push('/goal-editor'),
              borderRadius: AppRadius.rMd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s8, vertical: AppSpace.s4),
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: AppRadius.rMd,
                  boxShadow: palette.shadowMid,
                ),
                child: Text(
                  Copy.goalsEmptyOwn,
                  style: Theme.of(context).textTheme.titleS.copyWith(
                      color: palette.accentOn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 模板胶囊：26px 色点图标 + 一句话（进编辑器并预填模板）。
class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.template});

  final GoalTemplate template;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return InkWell(
      onTap: () => context.push('/goal-editor', extra: template),
      borderRadius: AppRadius.rFull,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.s2, AppSpace.s2, AppSpace.s4, AppSpace.s2),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.rFull,
          border: Border.all(color: palette.divider),
          boxShadow: palette.shadowLow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GoalColor.byKey(template.colorKey).of(context),
              ),
              child: Icon(GoalIcon.byKey(template.iconKey).icon,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: AppSpace.s2),
            Text(template.name, style: Theme.of(context).textTheme.bodyM),
          ],
        ),
      ),
    );
  }
}

/// 虚线圆角容器描边（胶囊 radius 50 即跑道形）。
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.2,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    const dash = 6.0, gap = 5.0;
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
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
