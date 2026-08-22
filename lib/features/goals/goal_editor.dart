/// GoalEditor（002 T017 重写，FR-001/002/011/012 · B 案动线 T014 定稿）。
///
/// 单一「目标」概念：不前置选类型——「一次性/截止日」是属性开关（FR-011）。
/// 布局序 = screen-editor.html 方案 B：模板一句话 → 想做什么（SMART 内联）
/// → 多久做一次 → 这是一次性目标（开 → 截止日快选，隐去频率）
/// → 这一诺（为什么必填一句 / 怎样算做到自动拟可改 / 提醒场景 chips）
/// → 图标颜色 → 立下这个心愿。
/// 编辑进行中目标频率变化仍提示「下周一生效」（FR-002）；旧目标空维度
/// 渐进补全（编辑模式下「为什么」不强制）。
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

  /// 引导页/空态带入的模板预填（仅创建模式）。
  final GoalTemplate? template;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  final _name = TextEditingController();
  final _motivation = TextEditingController();
  final _criterion = TextEditingController();

  /// 「怎样算做到」是否被用户改过：没改 → 随名称自动重拟（T014 B 案）。
  bool _criterionTouched = false;
  bool _whyError = false;

  /// B 案 envelope（T014/T015）：动机/成功标准/提醒场景。
  String? _cueScene;

  /// 一次性目标（= milestone kind 的属性化呈现；创建后冻结）。
  bool _once = false;
  var _pattern = const DailyFrequency(1) as FrequencyPattern;
  var _iconKey = 'star';
  var _colorKey = 'teal';
  var _deadline = LocalDate(2026, 12, 31); // 一次性默认年底，可改
  bool _hydrated = false;
  String? _selectedTemplate;

  bool get _isEdit => widget.goalId != null;

  /// 一次性开关在编辑模式下冻结（001 约定 kind 创建后不可变更）。
  bool get _onceLocked => _isEdit;

  /// 机械迁移（T011）：二元开关先映射 shortTerm/habit——
  /// longTerm 编辑暂落 habit 分支，US2 编辑器重构改三段选择器。
  GoalType get _type => _once ? GoalType.shortTerm : GoalType.habit;

  @override
  void initState() {
    super.initState();
    // 名称变化 → 未手改过的成功标准随名称重拟。
    _name.addListener(_redraftCriterion);
    if (_isEdit) {
      // 目标流就绪后一次性回填表单。
      ref.listenManual(goalsProvider, (prev, next) {
        final goal =
            next.value?.where((g) => g.id == widget.goalId).firstOrNull;
        if (!_hydrated && goal != null) _hydrate(goal);
      }, fireImmediately: true);
    } else if (widget.template != null) {
      _applyTemplate(widget.template!);
    }
  }

  void _redraftCriterion() {
    if (_criterionTouched) return;
    final n = _name.text.trim();
    final draft = n.isEmpty ? '' : (SmartSuggestion.suggest(n) ?? n);
    if (_criterion.text != draft) _criterion.text = draft;
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
      _once = goal.isShortTerm;
      _name.text = goal.name;
      _motivation.text = goal.motivation ?? '';
      // 旧目标已有标准视为手改（不随名称重拟）。
      _criterion.text = goal.successCriterion ?? '';
      _criterionTouched = goal.successCriterion != null;
      _cueScene = goal.cueScene;
      _pattern = pattern;
      _iconKey = goal.iconKey;
      _colorKey = goal.colorKey;
      _deadline = goal.deadline ?? _deadline;
    });
  }

  @override
  void dispose() {
    _name.removeListener(_redraftCriterion);
    _name.dispose();
    _motivation.dispose();
    _criterion.dispose();
    super.dispose();
  }

  void _applyTemplate(GoalTemplate t) {
    setState(() {
      _selectedTemplate = t.name;
      _once = t.goalType == GoalType.shortTerm;
      _name.text = t.name;
      _iconKey = t.iconKey;
      _colorKey = t.colorKey;
      if (t.frequency != null) _pattern = t.frequency!;
    });
  }

  // ---- 一次性目标的截止日快选（screen-editor.html 同款 chips）----

  void _setDeadline(LocalDate d) => setState(() => _deadline = d);

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
    final why = _motivation.text.trim();
    if (name.isEmpty) return;
    // B 案：创建时动机必填一句（编辑旧目标 = 渐进补全，不强制）。
    if (!_isEdit && why.isEmpty) {
      setState(() => _whyError = true);
      return;
    }
    if (!_once && _pattern is WeekdaysFrequency) {
      if ((_pattern as WeekdaysFrequency).days.isEmpty) return;
    }
    final criterion = _criterion.text.trim();
    final envelope = (
      motivation: why.isEmpty ? null : why,
      successCriterion: criterion.isEmpty ? null : criterion,
      cueScene: _cueScene,
    );

    try {
      if (_isEdit) {
        final goal = (ref.read(goalsProvider).value ?? [])
            .firstWhere((g) => g.id == widget.goalId);
        await repo.update(goal.copyWith(
          name: name,
          iconKey: _iconKey,
          colorKey: _colorKey,
          motivation: envelope.motivation,
          successCriterion: envelope.successCriterion,
          cueScene: envelope.cueScene,
        ));
      } else {
        // 003 T013：新目标不再创建频率版本（存量表只读保全）。
        await repo.create(Goal(
          name: name,
          goalType: _type,
          iconKey: _iconKey,
          colorKey: _colorKey,
          createdAt: today,
          deadline: _once ? _deadline : null,
          motivation: envelope.motivation,
          successCriterion: envelope.successCriterion,
          cueScene: envelope.cueScene,
        ));
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
            _sectionLabel(Copy.editorTemplatesLabel),
            _templateRow(),
            const SizedBox(height: 20),
          ],
          _sectionLabel(Copy.editorNameLabel),
          TextField(
            key: const ValueKey('goalNameField'),
            controller: _name,
            maxLength: 30,
            // 输入即刷新 SMART 建议 chip（FR-001：模糊名要当场提示）。
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '比如：变健康'),
          ),
          _smartCard(theme),
          const SizedBox(height: 20),
          _sectionLabel(Copy.editorFrequencyLabel),
          if (_once) ...[
            _deadlineChips(theme),
          ] else ...[
            _frequencyEditor(theme),
          ],
          _onceSwitch(theme),
          const SizedBox(height: 20),
          _sectionLabel(Copy.editorWhyLabel, badge: true),
          TextField(
            key: const ValueKey('goalWhyField'),
            controller: _motivation,
            maxLength: 60,
            minLines: 1,
            maxLines: 2,
            onChanged: (_) {
              if (_whyError) setState(() => _whyError = false);
            },
            decoration: InputDecoration(
              hintText: Copy.editorWhyHint,
              errorText: _whyError ? Copy.editorWhyRequired : null,
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(Copy.editorCriterionLabel,
              note: _criterionTouched ? null : Copy.editorCriterionAutoNote),
          TextField(
            key: const ValueKey('goalCriterionField'),
            controller: _criterion,
            maxLength: 60,
            onChanged: (_) => _criterionTouched = true,
            decoration: const InputDecoration(hintText: '比如：散步 20 分钟'),
          ),
          const SizedBox(height: 20),
          _sectionLabel(Copy.editorCueLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in Copy.editorCueScenes)
                ChoiceChip(
                  label: Text(s),
                  selected: _cueScene == s,
                  onSelected: (_) => setState(
                      () => _cueScene = _cueScene == s ? null : s),
                ),
            ],
          ),
          if (_cueScene != null && _cueScene != Copy.editorCueScenes.last)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                Copy.editorCuePreview(_cueScene!),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                Copy.editorCueFallback,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 20),
          _sectionLabel(Copy.editorIconColor),
          _iconPicker(),
          const SizedBox(height: 12),
          _colorPicker(theme),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? Copy.editorSave : Copy.editorSaveCreate),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {String? note, bool badge = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          if (badge) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('必填',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
          if (note != null) ...[
            const SizedBox(width: 6),
            Text(note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ]),
      );

  /// 模板横滑行（screen-editor.html：色点 + 一句话，单行滑选）。
  Widget _templateRow() => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kAllTemplates.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final t = kAllTemplates[i];
            final color = GoalColor.byKey(t.colorKey).of(context);
            return ChoiceChip(
              avatar: CircleAvatar(
                backgroundColor: color,
                radius: 11,
                child: Icon(GoalIcon.byKey(t.iconKey).icon,
                    size: 13, color: Colors.white),
              ),
              label: Text(t.name),
              selected: _selectedTemplate == t.name,
              onSelected: (_) => _applyTemplate(t),
            );
          },
        ),
      );

  /// SMART 建议（FR-001）：名称模糊时内联"换成更具体的？"。
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

  /// 截止日快选 chips：今年内 / 三个月内 / 自选日期。
  Widget _deadlineChips(ThemeData theme) {
    final today = ref.watch(todayProvider);
    final thisYear = LocalDate(today.year, 12, 31);
    final threeMonths = today.addDays(90);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, date) in [
              (Copy.editorDdlThisYear, thisYear),
              (Copy.editorDdl3Months, threeMonths),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _deadline == date,
                onSelected: (_) => _setDeadline(date),
              ),
            ChoiceChip(
              label: Text('${Copy.editorDdlCustom}（${_deadline.isoString}）'),
              selected: _deadline != thisYear && _deadline != threeMonths,
              onSelected: (_) => _pickDeadline(),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            Copy.editorDeadlineRequired,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  /// 一次性属性开关（FR-011：属性，不是前置类型分叉；编辑模式冻结）。
  Widget _onceSwitch(ThemeData theme) {
    return Opacity(
      opacity: _onceLocked ? 0.75 : 1,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: _onceLocked ? null : () => setState(() => _once = !_once),
        title: Text(Copy.editorOnceLabel, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          _onceLocked ? Copy.editorOnceKindNote : Copy.editorOnceSub,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Switch(
          value: _once,
          onChanged:
              _onceLocked ? null : (v) => setState(() => _once = v),
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
