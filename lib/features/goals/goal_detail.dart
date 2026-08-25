/// 目标详情页（003 T021 管理动线 → 004 T014 冻结稿换装 → 2026-08-25
/// 里程碑/达成交互重设计）。
///
/// 全屏 push 无底部页签；顶栏 = 返回 + 「目标详情」+「⋯」更多。身份区
/// hero 随三大类变色（icon/徽章/meta 点），meta 胶囊：习惯/长期 = 连续/
/// 本周/提醒摘要，短期 = 倒计时 + 截止日；今日记录卡 = 选填一句话 +
/// accent 打卡主按钮 + 近 7 天点阵（绿勾 = 已记录、蓝圆 = 今日、灰圆
/// 小「+」角标 = 可补记——纯形色状态无文字层；点过去日开补签弹层：
/// 14 天窗口日历单选）；历史记录含「补签」标记；短期另有里程碑卡
///（题头百分比 + 圆角卡行：点行勾选/达成日副题/删除/拖柄排序 +
/// 统一输入语言添加行）；标记达成 = 全宽胶囊双通道（轻点校验弹窗 /
/// 长按 800ms 填充动画快速标记，未完成里程碑时两条通道都警示）；
/// 编辑/暂停/恢复/删除收纳「⋯」菜单，删除二次确认后物理级联删除
/// （FR-016 全能力零丢失）。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // 2026-08-25：同编辑器——分支 push 淡入铺实底，消除转场结束的
      // 背景突变（下层分支页在 opaque 转场完成后不再绘制）。
      backgroundColor: TargetPalette.of(context).background,
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
                  if (active && goal.isShortTerm) ...[
                    const SizedBox(height: AppSpace.s4),
                    _AchieveSection(
                      goal: goal,
                      steps: steps,
                      onConfirmed: () => _achieveAndPop(context, ref, goal),
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
      // 2026-08-25：Flutter 3.47 起 useRootNavigator 缺省 false——分支
      // 页弹层会落在壳层 body 内（止于 dock 顶，导航条露在 sheet 之下）。
      // 定稿口径：整屏 sheet 盖于导航条之前、贴屏幕物理底。
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        key: const ValueKey('goalMenuSheet'),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
          boxShadow: palette.shadowHigh,
        ),
        // 底距 s4 + 安全区——内容避让 Home 指示条，指示区由 sheet
        // 表面承载（原生 sheet 观感），不再留固定 28px 空带。
        padding: EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s3,
          AppSpace.s5,
          AppSpace.s4 + MediaQuery.paddingOf(sheetContext).bottom,
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
      // 同 ⋯ 菜单：整屏 sheet（盖于导航条之前、贴屏幕物理底）。
      useRootNavigator: true,
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
        ],
      ),
    );
  }
}

String _recentRange(LocalDate today) {
  final start = today.addDays(-6);
  return '${start.month}月${start.day}日 – ${today.month}月${today.day}日';
}

