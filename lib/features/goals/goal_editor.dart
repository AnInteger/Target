/// GoalEditor（004 T013 换装，v2-goal-editor.html 冻结稿）。
///
/// 全屏 push：顶栏 38 圆返回键 + 标题（新建目标/编辑目标），保存落
/// 底部固定主行动胶囊（必填未满足置灰 .4）。组序（冻结稿）：模板条
/// （仅创建，点击回填名称/类型/图标）→ 类型 → 一句话描述 → 分类 →
/// 提醒（短期无提醒区，另有里程碑提示卡）。
/// 形态决策（冻结稿）：**类型编辑锁定**（003「类型可改」随之退役）；
/// 分类 = 常用 6 + 「更多」上滑弹层全量按域分组（组头三大类色点），
/// 选中格 accent 描边同色图标 + 域归属提示行。FR-016 底线：退役字段
/// 仅编辑时原值继承（colorKey/motivation/successCriterion/cueScene）。
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

  /// null = 创建；非 null = 编辑（类型锁定，冻结稿板 4）。
  final String? goalId;

  /// 引导页/空态带入的模板预填（仅创建模式）。
  final GoalTemplate? template;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  final _name = TextEditingController();

  /// 类型默认短期（冻结稿板 2：新目标默认落短期，截止必填）。
  GoalType _type = GoalType.shortTerm;
  String _iconKey = GoalIconCatalog.explore.key;

  /// 短期截止日：默认 today+39（冻结稿同款），切离短期不写库。
  LocalDate? _deadline;

  /// 提醒开关（习惯/长期共用区）：切型时重置——习惯默认开、长期默认关。
  bool _remindOn = false;
  Cadence _cadence = Cadence.daily;

  /// 提醒时间默认 09:00（冻结稿板 1 为 08:00 示例，应用默认沿 09:00）。
  LocalTime _remindTime = const LocalTime(9, 0);

  /// 编辑模式下既有提醒行 id（保存时原行续写，避免重复建行）。
  String? _reminderId;
  bool _hydrated = false;

  bool get _isEdit => widget.goalId != null;

  /// 保存亮灯条件（冻结稿：必填未满足 → 底部主按钮置灰）。
  bool get _canSave =>
      _name.text.trim().isNotEmpty &&
      (_type != GoalType.shortTerm || _deadline != null);

  @override
  void initState() {
    super.initState();
    // 计数行与保存亮灯随输入即时刷新。
    _name.addListener(() => setState(() {}));
    if (_isEdit) {
      // 目标流就绪后一次性回填表单（含提醒行）。
      ref.listenManual(goalsProvider, (prev, next) {
        final goal = next.value
            ?.where((g) => g.id == widget.goalId)
            .firstOrNull;
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

  /// 切型（仅创建态可达）：提醒语义随型重置，截止日兜底。
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
        await reminderRepo.upsert(
          Reminder(
            id: _reminderId,
            goalId: goalId,
            time: _remindTime,
            isEnabled: true,
            cadence: _cadence,
          ),
        );
      } else if (_reminderId != null) {
        if (_type == GoalType.shortTerm) {
          await reminderRepo.removeByGoal(goalId);
        } else {
          await reminderRepo.upsert(
            Reminder(
              id: _reminderId,
              goalId: goalId,
              time: _remindTime,
              isEnabled: false,
              cadence: _cadence,
            ),
          );
        }
      }
    }

    try {
      if (_isEdit) {
        final goal = (ref.read(goalsProvider).value ?? []).firstWhere(
          (g) => g.id == widget.goalId,
        );
        // 编辑同构（类型锁定）：直构完整 Goal（copyWith 不支持清
        // deadline）；退役字段原值继承（FR-016 存量保全，表单无写入路径）。
        await repo.update(
          Goal(
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
          ),
        );
        await syncReminder(goal.id);
      } else {
        final created = await repo.create(
          Goal(
            name: name,
            goalType: _type,
            iconKey: _iconKey,
            colorKey: 'teal', // 退役列兜底值，任何界面不再读取（FR-015/016）
            createdAt: today,
            deadline: _type == GoalType.shortTerm ? _deadline : null,
          ),
        );
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
                child: const Text(Copy.notifAck),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && !_hydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // v2 push 顶栏：38 圆返回键 + 标题（新建目标/编辑目标）。
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s5,
                AppSpace.s3,
                AppSpace.s5,
                AppSpace.s2,
              ),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: AppSpace.s3),
                  Text(
                    _isEdit ? Copy.goalEdit : Copy.editorNewGoal,
                    style: Theme.of(context).textTheme.titleM,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s5,
                  AppSpace.s2,
                  AppSpace.s5,
                  AppSpace.s4,
                ),
                children: [
                  if (!_isEdit) ...[
                    _TemplateStrip(onTap: _applyTemplate),
                    const SizedBox(height: AppSpace.s4),
                  ],
                  _GroupCard(
                    title: Copy.editorSectionType,
                    badge: _isEdit
                        ? const _Tag(
                            Copy.editorTypeLockedTag,
                            emphasized: false,
                          )
                        : null,
                    child: _typeSection(),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  _GroupCard(
                    title: Copy.editorSectionBasics,
                    badge: const _Tag(Copy.editorRequiredTag, emphasized: true),
                    child: _nameField(),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  _GroupCard(
                    title: Copy.editorSectionCategory,
                    child: _categoryCard(),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  if (_type == GoalType.shortTerm)
                    _GroupCard(
                      title: Copy.editorMilestoneTitle,
                      badge: const _Tag(
                        Copy.editorOptionalTag,
                        emphasized: false,
                      ),
                      child: Text(
                        Copy.editorMilestoneHint,
                        style: Theme.of(context).textTheme.bodyL.copyWith(
                          color: TargetPalette.of(context).onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    _GroupCard(
                      title: Copy.editorSectionReminder,
                      child: _reminderCard(),
                    ),
                ],
              ),
            ),
            // 底部固定主行动（冻结稿 .btn-primary：胶囊 + accent 实心，
            // 必填未满足置灰）。
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s5,
                AppSpace.s3,
                AppSpace.s5,
                AppSpace.s5,
              ),
              child: _SaveButton(enabled: _canSave, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }

  /// 类型区：三段分段（编辑态锁定 .55）+ 短期截止行（含倒计时）。
  Widget _typeSection() {
    final seg = SegmentedPill<GoalType>(
      key: const ValueKey('goalTypeSeg'),
      values: GoalType.values,
      labelOf: (t) => switch (t) {
        GoalType.longTerm => Copy.typeBadgeLongTerm,
        GoalType.shortTerm => Copy.typeBadgeShortTerm,
        GoalType.habit => Copy.typeBadgeHabit,
      },
      selected: _type,
      onSelected: _isEdit ? null : (t) => setState(() => _setType(t)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 冻结稿板 4：编辑态类型锁定（opacity .55 + 不可点）。
        Opacity(
          opacity: _isEdit ? .55 : 1,
          child: IgnorePointer(ignoring: _isEdit, child: seg),
        ),
        if (_type == GoalType.shortTerm) ...[
          const SizedBox(height: AppSpace.s3),
          _deadlineRow(),
        ],
      ],
    );
  }

  /// 短期截止行：必填小标 + 日期值 + 倒计时预告（冻结稿板 2）。
  Widget _deadlineRow() {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final days = _deadline?.differenceInDays(today) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('goalDeadlineField'),
          onTap: _pickDeadline,
          child: Row(
            children: [
              Text(Copy.editorDeadlineLabel, style: theme.textTheme.bodyL),
              const SizedBox(width: AppSpace.s2),
              const _Tag(Copy.editorRequiredTag, emphasized: true),
              const Spacer(),
              Text(_deadline?.isoString ?? '', style: theme.textTheme.bodyL),
              Icon(
                Icons.expand_more,
                size: 18,
                color: palette.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Text(
          Copy.editorCountdownPreview(days),
          key: const ValueKey('goalCountdownPreview'),
          style: theme.textTheme.bodyS.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 一句话描述（40 字计数，冻结稿 .input/.cnt）。
  Widget _nameField() {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final border = BorderSide(color: palette.divider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('goalNameField'),
          controller: _name,
          maxLength: 40,
          style: theme.textTheme.bodyL,
          decoration: InputDecoration(
            hintText: Copy.editorNameHint,
            counterText: '',
            isDense: true,
            filled: true,
            fillColor: palette.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s4,
              vertical: AppSpace.s3,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: border,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(color: palette.accent),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s1),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_name.text.length}/40',
            style: theme.textTheme.bodyS.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// 分类组（冻结稿）：常用一行策展 6 枚 + 「更多」上滑弹层全量；
  /// 选中格 accent 描边 + 同色图标；行下域归属提示（大类色点）。
  static const _commonIcons = [
    GoalIconCatalog.fitnessCenter,
    GoalIconCatalog.menuBook,
    GoalIconCatalog.favorite,
    GoalIconCatalog.directionsBike,
    GoalIconCatalog.brush,
    GoalIconCatalog.savings,
  ];

  Widget _categoryCard() {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final icon = GoalIconCatalog.byKey(_iconKey);
    final majorColor = MajorColors.byKey(icon.domain.major.name).of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final c in _commonIcons) ...[
              _IconCell(
                icon: c.icon,
                selected: _iconKey == c.key,
                semanticLabel: Copy.editorIconSemantics(c.key),
                onTap: () => setState(() => _iconKey = c.key),
              ),
              const SizedBox(width: AppSpace.s2),
            ],
            _MoreCell(onTap: _openPicker),
          ],
        ),
        const SizedBox(height: AppSpace.s3),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: majorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.s2),
            Text(
              '${icon.domain.zhLabel} · ${icon.domain.major.zhLabel}',
              style: theme.textTheme.bodyS.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IconPickerSheet(selectedKey: _iconKey),
    );
    if (picked != null) setState(() => _iconKey = picked);
  }

  /// 提醒区（习惯/长期）：开关 →（开）频率三档 + 提醒时间行。
  Widget _reminderCard() {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(Copy.editorReminderSwitch, style: theme.textTheme.bodyL),
            const Spacer(),
            Switch(
              key: const ValueKey('goalRemindSwitch'),
              value: _remindOn,
              onChanged: (v) => setState(() => _remindOn = v),
            ),
          ],
        ),
        if (!_remindOn)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s1),
            child: Text(
              Copy.editorReminderOffSub,
              style: theme.textTheme.bodyS.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          const SizedBox(height: AppSpace.s3),
          Text(
            Copy.editorCadenceLabel,
            style: theme.textTheme.labelS.copyWith(
              color: palette.onSurfaceVariant,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          SegmentedPill<Cadence>(
            key: const ValueKey('goalCadenceSeg'),
            values: Cadence.values,
            labelOf: (c) => switch (c) {
              Cadence.daily => Copy.cadenceDaily,
              Cadence.threeDay => Copy.cadenceThreeDay,
              Cadence.weekly => Copy.cadenceWeekly,
            },
            selected: _cadence,
            onSelected: (c) => setState(() => _cadence = c),
          ),
          const SizedBox(height: AppSpace.s3),
          InkWell(
            key: const ValueKey('goalRemindTimeField'),
            onTap: _pickTime,
            child: Row(
              children: [
                Text(Copy.editorRemindTimeLabel, style: theme.textTheme.bodyL),
                const Spacer(),
                Text(_remindTime.isoString, style: theme.textTheme.bodyL),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: palette.onSurfaceVariant,
                ),
              ],
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
      initialTime: TimeOfDay(
        hour: _remindTime.hour,
        minute: _remindTime.minute,
      ),
    );
    if (picked != null) {
      setState(() => _remindTime = LocalTime(picked.hour, picked.minute));
    }
  }
}

/// push 顶栏返回键（v2 .ed-back）：38 圆 surface 底 + 细边 + 低影。
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Semantics(
      button: true,
      label: '返回',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.surface,
            shape: BoxShape.circle,
            border: Border.all(color: palette.divider),
            boxShadow: palette.shadowLow,
          ),
          child: Icon(Icons.chevron_left, size: 26, color: palette.onSurface),
        ),
      ),
    );
  }
}

/// 模板快捷条（冻结稿板 1 .tpl-row）：横滑胶囊，点击回填名称/类型/图标。
class _TemplateStrip extends StatelessWidget {
  const _TemplateStrip({required this.onTap});

  final ValueChanged<GoalTemplate> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (final t in kHabitTemplates)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.s2),
              child: InkWell(
                onTap: () => onTap(t),
                borderRadius: AppRadius.rFull,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s4,
                    vertical: AppSpace.s2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: AppRadius.rFull,
                    border: Border.all(color: palette.divider),
                  ),
                  child: Row(
                    children: [
                      // 冻结稿 .tpl：药丸统一环徽（trip_origin 18px accent），
                      // 不逐模板取形（与常用行图标解耦，避免同名双现）。
                      Icon(Icons.trip_origin, size: 18, color: palette.accent),
                      const SizedBox(width: AppSpace.s2),
                      Text(t.name, style: theme.textTheme.bodyM),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 分组卡（冻结稿 .card）：surface 底 + rLg + shadowLow、无描边；
/// 标题 = label 大写间距小字 + 可选角标（必填 accent / 选填 surfaceAlt）。
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, this.badge, required this.child});

  final String title;
  final Widget? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Material(
      color: palette.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rLg,
          boxShadow: palette.shadowLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelS.copyWith(
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
            const SizedBox(height: AppSpace.s3),
            child,
          ],
        ),
      ),
    );
  }
}

