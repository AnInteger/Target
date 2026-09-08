/// v3 记录进展 sheet（富记录；R1–R3 定稿，系统样式头部）。
///
/// 全局记录钮 / 详情 CTA / 菜单共用；目标切换（暂停/归档不列）；
/// 标题必填 + 正文 + 时长快捷档 + 日期（今天/昨天/更早）+ 里程碑关联。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import 'goal_card.dart' show goalIconData;

Future<void> showRecordSheet(
  BuildContext context, {
  String? goalId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
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
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
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

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            grabber(context),
            _header(context),
            Flexible(
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
                            .copyWith(color: p.onSurfaceVariant),
                      ),
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

  Widget grabber(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: TargetPalette.of(context).divider,
          borderRadius: BorderRadius.circular(3),
        ),
      );

  Widget _header(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              Copy.cancel,
              style: text.bodyL.copyWith(color: p.accentText),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(Copy.recordSheetTitle, style: text.titleM),
            ),
          ),
          GestureDetector(
            onTap: _canSave ? _save : null,
            child: Text(
              Copy.save,
              style: text.bodyL.copyWith(
                color: _canSave ? p.accentText : p.onSurfaceTertiary,
                fontWeight: _canSave ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String s) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
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
    final text = Theme.of(context).textTheme;
    if (cur == null) return const SizedBox.shrink();
    final color = GoalPalette.byKey(
        cur.colorKey, brightness: Theme.of(context).brightness);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => setState(() => _switching = !_switching),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(
            children: [
              Row(
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
                  Icon(Icons.unfold_more,
                      size: 16, color: p.onSurfaceTertiary),
                ],
              ),
              if (_switching)
                for (final g in goals.where((g) => g.id != cur.id))
                  InkWell(
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
                                      Theme.of(context).brightness)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(g.name, style: text.bodyL)),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _goalIcon(Goal g) => goalIconData(g.iconKey);

  Widget _editorCard(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      child: Column(
        children: [
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            style: text.bodyL.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: Copy.recordTitleHint,
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: p.divider, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            maxLines: 4,
            minLines: 3,
            style: text.bodyM,
            decoration: InputDecoration(
              hintText: Copy.recordBodyHint,
              border: InputBorder.none,
            ),
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
    final text = Theme.of(context).textTheme;
    final day = _day ?? today;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule, size: 17),
            title: Text(Copy.recordDuration, style: text.bodyL),
            trailing: Text(
              _duration == null
                  ? Copy.recordMilestonePick
                  : Copy.durationMinutes(_duration!),
              style: text.bodyM.copyWith(color: p.onSurfaceVariant),
            ),
            onTap: _pickDuration,
          ),
          Divider(height: 1, color: p.divider),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined, size: 17),
            title: Text(Copy.recordDate, style: text.bodyL),
            trailing: Text(
              day.isoString,
              style: text.bodyM.copyWith(color: p.onSurfaceVariant),
            ),
            onTap: () => _pickDate(today),
          ),
          Divider(height: 1, color: p.divider),
          ListTile(
            leading: const Icon(Icons.flag_outlined, size: 17),
            title: Text(Copy.recordMilestone, style: text.bodyL),
            trailing: Text(
              _milestoneId == null
                  ? Copy.recordMilestonePick
                  : milestones
                      .firstWhere((m) => m.id == _milestoneId)
                      .title,
              style: text.bodyM.copyWith(color: p.onSurfaceVariant),
            ),
            onTap: () => _pickMilestone(milestones),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDuration() async {
    final p = TargetPalette.of(context);
    final chosen = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(Copy.durationQuestion,
                    style: Theme.of(context).textTheme.titleM),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _durations)
                      ActionChip(
                        label: Text(Copy.durationMinutes(m)),
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(m),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) setState(() => _duration = chosen);
  }

  Future<void> _pickDate(LocalDate today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _day = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _pickMilestone(List<Milestone> milestones) async {
    if (milestones.isEmpty) return;
    final p = TargetPalette.of(context);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              for (final m in milestones)
                ListTile(
                  title: Text(m.title),
                  onTap: () => Navigator.of(sheetContext).pop(m.id),
                ),
              ListTile(
                title: Text(Copy.recordMilestonePick),
                onTap: () => Navigator.of(sheetContext).pop(''),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(Copy.recordSavedToast),
        action: SnackBarAction(
          label: Copy.undo,
          onPressed: () => ref.read(recordRepoProvider).remove(record.id),
        ),
      ),
    );
  }
}
