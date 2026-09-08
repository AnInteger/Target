/// v3 目标页（tab 1）：置顶大卡（两栏）+ 其他目标列表 + 空态 +
/// 长按管理菜单 + 编辑置顶模式（R1–R3 定稿）。
/// v3.1：Cupertino 组件重写（CircleIconButton / CupertinoButton.filled /
/// CupertinoActivityIndicator）。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../shared/goal_card.dart';
import 'edit_pinned_sheet.dart';
import 'goal_menu.dart';

class GoalsView extends ConsumerStatefulWidget {
  const GoalsView({super.key});

  @override
  ConsumerState<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends ConsumerState<GoalsView> {
  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final goalsAsync = ref.watch(goalsProvider);
    final records = ref.watch(recordsProvider).value ?? const <ProgressRecord>[];
    final milestones =
        ref.watch(milestonesProvider).value ?? const <Milestone>[];
    final today = ref.watch(todayProvider);

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
        minimum: const EdgeInsets.only(top: 12),
        child: goalsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (goals) {
            if (goals.isEmpty) {
              return Column(
                children: [
                  _Header(onCreate: _openEditor),
                  Expanded(child: _EmptyState(onCreate: _openEditor)),
                ],
              );
            }
            final pinned =
                goals.where((g) => g.pinned).toList(growable: false);
            final others =
                goals.where((g) => !g.pinned).toList(growable: false);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(onCreate: _openEditor)),
                if (pinned.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: Copy.pinnedSection,
                      trailing: Copy.pinnedEdit,
                      onTrailing: () => showEditPinned(context),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverList.builder(
                    itemCount: pinned.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(bottom: i == pinned.length - 1 ? 0 : 12),
                      child: GoalCard(
                        goal: pinned[i],
                        records: records,
                        milestones: milestones,
                        today: today,
                        onTap: () => context.push('/goal/${pinned[i].id}'),
                        onLongPress: () =>
                            showGoalMenu(context, ref, pinned[i]),
                      ),
                    ),
                  ),
                ),
                if (others.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionHeader(title: Copy.othersSection),
                  ),
                if (others.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    sliver: SliverList.builder(
                      itemCount: others.length,
                      itemBuilder: (_, i) => OthersRow(
                        goal: others[i],
                        records: records,
                        today: today,
                        onTap: () => context.push('/goal/${others[i].id}'),
                        onLongPress: () =>
                            showGoalMenu(context, ref, others[i]),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openEditor() => context.push('/goal-editor');
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Copy.goalsTitle, style: text.displayL),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CircleIconButton(
            icon: CupertinoIcons.add,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.onTrailing});

  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 4, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: text.titleS),
          ),
          if (trailing != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.square(32),
              onPressed: onTrailing,
              child: Text(
                trailing!,
                style: text.bodyM.copyWith(color: p.accentText),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: p.divider, width: 0.5),
            ),
            child: Icon(CupertinoIcons.scope, size: 36, color: p.accent),
          ),
          const SizedBox(height: 12),
          Text(Copy.goalsEmptyTitle, style: text.titleM),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              Copy.goalsEmptyBody,
              textAlign: TextAlign.center,
              style: text.bodyM.copyWith(color: p.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: onCreate,
            child: Text(Copy.goalsEmptyCta),
          ),
        ],
      ),
    );
  }
}
