/// 目标详情页（003 T021 管理动线 → 004 T014 按冻结稿 v2-goal-detail 换装）。
///
/// 全屏 push 无底部页签；顶栏 = 返回 + 「目标详情」+「⋯」更多。身份区
/// hero 随三大类变色（icon/徽章/meta 点），meta 胶囊：习惯/长期 = 连续/
/// 本周/提醒摘要，短期 = 倒计时 + 截止日；今日记录卡 = 选填一句话 +
/// accent 打卡主按钮 + 近 7 天点阵（对勾完成、虚线补签，点过去日开
/// 补签弹层：14 天窗口日历单选）；历史记录含「补签」标记；短期另有
/// 里程碑卡（进度百分比 + 勾选/删除/添加）与 标记达成/续期 常驻行；
/// 暂停/恢复/删除收纳「⋯」菜单，删除二次确认后物理级联删除
/// （FR-016 全能力零丢失）。
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
import 'day_records_sheet.dart';
import 'goal_lifecycle.dart';
import 'progress_record_sheet.dart';
import 'goal_type_badge.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value;
    if (goals == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(Copy.goalMissing)));
        context.go('/today');
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final reminderRow = reminders.where((r) => r.goalId == goalId).firstOrNull;
    final steps =
        ref.watch(stepsProvider(goalId)).value ?? const <MilestoneStep>[];
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];
    final today = ref.watch(todayProvider);
    final mine =
        checkIns.where((c) => c.goalId == goal.id && c.isValid).toList()..sort(
          (a, b) => a.day != b.day
              ? b.day.compareTo(a.day)
              : b.createdAt.compareTo(a.createdAt),
        );
    final days = goal.deadline?.differenceInDays(today) ?? 0;
    final active = goal.status == GoalStatus.active;
    final icon = GoalIconCatalog.byKey(goal.iconKey);
    final majorColor = MajorColors.byKey(icon.domain.major.name).of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 005 T008：共享次级顶栏（原手写 _TopBar 退役，D5 同构；
            // ⋯ 菜单钮入 trailing 槽）。
            PageTopBar(
              title: Copy.goalDetailTitle,
              trailing: _CircleButton(
                icon: Icons.more_vert,
                iconSize: 20,
                tooltip: Copy.goalMoreActions,
                onTap: () => _showMenu(context, ref, goal),
              ),
            ),
            Expanded(
              child: ListView(
                // 005 D2：页缘=列表档 s4(16) 对称（原左 s2/右 s5 偏离
                // 冻结稿 .dt-list 对称 20，随分层基准一并归直）。
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s4,
                  AppSpace.s2,
                  AppSpace.s4,
                  AppSpace.s5,
                ),
                children: [
                  if (goal.status == GoalStatus.paused)
                    _PausedBanner(
                      onResume: () => resumeGoal(context, ref, goal),
                    ),
                  _HeroCard(
                    goal: goal,
                    today: today,
                    reminderRow: reminderRow,
                    mine: mine,
                    days: days,
                    dimmed: !active,
                    majorColor: majorColor,
                  ),
                  if (active) ...[
                    const SizedBox(height: AppSpace.s4),
                    _TodayCard(
                      goal: goal,
                      currentStep: steps
                          .where((step) => !step.isDone)
                          .firstOrNull,
                      mine: mine,
                      today: today,
                    ),
                  ],
                  if (goal.isShortTerm) ...[
                    const SizedBox(height: AppSpace.s4),
                    _MilestoneCard(
                      goalId: goal.id,
                      steps: steps,
                      majorColor: majorColor,
                    ),
                  ],
                  if (active) ...[
                    const SizedBox(height: AppSpace.s4),
                    _ActionRowsCard(
                      goal: goal,
                      days: days,
                      onRenew: () => _postpone(context, ref, goal),
                      onAchieve: () => _achieveAndPop(context, ref, goal),
                    ),
                  ],
                  if (mine.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.s4),
                    _HistoryCard(items: mine),
                  ],
                  if (!active) ...[
                    const SizedBox(height: AppSpace.s2),
                    _DeleteLineButton(
                      onTap: () => _confirmDelete(context, ref, goal),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 动作编排 ----

  Future<void> _achieveAndPop(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    await achieveGoal(ref, goal);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(Copy.milestoneDone)));
      context.go('/today');
    }
  }

  /// 温和续期（D4）：新截止日自选，立即生效；超期目标锚定今天起选。
  Future<void> _postpone(BuildContext context, WidgetRef ref, Goal goal) async {
    final first = DateTime.now();
    final base = goal.deadline?.atStartOfDay ?? first;
    final picked = await showDatePicker(
      context: context,
      initialDate: base.isBefore(first) ? first : base,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    await ref
        .read(goalRepoProvider)
        .update(goal.copyWith(deadline: LocalDate.fromDateTime(picked)));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(Copy.milestonePostponed)));
    }
  }

  /// 「⋯」管理菜单（冻结稿板 4）：编辑 / 暂停(恢复) / 删除。
  Future<void> _showMenu(BuildContext context, WidgetRef ref, Goal goal) async {
    final palette = TargetPalette.of(context);
    final actions = <Widget>[
      _MenuRow(
        icon: Icons.edit_outlined,
        label: Copy.goalEdit,
        onTap: () => context.push('/goal-editor?id=${goal.id}'),
      ),
      if (goal.canTransitTo(GoalStatus.paused))
        _MenuRow(
          icon: Icons.pause_circle_outline,
          label: Copy.menuPauseGoal,
          onTap: () => pauseGoal(ref, goal),
        ),
      if (goal.canTransitTo(GoalStatus.active))
        _MenuRow(
          icon: Icons.play_circle_outline,
          label: Copy.goalResumeAction,
          onTap: () => resumeGoal(context, ref, goal),
        ),
      _MenuRow(
        icon: Icons.delete_outline,
        label: Copy.menuDeleteGoal,
        danger: true,
        onTap: () => _confirmDelete(context, ref, goal),
      ),
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        key: const ValueKey('goalMenuSheet'),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
          boxShadow: palette.shadowHigh,
        ),
        // 005 留档：底距 s5+8 为弹层 home 避让裸算式（垂直底距非
        // 本轮页缘口径，不强行刻度化）。
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s3,
          AppSpace.s5,
          AppSpace.s5 + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 抓手条（冻结稿 .grab）。
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpace.s3),
              decoration: BoxDecoration(
                color: palette.divider,
                borderRadius: AppRadius.rFull,
              ),
            ),
            for (final (i, a) in actions.indexed) ...[
              if (i > 0)
                Container(
                  height: 1,
                  width: double.infinity,
                  color: palette.divider,
                ),
              a,
            ],
          ],
        ),
      ),
    );
  }

  /// 删除二次确认（冻结稿 .dlg）：居中对话框 + 双胶囊按钮；确认后
  /// 物理级联删除（打卡/步骤/提醒/频率版本）并退出详情。
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
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
    if (context.mounted) context.go('/today');
  }
}

