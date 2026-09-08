/// v3 目标详情：⋯ 菜单 + 名称/为什么 + 下个里程碑卡 + 富记录时间线
/// + 底部「记录进展」CTA（R1 定稿）。
/// v3.1：Cupertino 组件重写（CircleIconButton / CupertinoButton.filled /
/// CupertinoPageRoute 转场）。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/sheet.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';
import '../../core/models/relative_time.dart';
import '../shared/record_meta.dart';
import '../shared/record_sheet.dart';
import 'goal_menu.dart';
import 'milestones_view.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final goal = ref
        .watch(goalsProvider)
        .valueOrNull
        ?.where((g) => g.id == goalId)
        .firstOrNull;
    if (goal == null) {
      // 目标已删除/不存在：下一帧自动返回，避免空白详情页。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return CupertinoPageScaffold(
        backgroundColor: p.background,
        child: const SizedBox(),
      );
    }
    final records = ref.watch(recordsOfProvider(goalId)).value ?? const [];
    final milestones =
        ref.watch(milestonesOfProvider(goalId)).value ?? const [];
    final today = ref.watch(todayProvider);
    final next = milestones.where((m) => !m.isDone).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final color = GoalPalette.byKey(
      goal.colorKey,
      brightness: TargetPalette.brightnessOf(context),
    );

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      resizeToAvoidBottomInset: false,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            minimum: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeaderTextButton(
                    label: Copy.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  CircleIconButton(
                    size: 40,
                    iconSize: 16,
                    icon: CupertinoIcons.ellipsis,
                    onTap: () => showGoalMenu(context, ref, goal),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name, style: text.displayM),
                if (goal.why != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    goal.why!,
                    style: text.bodyM.copyWith(color: p.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              children: [
                _contextChips(
                  context,
                  goal,
                  milestones.length,
                  milestones.where((m) => m.isDone).length,
                ),
                const SizedBox(height: 12),
                _statCard(context, goal, records.length, today),
                const SizedBox(height: 16),
                if (next.isNotEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => MilestonesPage(goalId: goalId),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.flag,
                            size: 17,
                            color: p.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Copy.milestoneEntryTitle,
                                style: text.titleM,
                              ),
                              Text(
                                Copy.nextWaypoint(next.first.title),
                                style: text.bodyS.copyWith(
                                  color: p.onSurfaceTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 14,
                          color: p.onSurfaceTertiary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(Copy.detailRecords, style: text.titleM),
                ),
                for (final (i, r) in records.indexed)
                  _TimelineRow(
                    record: r,
                    isLast: i == records.length - 1,
                    today: today,
                    color: color,
                    milestoneTitle: milestones
                        .where((m) => m.id == r.milestoneId)
                        .firstOrNull
                        ?.title,
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: p.accent,
                  disabledColor: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: () => showRecordSheet(context, goalId: goalId),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.square_pencil,
                        size: 17,
                        color: p.accentOn,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Copy.recordProgress,
                        style: text.titleM.copyWith(color: p.accentOn),
                      ),
                    ],
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

/// 上下文 chips：分类 / 状态 / 执行节奏 / 里程碑进度。
Widget _contextChips(
  BuildContext context,
  Goal goal,
  int milestoneTotal,
  int milestoneDone,
) {
  final p = TargetPalette.of(context);
  final color = GoalPalette.byKey(
    goal.colorKey,
    brightness: TargetPalette.brightnessOf(context),
  );
  final (statusLabel, statusColor) = switch (goal.status) {
    GoalStatus.active => (Copy.statusActive, p.accent),
    GoalStatus.paused => (Copy.statusPaused, p.onSurfaceTertiary),
    GoalStatus.achieved => (Copy.statusAchieved, p.positive),
    GoalStatus.archived => (Copy.statusArchived, p.onSurfaceTertiary),
  };
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          label: goal.categoryKey == null
              ? Copy.categoryUncategorized
              : Copy.categoryOf(goal.categoryKey!.name),
          color: color,
        ),
        _InfoChip(label: statusLabel, color: statusColor),
        if (goal.frequency != null)
          _InfoChip(label: _freqLabel(goal.frequency!), color: p.milestone),
        if (milestoneTotal > 0)
          _InfoChip(
            label: Copy.detailMilestonesDone(milestoneDone, milestoneTotal),
            color: p.onSurfaceTertiary,
          ),
      ],
    ),
  );
}