/// 角标胶囊（冻结稿 .req/.opt）：必填 accent 实底 / 选填 surfaceAlt。
class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.emphasized});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final on = emphasized ? palette.accent : palette.surfaceAlt;
    final fg = emphasized ? palette.accentOn : palette.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: 1),
      decoration: BoxDecoration(color: on, borderRadius: AppRadius.rFull),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelS
            .copyWith(color: fg, letterSpacing: 0),
      ),
    );
  }
}

/// v2 分段控件（冻结稿 .seg）：surfaceAlt 轨道 + 选中段 surface 浮起
/// 加粗。onSelected 为 null = 锁定（不响应点选）。
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    this.onSelected,
  });

  final List<T> values;
  final String Function(T) labelOf;

  /// 当前选中值（测试经 `widget<SegmentedPill<T>>().selected` 读态）。
  final T selected;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        children: [
          for (final (i, v) in values.indexed) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: InkWell(
                onTap: onSelected == null ? null : () => onSelected!(v),
                borderRadius: AppRadius.rSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
                  decoration: BoxDecoration(
                    color: v == selected ? palette.surface : null,
                    borderRadius: AppRadius.rSm,
                    boxShadow: v == selected ? palette.shadowLow : null,
                  ),
                  child: Text(
                    labelOf(v),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyM.copyWith(
                      color: v == selected
                          ? palette.onSurface
                          : palette.onSurfaceVariant,
                      fontWeight: v == selected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 保存主行动（冻结稿 .btn-primary）：全宽胶囊 accent 实心 + 中影；
/// 置灰态 opacity .4 无影。
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        boxShadow: enabled ? palette.shadowMid : null,
      ),
      child: FilledButton(
        key: const ValueKey('goalSaveButton'),
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          disabledBackgroundColor: palette.accent.withValues(alpha: .4),
          foregroundColor: palette.accentOn,
          disabledForegroundColor: palette.accentOn,
          textStyle: Theme.of(context).textTheme.titleS,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rFull),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
          minimumSize: const Size(double.infinity, 0),
        ),
        child: const Text(Copy.editorSave),
      ),
    );
  }
}

