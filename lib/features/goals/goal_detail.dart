/// v3 目标详情：⋯ 菜单 + 名称/为什么 + 下个里程碑卡 + 富记录时间线
/// + 底部「记录进展」CTA（R1 定稿）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/relative_time.dart';
import '../shared/record_sheet.dart';
import 'goal_menu.dart';
import 'milestones_view.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    final goal = ref
        .watch(goalsProvider)
        .valueOrNull
        ?.where((g) => g.id == goalId)
        .firstOrNull;
    if (goal == null) {
      return Scaffold(backgroundColor: p.background, body: const SizedBox());
    }
    final records = ref.watch(recordsOfProvider(goalId)).value ?? const [];
    final milestones =
        ref.watch(milestonesOfProvider(goalId)).value ?? const [];
    final today = ref.watch(todayProvider);
    final next = milestones.where((m) => !m.isDone).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final color = GoalPalette.byKey(
        goal.colorKey, brightness: Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleBtn(context, Icons.chevron_left,
                      () => Navigator.of(context).pop()),
                  _circleBtn(
                      context, Icons.more_horiz, () => showGoalMenu(context, ref, goal)),
                ],
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
                      style:
                          text.bodyM.copyWith(color: p.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  if (next.isNotEmpty)
                    Material(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                MilestonesPage(goalId: goalId),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            boxShadow: p.shadowLow,
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
                                child: Icon(Icons.flag_outlined,
                                    size: 17, color: p.onSurface),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(Copy.milestoneEntryTitle,
                                        style: text.titleM),
                                    Text(
                                      Copy.nextWaypoint(next.first.title),
                                      style: text.bodyS.copyWith(
                                          color: p.onSurfaceTertiary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 14,
                                  color: p.onSurfaceTertiary
                                      .withValues(alpha: 0.6)),
                            ],
                          ),
                        ),
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
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            onPressed: () => showRecordSheet(context, goalId: goalId),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 17),
                SizedBox(width: 8),
                Text(Copy.recordProgress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: p.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 16, color: p.onSurface),
        ),
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
  });

  final ProgressRecord record;
  final bool isLast;
  final LocalDate today;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    final isMilestone = record.kind == RecordKind.milestoneAchievement;
    final nodeColor =
        isMilestone ? p.milestone : (isLast ? p.accent : p.divider);
    final nodeBg = isMilestone ? p.milestoneTint : (isLast ? p.accentTint : p.divider);
    final dayLabel = relativeDayLabel(record.day, today);

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
                  decoration: BoxDecoration(color: nodeBg, shape: BoxShape.circle),
                  child: Icon(
                    isMilestone
                        ? Icons.flag
                        : Icons.edit_outlined,
                    size: 15,
                    color: nodeColor,
                  ),
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
                    isMilestone
                        ? Copy.milestoneAchievedEntry
                        : record.title,
                    style: text.titleS,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayLabel,
                    style:
                        text.bodyS.copyWith(color: p.onSurfaceTertiary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: p.shadowLow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMilestone ? record.title : (record.body ?? ''),
                          style: text.bodyM
                              .copyWith(color: p.onSurface),
                        ),
                        if (!isMilestone &&
                            record.body != null &&
                            record.body!.trim().isNotEmpty)
                          const SizedBox(height: 0),
                        if (record.durationMinutes != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 13, color: p.onSurfaceTertiary),
                              const SizedBox(width: 6),
                              Text(
                                Copy.durationMinutes(
                                    record.durationMinutes!),
                                style: text.bodyS.copyWith(
                                    color: p.onSurfaceTertiary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