/// 统计卡：坚持天数 / 剩余时间 / 累计记录。
Widget _statCard(
  BuildContext context,
  Goal goal,
  int recordCount,
  LocalDate today,
) {
  final p = TargetPalette.of(context);
  final text = AppText.of(context);
  final dayN = (_daysBetween(goal.createdAt, today) + 1).clamp(1, 999999);
  final String deadline;
  if (goal.targetDate == null) {
    deadline = Copy.detailNoDeadline;
  } else {
    final left = _daysBetween(today, goal.targetDate!);
    deadline = left >= 0 ? Copy.detailDaysLeft(left) : Copy.detailNoDeadline;
  }
  return AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Expanded(child: _stat(text, Copy.detailDayN(dayN), Copy.detailStatDay)),
        Container(width: 0.5, height: 28, color: p.divider),
        Expanded(child: _stat(text, deadline, Copy.detailStatDeadline)),
        Container(width: 0.5, height: 28, color: p.divider),
        Expanded(
          child: _stat(
            text,
            Copy.detailRecordCount(recordCount),
            Copy.detailStatRecord,
          ),
        ),
      ],
    ),
  );
}

Widget _stat(AppText text, String value, String label) {
  return Column(
    children: [
      Text(value, style: text.titleM),
      const SizedBox(height: 2),
      Text(label, style: text.labelS),
    ],
  );
}

int _daysBetween(LocalDate a, LocalDate b) => DateTime(
  b.year,
  b.month,
  b.day,
).difference(DateTime(a.year, a.month, a.day)).inDays;

String _freqLabel(FrequencyPattern f) => switch (f) {
  DailyFrequency() => Copy.freqDaily,
  WeeklyFrequency(:final timesPerWeek) => '每周$timesPerWeek次',
  WeekdaysFrequency() => Copy.freqWeekdays,
};

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: text.bodyS.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.record,
    required this.isLast,
    required this.today,
    required this.color,
    this.milestoneTitle,
  });

  final ProgressRecord record;
  final bool isLast;
  final LocalDate today;
  final Color color;

  /// 关联里程碑标题（无关联为 null）。
  final String? milestoneTitle;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final isMilestone = record.kind == RecordKind.milestoneAchievement;
    final linkedMilestone =
        !isMilestone && milestoneTitle != null && milestoneTitle!.isNotEmpty;
    final body = record.body;
    final hasBody = !isMilestone && body != null && body.trim().isNotEmpty;
    final hasDuration = record.durationMinutes != null;

    // 节点图形多样化（与动态 feed 共用 recordNodeIcon）。
    final milestoneNode = isMilestone || linkedMilestone;
    final nodeIcon = recordNodeIcon(
      milestone: isMilestone,
      linkedMilestone: linkedMilestone,
      hasDuration: hasDuration,
      hasBody: hasBody,
    );
    final nodeColor = milestoneNode
        ? p.milestone
        : (isLast ? p.accent : p.onSurfaceVariant);
    final nodeBg = milestoneNode
        ? p.milestoneTint
        : (isLast ? p.accentTint : p.divider);

    // 内容卡仅在有正文（或里程碑达成）时渲染。
    final showCard = isMilestone || hasBody;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: nodeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(nodeIcon, size: 15, color: nodeColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: p.divider,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMilestone ? Copy.milestoneAchievedEntry : record.title,
                    style: text.titleS,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _metaLine(hasDuration, linkedMilestone),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyS.copyWith(color: p.onSurfaceTertiary),
                  ),
                  if (showCard) ...[
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        isMilestone ? record.title : body!,
                        style: text.bodyM.copyWith(color: p.onSurface),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 元信息行：日期时间（精确到秒）· 时长 · 关联里程碑。
  String _metaLine(bool hasDuration, bool linkedMilestone) {
    return [
      timestampLabel(record.day, today, record.createdAt.toLocal()),
      if (hasDuration) Copy.durationMinutes(record.durationMinutes!),
      if (linkedMilestone) Copy.recordMilestoneLink(milestoneTitle!),
    ].join(' · ');
  }
}
