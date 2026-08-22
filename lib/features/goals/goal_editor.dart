/// GoalEditor（003 T023 重构，FR-011~015/021 · 原型 screen-editor R3 定稿）。
///
/// 分组平铺无折叠（R2 裁决 1）：分类（置顶，常用行+「更多」弹窗 = T026）
/// / 基础信息（一句话描述，40 字，research D8）/ 目标类型与提醒
/// （三选分段 + 改型联动显隐）。保存常驻底部、文案统一「保存」
/// （R3 裁决 2）；表单零行为说明句（R3 裁决 3）。002 B 案动线
/// （为什么/怎样算/场景 chips/频率问答/一次性开关/颜色步/SMART 卡）
/// 全量退役，退役字段仅编辑时原值继承（FR-016 存量保全）。
/// 编辑同构：类型可改（ui-contract），改型即切提醒语义——短期=截止、
/// 习惯/长期=提醒开关；保存直构完整 Goal（deadline 随类型成对出现/清空）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/db/repositories.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import 'goal_templates.dart';

class GoalEditorPage extends ConsumerStatefulWidget {
  const GoalEditorPage({super.key, this.goalId, this.template});

  /// null = 创建；非 null = 编辑（类型可改，改型联动显隐）。
  final String? goalId;

  /// 引导页/空态带入的模板预填（仅创建模式）。
  final GoalTemplate? template;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  final _name = TextEditingController();

  /// 类型默认短期（原型画板①：新目标默认落短期，截止必填）。
  GoalType _type = GoalType.shortTerm;
  String _iconKey = GoalIconCatalog.explore.key;

  /// 短期截止日：默认 today+39（原型同款），切离短期不写库。
  LocalDate? _deadline;

  /// 提醒开关（习惯/长期共用区）：切型时重置——习惯默认开、长期默认关。
  /// 频率档与时间 = T025。
  bool _remindOn = false;
  bool _hydrated = false;