/// 最近七天日历（2026-08-25 收敛：文字状态层退役——绿勾 = 已记录、
/// 蓝圆 = 今日、灰圆 + 角标「+」= 可补记，状态全部走形与色；读屏标签
/// 仍带完整状态语，不依赖颜色判断）。
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const minimumWidth = 44.0 * 7;
        final rowWidth = constraints.maxWidth < minimumWidth
            ? minimumWidth
            : constraints.maxWidth;
        final calendar = SizedBox(
          width: rowWidth,
          child: Row(
            key: const ValueKey('detailWeekCalendar'),
            children: [
              for (var i = 6; i >= 0; i--)
                Expanded(
                  child: _dayColumn(palette, theme, today.addDays(-i), byDay),
                ),
            ],
          ),
        );
        if (rowWidth == constraints.maxWidth) return calendar;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: calendar,
        );
      },
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
    final canBackfill = !hit && !isToday;
    final state = isToday ? '今日' : hit ? '已记录' : '可补记';
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
          constraints: const BoxConstraints(minHeight: 58, minWidth: 44),
          child: Column(
            children: [
              Text(
                day.weekday.zhLabel,
                style: theme.textTheme.labelS.copyWith(
                  color: isToday ? palette.accent : palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.s1),
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
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
                            color: hit && !bf
                                ? Colors.transparent
                                : palette.divider,
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
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : null,
                                ),
                              ),
                      ),
                    ),
                    // 补记入口角标：灰圆 + 小「+」= 轻点补记（替代旧文字层）。
                    if (canBackfill)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          key: ValueKey('detailDayPlus-${day.isoString}'),
                          width: 15,
                          height: 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.divider),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 11,
                            color: palette.accent,
                          ),
                        ),
                      ),
                  ],
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
      // 底距同 _showMenu：s4 + 安全区（整屏 sheet，指示区由表面承载）。
      padding: EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s3,
        AppSpace.s5,
        AppSpace.s4 + MediaQuery.paddingOf(context).bottom,
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
              const gap = AppSpace.s1;
              const minimumCellWidth = 44.0;
              const minimumGridWidth = minimumCellWidth * 7 + gap * 6;
              final gridWidth = constraints.maxWidth < minimumGridWidth
                  ? minimumGridWidth
                  : constraints.maxWidth;
              final w = (gridWidth - 6 * gap) / 7;
              final cells = <Widget>[];
              for (var i = 0; i < leading; i++) {
                cells.add(SizedBox(width: w, height: w));
              }
              for (final d in daysInMonth) {
                cells.add(_cell(palette, theme, d, w));
              }
              final grid = SizedBox(
                width: gridWidth,
                child: Wrap(spacing: gap, runSpacing: gap, children: cells),
              );
              if (gridWidth == constraints.maxWidth) return grid;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: grid,
              );
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
    final state = done
        ? '已记录'
        : picked
        ? '已选择'
        : selectable
        ? '可补记'
        : '不可补记';
    return Semantics(
      key: ValueKey('backfillDay-${d.isoString}'),
      button: true,
      enabled: selectable,
      selected: picked,
      label: '${d.year}年${d.month}月${d.day}日，$state',
      excludeSemantics: true,
      child: Opacity(
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
// 里程碑卡（2026-08-25 重设计）：题头内联百分比 + 细进度条；行 = surfaceAlt
// 圆角卡（点行勾选、达成日副题、删除 ×、拖柄排序）；输入 = 应用统一
// 输入语言（surfaceAlt + divider 边 + 内联圆形加号钮）。
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
          Row(
            children: [
              Expanded(
                child: Text(
                  Copy.milestoneStepsHeader,
                  style: theme.textTheme.labelS.copyWith(
                    letterSpacing: .8,
                    color: palette.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleS.copyWith(
                  color: palette.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s2),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: Container(
              height: 6,
              color: palette.surfaceAlt,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent / 100,
                child: Container(color: majorColor),
              ),
            ),
          ),
          if (steps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
              child: Text(
                Copy.milestoneEmptyHint,
                style: theme.textTheme.bodyS.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            const SizedBox(height: AppSpace.s3),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              padding: EdgeInsets.zero,
              // onReorderItem：newIndex 已按移除旧位调整，直接插入即得
              // 新序（旧 onReorder 需自行 -1，3.41 起废弃）。
              onReorderItem: (oldIndex, newIndex) {
                final list = [...steps];
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                ref.read(goalRepoProvider).reorderSteps(
                  goalId,
                  [for (final s in list) s.id],
                );
              },
              children: [
                for (final (i, s) in steps.indexed)
                  _StepRow(key: ValueKey('stepRow-${s.id}'), step: s, index: i),
              ],
            ),
          ],
          _StepAddRow(goalId: goalId),
        ],
      ),
    );
  }
}

/// 里程碑行（重设计）：surfaceAlt 圆角卡；主区点按 = 勾选/回退，已完成
/// 行带「M月d日达成」历史副题；尾随 删除 × + 拖柄（拖柄起拖排序）。
class _StepRow extends ConsumerWidget {
  const _StepRow({super.key, required this.step, required this.index});

