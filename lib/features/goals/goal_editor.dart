/// GoalEditor（T018，FR-001/002/011/012）：创建/编辑目标的单页表单。
///
/// 布局序 = 任务描述：类型 → 模板或自定义 → 频率 → 图标/颜色；
/// 里程碑改为截止日期。编辑进行中目标频率时提示"下周一生效"（FR-002）。
/// SMART 建议（T019）在名称输入时内联呈现。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/db/repositories.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';
import '../../core/stats/versioning.dart';
import 'goal_templates.dart';
import 'smart_suggestion.dart';

class GoalEditorPage extends ConsumerStatefulWidget {
  const GoalEditorPage({super.key, this.goalId, this.template});

  /// null = 创建；非 null = 编辑（kind 不可改）。
  final String? goalId;

  /// 引导页带入的模板预填（仅创建模式）。
  final GoalTemplate? template;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  final _name = TextEditingController();

  var _kind = GoalKind.habit;
  var _pattern = const DailyFrequency(1) as FrequencyPattern;
  var _iconKey = 'star';
  var _colorKey = 'teal';
  var _deadline = LocalDate(2026, 12, 31); // 里程碑默认年底，可改

  /// 编辑模式：进入时的有效频率（判断是否变化 → 下周一生效提示）。
  FrequencyPattern? _originalPattern;
  bool _hydrated = false;
  String? _selectedTemplate;

