/// 周回顾页（US4 T038，FR-008 / research D11）：上周各目标完成率卡 +
/// 近 4 周趋势 + 补签透明 + 忙碌标注；反思输入；决策三选
/// （继续 / 调频下周生效 / 暂停）。展示实时重算，快照仅留痕。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';

class ReviewView extends ConsumerStatefulWidget {
  const ReviewView({super.key});

  @override
  ConsumerState<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<ReviewView> {
  final _note = TextEditingController();
  final _decisions = <String, ReviewDecision>{};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final week = today.weekStart.previous;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final stats = ref.watch(statsProvider);

    final cards = <Widget>[];
    for (final g in goals) {
      if (!g.isHabit || g.createdAt.isAfter(week.sunday)) continue;
      final w = stats?.weekStatOf(g.id, week);
      if (w == null || w.applicableDays == 0) continue;
      cards.add(_GoalReviewCard(
        goal: g,
        stat: w,
        rates: [
          for (var i = 3; i >= 0; i--)
            stats?.weekStatOf(g.id, week.addWeeks(-i)).completionRate ?? 0,
        ],
        decision: _decisions[g.id] ?? const ContinueDecision(),
        onDecision: (d) => setState(() => _decisions[g.id] = d),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text(Copy.reviewTitle)),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${week.monday.isoString} 起',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                if (cards.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(Copy.goalsEmpty),
                    ),
                  )
                else
                  ...cards,
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _note,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: Copy.reviewNoteHint,
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: cards.isEmpty ? null : _save,
                  child: Text(Copy.reviewSave),
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final settlement = ref.read(settlementServiceProvider);
    final today = ref.watch(todayProvider);
    // 幂等确保回顾行存在（快照仅留痕），再落决策与笔记。
    final review =
        await settlement.settleLastWeekIfNeeded(today: today, now: DateTime.now());
    ReviewDecision aggregate = const ContinueDecision();
    for (final e in _decisions.entries) {
      if (e.value is ContinueDecision) continue;
      await settlement.applyDecision(e.key, e.value, today: today);
      aggregate = e.value;
    }
    final note = _note.text.trim();
    await ref
        .read(reviewRepoProvider)
        .save(review.copyWith(note: note.isEmpty ? null : note, decision: aggregate));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(Copy.reviewSaved)));
      context.pop();
    }
  }
}

class _GoalReviewCard extends StatelessWidget {
  const _GoalReviewCard({
    required this.goal,
    required this.stat,
    required this.rates,
    required this.decision,
    required this.onDecision,
  });

  final Goal goal;
  final GoalWeekStat stat;
  final List<double?> rates;
  final ReviewDecision decision;
  final void Function(ReviewDecision) onDecision;

  @override
  Widget build(BuildContext context) {
    final color = GoalColor.byKey(goal.colorKey).of(context);
    final percent = ((stat.completionRate ?? 0) * 100).round();
    final struggling = percent < 50;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle),
                child:
                    Icon(GoalIcon.byKey(goal.iconKey).icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(goal.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(Copy.reviewCompletion(stat.completionRate ?? 0),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                          color: struggling
                              ? Theme.of(context).colorScheme.tertiary
                              : color,
                          fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stat.completionRate ?? 0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text(
                  '${Copy.reviewMetDays(stat.metDays, stat.applicableDays)}'
                  ' · ${Copy.reviewBackfills(stat.backfillCount)}',
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              if (stat.busyModeApplied) _tag(context, Copy.reviewBusyTag),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text(Copy.trendWeeks(4),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 8),
              SizedBox(
                height: 30,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final r in rates)
                      Container(
                        width: 10,
                        margin: const EdgeInsets.only(right: 4),
                        height: 6 + (r ?? 0) * 24,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25 + (r ?? 0) * 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
            if (struggling) ...[
              const SizedBox(height: 4),
              Text(Copy.reviewSuggestionLow,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary)),
            ],
            const SizedBox(height: 8),
            Text(Copy.reviewDecisionTitle,
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SegmentedButton<_Choice>(
              segments: const [
                ButtonSegment(
                    value: _Choice.continue_, label: Text(Copy.reviewDecisionContinue)),
                ButtonSegment(
                    value: _Choice.adjust, label: Text(Copy.reviewDecisionAdjust)),
                ButtonSegment(
                    value: _Choice.pause, label: Text(Copy.reviewDecisionPause)),
              ],
              selected: {_choiceOf(decision)},
              onSelectionChanged: (s) =>
                  onDecision(_decisionOf(s.first, decision)),
            ),
            if (decision is AdjustDecision) ...[
              const SizedBox(height: 4),
              Text(
                  '${(decision as AdjustDecision).newPattern} · ${Copy.reviewAdjustHint}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      );
}

enum _Choice { continue_, adjust, pause }

_Choice _choiceOf(ReviewDecision d) => switch (d) {
      ContinueDecision() => _Choice.continue_,
      AdjustDecision() => _Choice.adjust,
      PauseDecision() => _Choice.pause,
    };

ReviewDecision _decisionOf(_Choice c, ReviewDecision current) => switch (c) {
      _Choice.continue_ => const ContinueDecision(),
      _Choice.pause => const PauseDecision(),
      _Choice.adjust => current is AdjustDecision
          ? current
          : const AdjustDecision(DailyFrequency(1)),
    };
