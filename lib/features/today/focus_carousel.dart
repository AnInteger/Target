library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../../core/models/goal_progress.dart';

const double kFocusCardHeight = 286;

class FocusCarousel extends StatefulWidget {
  const FocusCarousel({
    super.key,
    required this.goals,
    required this.checkIns,
    required this.milestones,
    required this.scores,
    required this.today,
    required this.onRecord,
    required this.onOpenGoal,
  });

  final List<Goal> goals;
  final List<CheckIn> checkIns;
  final Map<String, List<MilestoneStep>> milestones;
  final Map<String, GoalScore> scores;
  final LocalDate today;
  final void Function(Goal goal, MilestoneStep? currentStep) onRecord;
  final void Function(Goal goal) onOpenGoal;

  @override
  State<FocusCarousel> createState() => _FocusCarouselState();
}

class _FocusCarouselState extends State<FocusCarousel> {
  PageController? _controller;
  PageController? _retired;
  double _fraction = -1;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    _retired?.dispose();
    super.dispose();
  }

  List<Goal> _ordered() {
    final latest = <String, DateTime>{};
    for (final check in widget.checkIns.where((check) => check.isValid)) {
      final old = latest[check.goalId];
      if (old == null || check.createdAt.isAfter(old)) {
        latest[check.goalId] = check.createdAt;
      }
    }
    final active = widget.goals
        .where((goal) => goal.status == GoalStatus.active)
        .toList();
    active.sort((a, b) {
      final aDate = latest[a.id] ?? a.createdAt.atStartOfDay;
      final bDate = latest[b.id] ?? b.createdAt.atStartOfDay;
      final order = bDate.compareTo(aDate);
      return order == 0 ? a.name.compareTo(b.name) : order;
    });
    return active;
  }

  @override
  Widget build(BuildContext context) {
    final goals = _ordered();
    if (goals.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fraction = width > 64 ? (width - 40) / width : 1.0;
        final page = _page.clamp(0, goals.length - 1);
        if (_controller == null || (_fraction - fraction).abs() > .001) {
          _retired = _controller;
          _controller = PageController(
            viewportFraction: fraction,
            initialPage: page,
          );
          _fraction = fraction;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _retired?.dispose();
            _retired = null;
          });
        }
        return Column(
          children: [
            SizedBox(
              height: kFocusCardHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: goals.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final steps = widget.milestones[goal.id] ?? const [];
                  final open = steps.where((step) => !step.isDone).firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: _FocusCard(
                      goal: goal,
                      steps: steps,
                      score: widget.scores[goal.id],
                      today: widget.today,
                      onRecord: () => widget.onRecord(goal, open),
                      onOpen: () => widget.onOpenGoal(goal),
                    ),
                  );
                },
              ),
            ),
            if (goals.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  key: const ValueKey('focusDots'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (index, _) in goals.indexed)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == page ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == page
                              ? TargetPalette.of(context).onSurface
                              : TargetPalette.of(context).divider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.goal,
    required this.steps,
    required this.score,
    required this.today,
    required this.onRecord,
    required this.onOpen,
  });

  final Goal goal;
  final List<MilestoneStep> steps;
  final GoalScore? score;
  final LocalDate today;
  final VoidCallback onRecord;
  final VoidCallback onOpen;

  String get _typeLabel => switch (goal.goalType) {
    GoalType.longTerm => '长期目标',
    GoalType.shortTerm => '短期目标',
    GoalType.habit => '习惯',
  };

  String get _statusLabel => switch (score?.band) {
    ScoreBand.stable => '稳定推进',
    ScoreBand.calibrate => '需要校准',
    ScoreBand.adjust => '优先调整',
    ScoreBand.replan => '建议重规划',
    null => '进行中',
  };

  String get _dateLabel {
    if (goal.deadline != null) {
      final days = goal.deadline!.differenceInDays(today);
      return days < 0 ? '已逾期 ${-days} 天' : '剩余 $days 天';
    }
    if (goal.targetDate != null) return '目标日 ${goal.targetDate!.isoString}';
    return '每 ${goal.progressCadenceDays} 天检查进展';
  }

  MilestoneStep? get _latestDone {
    final done = steps.where((step) => step.isDone).toList()
      ..sort(
        (a, b) => (b.doneAt ?? DateTime(0)).compareTo(a.doneAt ?? DateTime(0)),
      );
    return done.firstOrNull;
  }

  MilestoneStep? get _next => steps.where((step) => !step.isDone).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final gradient = MajorGradients.byKey(goal.major.name);
    const white = Colors.white;
    return Semantics(
      button: true,
      label: '${goal.name}，$_statusLabel',
      child: Material(
        key: ValueKey('focusCard-${goal.id}'),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradient.a.of(context), gradient.b.of(context)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: palette.shadowMid,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_typeLabel · $_dateLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: white.withValues(alpha: .84),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        GoalIconCatalog.byKey(goal.iconKey).icon,
                        color: white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  goal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _MilestoneLine(
                  label: '最新进展',
                  value: _latestDone?.title ?? '还没有完成的里程碑',
                  color: white,
                ),
                const SizedBox(height: 7),
                _MilestoneLine(
                  label: '下一步',
                  value: _next?.title ?? '待确认下一步计划',
                  color: white,
                ),
                const Spacer(),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onRecord,
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      label: const Text('记录进展'),
                      style: FilledButton.styleFrom(
                        backgroundColor: white,
                        foregroundColor: kFocusGoInk,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${goal.progressCadenceDays} 天节奏',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: white.withValues(alpha: .82),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneLine extends StatelessWidget {
  const _MilestoneLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 58,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: color.withValues(alpha: .7)),
        ),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    ],
  );
}
