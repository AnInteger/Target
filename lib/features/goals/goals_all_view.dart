/// GoalsAllPage · 全部目标（004 T023，v2-goals-all.html 冻结稿全量）。
///
/// 顶栏（返回圆钮 + 标题 + 计数 + 新建胶囊 → /goal-editor）+ 筛选
/// chips 单选（全部 + 十小类带大类色点；选中反色，深色描边态）；
/// 「全部」视图按三大类分组（组头色点 + 计数），筛选视图平铺；
/// 卡 = 大类色图标格 + 名称 + 状态/类型徽章（已暂停琥珀 / 已达成
/// 青柠）+ 摘要行（连续/倒计时·进度/达成照面/历史条数，口径同详情
/// meta 胶囊）+ 短期进度条；整卡进详情，长按上滑管理菜单（编辑/
/// 暂停恢复/删除走二次确认，003 管理职能全承）；筛选空态引导。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/page_top_bar.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../../core/stats/stats_engine.dart';
import 'goal_lifecycle.dart';

class GoalsAllPage extends ConsumerStatefulWidget {
  const GoalsAllPage({super.key});

  @override
  ConsumerState<GoalsAllPage> createState() => _GoalsAllPageState();
}

class _GoalsAllPageState extends ConsumerState<GoalsAllPage> {
  /// 单选筛选（null = 全部，冻结稿 chips 单选）。
  GoalIconDomain? _filter;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final goalsAsync = ref.watch(goalsProvider);
    final stats = ref.watch(statsProvider);
    if (!goalsAsync.hasValue || stats == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: CircularProgressIndicator(color: palette.accent)),
      );
    }
    final goals = goalsAsync.value!;
    final today = ref.watch(todayProvider);
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];
    // 暂停卡摘要 = 历史有效记录条数（口径同通知/详情历史）。
    final historyByGoal = <String, int>{};
    for (final c in checkIns) {
      if (!c.isValid) continue;
      historyByGoal[c.goalId] = (historyByGoal[c.goalId] ?? 0) + 1;
    }

    final shown = _filter == null
        ? goals
        : goals
              .where((g) => GoalIconCatalog.byKey(g.iconKey).domain == _filter)
              .toList();

    return Scaffold(
      // root 级 push 页：转场结束后下层 shell 路由不再绘制，透明底会
      // 露出原始画布（iOS 黑屏感）——按「我的/设置」同口径铺实底
      // （2026-08-25 修复「查看全部大面积黑色」）。
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 005 T008：共享次级顶栏（原手写 _TopBar 退役，D5 同构）。
            PageTopBar(
              title: Copy.goalsAllTitle,
              titleAccessory: Text(
                '${shown.length}',
                key: const ValueKey('goalsAllCount'),
                style: Theme.of(context).textTheme.bodyS.copyWith(
                  color: TargetPalette.of(context).onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              trailing: _NewCapsule(onTap: () => context.push('/goal-editor')),
            ),
            _FilterRow(
              selected: _filter,
              onSelect: (domain) => setState(() => _filter = domain),
            ),
            Expanded(
              // 004 T023：列表挂 key——本页出现两个可滚动件（横向筛选
              // 行 + 纵向列表），测试滚动需按 key 定位纵向 ListView。
              child: ListView(
                key: const ValueKey('goalsAllList'),
                // 005 D2：页缘=列表档 s4(16)（hero 两屏 24，分层基准）。
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s4,
                  0,
                  AppSpace.s4,
                  AppSpace.s6,
                ),
                children: [
                  if (shown.isEmpty)
                    _FilterEmpty(filter: _filter)
                  else if (_filter == null)
                    ..._groupedByMajor(shown, stats, today, historyByGoal)
                  else
                    ..._flat(shown, stats, today, historyByGoal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 「全部」视图：三大类分组（组头色点 + 计数），组内保持库序。
  List<Widget> _groupedByMajor(
    List<Goal> goals,
    StatsEvaluation stats,
    LocalDate today,
    Map<String, int> historyByGoal,
  ) {
    final items = <Widget>[];
    for (final major in MajorCategory.values) {
      final group = goals
          .where((g) => GoalIconCatalog.byKey(g.iconKey).domain.major == major)
          .toList();
      if (group.isEmpty) continue;
      if (items.isNotEmpty) {
        items.add(const SizedBox(height: AppSpace.s3 + AppSpace.s2));
      }
      items.add(_GroupHead(major: major, count: group.length));
      for (final goal in group) {
        items.add(const SizedBox(height: AppSpace.s3));
        items.add(
          _GoalCard(
            goal: goal,
            stats: stats,
            today: today,
            historyCount: historyByGoal[goal.id] ?? 0,
          ),
        );
      }
    }
    return items;
  }

  /// 筛选视图：平铺（无组头，冻结稿板 2）。
  List<Widget> _flat(
    List<Goal> goals,
    StatsEvaluation stats,
    LocalDate today,
    Map<String, int> historyByGoal,
  ) {
    final items = <Widget>[];
    for (final goal in goals) {
      if (items.isNotEmpty) items.add(const SizedBox(height: AppSpace.s3));
      items.add(
        _GoalCard(
          goal: goal,
          stats: stats,
          today: today,
          historyCount: historyByGoal[goal.id] ?? 0,
        ),
      );
    }
    return items;
  }
}

// 顶栏（005 T008 起共享 PageTopBar：返回 44 触达 + 标题 + 计数 +
// 新建胶囊；冻结稿 .ga-top 几何见 lib/app/page_top_bar.dart）。
// ---------------------------------------------------------------------------

/// 新建胶囊（冻结稿 .new）：surface 底 + divider 描边 + accent 加号
/// → /goal-editor。
class _NewCapsule extends StatelessWidget {
  const _NewCapsule({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return InkWell(
      key: const ValueKey('goalsAllNew'),
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.s2,
          horizontal: AppSpace.s4,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.divider),
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 14, color: palette.accent),
            const SizedBox(width: AppSpace.s1),
            Text(Copy.goalsNewCapsule, style: theme.textTheme.bodyM),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 筛选行（冻结稿 .filters）：横向滚动，chips 单选——未选 = surface 底 +
// divider 描边 + 大类色点；浅色选中 = 墨底反白 + 点反白；深色选中 =
// surface 底 + on-surface 描边（.fchip.on 深色覆写）。
// ---------------------------------------------------------------------------

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelect});

  final GoalIconDomain? selected;
  final void Function(GoalIconDomain? domain) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s4,
        AppSpace.s1,
        AppSpace.s4,
        AppSpace.s3,
      ),
      child: Row(
        children: [
          for (final (i, domain) in [
            null,
            ...GoalIconDomain.values,
          ].indexed) ...[
            if (i > 0) const SizedBox(width: AppSpace.s2),
            _FilterChip(
              domain: domain,
              selected: selected == domain,
              onTap: () => onSelect(domain),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.domain,
    required this.selected,
    required this.onTap,
  });

  /// null = 「全部」（无色点，冻结稿板 1）。
  final GoalIconDomain? domain;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final majorColor = domain == null
        ? null
        : MajorColors.byKey(domain!.major.name).of(context);
    // 选中反色：浅色墨底反白；深色 surface 底 + on-surface 描边。
    final background = selected && !isDark
        ? palette.onSurface
        : palette.surface;
    final foreground = selected && !isDark
        ? palette.surface
        : palette.onSurface;
    final border = selected
        ? isDark
              ? Border.all(color: palette.onSurface)
              : Border.all(color: Colors.transparent)
        : Border.all(color: palette.divider);
    final dotColor = selected
        ? (isDark ? palette.onSurface : palette.surface)
        : majorColor ?? palette.onSurfaceVariant;

    return InkWell(
      key: ValueKey('goalsAllFilter-${domain?.name ?? 'all'}'),
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.s2,
          horizontal: AppSpace.s4,
        ),
        decoration: BoxDecoration(
          color: background,
          border: border,
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              domain?.zhLabel ?? Copy.goalsFilterAll,
              style: theme.textTheme.bodyM.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 组头（冻结稿 .ghead）：10px 大类色点 + 类名 + 计数。
// ---------------------------------------------------------------------------

class _GroupHead extends StatelessWidget {
  const _GroupHead({required this.major, required this.count});

  final MajorCategory major;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MajorColors.byKey(major.name).of(context),
          ),
        ),
        const SizedBox(width: AppSpace.s2),
        Text(major.zhLabel, style: theme.textTheme.titleS),
        const SizedBox(width: AppSpace.s2),
        Text(
          '$count',
          style: theme.textTheme.bodyS.copyWith(
            color: palette.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 目标卡（冻结稿 .gcard）：44px 大类色图标格 + 名称 + 徽章 + 摘要行
// （+ 短期进度条）+ ›；整卡进详情，长按上滑管理菜单。
// ---------------------------------------------------------------------------

class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.goal,
    required this.stats,
    required this.today,
    required this.historyCount,
  });

  final Goal goal;
  final StatsEvaluation stats;
  final LocalDate today;
  final int historyCount;

  /// 摘要行（.r2，口径同详情 meta 胶囊的延展）：达成 = 完成日照面；
  /// 暂停 = 历史条数；短期 = 倒计时（· 已完成 N% 配进度条）；
  /// 习惯/长期 = 连击 → 今天已记录 → 还没有记录。
  String _aux(List<MilestoneStep>? steps) {
    switch (goal.status) {
      case GoalStatus.achieved:
        final at = goal.achievedAt;
        final day = at == null
            ? ''
            : '${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';
        return Copy.goalAchievedMeta(day);
      // archived 为 003 遗留态（004 已退役不可再达），按暂停口径呈现。
      case GoalStatus.paused:
      case GoalStatus.archived:
        return Copy.historyCountMeta(historyCount);
      case GoalStatus.active:
        if (goal.isShortTerm) {
          final countdown = Copy.deadlineCountdownMeta(
            goal.deadline!.differenceInDays(today),
          );
          if (steps == null || steps.isEmpty) return countdown;
          final done = steps.where((s) => s.isDone).length;
          final percent = (done * 100 / steps.length).round();
          return '$countdown · ${Copy.shortTermProgressMeta(percent)}';
        }
        final streak = stats.streakOf(goal.id);
        if (streak > 0) return Copy.streakMeta(streak);
        return stats.dayStatusOf(goal.id).done
            ? Copy.goalRecordedTodayMeta
            : Copy.todayLatestNone;
    }
  }

  Future<void> _showManageSheet(BuildContext context, WidgetRef ref) async {
    final palette = TargetPalette.of(context);
    final icon = GoalIconCatalog.byKey(goal.iconKey);
    final actions = <_SheetAction>[
      _SheetAction(
        actionKey: 'edit',
        icon: Icons.edit_outlined,
        label: Copy.goalEdit,
        hint: true,
        onTap: () => context.go('/goal-editor?id=${goal.id}'),
      ),
      if (goal.canTransitTo(GoalStatus.paused))
        _SheetAction(
          actionKey: 'pause',
          icon: Icons.pause_circle_outline,
          label: Copy.menuPauseGoal,
          onTap: () => pauseGoal(ref, goal),
        ),
      if (goal.canTransitTo(GoalStatus.active))
        _SheetAction(
          actionKey: 'resume',
          icon: Icons.play_circle_outline,
          label: Copy.goalResumeAction,
          onTap: () => resumeGoal(context, ref, goal),
        ),
      _SheetAction(
        actionKey: 'delete',
        icon: Icons.delete_outline,
        label: Copy.menuDeleteGoal,
        danger: true,
        onTap: () => _confirmDelete(context, ref),
      ),
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        key: const ValueKey('goalsAllManageSheet'),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
          boxShadow: palette.shadowHigh,
        ),
        // 本页为 root 级 push（无 dock）：底距 s4 + 真实安全区。
        padding: EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s3,
          AppSpace.s5,
          AppSpace.s4 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpace.s3),
              decoration: BoxDecoration(
                color: palette.divider,
                borderRadius: AppRadius.rFull,
              ),
            ),
            // caption（冻结稿 .cap）：图标 + 目标名。
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpace.s2,
                right: AppSpace.s2,
                bottom: AppSpace.s3,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: AppRadius.rMd,
                    ),
                    child: Icon(
                      icon.icon,
                      size: 20,
                      color: MajorColors.byKey(icon.domain.major.name)
                          .of(context),
                    ),
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
                ],
              ),
            ),
            for (final (i, a) in actions.indexed) ...[
              if (i > 0)
                Container(
                  height: 1,
                  width: double.infinity,
                  color: palette.divider,
                ),
              _SheetRow(
                actionKey: a.actionKey,
                goalId: goal.id,
                icon: a.icon,
                label: a.label,
                danger: a.danger,
                hint: a.hint,
                onTap: a.onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 删除二次确认（同详情 .dlg 双胶囊）：确认后物理级联删除，
  /// goalsProvider 流实时移出列表。
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const ValueKey('goalDeleteDialog'),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.rXl,
            boxShadow: palette.shadowHigh,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Copy.deleteConfirmTitle, style: theme.textTheme.titleS),
              const SizedBox(height: AppSpace.s3),
              Text(
                Copy.deleteConfirmBody(goal.name),
                style: theme.textTheme.bodyM.copyWith(
                  color: palette.onSurfaceVariant,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: AppSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      label: Copy.dialogCancel,
                      background: palette.surfaceAlt,
                      foreground: palette.onSurface,
                      onTap: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: _PillButton(
                      label: Copy.deleteConfirmYes,
                      background: palette.badge,
                      foreground: palette.badgeOn,
                      onTap: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    await ref.read(goalRepoProvider).deleteGoal(goal.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final icon = GoalIconCatalog.byKey(goal.iconKey);
    final majorColor = MajorColors.byKey(icon.domain.major.name).of(context);
    // 短期目标的里程碑进度（其余类型不查，避免无用流订阅）。
    final steps = goal.isShortTerm && goal.status == GoalStatus.active
        ? ref.watch(stepsProvider(goal.id)).value
        : null;
    final hasProgress = steps != null && steps.isNotEmpty;
    final aux = _aux(steps);

    return DecoratedBox(
      key: ValueKey('goalCard-${goal.id}'),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: palette.shadowLow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          // 004 T022 立下的行 key 契约：goalsAllRow-{id}（tap 进详情）。
          key: ValueKey('goalsAllRow-${goal.id}'),
          onTap: () => context.go('/goal/${goal.id}'),
          onLongPress: () => _showManageSheet(context, ref),
          borderRadius: AppRadius.rLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: AppRadius.rMd,
                  ),
                  child: Icon(icon.icon, size: 22, color: majorColor),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleS,
                            ),
                          ),
                          const SizedBox(width: AppSpace.s2),
                          _StatusBadge(goal: goal),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        aux,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyS.copyWith(
                          color: palette.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (hasProgress) ...[
                        const SizedBox(height: AppSpace.s2),
                        _ProgBar(
                          // 口径同详情里程碑卡：完成步数占比。
                          percent:
                              (steps.where((s) => s.isDone).length *
                                      100 /
                                      steps.length)
                                  .round(),
                          color: majorColor,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s3),
                Text(
                  '›',
                  style: theme.textTheme.bodyM.copyWith(
                    color: palette.onSurfaceVariant,
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

/// 徽章（冻结稿 .bdg）：状态优先——已暂停琥珀 / 已达成青柠；
/// 活跃 = 类型（习惯/短期/长期）。surfaceAlt 胶囊。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final (label, color) = switch (goal.status) {
      // archived（003 遗留态）按暂停口径呈现。
      GoalStatus.paused ||
      GoalStatus.archived => (Copy.goalStatusPausedSuffix, palette.warning),
      GoalStatus.achieved => (Copy.goalStatusAchievedSuffix, palette.positive),
      GoalStatus.active => (
        goal.isHabit
            ? Copy.typeBadgeHabit
            : goal.isShortTerm
            ? Copy.typeBadgeShortTerm
            : Copy.typeBadgeLongTerm,
        palette.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: 1),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelS.copyWith(color: color, height: 1),
      ),
    );
  }
}

/// 短期进度条（冻结稿 .prog）：6px 圆轨 + 大类色填充。
class _ProgBar extends StatelessWidget {
  const _ProgBar({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return ClipRRect(
      borderRadius: AppRadius.rFull,
      child: Container(
        height: 6,
        color: palette.surfaceAlt,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: percent / 100,
          child: Container(color: color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 筛选空态（冻结稿 .fempty）：88px 圆底图形 + 分类名明示 + 新建 CTA；
// 全库空（深链直达）复用今日页空态文案。
// ---------------------------------------------------------------------------

class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty({required this.filter});

  final GoalIconDomain? filter;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final global = filter == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceAlt,
            ),
            child: Icon(
              Icons.flag_outlined,
              size: 38,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          Text(
            global ? Copy.todayEmptyTitle : Copy.goalsFilterEmptyTitle,
            style: theme.textTheme.titleM,
          ),
          const SizedBox(height: AppSpace.s3),
          Text(
            global
                ? Copy.todayEmptyBody
                : Copy.goalsFilterEmptyBody(filter!.zhLabel),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyM.copyWith(
              color: palette.onSurfaceVariant,
              height: 1.7,
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.rFull,
              boxShadow: palette.shadowMid,
            ),
            child: Material(
              color: palette.accent,
              borderRadius: AppRadius.rFull,
              child: InkWell(
                key: const ValueKey('goalsAllEmptyCta'),
                onTap: () => context.push('/goal-editor'),
                borderRadius: AppRadius.rFull,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s6,
                    vertical: AppSpace.s3,
                  ),
                  child: Text(
                    Copy.todayNewGoal,
                    style: theme.textTheme.bodyL.copyWith(
                      color: palette.accentOn,
                    ),
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

// ---------------------------------------------------------------------------
// 管理菜单（冻结稿 .sheet .cap .menu）：caption = 目标图标 + 名称；
// 行先 pop sheet 再执行动作（同详情 _MenuRow 口径）；删除行 danger 红。
// ---------------------------------------------------------------------------

/// 管理动作描述（组装后交给 [_SheetRow] 渲染）。
class _SheetAction {
  const _SheetAction({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.hint = false,
  });

  final String actionKey;
  final IconData icon;
  final String label;
  final FutureOr<void> Function() onTap;
  final bool danger;
  final bool hint;
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.actionKey,
    required this.goalId,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.hint = false,
  });

  /// 行 key（goalsAllMenu-edit/pause/resume/delete——测试锚点）。
  final String actionKey;
  final String goalId;
  final IconData icon;
  final String label;
  final FutureOr<void> Function() onTap;
  final bool danger;

  /// 尾随 › 提示（冻结稿 .to，编辑行）。
  final bool hint;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final color = danger ? palette.badge : palette.onSurface;
    final iconColor = danger ? palette.badge : palette.onSurfaceVariant;
    return InkWell(
      key: ValueKey('goalAction-$actionKey-$goalId'),
      onTap: () async {
        Navigator.of(context).pop();
        await Future<void>.sync(onTap);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s2,
          vertical: AppSpace.s4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: AppSpace.s3),
            Text(label, style: theme.textTheme.bodyL.copyWith(color: color)),
            const Spacer(),
            if (hint)
              Text(
                '›',
                style: theme.textTheme.bodyS.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.rFull,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpace.s3,
            horizontal: AppSpace.s5,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyL
                  .copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
