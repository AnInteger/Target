/// v3 目标编辑器（R2 定稿：属性行 + 选择器 sheet；名称必填即可保存）。
/// v3.1：Cupertino 组件重写——CupertinoListSection/ListTile 属性行、
/// CupertinoTextField、CupertinoSwitch、CupertinoSlidingSegmentedControl、
/// CupertinoActionSheet/CupertinoDatePicker 选择器。
library;

import 'dart:async' show unawaited;

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
  String _iconKey = 'explore';
  String? _colorKey;

  /// 新建默认置顶（大卡样式即门面；编辑既有目标时由 loadExisting 覆盖）。
  bool _pinned = true;

  /// 用户已手动选过图标 → 分类联动不再覆盖。
  bool _iconPicked = false;
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
    final text = AppText.of(context);

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            _header(context, editing),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // R11b：去掉口号式 hero 大标题（头部已有「添加目标」）。
                  _card(
                    child: Column(
                      children: [
                        _field(
                          Copy.fieldName,
                          _name,
                          Copy.fieldNameHint,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          Copy.fieldWhy,
                          _why,
                          Copy.fieldWhyHint,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _propertySection(
                    context,
                    children: [
                      CupertinoListTile(
                        title: Text(Copy.fieldCategory),
                        additionalInfo: Text(
                          _category == null
                              ? Copy.categoryUncategorized
                              : Copy.categoryOf(_category!.name),
                          style: text.bodyM,
                        ),
                        trailing: _chevron(context),
                        backgroundColor: p.surface,
                        onTap: _pickCategory,
                      ),
                      CupertinoListTile(
                        title: Text(Copy.fieldIconColor),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              goalIconData(_iconKey),
                              size: 18,
                              color: GoalPalette.byKey(
                                _colorKey ??
                                    (_category?.defaultColorKey ?? 'gray'),
                                brightness: TargetPalette.brightnessOf(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _colorDot(context),
                            const SizedBox(width: 8),
                            _chevron(context),
                          ],
                        ),
                        backgroundColor: p.surface,
                        onTap: _pickIcon,
                      ),
                      CupertinoListTile(
                        title: Text(Copy.fieldPinned),
                        trailing: CupertinoSwitch(
                          value: _pinned,
                          activeTrackColor: p.accent,
                          onChanged: (v) => setState(() => _pinned = v),
                        ),
                        backgroundColor: p.surface,
                      ),
                      CupertinoListTile(
                        title: Text(Copy.fieldTargetDate),
                        additionalInfo: Text(
                          _targetDate == null
                              ? Copy.dateNone
                              : _targetDate!.isoString,
                          style: text.bodyM,
                        ),
                        trailing: _chevron(context),
                        backgroundColor: p.surface,
                        onTap: _pickDate,
                      ),
                      CupertinoListTile(
                        title: Text(Copy.fieldFrequency),
                        additionalInfo: Text(
                          _frequency == null
                              ? Copy.freqNone
                              : _frequencyLabel(_frequency!),
                          style: text.bodyM,
                        ),
                        trailing: _chevron(context),
                        backgroundColor: p.surface,
                        onTap: _pickFrequency,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label(Copy.reminderGroup),
                  _propertySection(
                    context,
                    children: [
                      CupertinoListTile(
                        title: Text(Copy.reminderToggle),
                        trailing: CupertinoSwitch(
                          value: _reminderEnabled,
                          activeTrackColor: p.accent,
                          onChanged: (v) =>
                              setState(() => _reminderEnabled = v),
                        ),
                        backgroundColor: p.surface,
                      ),
                      if (_reminderEnabled) ...[
                        CupertinoListTile(
                          title: Text(Copy.reminderTime),
                          additionalInfo: Text(
                            _reminderTime.isoString,
                            style: text.bodyM,
                          ),
                          trailing: _chevron(context),
                          backgroundColor: p.surface,
                          onTap: _pickTime,
                        ),
                        CupertinoListTile(
                          title: Text(Copy.reminderCadence),
                          additionalInfo: Text(
                            _cadenceLabel(_reminderCadence),
                            style: text.bodyM,
                          ),
                          trailing: _chevron(context),
                          backgroundColor: p.surface,
                          onTap: _pickCadence,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label(
                    editing ? Copy.milestoneGroup : Copy.firstMilestoneGroup,
                  ),
                  for (final (i, (t, d)) in _milestones.indexed) ...[
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoTextField(
                                  controller: t,
                                  style: text.bodyL.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  placeholder: Copy.milestoneFieldTitle,
                                  decoration: _transparentFieldDecoration,
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.square(30),
                                onPressed: () =>
                                    setState(() => _milestones.removeAt(i)),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  size: 16,
                                  color: p.danger,
                                ),
                              ),
                            ],
                          ),
                          CupertinoTextField(
                            controller: d,
                            style: text.bodyM,
                            placeholder: Copy.milestoneFieldDesc,
                            decoration: _transparentFieldDecoration,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _card(
                    onTap: () => setState(
                      () => _milestones.add((
                        TextEditingController(),
                        TextEditingController(),
                      )),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.flag,
                          size: 18,
                          color: p.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Copy.milestonesAdd,
                          style: text.bodyL.copyWith(color: p.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Copy.editorNote,
                    style: text.bodyS.copyWith(color: p.onSurfaceVariant),
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
    final text = AppText.of(context);
    return Padding(
      // R11：头部按钮与页缘留出安全边距（与内容页缘 20 一致）。
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          HeaderTextButton(
            label: Copy.cancel,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                editing ? Copy.editorEditTitle : Copy.editorAddTitle,
                style: text.titleM,
              ),
            ),
          ),
          HeaderTextButton(
            label: Copy.save,
            emphasized: true,
            onTap: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  // ---- 组件 ----

  BoxDecoration get _transparentFieldDecoration =>
      const BoxDecoration(color: CupertinoColors.transparent);

  Widget _chevron(BuildContext context) {
    final p = TargetPalette.of(context);
    return Icon(
      CupertinoIcons.chevron_forward,
      size: 14,
      color: p.onSurfaceTertiary.withValues(alpha: 0.6),
    );
  }

  Widget _card({required Widget child, VoidCallback? onTap}) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      onTap: onTap,
      child: child,
    );
  }

  Widget _propertySection(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final p = TargetPalette.of(context);
    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      topMargin: null,
      backgroundColor: CupertinoColors.transparent,
      hasLeading: false,
      separatorColor: p.divider,
      // 自带子项裁角固定 10；改由 decoration（28）出圆角、关闭内置
      // 裁剪，避免两套半径相交出缺角（R11b 卡片圆角 28）。
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      children: children,
    );
  }

  Widget _label(String s) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(s, style: text.bodyS.copyWith(color: p.onSurfaceVariant)),
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
    final text = AppText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodyS.copyWith(color: p.onSurfaceVariant)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: text.bodyL,
          placeholder: hint,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: p.divider, width: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _colorDot(BuildContext context) {
    final color = GoalPalette.byKey(
      _colorKey ?? (_category?.defaultColorKey ?? 'gray'),
      brightness: TargetPalette.brightnessOf(context),
    );
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ---- 选择器 ----

  Future<void> _pickCategory() async {
    final chosen = await showAppChoiceSheet<GoalCategory>(
      context,
      title: Copy.fieldCategory,
      selected: _category,
      options: [
        for (final c in GoalCategory.values) (c, Copy.categoryOf(c.name)),
      ],
    );
    if (chosen != null) {
      setState(() {
        _category = chosen;
        _colorKey = chosen.defaultColorKey;
        if (!_iconPicked) _iconKey = chosen.defaultIconKey;
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
        _iconPicked = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initial: _targetDate == null
          ? now
          : DateTime(_targetDate!.year, _targetDate!.month, _targetDate!.day),
      first: now.subtract(const Duration(days: 365)),
      last: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _targetDate = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _pickFrequency() async {
    var weeklyTimes = 3;
    final weekdays = <int>{1, 3};
    var mode = 0; // 0 不设 1 每天 2 每周N次 3 指定星期

    final confirmed = await showAppSheet<bool>(
      context,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final text = AppText.of(sheetContext);
          return AppSheet(
            resizeForKeyboard: false,
            title: Copy.frequencySheetTitle,
            leading: HeaderTextButton(
              label: Copy.cancel,
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
            trailing: HeaderTextButton(
              label: Copy.done,
              emphasized: true,
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoSlidingSegmentedControl<int>(
                      groupValue: mode,
                      onValueChanged: (m) => setSheet(() => mode = m!),
                      children: {
                        for (final (i, label) in [
                          Copy.freqNone,
                          Copy.freqDaily,
                          Copy.freqWeekly,
                          Copy.freqWeekdays,
                        ].indexed)
                          i: SegmentedLabel(label: label, selected: i == mode),
                      },
                    ),
                    // 参数区定高（覆盖每周N次/指定星期/空三态），高度恒定
                    // → 切换选项时上方控件不再位移。
                    SizedBox(
                      height: 84,
                      child: Center(
                        child: mode == 2
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.square(36),
                                    onPressed: () => setSheet(
                                      () => weeklyTimes = (weeklyTimes - 1)
                                          .clamp(1, 7),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.minus_circled,
                                      size: 26,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        '$weeklyTimes 次 / 周',
                                        style: text.titleM,
                                      ),
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.square(36),
                                    onPressed: () => setSheet(
                                      () => weeklyTimes = (weeklyTimes + 1)
                                          .clamp(1, 7),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.add_circled,
                                      size: 26,
                                    ),
                                  ),
                                ],
                              )
                            : mode == 3
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final d in [1, 2, 3, 4, 5, 6, 7])
                                    PillSelectButton<void>(
                                      label: '一二三四五六日'[d - 1],
                                      selected: weekdays.contains(d),
                                      onTap: () => setSheet(() {
                                        weekdays.contains(d)
                                            ? weekdays.remove(d)
                                            : weekdays.add(d);
                                      }),
                                    ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _frequency = switch (mode) {
        1 => const DailyFrequency(1),
        2 => WeeklyFrequency(weeklyTimes),
        3 => WeekdaysFrequency(weekdays.map(Weekday.fromIso).toSet(), 1),
        _ => null,
      };
    });
  }

  Future<void> _pickTime() async {
    final picked = await showAppTimePicker(context, initial: _reminderTime);
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _pickCadence() async {
    // 与执行节奏同款（CupertinoSlidingSegmentedControl 弹层）；
    // 点选即回填关闭，无需确认钮。
    var chosen = _reminderCadence;
    final confirmed = await showAppSheet<Cadence>(
      context,
      builder: (sheetContext) => AppSheet(
        title: Copy.reminderCadence,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: CupertinoSlidingSegmentedControl<Cadence>(
              groupValue: _reminderCadence,
              onValueChanged: (v) {
                chosen = v!;
                Navigator.of(sheetContext).pop(chosen);
              },
              children: {
                for (final c in Cadence.values)
                  c: SegmentedLabel(
                    label: _cadenceLabel(c),
                    selected: c == _reminderCadence,
                  ),
              },
            ),
          ),
        ),
      ),
    );
    if (confirmed != null) setState(() => _reminderCadence = confirmed);
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
    _iconPicked = true;
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
      }),
    );
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
      }),
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final today = ref.read(todayProvider);
    final editing = widget.goalId != null;
    final existing = editing
        ? ref
              .read(goalsProvider)
              .valueOrNull
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
      await ref
          .read(milestoneRepoProvider)
          .reorderFromEditor(goal.id, milestones);
      await ref
          .read(reminderRepoProvider)
          .upsert(
            Reminder(
              goalId: goal.id,
              time: _reminderTime,
              isEnabled: _reminderEnabled,
              cadence: _reminderCadence,
            ),
          );
    } else {
      await ref
          .read(goalRepoProvider)
          .createPlan(
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
      AppToast.show(context, Copy.editorGoalSavedToast);
      Navigator.of(context).pop();
    }
  }
}

String _frequencyLabel(FrequencyPattern f) => switch (f) {
  DailyFrequency() => Copy.freqDaily,
  WeeklyFrequency(:final timesPerWeek) => '${Copy.freqWeekly}（$timesPerWeek）',
  WeekdaysFrequency() => Copy.freqWeekdays,
};

String _cadenceLabel(Cadence c) => switch (c) {
  Cadence.daily => Copy.cadenceDaily,
  Cadence.threeDay => Copy.cadenceThreeDay,
  Cadence.weekly => Copy.cadenceWeekly,
};
