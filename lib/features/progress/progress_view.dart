import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import 'attention_goal_list.dart';
import 'progress_trend_card.dart';

class ProgressView extends ConsumerWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value;
    final snapshot = ref.watch(goalProgressProvider);
    if (goals == null || snapshot == null) {
      return Scaffold(
        backgroundColor: TargetPalette.of(context).background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      key: const ValueKey('progressPage'),
      backgroundColor: TargetPalette.of(context).background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '进展',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: ProgressTrendCard(snapshot: snapshot),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverToBoxAdapter(
                child: AttentionGoalList(
                  evaluation: snapshot.evaluation,
                  goals: goals,
                  onOpen: (goal) => context.push('/goal/${goal.id}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