/// 图标格（冻结稿 .icell）：surfaceAlt 底 rMd；选中 = accent 1.5 描边
/// + accent 图标（003 accent 实底形态退役）。常用行 38px/图标 22。
class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.icon,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
    this.size = 38,
    this.iconSize = 22,
  });

  final IconData icon;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

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
            color: palette.surfaceAlt,
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: selected ? palette.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: selected ? palette.accent : palette.onSurface,
          ),
        ),
      ),
    );
  }
}

/// 「更多」格（冻结稿 .imore）：虚线描边 + 环形图标 + 「更多」小字。
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
          foregroundPainter: _DashedBorderPainter(color: palette.divider),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trip_origin,
                  size: 13,
                  color: palette.onSurfaceVariant,
                ),
                const SizedBox(height: 1),
                Text(
                  Copy.editorIconMoreShort,
                  style: Theme.of(context).textTheme.labelS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆角矩形虚线描边（冻结稿 border: dashed；Flutter 边框无 dash 选项，自绘）。
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
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, AppRadius.rMd.topLeft),
      );
    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        canvas.drawPath(metric.extractPath(start, start + 4), paint);
        start += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

/// 分类全量上滑弹层（冻结稿板 3 .sheet）：38 枚按 10 域分组，组头
/// 带三大类色点；6 列方格；点选即关（pop key）；scrim 点外关闭。
class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({required this.selectedKey});

  final String selectedKey;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * .78;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
        boxShadow: palette.shadowHigh,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 抓手条（冻结稿 .grab）。
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(
              top: AppSpace.s3,
              bottom: AppSpace.s3,
            ),
            decoration: BoxDecoration(
              color: palette.divider,
              borderRadius: AppRadius.rFull,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s5,
              0,
              AppSpace.s5,
              AppSpace.s3,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                Copy.editorPickCategoryTitle,
                style: theme.textTheme.titleS,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s5,
                0,
                AppSpace.s5,
                AppSpace.s5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in GoalIconCatalog.byDomain.entries) ...[
                    _DomainHeader(domain: entry.key),
                    const SizedBox(height: AppSpace.s2),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = AppSpace.s2;
                        final w = (constraints.maxWidth - 5 * gap) / 6;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final c in entry.value)
                              SizedBox(
                                width: w,
                                height: w,
                                child: _IconCell(
                                  icon: c.icon,
                                  size: w,
                                  iconSize: 22,
                                  selected: c.key == selectedKey,
                                  semanticLabel: Copy.editorIconSemantics(
                                    c.key,
                                  ),
                                  onTap: () => Navigator.of(context).pop(c.key),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpace.s4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹层域组头（冻结稿 .dh）：大类色点 + 「域 · 大类」。
class _DomainHeader extends StatelessWidget {
  const _DomainHeader({required this.domain});

  final GoalIconDomain domain;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final color = MajorColors.byKey(domain.major.name).of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.s2),
        Text(
          '${domain.zhLabel} · ${domain.major.zhLabel}',
          style: Theme.of(context).textTheme.labelS
              .copyWith(color: palette.onSurfaceVariant),
        ),
      ],
    );
  }
}