  bool get _isEdit => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      // 目标流就绪后一次性回填表单。
      ref.listenManual(goalsProvider, (prev, next) {
        final goal =
            next.value?.where((g) => g.id == widget.goalId).firstOrNull;
        if (!_hydrated && goal != null) _hydrate(goal);
      }, fireImmediately: true);
    } else if (widget.template != null) {
      final t = widget.template!;
      _kind = t.kind;
      _name.text = t.name;
      _iconKey = t.iconKey;
      _colorKey = t.colorKey;
      if (t.frequency != null) _pattern = t.frequency!;
      _selectedTemplate = t.name;
    }
  }

  void _hydrate(Goal goal) {
    final today = ref.read(todayProvider);
    final versions = ref.read(versionsProvider).value ?? const [];
    final pattern =
        effectivePattern(versions.where((v) => v.goalId == goal.id).toList(),
                today) ??
            const DailyFrequency(1);
    setState(() {
      _hydrated = true;
      _kind = goal.kind;
      _name.text = goal.name;
      _pattern = pattern;
      _originalPattern = pattern;
      _iconKey = goal.iconKey;
      _colorKey = goal.colorKey;
      _deadline = goal.deadline ?? _deadline;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _applyTemplate(GoalTemplate t) {
    setState(() {
      _selectedTemplate = t.name;
      _kind = t.kind;
      _name.text = t.name;
      _iconKey = t.iconKey;
      _colorKey = t.colorKey;
      if (t.frequency != null) _pattern = t.frequency!;
    });
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline.atStartOfDay,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() => _deadline = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _save() async {
    final repo = ref.read(goalRepoProvider);
    final today = ref.read(todayProvider);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (_kind == GoalKind.habit && _pattern is WeekdaysFrequency) {
      if ((_pattern as WeekdaysFrequency).days.isEmpty) return;
    }

    try {
      if (_isEdit) {
        final goal =
            (ref.read(goalsProvider).value ?? []).firstWhere((g) => g.id == widget.goalId);
        await repo.update(goal.copyWith(
          name: name,
          iconKey: _iconKey,
          colorKey: _colorKey,
          deadline: _kind == GoalKind.milestone ? _deadline : null,
        ));
        // 频率变化 → 下周一版本（FR-002；本周仍按原口径）。
        if (_kind == GoalKind.habit && _pattern != _originalPattern) {
          await repo.addUserEdit(goal.id, _pattern, today.weekStart.next);
        }
      } else {
        final goal = await repo.create(Goal(
          name: name,
          kind: _kind,
          iconKey: _iconKey,
          colorKey: _colorKey,
          createdAt: today,
          deadline: _kind == GoalKind.milestone ? _deadline : null,
        ));
        if (_kind == GoalKind.habit) {
          await repo.addInitial(goal.id, _pattern, today.weekStart);
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on ActiveGoalLimitException {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(Copy.focusLimitTitle),
            content: const Text(Copy.focusLimitBody),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(), child: const Text('知道了')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && !_hydrated) {
      return Scaffold(
        appBar: AppBar(title: const Text(Copy.editorNewGoal)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑目标' : Copy.editorNewGoal)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (!_isEdit) ...[
            _sectionLabel('类型'),
            SegmentedButton<GoalKind>(
              segments: const [
                ButtonSegment(
                    value: GoalKind.habit, label: Text(Copy.editorKindHabit)),
                ButtonSegment(
                    value: GoalKind.milestone,
                    label: Text(Copy.editorKindMilestone)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 20),
            _sectionLabel(Copy.editorFromTemplate),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in (_kind == GoalKind.habit
                    ? kHabitTemplates
                    : kMilestoneTemplates))
                  ChoiceChip(
                    label: Text(t.name),
                    selected: _selectedTemplate == t.name,
                    onSelected: (_) => _applyTemplate(t),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          _sectionLabel('名称'),
          TextField(
            controller: _name,
            maxLength: 30,
            // 输入即刷新 SMART 建议 chip（FR-001：模糊名要当场提示）。
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '比如：23 点前上床'),
          ),
          _smartCard(theme),
          const SizedBox(height: 20),
          if (_kind == GoalKind.habit) ...[
            _sectionLabel(Copy.editorFrequency),
            _frequencyEditor(theme),
          ] else ...[
            _sectionLabel(Copy.editorDeadline),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_deadline.isoString),
              subtitle: const Text(Copy.editorDeadlineRequired),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDeadline,
            ),
          ],
          const SizedBox(height: 20),
          _sectionLabel(Copy.editorIconColor),
          _iconPicker(),
          const SizedBox(height: 12),
          _colorPicker(theme),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: const Text(Copy.editorSave),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  /// SMART 建议（T019）：名称模糊时内联"换成更具体的？"。
  Widget _smartCard(ThemeData theme) {
    if (_isEdit) return const SizedBox.shrink();
    final suggestion = SmartSuggestion.suggest(_name.text);
    if (suggestion == null || suggestion == _name.text.trim()) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
                child: Text(Copy.smartSuggest(suggestion),
                    style: theme.textTheme.bodyMedium)),
            TextButton(
              onPressed: () => setState(() => _name.text = suggestion),
              child: const Text(Copy.smartApply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frequencyEditor(ThemeData theme) {
    final type = _pattern is DailyFrequency
        ? 'daily'
        : _pattern is WeeklyFrequency
            ? 'weekly'
            : 'weekdays';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'daily', label: Text('每天')),
            ButtonSegment(value: 'weekly', label: Text('每周')),
            ButtonSegment(value: 'weekdays', label: Text('指定日')),
          ],
          selected: {type},
          onSelectionChanged: (s) => setState(() => _pattern = switch (s.first) {
                'daily' => const DailyFrequency(1),
                'weekly' => const WeeklyFrequency(3),
                _ => WeekdaysFrequency({Weekday.mon, Weekday.wed, Weekday.fri}, 1),
              }),
        ),
        const SizedBox(height: 12),
        if (type == 'weekdays')
          Wrap(
            spacing: 6,
            children: [
              for (final w in Weekday.values)
                ChoiceChip(
                  label: Text(w.zhLabel),
                  selected:
                      (_pattern as WeekdaysFrequency).days.contains(w),
                  onSelected: (on) => setState(() {
                    final days = {...(_pattern as WeekdaysFrequency).days};
                    on ? days.add(w) : days.remove(w);
                    if (days.isNotEmpty) {
                      _pattern = WeekdaysFrequency(
                          days, (_pattern as WeekdaysFrequency).targetPerDay);
                    }
                  }),
                ),
            ],
          )
        else if (type == 'daily')
          _stepper(
            label: '次数 / 天',
            value: (_pattern as DailyFrequency).targetPerDay,
            min: 1,
            max: 9,
            onChanged: (n) => _pattern = DailyFrequency(n),
          )
        else
          _stepper(
            label: '次数 / 周',
            value: (_pattern as WeeklyFrequency).timesPerWeek,
            min: 1,
            max: 7,
            onChanged: (n) => _pattern = WeeklyFrequency(n),
          ),
        if (type == 'weekdays')
          _stepper(
            label: '次数 / 天',
            value: (_pattern as WeekdaysFrequency).targetPerDay,
            min: 1,
            max: 9,
            onChanged: (n) => _pattern = WeekdaysFrequency(
                (_pattern as WeekdaysFrequency).days, n),
          ),
        if (_isEdit && _pattern != _originalPattern)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              Copy.editorNextWeekEffect,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.tertiary),
            ),
          ),
      ],
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) =>
      Row(
        children: [
          Text(label),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => setState(() => onChanged(value - 1)) : null,
          ),
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => setState(() => onChanged(value + 1)) : null,
          ),
        ],
      );

  Widget _iconPicker() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final i in GoalIcon.values)
            ChoiceChip(
              label: Text(i.zhLabel),
              avatar: Icon(i.icon, size: 18),
              selected: _iconKey == i.name,
              onSelected: (_) => setState(() => _iconKey = i.name),
            ),
        ],
      );

  Widget _colorPicker(ThemeData theme) => Wrap(
        spacing: 10,
        children: [
          for (final c in GoalColor.values)
            GestureDetector(
              onTap: () => setState(() => _colorKey = c.name),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.of(context),
                  shape: BoxShape.circle,
                  border: _colorKey == c.name
                      ? Border.all(
                          color: theme.colorScheme.onSurface, width: 2.5)
                      : null,
                ),
              ),
            ),
        ],
      );
}
