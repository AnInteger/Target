/// TodayView（004 T020 重做，按 v2-today.html R3 冻结稿）。
///
/// 今日页骨架 v2：头部（中文「星期, 日期」行 + 大标题「今日」+ 右上
/// 头像入「我的」页，同一连续图层无分隔线）+ 三大类健康度环（R3
/// 裁决案 C「单环·三段弧」：一环三色各占 1/3 槽位，弧长 = 该类分
/// 数，中心 = 有数据类平均分；类内零活跃 = 空置段 + 图例弱化无数字；
/// 全库零活跃环区整体让位空态新建 CTA，FR-004）。今日目标列表暂承
/// 003 形态（T022 换装关注卡轮播）；成就覆盖层与补签长按保留。铃
/// 铛（T009 冻结形态 = 通知列表上滑入口）与 ＋（T025 中央 FAB 落
/// 地前的过渡新建入口）暂驻头部右侧。
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
import '../../core/models/goal_icon_catalog.dart';
import '../../core/models/health_score.dart';
import '../goals/goal_type_badge.dart';
import '../notifications/notification_list.dart';
import '../profile/profile.dart';
import 'backfill_calendar.dart';
import 'celebration.dart';

class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final stats = ref.watch(statsProvider);
    final health = ref.watch(healthScoreProvider);
    if (!goalsAsync.hasValue || stats == null || health == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: TargetPalette.of(context).accent,
          ),
        ),
      );
    }
    final today = ref.watch(todayProvider);
    final checkIns = ref.watch(checkInsProvider).value ?? const <CheckIn>[];

    final active = goalsAsync.value!
        .where((g) => g.status == GoalStatus.active)
        .toList();
    final doneGoals = active.where((g) => stats.dayStatusOf(g.id).done).length;
    final actions = active.fold<int>(
      0,
      (sum, g) => sum + stats.dayStatusOf(g.id).doneCount,
    );
    final allProgress = active.isNotEmpty && doneGoals == active.length;
    // 全库零活跃 = health.isEmpty（环区让位口径，FR-004）。
    final isEmpty = health.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 成就覆盖层铺满全屏（不进 SafeArea，状态栏也要被辉光盖住）。
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: ListView(
                // FR-008：水平 24 = 三屏标题带左缘基准。
                padding: const EdgeInsets.fromLTRB(
                  AppScreen.padX,
                  0,
                  AppScreen.padX,
                  AppSpace.s6,
                ),
                children: [
                  const _Head(),
                  if (!isEmpty) ...[
                    _RingZone(health: health),
                    _SectionHeader(
                      note: Copy.todayRecordedNote(doneGoals, active.length),
                    ),
                    for (final g in active)
                      _GoalCard(
                        goal: g,
                        done: stats.dayStatusOf(g.id).done,
                        latest: _latestLine(
                          checkIns.where((c) => c.goalId == g.id).toList(),
                          today,
                        ),
                        today: today,
                      ),
                  ],
                  if (isEmpty)
                    _EmptyCTA(onTap: () => context.push('/goal-editor')),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Celebration(active: allProgress, actions: actions),
          ),
        ],
      ),
    );
  }

  /// 最新记录行（T007 R2 裁决 2）：「相对时间 - 该次描述」；
  /// 未填描述兜底「完成打卡」（FR-019）；无任何记录 → 还没有记录。
  String _latestLine(List<CheckIn> mine, LocalDate today) {
    final valid = mine.where((c) => c.isValid).toList();
    if (valid.isEmpty) return Copy.todayLatestNone;
    valid.sort(
      (a, b) => a.day != b.day
          ? a.day.compareTo(b.day)
          : a.createdAt.compareTo(b.createdAt),
    );
    final last = valid.last;
    final gap = today.differenceInDays(last.day);
    final rel = gap <= 0
        ? Copy.todayLatestToday
        : gap == 1
        ? Copy.todayLatestYesterday
        : Copy.todayLatestDaysAgo(gap);
    final note = (last.note ?? '').trim();
    return '$rel - ${note.isEmpty ? Copy.checkInDefaultNote : note}';
  }
}

