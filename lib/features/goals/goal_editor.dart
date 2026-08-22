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
  bool _remindOn = false;
  Cadence _cadence = Cadence.daily;

  /// 提醒时间默认 09:00（原型 R3 同款）。
  LocalTime _remindTime = const LocalTime(9, 0);

  /// 编辑模式下既有提醒行 id（保存时原行续写，避免重复建行）。
  String? _reminderId;
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

  Future<void> _hydrate(Goal goal) async {
    // 直查仓库：编辑器首帧时 remindersProvider 流可能未首发，读缓存会漏行。
    final reminders = await ref.read(reminderRepoProvider).all();
    final mine = reminders.where((r) => r.goalId == goal.id).firstOrNull;
    setState(() {
      _hydrated = true;
      _type = goal.goalType;
      _name.text = goal.name;
      _iconKey = goal.iconKey;
      _deadline = goal.deadline ?? ref.read(todayProvider).addDays(39);
      _remindOn = mine?.isEnabled ?? false;
      _cadence = mine?.effectiveCadence ?? Cadence.daily;
      _remindTime = mine?.time ?? const LocalTime(9, 0);
      _reminderId = mine?.id;
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
    final reminderRepo = ref.read(reminderRepoProvider);
    final today = ref.read(todayProvider);
    final name = _name.text.trim();
    if (name.isEmpty) return;

    // 提醒写入口径（goal-type-model）：习惯/长期开关开 → upsert 行
    // （isEnabled/cadence/time）；关 → 既有行置 isEnabled=false（即时取消，
    // 历史不受影响）；改型短期 → cadence 恒不适用，删行（到期询问由
    // 排程器按 deadline 推导，无行承载）。
    Future<void> syncReminder(String goalId) async {
      final wants = _type != GoalType.shortTerm && _remindOn;
      if (wants) {
        await reminderRepo.upsert(Reminder(
          id: _reminderId,
          goalId: goalId,
          time: _remindTime,
          isEnabled: true,
          cadence: _cadence,
        ));
      } else if (_reminderId != null) {
        if (_type == GoalType.shortTerm) {
          await reminderRepo.removeByGoal(goalId);
        } else {
          await reminderRepo.upsert(Reminder(
            id: _reminderId,
            goalId: goalId,
            time: _remindTime,
            isEnabled: false,
            cadence: _cadence,
          ));
        }
      }
    }

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
        await syncReminder(goal.id);
      } else {
        final created = await repo.create(Goal(
          name: name,
          goalType: _type,
          iconKey: _iconKey,
          colorKey: 'teal', // 退役列兜底值，任何界面不再读取（FR-015/016）
          createdAt: today,
          deadline: _type == GoalType.shortTerm ? _deadline : null,
        ));
        await syncReminder(created.id);
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

  /// 分类组（T026，原型 buildCommonRow/buildPicker）：常用一行 6 枚策展
  /// + 「更多」虚线格 → 弹窗全量按领域分组；单选即存 iconKey，两处选中
  /// 态同步（选中不在常用行时行内无高亮，原型同款）。无颜色步
  /// （FR-015：表单零 colorKey 写入）。
  static const _commonIcons = [
    GoalIconCatalog.fitnessCenter,
    GoalIconCatalog.menuBook,
    GoalIconCatalog.favorite,
    GoalIconCatalog.selfImprovement,
    GoalIconCatalog.brush,
    GoalIconCatalog.savings,
  ];

  Widget _categoryPicker() {
    return Row(
      children: [
        for (final c in _commonIcons) ...[
          _IconCell(
            icon: c.icon,
            size: 36,
            iconSize: 18,
            selected: _iconKey == c.key,
            semanticLabel: Copy.editorIconSemantics(c.key),
            onTap: () => setState(() => _iconKey = c.key),
          ),
          const SizedBox(width: AppSpace.s2),
        ],
        _MoreCell(onTap: _openPicker),
      ],
    );
  }

  Future<void> _openPicker() async {
    final picked = await showDialog<String>(
      context: context,
      barrierDismissible: true, // scrim 点外关闭（原型同款）
      builder: (_) => _IconPickerDialog(selectedKey: _iconKey),
    );
    if (picked != null) setState(() => _iconKey = picked);
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

  /// 短期子区：截止日（必填，tap 弹日期选择器）+ 倒计时预告。
  Widget _deadlineRow(TargetPalette palette) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final days = _deadline?.differenceInDays(today) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('goalDeadlineField'),
          onTap: _pickDeadline,
          borderRadius: AppRadius.rMd,
          child: Container(
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
                    style: theme.textTheme.bodyM),
                Icon(Icons.expand_more,
                    size: 20, color: palette.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Text(Copy.editorCountdownPreview(days),
            key: const ValueKey('goalCountdownPreview'),
            style: theme.textTheme.bodyS
                .copyWith(color: palette.onSurfaceVariant)),
      ],
    );
  }

  /// 习惯/长期子区：提醒开关 →（开）频率档 + 提醒时间（FR-013）。
  Widget _reminderRow(TargetPalette palette) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.s3),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: palette.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Copy.editorReminderSwitch,
                        style: theme.textTheme.bodyM),
                    Text(Copy.editorReminderSub,
                        style: theme.textTheme.bodyS
                            .copyWith(color: palette.onSurfaceVariant)),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('goalRemindSwitch'),
                value: _remindOn,
                onChanged: (v) => setState(() => _remindOn = v),
              ),
            ],
          ),
        ),
        if (_remindOn) ...[
          const SizedBox(height: AppSpace.s3),
          SegmentedButton<Cadence>(
            key: const ValueKey('goalCadenceSeg'),
            segments: const [
              ButtonSegment(value: Cadence.daily, label: Text(Copy.cadenceDaily)),
              ButtonSegment(
                  value: Cadence.threeDay, label: Text(Copy.cadenceThreeDay)),
              ButtonSegment(
                  value: Cadence.weekly, label: Text(Copy.cadenceWeekly)),
            ],
            selected: {_cadence},
            onSelectionChanged: (s) => setState(() => _cadence = s.first),
          ),
          const SizedBox(height: AppSpace.s3),
          InkWell(
            key: const ValueKey('goalRemindTimeField'),
            onTap: _pickTime,
            borderRadius: AppRadius.rMd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s4, vertical: AppSpace.s3),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: palette.divider),
              ),
              child: Row(
                children: [
                  Text(Copy.editorRemindTimeLabel,
                      style: theme.textTheme.bodyM),
                  const Spacer(),
                  Text(_remindTime.isoString, style: theme.textTheme.bodyM),
                  Icon(Icons.expand_more,
                      size: 20, color: palette.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDeadline() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      // 宽松下界：超期目标编辑时 initialDate 可在过去。
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      initialDate: (_deadline ?? today.addDays(39)).atStartOfDay,
    );
    if (picked != null) {
      setState(() => _deadline = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _remindTime.hour, minute: _remindTime.minute),
    );
    if (picked != null) {
      setState(
          () => _remindTime = LocalTime(picked.hour, picked.minute));
    }
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

/// 图标格（原型 .ico）：surface 底 + divider 边 + rMd；选中 → accent
/// 底/边 + accentOn 色（常用行 36px/弹窗 40px 两档尺寸）。
class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final double iconSize;
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
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.accent : palette.surface,
            borderRadius: AppRadius.rMd,
            border: Border.all(
                color: selected ? palette.accent : palette.divider),
          ),
          child: Icon(icon,
              size: iconSize,
              color: selected ? palette.accentOn : palette.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// 「更多」虚线格（原型 .more-btn）：40px、divider 虚线边、九点标识。
class _MoreCell extends StatelessWidget {
  const _MoreCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Semantics(
      label: Copy.editorIconMoreLabel,
      button: true,
      child: InkWell(
        key: const ValueKey('goalIconMoreButton'),
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: CustomPaint(
          foregroundPainter:
              _DashedBorderPainter(color: palette.divider),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: _DotsIcon(color: palette.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// 圆角矩形虚线描边（原型 border: dashed；Flutter 边框无 dash 选项，自绘）。
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, AppRadius.rMd.topLeft));
    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        canvas.drawPath(metric.extractPath(start, start + 4), paint);
        start += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color;
}

/// 3×3 九点标识（原型 more-btn svg 同款）。
class _DotsIcon extends StatelessWidget {
  const _DotsIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
          width: 3.5,
          height: 3.5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    Widget row() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [dot(), const SizedBox(width: 5), dot(),
            const SizedBox(width: 5), dot()],
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [row(), const SizedBox(height: 5), row(),
        const SizedBox(height: 5), row()],
    );
  }
}

/// 「选择分类」弹窗（原型 .picker）：全量 38 枚按领域分组、40px 格、
/// 点选即关（pop key）；scrim 点外/Esc/✕ 关闭不选。
class _IconPickerDialog extends StatelessWidget {
  const _IconPickerDialog({required this.selectedKey});

  final String selectedKey;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 326, maxHeight: 560),
        child: Material(
          color: palette.surface,
          borderRadius: AppRadius.rLg,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: palette.divider),
              boxShadow: palette.shadowHigh,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.s4, AppSpace.s4, AppSpace.s3, AppSpace.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(Copy.editorPickCategoryTitle,
                            style: theme.textTheme.titleS),
                      ),
                      Semantics(
                        label: Copy.editorIconCloseLabel,
                        button: true,
                        child: InkWell(
                          key: const ValueKey('goalIconPickerClose'),
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: AppRadius.rFull,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: AppRadius.rFull,
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 16, color: palette.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(AppSpace.s4, 0, AppSpace.s4,
                            AppSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry
                            in GoalIconCatalog.byDomain.entries) ...[
                          Text(entry.key.zhLabel,
                              style: theme.textTheme.labelS.copyWith(
                                  color: palette.onSurfaceVariant)),
                          const SizedBox(height: AppSpace.s2),
                          Wrap(
                            spacing: AppSpace.s2,
                            runSpacing: AppSpace.s2,
                            children: [
                              for (final c in entry.value)
                                _IconCell(
                                  icon: c.icon,
                                  size: 40,
                                  iconSize: 20,
                                  selected: c.key == selectedKey,
                                  semanticLabel:
                                      Copy.editorIconSemantics(c.key),
                                  onTap: () =>
                                      Navigator.of(context).pop(c.key),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.s3),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