  bool get _isEdit => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      // 目标流就绪后一次性回填表单（含提醒行）。
      ref.listenManual(goalsProvider, (prev, next) {
        final goal =
            next.value?.where((g) => g.id == widget.goalId).firstOrNull;
        if (!_hydrated && goal != null) _hydrate(goal);
      }, fireImmediately: true);
    } else {
      final today = ref.read(todayProvider);
      _deadline = today.addDays(39);
      _remindOn = _type == GoalType.habit;
      if (widget.template != null) _applyTemplate(widget.template!);
    }
  }

  void _hydrate(Goal goal) {
    final reminders = ref.read(remindersProvider).value ?? const <Reminder>[];
    final mine = reminders.where((r) => r.goalId == goal.id).firstOrNull;
    setState(() {
      _hydrated = true;
      _type = goal.goalType;
      _name.text = goal.name;
      _iconKey = goal.iconKey;
      _deadline = goal.deadline ?? ref.read(todayProvider).addDays(39);
      _remindOn = mine?.isEnabled ?? false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _applyTemplate(GoalTemplate t) {
    setState(() {
      _setType(t.goalType);
      _name.text = t.name;
      _iconKey = t.iconKey;
    });
  }

  /// 切型：提醒语义随型重置（习惯默认开、其余默认关），截止日兜底。
  void _setType(GoalType t) {
    _type = t;
    _remindOn = t == GoalType.habit;
    if (t == GoalType.shortTerm && _deadline == null) {
      _deadline = ref.read(todayProvider).addDays(39);
    }
  }

  Future<void> _save() async {
    final repo = ref.read(goalRepoProvider);
    final today = ref.read(todayProvider);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    try {
      if (_isEdit) {
        final goal = (ref.read(goalsProvider).value ?? [])
            .firstWhere((g) => g.id == widget.goalId);
        // 编辑同构：类型可改。直构完整 Goal（copyWith 不支持改型/清 deadline）；
        // 退役字段原值继承（FR-016 存量保全，表单无写入路径）。
        await repo.update(Goal(
          id: goal.id,
          name: name,
          goalType: _type,
          iconKey: _iconKey,
          colorKey: goal.colorKey,
          status: goal.status,
          createdAt: goal.createdAt,
          deadline: _type == GoalType.shortTerm ? _deadline : null,
          motivation: goal.motivation,
          successCriterion: goal.successCriterion,
          cueScene: goal.cueScene,
          achievedAt: goal.achievedAt,
        ));
      } else {
        await repo.create(Goal(
          name: name,
          goalType: _type,
          iconKey: _iconKey,
          colorKey: 'teal', // 退役列兜底值，任何界面不再读取（FR-015/016）
          createdAt: today,
          deadline: _type == GoalType.shortTerm ? _deadline : null,
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('知道了')),
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? Copy.goalEdit : Copy.editorNewGoal)),
      // 保存常驻底部（ListView 外，导航条上方——编辑器挂 today 分支，FR-010）。
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                _GroupCard(label: Copy.editorSectionCategory, child: _categoryPicker()),
                const SizedBox(height: AppSpace.s4),
                _GroupCard(label: Copy.editorSectionBasics, child: _nameField()),
                const SizedBox(height: AppSpace.s4),
                _GroupCard(
                    label: Copy.editorSectionType, child: _typeSection()),
                const SizedBox(height: AppSpace.s2),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              key: const ValueKey('goalSaveButton'),
              onPressed: _save,
              child: const Text(Copy.editorSave),
            ),
          ),
        ],
      ),
    );
  }

  /// 分类组（T023 占位：当前选中图标；T026 = 常用行 + 「更多」弹窗）。
  Widget _categoryPicker() {
    final palette = TargetPalette.of(context);
    final selected = GoalIconCatalog.byKey(_iconKey);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: palette.divider),
          ),
          child: Icon(selected.icon, size: 22, color: palette.onSurface),
        ),
      ],
    );
  }

  /// 基础信息：一句话描述（name 语义升级，40 字上限，research D8）。
  Widget _nameField() {
    return TextField(
      key: const ValueKey('goalNameField'),
      controller: _name,
      maxLength: 40,
      decoration: const InputDecoration(hintText: Copy.editorNameHint),
    );
  }

  /// 类型与提醒：三选分段 + 改型联动显隐
  /// （短期 → 截止区；习惯/长期 → 提醒开关区；频率档+时间 = T025）。
  Widget _typeSection() {
    final palette = TargetPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<GoalType>(
          key: const ValueKey('goalTypeSeg'),
          segments: const [
            ButtonSegment(value: GoalType.longTerm, label: Text(Copy.typeBadgeLongTerm)),
            ButtonSegment(
                value: GoalType.shortTerm, label: Text(Copy.typeBadgeShortTerm)),
            ButtonSegment(value: GoalType.habit, label: Text(Copy.typeBadgeHabit)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _setType(s.first)),
        ),
        if (_type == GoalType.shortTerm) ...[
          const SizedBox(height: AppSpace.s3),
          _deadlineRow(palette),
        ] else ...[
          const SizedBox(height: AppSpace.s3),
          _reminderRow(palette),
        ],
      ],
    );
  }

  /// 短期子区：截止日（必填；选择器与倒计时预告 = T025）。
  Widget _deadlineRow(TargetPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4, vertical: AppSpace.s3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          const Text(Copy.editorDeadlineLabel),
          const SizedBox(width: AppSpace.s2),
          const _RequiredTag(),
          const Spacer(),
          Text(_deadline?.isoString ?? '',
              style: Theme.of(context).textTheme.bodyM),
        ],
      ),
    );
  }

  /// 习惯/长期子区：提醒开关（频率档 + 时间选择器 = T025）。
  Widget _reminderRow(TargetPalette palette) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(Copy.editorReminderSwitch,
                style: Theme.of(context).textTheme.bodyM),
          ),
          Switch(
            key: const ValueKey('goalRemindSwitch'),
            value: _remindOn,
            onChanged: (v) => setState(() => _remindOn = v),
          ),
        ],
      ),
    );
  }
}

/// 分组卡：平铺展开、无折叠（R2 裁决 1）；与今日卡同语言
/// （glassCard + rLg + divider 边 + shadowLow）。
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Material(
      color: palette.glassCard,
      borderRadius: AppRadius.rLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rLg,
          border: Border.all(color: palette.divider),
          boxShadow: palette.shadowLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleS),
            const SizedBox(height: AppSpace.s3),
            child,
          ],
        ),
      ),
    );
  }
}

/// 「必填」小标（短期截止日；positive 填充，原型 .tag.req 同语言）。
class _RequiredTag extends StatelessWidget {
  const _RequiredTag();

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: palette.positiveFill,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(Copy.editorRequiredTag,
          style: Theme.of(context)
              .textTheme
              .labelS
              .copyWith(color: palette.positiveOn)),
    );
  }
}