/// v2 头部（v2-today 冻结稿 .head）：左 = 日期行（label 体 + 字距）
/// 叠大标题「今日」（displayL）；右 = 头像 44px（surface 描边环 + 低
/// 投影，tap → 「我的」页，Q1 裁决）。铃铛/＋ 为过渡驻留（见文件头）。
class _Head extends ConsumerWidget {
  const _Head();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final profile = ref.watch(profileProvider).value;
    final today = ref.watch(todayProvider);
    final badge = todayBadgeCount(ref.watch(notificationItemsProvider), today);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Copy.todayHeadDate(
                    today.weekday.zhLabel,
                    today.month,
                    today.day,
                  ),
                  style: Theme.of(context).textTheme.labelS.copyWith(
                    color: palette.onSurfaceVariant,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: AppSpace.s1),
                Text(
                  Copy.todayNav,
                  style: Theme.of(context).textTheme.displayL,
                ),
              ],
            ),
          ),
          _CircleButton(
            ghost: true,
            tooltip: Copy.notificationTitle,
            icon: Icons.notifications_outlined,
            badge: badge,
            onTap: () => showNotificationSheet(context),
          ),
          const SizedBox(width: AppSpace.s2),
          _CircleButton(
            ghost: false,
            tooltip: Copy.todayNewGoal,
            icon: Icons.add,
            onTap: () => context.push('/goal-editor'),
          ),
          const SizedBox(width: AppSpace.s3),
          _AvatarEntry(profile: profile),
        ],
      ),
    );
  }
}

/// 头像入口：36px 头像 + surface 双层描边环成 44px 视觉（冻结稿
/// .avatar 2px surface 边 + 低投影），tap → /settings（「我的」页）。
class _AvatarEntry extends StatelessWidget {
  const _AvatarEntry({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Tooltip(
      message: Copy.mineNav,
      child: InkWell(
        onTap: () => context.go('/settings'),
        borderRadius: AppRadius.rFull,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
              boxShadow: palette.shadowLow,
            ),
            padding: const EdgeInsets.all(2),
            child: ProfileAvatar(profile: profile, size: 36),
          ),
        ),
      ),
    );
  }
}

/// 三段弧环区（v2-today 冻结稿 .ring-zone）：128px 单环三段弧 +
/// 右侧图例三行。中心数字 = 有数据类平均分（案 C 裁决）；无数据类
/// 空置段（只余底轨）+ 图例弱化「—」。
class _RingZone extends StatelessWidget {
  const _RingZone({required this.health});

  final HealthSnapshot health;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final colors = {
      for (final c in MajorCategory.values)
        c: MajorColors.byKey(c.name).of(context),
    };
    final scored = MajorCategory.values
        .map((c) => health.byCategory[c]!)
        .where((c) => c.hasData)
        .toList();
    final average = scored.isEmpty
        ? 0
        : scored.fold<int>(0, (s, c) => s + c.score) ~/ scored.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpace.s5, 0, AppSpace.s2),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TriArcPainter(
                      health: health,
                      colors: colors,
                      track: palette.surfaceAlt,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$average',
                        style: Theme.of(context).textTheme.titleM.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        Copy.todayHealthLabel,
                        style: Theme.of(context).textTheme.labelS
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in MajorCategory.values)
                _LegendRow(data: health.byCategory[c]!, color: colors[c]!),
            ],
          ),
        ],
      ),
    );
  }
}

