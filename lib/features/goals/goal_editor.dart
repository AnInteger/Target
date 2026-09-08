/// v3 目标编辑器（R2 定稿：属性行 + 选择器 sheet；名称必填即可保存）。
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';
import 'goal_icon_picker.dart';
import '../shared/goal_card.dart' show goalIconData;

class GoalEditorPage extends ConsumerStatefulWidget {
  const GoalEditorPage({super.key, this.goalId});

  final String? goalId;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  final _name = TextEditingController();
  final _why = TextEditingController();
  GoalCategory? _category;
  String _iconKey = 'target';
  String? _colorKey;
  bool _pinned = false;
  LocalDate? _targetDate;
  FrequencyPattern? _frequency;
  bool _reminderEnabled = false;
  LocalTime _reminderTime = const LocalTime(9, 0);
  Cadence _reminderCadence = Cadence.daily;
  final _milestones = <(TextEditingController, TextEditingController)>[];
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _why.dispose();
    for (final (t, d) in _milestones) {
      t.dispose();
      d.dispose();
    }
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final editing = widget.goalId != null;
    if (editing && !_loaded) _loadExisting();
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context, editing),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  if (!editing) ...[
                    Text(Copy.editorHeroTitle, style: text.displayS),
                    const SizedBox(height: 4),
                    Text(
                      Copy.editorHeroSubtitle,
                      style:
                          text.bodyM.copyWith(color: p.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _card(
                    child: Column(
                      children: [
                        _field(Copy.fieldName, _name, Copy.fieldNameHint,
                            onChanged: (_) => setState(() {})),
                        const SizedBox(height: 16),
                        _field(Copy.fieldWhy, _why, Copy.fieldWhyHint,
                            maxLines: 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    child: Column(
                      children: [
                        _row(
                          Copy.fieldCategory,
                          _category == null
                              ? Copy.categoryUncategorized
                              : Copy.categoryOf(_category!.name),
                          onTap: _pickCategory,
                        ),
                        _divider(),
                        _row(
                          Copy.fieldIconColor,
                          '',
                          onTap: _pickIcon,
                          trailing: Row(
                            children: [
                              Icon(
                                goalIconData(_iconKey),
                                size: 18,
                                color: GoalPalette.byKey(
                                  _colorKey ??
                                      (_category?.defaultColorKey ??
                                          'gray'),
                                  brightness: Theme.of(context).brightness,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _colorDot(context),
                            ],
                          ),
                        ),
                        _divider(),
                        _row(
                          Copy.fieldPinned,
                          '',
                          trailing: Switch(
                            value: _pinned,
                            onChanged: (v) => setState(() => _pinned = v),
                          ),
                        ),
                        _divider(),
                        _row(
                          Copy.fieldTargetDate,
                          _targetDate == null
                              ? Copy.dateNone
                              : _targetDate!.isoString,
                          onTap: _pickDate,
                        ),
                        _divider(),
                        _row(
                          Copy.fieldFrequency,
                          _frequency == null
                              ? Copy.freqNone
                              : _frequencyLabel(_frequency!),
                          onTap: _pickFrequency,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label(Copy.reminderGroup),
                  _card(
                    child: Column(
                      children: [
                        _row(
                          Copy.reminderToggle,
                          '',
                          trailing: Switch(
                            value: _reminderEnabled,
                            onChanged: (v) =>
                                setState(() => _reminderEnabled = v),
                          ),
                        ),
                        if (_reminderEnabled) ...[
                          _divider(),
                          _row(
                            Copy.reminderTime,
                            _reminderTime.isoString,
                            onTap: _pickTime,
                          ),
                          _divider(),
                          _row(
                            Copy.reminderCadence,
                            _cadenceLabel(_reminderCadence),
                            onTap: _pickCadence,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label(
                      editing ? Copy.milestoneGroup : Copy.firstMilestoneGroup),
                  for (final (i, (t, d)) in _milestones.indexed) ...[
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: t,
                                  style: text.bodyL
                                      .copyWith(fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: Copy.milestoneFieldTitle,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close,
                                    size: 16, color: p.danger),
                                onPressed: () =>
                                    setState(() => _milestones.removeAt(i)),
                              ),
                            ],
                          ),
                          TextField(
                            controller: d,
                            style: text.bodyM,
                            decoration: InputDecoration(
                              hintText: Copy.milestoneFieldDesc,
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _card(
                    onTap: () => setState(() => _milestones.add((
                          TextEditingController(),
                          TextEditingController(),
                        ))),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined,
                            size: 18, color: p.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          Copy.milestonesAdd,
                          style:
                              text.bodyL.copyWith(color: p.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Copy.editorNote,
                    style:
                        text.bodyS.copyWith(color: p.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 头部（系统样式文本按钮） ----

  Widget _header(BuildContext context, bool editing) {
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
              child: Text(
                editing ? Copy.editorEditTitle : Copy.editorAddTitle,
                style: text.titleM,
              ),
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

  // ---- 组件 ----

  Widget _card({required Widget child, VoidCallback? onTap}) {
    final p = TargetPalette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: p.shadowLow,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _divider() {
    final p = TargetPalette.of(context);
    return Divider(height: 1, color: p.divider);
  }

  Widget _label(String s) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child:
          Text(s, style: text.bodyS.copyWith(color: p.onSurfaceVariant)),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: text.bodyS.copyWith(color: p.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: text.bodyL,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: p.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: p.divider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(child: Text(label, style: text.bodyL)),
            if (value.isNotEmpty)
              Text(
                value,
                style: text.bodyM.copyWith(color: p.onSurfaceVariant),
              ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
            if (trailing == null)
              Icon(Icons.chevron_right,
                  size: 14,
                  color: p.onSurfaceTertiary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(BuildContext context) {
    final color = GoalPalette.byKey(
      _colorKey ?? (_category?.defaultColorKey ?? 'gray'),
      brightness: Theme.of(context).brightness,
    );
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ---- 选择器 ----

  Future<void> _pickCategory() async {
    final p = TargetPalette.of(context);
    final chosen = await showModalBottomSheet<GoalCategory>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
              for (final c in GoalCategory.values)
                ListTile(
                  title: Text(Copy.categoryOf(c.name)),
                  onTap: () => Navigator.of(context).pop(c),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      setState(() {
        _category = chosen;
        _colorKey = chosen.defaultColorKey;
      });
    }
  }

  Future<void> _pickIcon() async {
    final result = await showGoalIconPicker(
      context,
      initialIconKey: _iconKey,
      initialColorKey: _colorKey ?? _category?.defaultColorKey ?? 'gray',
    );
    if (result != null) {
      setState(() {
        _iconKey = result.$1;
        _colorKey = result.$2;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _targetDate == null
              ? DateTime.now()
              : DateTime(_targetDate!.year, _targetDate!.month, _targetDate!.day),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _targetDate = LocalDate.fromDateTime(picked));
  }

  Future<void> _pickFrequency() async {
    final p = TargetPalette.of(context);
    var weeklyTimes = 3;
    final weekdays = <int>{1, 3};
    var mode = 0; // 0 不设 1 每天 2 每周N次 3 指定星期

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      Copy.frequencySheetTitle,
                      style: Theme.of(sheetContext).textTheme.titleM,
                    ),
                  ),
                ),
                Text(Copy.frequencyQuestion),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, label) in [
                      Copy.freqNone,
                      Copy.freqDaily,
                      Copy.freqWeekly,
                      Copy.freqWeekdays,
                    ].indexed)
                      ChoiceChip(
                        label: Text(label),
                        selected: mode == i,
                        onSelected: (_) => setSheet(() => mode = i),
                      ),
                  ],
                ),
                if (mode == 2)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setSheet(
                            () => weeklyTimes = (weeklyTimes - 1).clamp(1, 7)),
                      ),
                      Text('$weeklyTimes 次 / 周'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setSheet(
                            () => weeklyTimes = (weeklyTimes + 1).clamp(1, 7)),
                      ),
                    ],
                  ),
                if (mode == 3)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final d in [1, 2, 3, 4, 5, 6, 7])
                        FilterChip(
                          label: Text('一二三四五六日'[d - 1]),
                          selected: weekdays.contains(d),
                          onSelected: (on) => setSheet(() {
                            on ? weekdays.add(d) : weekdays.remove(d);
                          }),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: const Text(Copy.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: const Text(Copy.done),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _frequency = switch (mode) {
        1 => const DailyFrequency(1),
        2 => WeeklyFrequency(weeklyTimes),
        3 => WeekdaysFrequency(
            weekdays.map(Weekday.fromIso).toSet(),
            1,
          ),
        _ => null,
      };
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderTime.hour, minute: _reminderTime.minute),
    );
    if (picked != null) {
      setState(
          () => _reminderTime = LocalTime(picked.hour, picked.minute));
    }
  }

  Future<void> _pickCadence() async {
    final p = TargetPalette.of(context);
    final chosen = await showModalBottomSheet<Cadence>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
              for (final c in Cadence.values)
                ListTile(
                  title: Text(_cadenceLabel(c)),
                  onTap: () => Navigator.of(context).pop(c),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) setState(() => _reminderCadence = chosen);
  }

  // ---- 加载 / 保存 ----

  void _loadExisting() {
    final goal = ref
        .read(goalsProvider)
        .valueOrNull
        ?.where((g) => g.id == widget.goalId)
        .firstOrNull;
    if (goal == null) {
      _loaded = true;
      return;
    }
    _name.text = goal.name;
    _why.text = goal.why ?? '';
    _category = goal.categoryKey;
    _iconKey = goal.iconKey;
    _colorKey = goal.colorKey;
    _pinned = goal.pinned;
    _targetDate = goal.targetDate;
    _frequency = goal.frequency;
    _loaded = true;
    unawaited(
        ref.read(reminderRepoProvider).of(goal.id).then((r) {
      if (r != null && mounted) {
        setState(() {
          _reminderEnabled = r.isEnabled;
          _reminderTime = r.time;
          _reminderCadence = r.cadence;
        });
      }
    }));
    unawaited(
        ref.read(milestonesOfProvider(goal.id).future).then((ms) {
      if (!mounted) return;
      setState(() {
        for (final m in ms) {
          final t = TextEditingController(text: m.title);
          final d = TextEditingController(text: m.description ?? '');
          _milestones.add((t, d));
        }
      });
    }));
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final today = ref.read(todayProvider);
    final editing = widget.goalId != null;
    final existing = editing
        ? ref.read(goalsProvider).valueOrNull
        ?.where((g) => g.id == widget.goalId)
            .firstOrNull
        : null;

    final goal = Goal(
      id: existing?.id,
      name: _name.text.trim(),
      why: _why.text.trim().isEmpty ? null : _why.text.trim(),
      categoryKey: _category,
      iconKey: _iconKey,
      colorKey: _colorKey,
      pinned: _pinned,
      pinnedOrder: existing?.pinnedOrder,
      targetDate: _targetDate,
      frequency: _frequency,
      status: existing?.status ?? GoalStatus.active,
      achievedAt: existing?.achievedAt,
      archivedAt: existing?.archivedAt,
      createdAt: existing?.createdAt ?? today,
    );

    final milestones = [
      for (final (t, d) in _milestones)
        if (t.text.trim().isNotEmpty)
          Milestone(
            goalId: goal.id,
            title: t.text.trim(),
            description: d.text.trim().isEmpty ? null : d.text.trim(),
            position: 0,
          ),
    ];

    if (editing) {
      await ref.read(goalRepoProvider).update(goal);
      await ref.read(milestoneRepoProvider).reorderFromEditor(
            goal.id,
            milestones,
          );
      await ref.read(reminderRepoProvider).upsert(Reminder(
            goalId: goal.id,
            time: _reminderTime,
            isEnabled: _reminderEnabled,
            cadence: _reminderCadence,
          ));
    } else {
      await ref.read(goalRepoProvider).createPlan(
            goal,
            milestones,
            reminder: _reminderEnabled
                ? Reminder(
                    goalId: goal.id,
                    time: _reminderTime,
                    isEnabled: true,
                    cadence: _reminderCadence,
                  )
                : null,
          );
      if (_pinned) {
        await ref.read(goalRepoProvider).setPinned(goal.id, true);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(Copy.editorGoalSavedToast)));
    }
  }
}

String _frequencyLabel(FrequencyPattern f) => switch (f) {
      DailyFrequency() => Copy.freqDaily,
      WeeklyFrequency(:final timesPerWeek) =>
        '${Copy.freqWeekly}（$timesPerWeek）',
      WeekdaysFrequency() => Copy.freqWeekdays,
    };

String _cadenceLabel(Cadence c) => switch (c) {
      Cadence.daily => Copy.cadenceDaily,
      Cadence.threeDay => Copy.cadenceThreeDay,
      Cadence.weekly => Copy.cadenceWeekly,
    };
