library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/page_top_bar.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import 'goal_editor_draft.dart';
import 'goal_frequency_field.dart';
import 'goal_icon_picker.dart';
import 'goal_milestone_editor.dart';
import 'goal_reminder_field.dart';

class GoalEditorPage extends ConsumerStatefulWidget {
  const GoalEditorPage({super.key, this.goalId});

  final String? goalId;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  final _name = TextEditingController();
  GoalEditorDraft _draft = GoalEditorDraft.empty();
  Goal? _existing;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() {
      _draft.name = _name.text;
      setState(() {});
    });
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final snapshot = await ref.read(goalPlanRepoProvider).load(widget.goalId!);
    if (!mounted) return;
    if (snapshot == null) {
      setState(() {
        _loading = false;
        _error = Copy.goalMissing;
      });
      return;
    }
    setState(() {
      _existing = snapshot.goal;
      _draft = GoalEditorDraft.fromSnapshot(snapshot);
      _name.text = _draft.name;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_draft.canSave || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(goalPlanRepoProvider);
      final input = _draft.toInput(
        existing: _existing,
        today: ref.read(todayProvider),
      );
      if (_existing == null) {
        final created = await repo.create(input);
        if (mounted) context.pushReplacement('/goal/${created.id}');
      } else {
        await repo.update(input);
        if (mounted) context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '保存失败，请重试';
        _saving = false;
      });
    }
  }

  void _updateDraft(void Function(GoalEditorDraft draft) change) {
    setState(() {
      change(_draft);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: TargetPalette.of(context).background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTopBar(title: _isEdit ? Copy.goalEdit : Copy.editorNewGoal),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s3,
                  AppSpace.s1,
                  AppSpace.s3,
                  AppSpace.s3,
                ),
                children: [
                  _Section(
                    title: '目标名称',
                    badge: const _Tag(Copy.editorRequiredTag, emphasized: true),
                    child: _nameField(),
                  ),
                  const SizedBox(height: AppSpace.s2),
                  _Section(title: '图标与分类', child: _iconSection()),
                  const SizedBox(height: AppSpace.s2),
                  _Section(title: '目标日期', child: _dateSection()),
                  const SizedBox(height: AppSpace.s2),
                  _Section(
                    title: '执行节奏',
                    badge: const _Tag(Copy.editorOptionalTag, emphasized: false),
                    child: GoalFrequencyField(
                      value: _draft.frequency,
                      onChanged: (value) =>
                          _updateDraft((draft) => draft.frequency = value),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s2),
                  _Section(
                    title: '里程碑',
                    badge: const _Tag(Copy.editorOptionalTag, emphasized: false),
                    child: GoalMilestoneEditor(
                      value: _draft.milestones,
                      onChanged: (value) =>
                          _updateDraft((draft) => draft.milestones = value),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s2),
                  _Section(
                    title: '提醒',
                    badge: const _Tag(Copy.editorOptionalTag, emphasized: false),
                    child: GoalReminderField(
                      value: _draft.reminder,
                      onChanged: (value) =>
                          _updateDraft((draft) => draft.reminder = value),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpace.s3),
                    Text(
                      _error!,
                      key: const ValueKey('goalSaveError'),
                      style: Theme.of(context).textTheme.bodyM.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s4,
                AppSpace.s2,
                AppSpace.s4,
                AppSpace.s3,
              ),
              child: FilledButton(
                key: const ValueKey('goalSaveButton'),
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(_saving ? '保存中...' : Copy.editorSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameField() {
    final palette = TargetPalette.of(context);
    return TextField(
      key: const ValueKey('goalNameField'),
      controller: _name,
      maxLength: 30,
      decoration: InputDecoration(
        hintText: '例如：学习摄影',
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s3,
          vertical: AppSpace.s2,
        ),
        filled: true,
        fillColor: palette.surfaceAlt,
      ),
    );
  }

  Widget _iconSection() {
    final palette = TargetPalette.of(context);
    final icon = GoalIconCatalog.byKey(_draft.iconKey);
    final domain = _draft.category ?? icon.domain;
    final majorColor = MajorColors.byKey(domain.major.name).of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          children: [
            for (final item in _commonIcons)
              _IconCell(
                icon: item.icon,
                selected: item.key == _draft.iconKey,
                semanticLabel: goalIconLabel(item),
                onTap: () => _updateDraft((draft) => draft.iconKey = item.key),
              ),
            _MoreCell(onTap: _openPicker),
          ],
        ),
        const SizedBox(height: AppSpace.s1),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: majorColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpace.s2),
            Expanded(
              child: Text(
                '${_draft.category == null ? '自动分类' : '已更正'}：'
                '${domain.zhLabel} · ${domain.major.zhLabel}',
                style: Theme.of(context).textTheme.bodyS.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(onPressed: _correctCategory, child: const Text('更正')),
          ],
        ),
      ],
    );
  }

  Widget _dateSection() {
    final palette = TargetPalette.of(context);
    final hasDate = _draft.targetDate != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('goalHasDateSwitch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('设置目标日期'),
          value: hasDate,
          onChanged: (value) => _updateDraft(
            (draft) =>
                draft.targetDate = value ? ref.read(todayProvider).addDays(90) : null,
          ),
        ),
        if (hasDate)
          InkWell(
            key: const ValueKey('goalTargetDateField'),
            onTap: _pickTargetDate,
            borderRadius: AppRadius.rMd,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.rMd,
              ),
              child: Text(_draft.targetDate!.isoString),
            ),
          ),
      ],
    );
  }

  Future<void> _pickTargetDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(today.year + 10, 12, 31),
      initialDate: (_draft.targetDate ?? today.addDays(90)).atStartOfDay,
    );
    if (picked != null) {
      _updateDraft(
        (draft) => draft.targetDate = LocalDate.fromDateTime(picked),
      );
    }
  }

  Future<void> _openPicker() async {
    final picked = await showGoalIconPicker(context, selectedKey: _draft.iconKey);
    if (picked != null) {
      _updateDraft((draft) => draft.iconKey = picked.key);
    }
  }

  Future<void> _correctCategory() async {
    final picked = await showModalBottomSheet<GoalIconDomain>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = TargetPalette.of(context);
        return Container(
          padding: EdgeInsets.fromLTRB(
            AppSpace.s5,
            AppSpace.s4,
            AppSpace.s5,
            AppSpace.s5 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final domain in GoalIconDomain.values)
                ListTile(
                  minTileHeight: 44,
                  leading: Icon(
                    GoalIconCatalog.byDomain[domain]!.first.icon,
                    color: MajorColors.byKey(domain.major.name).of(context),
                  ),
                  title: Text(domain.zhLabel),
                  subtitle: Text(domain.major.zhLabel),
                  onTap: () => Navigator.of(context).pop(domain),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) _updateDraft((draft) => draft.category = picked);
  }

  static const _commonIcons = [
    GoalIconCatalog.explore,
    GoalIconCatalog.menuBook,
    GoalIconCatalog.camera,
    GoalIconCatalog.directionsBike,
    GoalIconCatalog.favorite,
    GoalIconCatalog.savings,
  ];
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.badge});

  final String title;
  final Widget child;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelS.copyWith(
                  color: palette.onSurfaceVariant,
                  letterSpacing: .8,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpace.s2),
                badge!,
              ],
            ],
          ),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.emphasized});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: 1),
      decoration: BoxDecoration(
        color: emphasized ? palette.accent : palette.surfaceAlt,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelS.copyWith(
          color: emphasized ? palette.accentOn : palette.onSurfaceVariant,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.icon,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: selected ? palette.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: selected ? palette.accent : palette.onSurface,
          ),
        ),
      ),
    );
  }
}

class _MoreCell extends StatelessWidget {
  const _MoreCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return InkWell(
      key: const ValueKey('goalIconMoreButton'),
      onTap: onTap,
      borderRadius: AppRadius.rMd,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: palette.divider),
        ),
        child: const Icon(Icons.more_horiz_rounded),
      ),
    );
  }
}