/// 图例行（冻结稿 .lg .li）：10px 色点 + 类名 + 分数 / 100；无数据
/// 态色点淡化、类名弱化、数字位「—」（FR-004 非满分非 0 的空置呈现）。
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.data, required this.color});

  final CategoryHealth data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s1),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.hasData ? color : color.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          Text(
            data.category.zhLabel,
            style: theme.textTheme.bodyM.copyWith(
              color: data.hasData
                  ? palette.onSurface
                  : palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          if (data.hasData) ...[
            Text(
              '${data.score}',
              style: theme.textTheme.bodyM.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              ' ${Copy.todayHealthSuffix}',
              style: theme.textTheme.bodyM.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          ] else
            Text(
              Copy.todayHealthNone,
              style: theme.textTheme.bodyM.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 案 C 单环三段弧画笔（冻结稿 SVG 几何）：128 画布、r=56、描边 11；
/// 三类各占 120° 槽位、槽内 1.5° 起始留缝、尾部 9° 段缝；弧长 =
/// 分数 × 可用槽长；butt 端帽（无圆头）。12 点方向起步（健康段），
/// 顺时针 健康 → 习惯 → 目标。
class _TriArcPainter extends CustomPainter {
  _TriArcPainter({
    required this.health,
    required this.colors,
    required this.track,
  });

  final HealthSnapshot health;
  final Map<MajorCategory, Color> colors;
  final Color track;

  static const double _center = 64, _radius = 56, _stroke = 11;
  static const double _slotDeg = 120, _leadDeg = 1.5, _gapDeg = 9;

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
    for (final (i, category) in MajorCategory.values.indexed) {
      final data = health.byCategory[category]!;
      if (!data.hasData) continue; // 无数据态：槽位空置只余底轨
      final startDeg = -90 + i * _slotDeg + _leadDeg;
      final sweepDeg = data.score / 100 * (_slotDeg - _leadDeg - _gapDeg);
      canvas.drawArc(
        rect,
        startDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.butt
          ..color = colors[category]!,
      );
    }
  }

  @override
  bool shouldRepaint(_TriArcPainter old) {
    if (old.track != track || old.colors.length != colors.length) return true;
    for (final e in colors.entries) {
      if (old.colors[e.key] != e.value) return true;
    }
    for (final c in MajorCategory.values) {
      final a = health.byCategory[c]!, b = old.health.byCategory[c]!;
      if (a.score != b.score || a.hasData != b.hasData) return true;
    }
    return false;
  }
}

/// 36px 圆钮：主（墨实心）/ 次（白面 + 发丝边）；铃铛带数字角标。
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.ghost,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final bool ghost;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  /// 数字角标（0 = 隐藏）：铃铛 = 今日推导条目数。
  final int badge;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rFull,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ghost ? palette.surface : palette.accent,
            border: ghost ? Border.all(color: palette.divider) : null,
            boxShadow: ghost ? palette.shadowLow : palette.shadowMid,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: ghost ? palette.onSurface : palette.accentOn,
              ),
              if (badge > 0)
                Positioned(
                  top: -5,
                  right: -7,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.rFull,
                      color: palette.badge,
                      border: Border.all(color: palette.surface, width: 2),
                    ),
                    child: Text(
                      '$badge',
                      style: Theme.of(context).textTheme.labelS.copyWith(
                        color: palette.badgeOn,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 节头：今日目标 + 节注「已记录 N/M」（T022 关注卡轮播换装前过渡）。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s5, bottom: AppSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(Copy.todaySection, style: Theme.of(context).textTheme.titleS),
          const Spacer(),
          Text(
            note,
            style: Theme.of(context).textTheme.bodyM
                .copyWith(color: palette.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 统一目标卡（三类型一卡）：图标格 + 一句话 + 类型徽章 + 最新记录行。
/// 整卡可点进详情（卡上无按钮），长按 = 补签日历。
class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.goal,
    required this.done,
    required this.latest,
    required this.today,
  });

  final Goal goal;
  final bool done;
  final String latest;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Material(
        color: palette.glassCard,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          onTap: () => context.push('/goal/${goal.id}'),
          onLongPress: () => showBackfillCalendar(context, ref, goal),
          borderRadius: AppRadius.rLg,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s4),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: palette.divider),
              boxShadow: palette.shadowLow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: palette.divider),
                  ),
                  child: Icon(
                    GoalIconCatalog.byKey(goal.iconKey).icon,
                    size: 22,
                    color: palette.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleS.copyWith(
                          color: done ? palette.positive : palette.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s1),
                      GoalTypeBadge(goal: goal),
                      const SizedBox(height: AppSpace.s1),
                      Text(
                        latest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyS.copyWith(
                          color: done
                              ? palette.positive
                              : palette.onSurfaceVariant,
                        ),
                      ),
                    ],
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

/// 空态（v2-today 板 4 冻结稿 .empty）：96px 圆底图形 + 两行引导 +
/// accent 胶囊「新建目标」CTA（同 FAB 动作）。全库零活跃时环区与
/// 列表整体让位于此（FR-004 / 场景 7）。
class _EmptyCTA extends StatelessWidget {
  const _EmptyCTA({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s12, bottom: AppSpace.s6),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceAlt,
            ),
            child: Icon(Icons.eco, size: 40, color: palette.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.s3),
          Text(Copy.todayEmptyTitle, style: Theme.of(context).textTheme.titleM),
          const SizedBox(height: AppSpace.s3),
          Text(
            Copy.todayEmptyBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyM
                .copyWith(color: palette.onSurfaceVariant, height: 1.7),
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
                onTap: onTap,
                borderRadius: AppRadius.rFull,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s6,
                    vertical: AppSpace.s3,
                  ),
                  child: Text(
                    Copy.todayNewGoal,
                    style: Theme.of(context).textTheme.bodyL
                        .copyWith(color: palette.accentOn),
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