  final MilestoneStep step;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final doneAt = step.doneAt;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.s2),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: ValueKey('stepCheck-${step.id}'),
              onTap: () => ref
                  .read(goalRepoProvider)
                  .updateStep(
                    step.toggled(now: DateTime.now(), done: !step.isDone),
                  ),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s3,
                  vertical: AppSpace.s2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isDone ? palette.positiveFill : null,
                        border: step.isDone
                            ? Border.all(color: Colors.transparent)
                            : Border.all(color: palette.divider, width: 1.5),
                      ),
                      child: step.isDone
                          ? Icon(
                              Icons.check,
                              size: 13,
                              color: palette.positiveOn,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.s1,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: step.isDone
                                  ? theme.textTheme.bodyM.copyWith(
                                      color: palette.onSurfaceVariant,
                                      decoration: TextDecoration.lineThrough,
                                    )
                                  : theme.textTheme.bodyM,
                            ),
                            if (step.isDone && doneAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                Copy.milestoneDoneAt(doneAt.month, doneAt.day),
                                style: theme.textTheme.labelS.copyWith(
                                  color: palette.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            key: ValueKey('stepDelete-${step.id}'),
            onTap: () => ref.read(goalRepoProvider).removeStep(step.id),
            borderRadius: AppRadius.rMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s2),
              child: Icon(
                Icons.close,
                size: 15,
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
          ReorderableDragStartListener(
            key: ValueKey('stepHandle-${step.id}'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpace.s2),
              child: Icon(
                Icons.drag_indicator,
                size: 18,
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 添加行（重设计）：应用统一输入语言——surfaceAlt 底 + 1px divider 边
/// + 内联 32px 圆形加号钮（空稿 = 变体色禁用观感，有稿 = accent 实底）。
class _StepAddRow extends ConsumerStatefulWidget {
  const _StepAddRow({required this.goalId});

  final String goalId;

  @override
  ConsumerState<_StepAddRow> createState() => _StepAddRowState();
}

class _StepAddRowState extends ConsumerState<_StepAddRow> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 加号钮的实/虚随草稿切换。
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canAdd => _controller.text.trim().isNotEmpty;

  void _add() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    // 追加到当前最大位之后（reorder 后即列表末位；兼容历史空洞位序）。
    final steps =
        ref.read(stepsProvider(widget.goalId)).value ??
        const <MilestoneStep>[];
    final next = steps.isEmpty
        ? 0
        : steps
              .map((s) => s.position)
              .reduce((a, b) => a > b ? a : b) +
              1;
    ref
        .read(goalRepoProvider)
        .addStep(
          MilestoneStep(
            goalId: widget.goalId,
            title: title,
            position: next,
          ),
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('stepAddRow'),
      height: 44,
      margin: const EdgeInsets.only(top: AppSpace.s2),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('stepInputField'),
              controller: _controller,
              maxLength: 50,
              style: theme.textTheme.bodyM,
              decoration: InputDecoration(
                hintText: Copy.milestoneInputHint,
                counterText: '',
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s3,
                ),
              ),
              onSubmitted: (_) => _add(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.s1),
            child: InkWell(
              key: const ValueKey('stepAddButton'),
              onTap: _canAdd ? _add : null,
              customBorder: const CircleBorder(),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _canAdd ? palette.accent : null,
                  border: _canAdd
                      ? null
                      : Border.all(color: palette.divider),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: _canAdd ? palette.accentOn : palette.onSurfaceVariant,
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
// 标记达成（2026-08-25 重设计）：双通道确认——轻点 = 校验弹窗（有未完成
// 里程碑时警示；无则温和确认），长按 ≈800ms = 填充扫过动画快速标记
//（仍有未完成里程碑时长按结束同样走弹窗）。编辑目标/续期常驻行退役
//（编辑已在「⋯」菜单；续期经编辑器改截止日）。
// ---------------------------------------------------------------------------

class _AchieveSection extends StatelessWidget {
  const _AchieveSection({
    required this.goal,
    required this.steps,
    required this.onConfirmed,
  });

  final Goal goal;
  final List<MilestoneStep> steps;
  final VoidCallback onConfirmed;

  /// 轻点（或长按结束仍有未完成里程碑时）的校验弹窗。
  Future<void> _confirm(BuildContext context) async {
    final pending = steps.where((s) => !s.isDone).length;
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const ValueKey('goalAchieveDialog'),
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
              Text(
                pending > 0
                    ? Copy.achievePendingTitle(pending)
                    : Copy.achieveConfirmTitle,
                style: theme.textTheme.titleS,
              ),
              const SizedBox(height: AppSpace.s3),
              Text(
                pending > 0
                    ? Copy.achievePendingBody(goal.name)
                    : Copy.achieveConfirmBody(goal.name),
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
                      key: const ValueKey('goalAchieveConfirm'),
                      label: Copy.achieveYes,
                      background: palette.positiveFill,
                      foreground: palette.positiveOn,
                      shadow: true,
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
    if (yes == true) onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final hasPending = steps.any((s) => !s.isDone);
    return Column(
      children: [
        _HoldAchieveButton(
          key: const ValueKey('goalMarkAchievedButton'),
          onTap: () => _confirm(context),
          // 长按快速通道：无未完成里程碑直接达成，否则同样落回校验弹窗。
          onHoldComplete: () async {
            if (hasPending) {
              await _confirm(context);
            } else {
              onConfirmed();
            }
          },
        ),
        const SizedBox(height: AppSpace.s2),
        Text(
          Copy.achieveHoldCaption,
          style: theme.textTheme.bodyS.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 长按填充达成钮：按住 = 左→右白色扫过（800ms）+ 微缩按压感；填满 =
/// 震感 + 翻绿「已达成」闪示后回调。轻点（<250ms 且未起填）走 onTap。
class _HoldAchieveButton extends StatefulWidget {
  const _HoldAchieveButton({super.key, required this.onTap, required this.onHoldComplete});

  final VoidCallback onTap;
  final Future<void> Function() onHoldComplete;

  @override
  State<_HoldAchieveButton> createState() => _HoldAchieveButtonState();
}

class _HoldAchieveButtonState extends State<_HoldAchieveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  /// 快速轻点判定窗（按下→抬起小于此且几乎未起填 = 轻点）。
  static const _tapWindow = Duration(milliseconds: 250);

  DateTime? _downAt;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _hold.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onHoldDone();
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    if (_completed) return;
    _downAt = DateTime.now();
    _hold.forward();
  }

  void _up(PointerUpEvent _) {
    if (_completed) return;
    final quick =
        _downAt != null &&
        DateTime.now().difference(_downAt!) < _tapWindow &&
        _hold.value < .2;
    _hold.reverse();
    _downAt = null;
    if (quick) widget.onTap();
  }

  void _cancel(PointerCancelEvent _) {
    if (_completed) return;
    _hold.reverse();
    _downAt = null;
  }

  Future<void> _onHoldDone() async {
    if (_completed) return;
    _completed = true;
    HapticFeedback.mediumImpact();
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await widget.onHoldComplete();
    // 弹窗取消（未达成跳转）时复位回待按状态。
    if (mounted) {
      setState(() {
        _completed = false;
        _hold.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: Copy.goalMarkAchieved,
      hint: Copy.achieveHoldCaption,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            final holding = _hold.value > 0 && !_completed;
            return AnimatedScale(
              scale: holding ? .98 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.rFull,
                  boxShadow: palette.shadowMid,
                ),
                child: Material(
                  color: _completed ? palette.positiveFill : palette.accent,
                  borderRadius: AppRadius.rFull,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // 按住填充扫过（半透明白，左→右）。
                      if (_hold.value > 0)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _hold.value,
                          child: Container(
                            color: Colors.white.withValues(alpha: .25),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.s4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _completed
                                  ? Icons.check_circle_rounded
                                  : Icons.flag_rounded,
                              size: 18,
                              color: _completed
                                  ? palette.positiveOn
                                  : palette.accentOn,
                            ),
                            const SizedBox(width: AppSpace.s2),
                            Text(
                              _completed ? Copy.goalStatusAchievedSuffix : Copy.goalMarkAchieved,
                              style: theme.textTheme.titleS.copyWith(
                                color: _completed
                                    ? palette.positiveOn
                                    : palette.accentOn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