/// 38px 圆钮（冻结稿 .dt-btn）：surface 底 + divider 描边 + 低影。
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 20,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final button = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(color: palette.divider),
        boxShadow: palette.shadowLow,
      ),
      child: Icon(icon, size: iconSize, color: palette.onSurface),
    );
    return SizedBox(
      // 005 D6（FR-009）：触达外扩 44×44——38 视觉钮居中不变（T008 起
      // 仅存 PageTopBar trailing ⋯ 菜单钮消费）。
      width: 44,
      height: 44,
      child: InkWell(
        key: const ValueKey('goalMoreButton'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(
          child: tooltip == null
              ? button
              : Tooltip(message: tooltip!, child: button),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 暂停横幅（冻结稿板 5 .paused）：琥珀点 + 恢复行动。
// ---------------------------------------------------------------------------

class _PausedBanner extends StatelessWidget {
  const _PausedBanner({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.s4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s4,
        vertical: AppSpace.s3,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: palette.shadowLow,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: palette.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Text(
              Copy.goalPausedBanner,
              style: Theme.of(context).textTheme.bodyM,
            ),
          ),
          InkWell(
            onTap: onResume,
            child: Text(
              Copy.goalResumeAction,
              style: Theme.of(context).textTheme.bodyM
                  .copyWith(color: palette.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 身份区（冻结稿 .hero）：大类色 icon + 名称 + 组合徽章 + meta 胶囊。
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.goal,
    required this.today,
    required this.reminderRow,
    required this.mine,
    required this.days,
    required this.dimmed,
    required this.majorColor,
  });

  final Goal goal;
  final LocalDate today;
  final Reminder? reminderRow;
  final List<CheckIn> mine;
  final int days;
  final bool dimmed;
  final Color majorColor;

  static String _cadenceLabel(Cadence c) => switch (c) {
    Cadence.daily => Copy.cadenceDaily,
    Cadence.threeDay => Copy.cadenceThreeDay,
    Cadence.weekly => Copy.cadenceWeekly,
  };

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final icon = GoalIconCatalog.byKey(goal.iconKey);
    final suffix = switch (goal.status) {
      GoalStatus.paused => Copy.goalStatusPausedSuffix,
      GoalStatus.achieved => Copy.goalStatusAchievedSuffix,
      GoalStatus.archived => Copy.goalStatusArchivedSuffix,
      GoalStatus.active => null,
    };
    return Opacity(
      opacity: dimmed ? .75 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s5),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.rXl,
          boxShadow: palette.shadowLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: AppRadius.rMd,
                  ),
                  child: Icon(icon.icon, size: 28, color: majorColor),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: theme.textTheme.titleL),
                      const SizedBox(height: AppSpace.s2),
                      GoalTypeBadge(goal: goal, suffix: suffix),
                    ],
                  ),
                ),
              ],
            ),
            if (_pills().isNotEmpty) ...[
              const SizedBox(height: AppSpace.s3),
              Wrap(
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: _pills(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// meta 胶囊组：活跃习惯/长期 = 连续（大类点）+ 本周 + 提醒；
  /// 活跃短期 = 倒计时（大类点）+ 截止日；非活跃 = 历史条数 + 创建日。
  List<Widget> _pills() {
    final active = goal.status == GoalStatus.active;
    if (active && goal.isShortTerm) {
      return [
        _MetaPill(dot: majorColor, text: Copy.deadlineCountdownMeta(days)),
        if (goal.deadline != null)
          _MetaPill(text: Copy.deadlineDateMeta(goal.deadline!.isoString)),
      ];
    }
    if (active) {
      return [
        if (_streak() > 0)
          _MetaPill(dot: majorColor, text: Copy.streakMeta(_streak())),
        if (_weekElapsed() > 0)
          _MetaPill(text: Copy.weekMeta(_weekDone(), _weekElapsed())),
        if (reminderRow != null)
          _MetaPill(
            text: Copy.reminderMeta(
              _cadenceLabel(reminderRow!.effectiveCadence),
              reminderRow!.time.isoString,
            ),
          ),
      ];
    }
    return [
      if (mine.isNotEmpty) _MetaPill(text: Copy.historyCountMeta(mine.length)),
      _MetaPill(text: Copy.createdMeta(goal.createdAt.isoString)),
    ];
  }

  /// 当前连击：自今天（或昨天）向前逐日有记录。
  int _streak() {
    final days = mine.map((c) => c.day).toSet();
    var d = days.contains(today) ? today : today.addDays(-1);
    if (!days.contains(d)) return 0;
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = d.addDays(-1);
    }
    return n;
  }

  /// 本周（周一起）截至昨天的过天数与记录数（今日另在行动卡呈现）。
  int _weekElapsed() => today.differenceInDays(today.weekStart.monday); // 周一=0
  int _weekDone() {
    final monday = today.weekStart.monday;
    final yesterday = today.addDays(-1);
    return mine
        .where((c) => !c.day.isBefore(monday) && !c.day.isAfter(yesterday))
        .length;
  }
}

/// meta 胶囊（冻结稿 .meta .m）：surfaceAlt 圆条 + 可选大类色点。
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text, this.dot});

  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s3,
        vertical: AppSpace.s1,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: AppRadius.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpace.s1),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.bodyS
                .copyWith(color: palette.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 今日记录卡（冻结稿板 1 .card）：选填一句话 + 打卡主按钮 + 7 天点阵。
// ---------------------------------------------------------------------------

class _TodayCard extends ConsumerStatefulWidget {
  const _TodayCard({
    required this.goal,
    required this.currentStep,
    required this.mine,
    required this.today,
  });

  final Goal goal;
  final MilestoneStep? currentStep;
  final List<CheckIn> mine;
  final LocalDate today;

  @override
  ConsumerState<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends ConsumerState<_TodayCard> {
  Future<void> _recordProgress() async {
    final saved = await showProgressRecordSheet(
      context,
      goal: widget.goal,
      currentStep: widget.currentStep,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('进展已记录')));
    }
  }

  Future<void> _openBackfill([LocalDate? initial]) async {
    final picked = await showModalBottomSheet<LocalDate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BackfillSheet(
        today: widget.today,
        recordedDays: widget.mine
            .where((c) => c.isValid)
            .map((c) => c.day)
            .toSet(),
        initial: initial,
      ),
    );
    if (picked == null) return;
    await ref.read(checkInServiceProvider).backfill(widget.goal.id, picked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Copy.backfillDone(picked.isoString))),
      );
    }
  }

  Future<void> _openRecords(LocalDate day, List<CheckIn> records) =>
      showDayRecordsSheet(context, day: day, records: records);

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: palette.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日进展',
            style: theme.textTheme.labelS.copyWith(
              letterSpacing: .8,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.s3),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: AppRadius.rMd,
            ),
            child: Text(
              widget.currentStep == null
                  ? '记录这次做了什么，并为目标补充下一步计划。'
                  : '当前里程碑：${widget.currentStep!.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyM.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          _PillButton(
            key: const ValueKey('recordProgressButton'),
            label: '记录进展',
            leading: Icon(
              Icons.edit_rounded,
              size: 18,
              color: palette.accentOn,
            ),
            background: palette.accent,
            foreground: palette.accentOn,
            shadow: true,
            onTap: _recordProgress,
          ),
          const SizedBox(height: AppSpace.s4),
          Divider(height: 1, color: palette.divider),
          const SizedBox(height: AppSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最近 7 天', style: theme.textTheme.titleS),
                    const SizedBox(height: AppSpace.s1),
                    Text(
                      _recentRange(widget.today),
                      style: theme.textTheme.bodyS.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('detailOpenCalendar'),
                onPressed: _openBackfill,
                child: const Text('查看日历'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          _WeekDots(
            mine: widget.mine,
            today: widget.today,
            onPickPast: (d) => _openBackfill(d),
            onOpenRecords: _openRecords,
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              _CalendarLegend(
                icon: Icons.check_rounded,
                label: '已记录',
                color: palette.positiveFill,
              ),
              const SizedBox(width: AppSpace.s4),
              _CalendarLegend(
                icon: Icons.add_rounded,
                label: '可补记',
                color: palette.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _recentRange(LocalDate today) {
  final start = today.addDays(-6);
  return '${start.month}月${start.day}日 – ${today.month}月${today.day}日';
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.bodyS),
    ],
  );
}

/// 最近七天日历：星期、日期和文字状态同时呈现，不依赖颜色判断。
class _WeekDots extends StatelessWidget {
  const _WeekDots({
    required this.mine,
    required this.today,
    required this.onPickPast,
    required this.onOpenRecords,
  });

  final List<CheckIn> mine;
  final LocalDate today;
  final void Function(LocalDate) onPickPast;
  final void Function(LocalDate, List<CheckIn>) onOpenRecords;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final byDay = <LocalDate, List<CheckIn>>{};
    for (final c in mine) {
      byDay.putIfAbsent(c.day, () => []).add(c);
    }
    return Row(
      key: const ValueKey('detailWeekCalendar'),
      children: [
        for (var i = 6; i >= 0; i--)
          Expanded(child: _dayColumn(palette, theme, today.addDays(-i), byDay)),
      ],
    );
  }

  Widget _dayColumn(
    TargetPalette palette,
    ThemeData theme,
    LocalDate day,
    Map<LocalDate, List<CheckIn>> byDay,
  ) {
    final rows = byDay[day] ?? const <CheckIn>[];
    final hit = rows.isNotEmpty;
    final bf = rows.any((c) => c.isBackfill);
    final isToday = day == today;
    final state = isToday
        ? '今日'
        : hit
        ? '已记录'
        : '可补记';
    return Semantics(
      button: !isToday,
      label: '星期${day.weekday.zhLabel}，${day.month}月${day.day}日，$state',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('detailDay-${day.isoString}'),
        onTap: isToday
            ? null
            : hit
            ? () => onOpenRecords(day, rows)
            : () => onPickPast(day),
        borderRadius: AppRadius.rMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82, minWidth: 44),
          child: Column(
            children: [
              Text(
                day.weekday.zhLabel,
                style: theme.textTheme.labelS.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.s1),
              CustomPaint(
                foregroundPainter: bf
                    ? _DashedCirclePainter(color: palette.divider)
                    : null,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hit
                        ? palette.positiveFill
                        : isToday
                        ? palette.accent
                        : palette.surfaceAlt,
                    border: Border.all(
                      color: hit && !bf ? Colors.transparent : palette.divider,
                    ),
                  ),
                  child: hit
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: palette.positiveOn,
                        )
                      : Text(
                          '${day.day}',
                          style: theme.textTheme.bodyS.copyWith(
                            color: isToday
                                ? palette.accentOn
                                : palette.onSurface,
                            fontWeight: isToday ? FontWeight.w700 : null,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                state,
                style: theme.textTheme.labelS.copyWith(
                  color: isToday ? palette.accent : palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 点阵补签虚线圈（.day.bf）。
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final rect = Offset.zero & size;
    final radius = size.width / 2;
    // 34px 圆按 6px 弧段切分。
    final circumference = 2 * 3.141592653589793 * radius;
    final dashCount = (circumference / 10).floor();
    var start = 0.0;
    final step = circumference / dashCount;
    while (start < circumference) {
      canvas.drawArc(rect, start, step / 2, false, paint);
      start += step;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// 补签弹层（冻结稿板 3 .sheet）：14 天窗口日历单选 + 确认主按钮。
// ---------------------------------------------------------------------------

class _BackfillSheet extends StatefulWidget {
  const _BackfillSheet({
    required this.today,
    required this.recordedDays,
    this.initial,
  });

  final LocalDate today;
  final Set<LocalDate> recordedDays;
  final LocalDate? initial;

  @override
  State<_BackfillSheet> createState() => _BackfillSheetState();
}

class _BackfillSheetState extends State<_BackfillSheet> {
  LocalDate? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  /// 完整日历提供最近六个月；未来、今日和已有记录不可重复选择。
  late final LocalDate _windowStart = widget.today.addDays(-183);
  late final LocalDate _windowEnd = widget.today.addDays(-1);

  bool _selectable(LocalDate d) =>
      !d.isBefore(_windowStart) &&
      !d.isAfter(_windowEnd) &&
      !widget.recordedDays.contains(d);

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final months = <_MonthSpan>[];
    for (var d = _windowStart; !d.isAfter(_windowEnd); d = d.addDays(1)) {
      final m = _MonthSpan(d.year, d.month);
      if (months.isEmpty || months.last != m) months.add(m);
    }
    return Container(
      key: const ValueKey('backfillSheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .78,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
        boxShadow: palette.shadowHigh,
      ),
      // 005 留档：同 _showMenu 弹层——底距 s5+8 home 避让裸算式非页缘口径。
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s3,
        AppSpace.s5,
        AppSpace.s5 + 8,
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
          SizedBox(
            width: double.infinity,
            child: Text(Copy.backfillSheetTitle, style: theme.textTheme.titleS),
          ),
          const SizedBox(height: AppSpace.s3),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in months)
                    _monthGrid(context, palette, theme, m),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          SizedBox(
            width: double.infinity,
            child: Text(
              Copy.backfillSheetHint,
              style: theme.textTheme.bodyS.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          _PillButton(
            key: const ValueKey('backfillConfirmButton'),
            label: _picked == null
                ? Copy.backfillConfirm(_windowEnd.month, _windowEnd.day)
                : Copy.backfillConfirm(_picked!.month, _picked!.day),
            leading: Icon(Icons.check, size: 18, color: palette.accentOn),
            background: palette.accent,
            foreground: palette.accentOn,
            shadow: true,
            enabled: _picked != null,
            onTap: () => Navigator.of(context).pop(_picked),
          ),
        ],
      ),
    );
  }

  Widget _monthGrid(
    BuildContext context,
    TargetPalette palette,
    ThemeData theme,
    _MonthSpan m,
  ) {
    final first = LocalDate(m.year, m.month, 1);
    // 月内天数：逐日推进直到跨月。
    final daysInMonth = <LocalDate>[];
    for (var d = first; ; d = d.addDays(1)) {
      if (d.month != m.month) break;
      daysInMonth.add(d);
    }
    final leading = first.weekdayIso - 1; // 周一=0
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${m.month}月',
            style: theme.textTheme.labelS.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.s1),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpace.s2;
              final w = (constraints.maxWidth - 6 * gap) / 7;
              final cells = <Widget>[];
              for (var i = 0; i < leading; i++) {
                cells.add(SizedBox(width: w, height: w));
              }
              for (final d in daysInMonth) {
                cells.add(_cell(palette, theme, d, w));
              }
              return Wrap(spacing: gap, runSpacing: gap, children: cells);
            },
          ),
        ],
      ),
    );
  }

  Widget _cell(TargetPalette palette, ThemeData theme, LocalDate d, double w) {
    final selectable = _selectable(d);
    final done = widget.recordedDays.contains(d);
    final picked = d == _picked;
    return Opacity(
      opacity: selectable ? 1 : .3,
      child: IgnorePointer(
        ignoring: !selectable,
        child: InkWell(
          onTap: () => setState(() => _picked = d),
          customBorder: const CircleBorder(),
          child: Container(
            width: w,
            height: w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: picked ? palette.accent : palette.surfaceAlt,
              border: Border.all(
                width: 2,
                color: done
                    ? palette.positiveFill
                    : picked
                    ? palette.accent
                    : Colors.transparent,
              ),
            ),
            child: Text(
              '${d.day}',
              style: theme.textTheme.bodyM.copyWith(
                color: picked ? palette.accentOn : palette.onSurface,
                fontWeight: picked ? FontWeight.w700 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSpan {
  const _MonthSpan(this.year, this.month);

  final int year;
  final int month;

  @override
  bool operator ==(Object o) =>
      o is _MonthSpan && o.year == year && o.month == month;
  @override
  int get hashCode => Object.hash(year, month);
}

// ---------------------------------------------------------------------------
// 里程碑卡（冻结稿板 2）：进度百分比 + 勾选/删除/添加。
// ---------------------------------------------------------------------------

class _MilestoneCard extends ConsumerWidget {
  const _MilestoneCard({
    required this.goalId,
    required this.steps,
    required this.majorColor,
  });

  final String goalId;
  final List<MilestoneStep> steps;
  final Color majorColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final done = steps.where((s) => s.isDone).length;
    final percent = steps.isEmpty ? 0 : (done * 100 / steps.length).round();

    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: palette.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Copy.milestoneStepsHeader,
            style: theme.textTheme.labelS.copyWith(
              letterSpacing: .8,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.rFull,
                  child: Container(
                    height: 8,
                    color: palette.surfaceAlt,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percent / 100,
                      child: Container(color: majorColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              SizedBox(
                width: 44,
                child: Text(
                  '$percent%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleS,
                ),
              ),
            ],
          ),
          if (steps.isNotEmpty) const SizedBox(height: AppSpace.s2),
          for (final s in steps)
            Row(
              children: [
                InkWell(
                  key: ValueKey('stepCheck-${s.id}'),
                  onTap: () => ref
                      .read(goalRepoProvider)
                      .updateStep(
                        s.toggled(now: DateTime.now(), done: !s.isDone),
                      ),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.isDone ? palette.positiveFill : null,
                      border: s.isDone
                          ? Border.all(color: Colors.transparent)
                          : Border.all(color: palette.divider, width: 1.5),
                    ),
                    child: s.isDone
                        ? Icon(Icons.check, size: 14, color: palette.positiveOn)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Text(
                    s.title,
                    style: s.isDone
                        ? theme.textTheme.bodyL.copyWith(
                            color: palette.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          )
                        : theme.textTheme.bodyL,
                  ),
                ),
                IconButton(
                  key: ValueKey('stepDelete-${s.id}'),
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: palette.onSurfaceVariant,
                  ),
                  tooltip: Copy.milestoneDeleteStep,
                  onPressed: () => ref.read(goalRepoProvider).removeStep(s.id),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          _StepAddRow(goalId: goalId),
        ],
      ),
    );
  }
}

/// 「添加步骤…」行（冻结稿 .ms-add）：输入 + 添加按钮。
class _StepAddRow extends ConsumerStatefulWidget {
  const _StepAddRow({required this.goalId});

  final String goalId;

  @override
  ConsumerState<_StepAddRow> createState() => _StepAddRowState();
}

class _StepAddRowState extends ConsumerState<_StepAddRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    ref
        .read(goalRepoProvider)
        .addStep(MilestoneStep(goalId: widget.goalId, title: title));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextFormField(
                controller: _controller,
                maxLength: 50,
                style: theme.textTheme.bodyM,
                decoration: InputDecoration(
                  hintText: Copy.milestoneStepHint,
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: palette.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.rMd,
                    borderSide: BorderSide(color: palette.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.rMd,
                    borderSide: BorderSide(color: palette.divider),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s3,
                    vertical: AppSpace.s2,
                  ),
                ),
                onFieldSubmitted: (_) => _add(),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          InkWell(
            onTap: _add,
            borderRadius: AppRadius.rMd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.rMd,
              ),
              child: Text(
                Copy.milestoneAddStep,
                style: theme.textTheme.bodyM.copyWith(color: palette.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 行式卡（冻结稿 .lrow）：短期 标记达成/续期 + 通用 编辑目标。
// ---------------------------------------------------------------------------

class _ActionRowsCard extends StatelessWidget {
  const _ActionRowsCard({
    required this.goal,
    required this.days,
    required this.onRenew,
    required this.onAchieve,
  });

  final Goal goal;
  final int days;
  final VoidCallback onRenew;
  final VoidCallback onAchieve;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final icon = GoalIconCatalog.byKey(goal.iconKey);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s4,
        vertical: AppSpace.s2,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: palette.shadowLow,
      ),
      child: Column(
        children: [
          if (goal.isShortTerm) ...[
            _LineRow(
              key: const ValueKey('goalMarkAchievedButton'),
              icon: Icons.trip_origin,
              label: Copy.goalMarkAchieved,
              onTap: onAchieve,
            ),
            _divider(palette),
            _LineRow(
              key: const ValueKey('goalRenewButton'),
              icon: Icons.add_circle_outline,
              label: Copy.goalRenewDeadline,
              value: goal.deadline?.isoString,
              onTap: onRenew,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 28 + AppSpace.s3,
                bottom: AppSpace.s2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  Copy.renewHint,
                  style: Theme.of(context).textTheme.bodyS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ),
            ),
            _divider(palette),
          ],
          _LineRow(
            icon: icon.icon,
            label: Copy.goalEdit,
            onTap: () =>
                GoRouter.of(context).push('/goal-editor?id=${goal.id}'),
          ),
        ],
      ),
    );
  }

  Widget _divider(TargetPalette palette) =>
      Container(height: 1, color: palette.divider);
}

/// 行式（.lrow）：28 盒图标 + 标签 + 行尾值 + ›。
class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.rSm,
              ),
              child: Icon(icon, size: 16, color: palette.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(child: Text(label, style: theme.textTheme.bodyL)),
            if (value != null) ...[
              Text(
                value!,
                style: theme.textTheme.bodyM.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpace.s1),
            ],
            Icon(
              Icons.chevron_right,
              size: 14,
              color: palette.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 历史记录卡（冻结稿 .hist）：MM-DD + 描述 + 「补签」标记。
// ---------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.items});

  final List<CheckIn> items;

  static String _mmdd(LocalDate d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: palette.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Copy.goalHistoryTitle,
            style: theme.textTheme.labelS.copyWith(
              letterSpacing: .8,
              color: palette.onSurfaceVariant,
            ),
          ),
          for (final (i, c) in items.indexed) ...[
            if (i > 0)
              Container(
                height: 1,
                width: double.infinity,
                color: palette.divider,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
              child: Row(
                children: [
                  Text(_mmdd(c.day), style: theme.textTheme.bodyM),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: Text(
                      (c.note ?? '').trim().isEmpty
                          ? Copy.checkInDefaultNote
                          : c.note!.trim(),
                      style: theme.textTheme.bodyS.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (c.isBackfill) ...[
                    const SizedBox(width: AppSpace.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: AppRadius.rFull,
                      ),
                      child: Text(
                        Copy.backfillTag,
                        style: theme.textTheme.labelS.copyWith(
                          color: palette.onSurfaceVariant,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 通用件：菜单行 / 胶囊按钮 / 删除直达行。
// ---------------------------------------------------------------------------

/// 「⋯」菜单行（冻结稿 .menu）：图标 20 + 标签；danger = 红。
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final FutureOr<void> Function() onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final color = danger ? palette.badge : palette.onSurface;
    final iconColor = danger ? palette.badge : palette.onSurfaceVariant;
    return InkWell(
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
          ],
        ),
      ),
    );
  }
}

/// 全宽胶囊按钮（.btn-primary / .dlg .acts 同族）：底色 + 前景 + 可选中影。
class _PillButton extends StatelessWidget {
  const _PillButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.leading,
    this.shadow = false,
    this.enabled = true,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool shadow;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        boxShadow: shadow && enabled ? palette.shadowMid : null,
      ),
      child: Material(
        color: enabled ? background : background.withValues(alpha: .4),
        borderRadius: AppRadius.rFull,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.rFull,
          child: Padding(
            padding: shadow
                ? const EdgeInsets.symmetric(vertical: AppSpace.s4)
                : const EdgeInsets.symmetric(vertical: AppSpace.s3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpace.s2),
                ],
                Text(
                  label,
                  style: theme.textTheme.titleS.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 非活跃态删除直达（冻结稿板 5 .btn-line.danger）。
class _DeleteLineButton extends StatelessWidget {
  const _DeleteLineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        border: Border.all(color: palette.badge),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.rFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rFull,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
            child: Center(
              child: Text(
                Copy.menuDeleteGoal,
                style: theme.textTheme.bodyL.copyWith(color: palette.badge),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
