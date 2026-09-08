/// v3 记录进展 sheet（富记录；R1–R3 定稿，系统样式头部）。
/// v3.1：Cupertino 组件重写——AppSheet 容器、CupertinoTextField、
/// CupertinoListTile meta 行、ActionSheet/DatePicker 选择器、AppToast。
///
/// 全局记录钮 / 详情 CTA / 菜单共用；目标切换（暂停/归档不列）；
/// 标题必填 + 正文 + 时长快捷档 + 日期（今天/昨天/更早）+ 里程碑关联。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../app/sheet.dart';
import '../../app/toast.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import 'goal_card.dart' show goalIconData;

Future<void> showRecordSheet(
  BuildContext context, {
  String? goalId,
}) {
  return showAppSheet(
    context,
    builder: (_) => _RecordSheet(initialGoalId: goalId),
  );
}

class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet({this.initialGoalId});

  final String? initialGoalId;

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _goalId;
  int? _duration;
  LocalDate? _day;
  String? _milestoneId;
  bool _switching = false;

  static const _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _goalId = widget.initialGoalId;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty && _goalId != null;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final goals =
        ref.watch(goalsProvider).value ?? const <Goal>[];
    final recordable = goals
        .where((g) =>
            g.status == GoalStatus.active || g.status == GoalStatus.paused)
        .toList();
    final goal = recordable.where((g) => g.id == _goalId).firstOrNull ??
        recordable.firstOrNull;
    _goalId = goal?.id;
    final milestones = (ref.watch(milestonesOfProvider(_goalId ?? '')).value ??
            const <Milestone>[])
        .where((m) => !m.isDone)
        .toList();
    final today = ref.watch(todayProvider);

    return AppSheet(
      resizeForKeyboard: true,
      maxHeightFactor: 0.92,
      title: Copy.recordSheetTitle,
      leading: HeaderTextButton(
        label: Copy.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailing: HeaderTextButton(
        label: Copy.save,
        emphasized: true,
        onTap: _canSave ? _save : null,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          if (recordable.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(Copy.goalsEmptyBody,
                  style: text.bodyM,
                  textAlign: TextAlign.center),
            )
          else ...[
            _label(context, Copy.recordGoalLabel),
            _goalSelector(context, recordable, goal),
            const SizedBox(height: 16),
            _label(context, Copy.recordWhatLabel),
            _editorCard(context),
            const SizedBox(height: 20),
            _label(context, Copy.recordDuration),
            _metaRows(context, milestones, today),
            const SizedBox(height: 12),
            Center(
              child: Text(
                Copy.recordSlogan,
                style: text.bodyS
                    .copyWith(color: TargetPalette.of(context).onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String s) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        s,
        style: text.bodyS.copyWith(color: p.onSurfaceVariant),
      ),
    );
  }

  Widget _goalSelector(BuildContext context, List<Goal> goals, Goal? cur) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    if (cur == null) return const SizedBox.shrink();
    final color = GoalPalette.byKey(
        cur.colorKey, brightness: TargetPalette.brightnessOf(context));
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _switching = !_switching),
            child: Row(
              children: [
                Icon(_goalIcon(cur), size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cur.name,
                    style: text.bodyL
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(CupertinoIcons.chevron_up_chevron_down,
                    size: 16, color: p.onSurfaceTertiary),
              ],
            ),
          ),
          if (_switching)
            for (final g in goals.where((g) => g.id != cur.id))
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() {
                  _goalId = g.id;
                  _milestoneId = null;
                  _switching = false;
                }),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(_goalIcon(g),
                          size: 18,
                          color: GoalPalette.byKey(
                              g.colorKey,
                              brightness:
                                  TargetPalette.brightnessOf(context))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(g.name, style: text.bodyL)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  IconData _goalIcon(Goal g) => goalIconData(g.iconKey);

  Widget _editorCard(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        children: [
          CupertinoTextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            style: text.bodyL.copyWith(fontWeight: FontWeight.w600),
            placeholder: Copy.recordTitleHint,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: p.divider, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          CupertinoTextField(
            controller: _body,
            maxLines: 4,
            minLines: 3,
            style: text.bodyM,
            placeholder: Copy.recordBodyHint,
            decoration: const BoxDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _metaRows(
    BuildContext context,
    List<Milestone> milestones,
    LocalDate today,
  ) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final day = _day ?? today;
    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      topMargin: null,
      backgroundColor: CupertinoColors.transparent,
      separatorColor: p.divider,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      children: [
        CupertinoListTile(
          leading: Icon(CupertinoIcons.clock, size: 20, color: p.onSurface),
          title: Text(Copy.recordDuration),
          additionalInfo: Text(
            _duration == null
                ? Copy.recordMilestonePick
                : Copy.durationMinutes(_duration!),
            style: text.bodyM,
          ),
          backgroundColor: p.surface,
          onTap: _pickDuration,
        ),
        CupertinoListTile(
          leading: Icon(CupertinoIcons.calendar, size: 20, color: p.onSurface),
          title: Text(Copy.recordDate),
          additionalInfo: Text(
            day.isoString,
            style: text.bodyM,
          ),
          backgroundColor: p.surface,
          onTap: () => _pickDate(today),
        ),
        CupertinoListTile(
          leading: Icon(CupertinoIcons.flag, size: 20, color: p.onSurface),
          title: Text(Copy.recordMilestone),
          additionalInfo: Text(
            _milestoneId == null
                ? Copy.recordMilestonePick
                : milestones
                    .firstWhere((m) => m.id == _milestoneId)
                    .title,
            style: text.bodyM,
          ),
          backgroundColor: p.surface,
          onTap: () => _pickMilestone(milestones),
        ),
      ],
    );
  }

  Future<void> _pickDuration() async {
    final chosen = await showAppChoiceSheet<int>(
      context,
      title: Copy.durationQuestion,
      selected: _duration,
      options: [
        for (final m in _durations) (m, Copy.durationMinutes(m)),
      ],
    );
    if (chosen != null) setState(() => _duration = chosen);
  }

  Future<void> _pickDate(LocalDate today) async {
    final picked = await showAppDatePicker(
      context,
      initial: DateTime.now(),
      first: DateTime(2020),
      last: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _day = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _pickMilestone(List<Milestone> milestones) async {
    if (milestones.isEmpty) return;
    final chosen = await showAppChoiceSheet<String>(
      context,
      title: Copy.recordMilestone,
      selected: _milestoneId,
      options: [
        for (final m in milestones) (m.id, m.title),
        ('', Copy.recordMilestonePick),
      ],
    );
    if (chosen != null) setState(() => _milestoneId = chosen.isEmpty ? null : chosen);
  }

  Future<void> _save() async {
    final goalId = _goalId;
    if (goalId == null || !_canSave) return;
    final today = ref.read(todayProvider);
    final record = await ref.read(recordRepoProvider).add(
          ProgressRecord(
            goalId: goalId,
            title: _title.text.trim(),
            body: _body.text.trim().isEmpty ? null : _body.text.trim(),
            durationMinutes: _duration,
            day: _day ?? today,
            createdAt: DateTime.now().toUtc(),
            milestoneId: _milestoneId,
          ),
          today: today,
        );
    if (!mounted) return;
    AppToast.show(
      context,
      Copy.recordSavedToast,
      actionLabel: Copy.undo,
      onAction: () => ref.read(recordRepoProvider).remove(record.id),
    );
    Navigator.of(context).pop();
  }
}
