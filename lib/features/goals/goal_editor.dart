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
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/page_top_bar.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/db/repositories.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import 'goal_templates.dart';
import 'goal_icon_picker.dart';

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
  final _firstPlans = <GoalType, TextEditingController>{
    for (final type in GoalType.values) type: TextEditingController(),
  };

  /// 类型默认短期（冻结稿板 2：新目标默认落短期，截止必填）。
  GoalType _type = GoalType.shortTerm;
  String _iconKey = GoalIconCatalog.explore.key;

  /// 短期截止日：默认 today+39（冻结稿同款），切离短期不写库。
  LocalDate? _deadline;
  LocalDate? _targetDate;
  int _shortCadenceDays = 7;
  int _longCadenceDays = 14;
  int _habitTargetPerWeek = 5;
  GoalIconDomain? _categoryOverride;

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
      _remindOn = false;
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
      _targetDate = goal.targetDate;
      if (goal.isShortTerm) _shortCadenceDays = goal.progressCadenceDays;
      if (goal.isLongTerm) _longCadenceDays = goal.progressCadenceDays;
      _habitTargetPerWeek = goal.habitTargetPerWeek ?? 5;
      _categoryOverride = goal.categoryOverride;
      _remindOn = mine?.isEnabled ?? false;
      _cadence = mine?.effectiveCadence ?? Cadence.daily;
      _remindTime = mine?.time ?? const LocalTime(9, 0);
      _reminderId = mine?.id;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _firstPlans.values) {
      controller.dispose();
    }
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
    _remindOn = false;
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
            categoryOverride: _categoryOverride,
            progressCadenceDays: _type == GoalType.longTerm
                ? _longCadenceDays
                : _shortCadenceDays,
            colorKey: goal.colorKey,
            status: goal.status,
            createdAt: goal.createdAt,
            deadline: _type == GoalType.shortTerm ? _deadline : null,
            targetDate: _type == GoalType.longTerm ? _targetDate : null,
            habitTargetPerWeek: _type == GoalType.habit
                ? _habitTargetPerWeek
                : null,
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
            categoryOverride: _categoryOverride,
            progressCadenceDays: _type == GoalType.longTerm
                ? _longCadenceDays
                : _shortCadenceDays,
            colorKey: 'teal', // 退役列兜底值，任何界面不再读取（FR-015/016）
            createdAt: today,
            deadline: _type == GoalType.shortTerm ? _deadline : null,
            targetDate: _type == GoalType.longTerm ? _targetDate : null,
            habitTargetPerWeek: _type == GoalType.habit
                ? _habitTargetPerWeek
                : null,
          ),
        );
        final firstPlan = _firstPlans[_type]!.text.trim();
        if (firstPlan.isNotEmpty) {
          await repo.addStep(
            MilestoneStep(goalId: created.id, title: firstPlan, position: 0),
          );
        }
      }
      if (mounted) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          GoRouter.maybeOf(context)?.go('/today');
        }
      }
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
            // 005 T008：共享次级顶栏（原手写行退役，D5 同构；默认
            // onBack 即 Navigator.maybePop，语义零变化）。
            PageTopBar(title: _isEdit ? Copy.goalEdit : Copy.editorNewGoal),
            Expanded(
              child: ListView(
                // 005 D2：页缘=列表档 s4(16)（hero 两屏 24，分层基准）。
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s4,
                  AppSpace.s2,
                  AppSpace.s4,
                  AppSpace.s4,
                ),
                children: [
                  _GroupCard(
                    title: '目标名称',
                    badge: const _Tag(Copy.editorRequiredTag, emphasized: true),
                    child: _nameField(),
                  ),
                  const SizedBox(height: AppSpace.s4),
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
                  _GroupCard(title: '图标与分类', child: _categoryCard()),
                  const SizedBox(height: AppSpace.s4),
                  _GroupCard(title: '计划设置', child: _planningSection()),
                  const SizedBox(height: AppSpace.s4),
                  _GroupCard(
                    title: _type == GoalType.habit ? '第一次行动' : '第一项里程碑',
                    badge: const _Tag(
                      Copy.editorOptionalTag,
                      emphasized: false,
                    ),
                    child: _firstPlanField(),
                  ),
                ],
              ),
            ),
            // 底部固定主行动（冻结稿 .btn-primary：胶囊 + accent 实心，
            // 必填未满足置灰）。
            Padding(
              // 005 D2：水平随页缘列表档 16。
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s4,
                AppSpace.s3,
                AppSpace.s4,
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
          maxLength: 30,
          style: theme.textTheme.bodyL,
          decoration: InputDecoration(
            hintText: '例如：拿到 OW 潜水证',
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
            '${_name.text.length}/30',
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
    final domain = _categoryOverride ?? icon.domain;
    final majorColor = MajorColors.byKey(domain.major.name).of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          children: [
            for (final c in _commonIcons) ...[
              _IconCell(
                icon: c.icon,
                selected: _iconKey == c.key,
                semanticLabel: goalIconLabel(c),
                onTap: () => setState(() {
                  _iconKey = c.key;
                  _categoryOverride = null;
                }),
              ),
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
              '${_categoryOverride == null ? '自动分类' : '已更正'}：'
              '${domain.zhLabel} · ${domain.major.zhLabel}',
              style: theme.textTheme.bodyS.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: _correctCategory, child: const Text('更正')),
          ],
        ),
      ],
    );
  }

  Future<void> _openPicker() async {
    final picked = await showGoalIconPicker(context, selectedKey: _iconKey);
    if (picked != null) {
      setState(() {
        _iconKey = picked.key;
        _categoryOverride = null;
      });
    }
  }

  Future<void> _correctCategory() async {
    final picked = await showModalBottomSheet<GoalIconDomain>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = TargetPalette.of(context);
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('更正分类', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '分类用于首页分数和筛选，不会改变你选择的图标。',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final domain in GoalIconDomain.values)
                      ListTile(
                        leading: Icon(
                          GoalIconCatalog.byDomain[domain]!.first.icon,
                          color: MajorColors.byKey(domain.major.name)
                              .of(context),
                        ),
                        title: Text(domain.zhLabel),
                        subtitle: Text(domain.major.zhLabel),
                        trailing:
                            domain ==
                                (_categoryOverride ??
                                    GoalIconCatalog.byKey(_iconKey).domain)
                            ? Icon(Icons.check_rounded, color: palette.accent)
                            : null,
                        onTap: () => Navigator.of(context).pop(domain),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _categoryOverride = picked);
  }

  Widget _planningSection() {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    if (_type == GoalType.habit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('执行频率', style: theme.textTheme.bodyL),
          const SizedBox(height: AppSpace.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: AppRadius.rMd,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: const ValueKey('habitFrequencyField'),
                value: _habitTargetPerWeek,
                isExpanded: true,
                items: [
                  for (var count = 1; count <= 7; count++)
                    DropdownMenuItem(value: count, child: Text('每周 $count 次')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _habitTargetPerWeek = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          Text(
            '频率用于计算最近七天的执行完成度，之后可以随实际节奏调整。',
            style: theme.textTheme.bodyS.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final cadence = _type == GoalType.longTerm
        ? _longCadenceDays
        : _shortCadenceDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_type == GoalType.shortTerm) _deadlineRow() else _targetDateRow(),
        const SizedBox(height: AppSpace.s4),
        Text('推进周期', style: theme.textTheme.bodyL),
        const SizedBox(height: AppSpace.s2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s3,
            vertical: AppSpace.s2,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: AppRadius.rMd,
          ),
          child: Row(
            children: [
              Expanded(child: Text('每 $cadence 天检查一次进展')),
              IconButton(
                tooltip: '减少推进周期',
                onPressed: cadence <= 1
                    ? null
                    : () => setState(() {
                        if (_type == GoalType.longTerm) {
                          _longCadenceDays--;
                        } else {
                          _shortCadenceDays--;
                        }
                      }),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              IconButton(
                tooltip: '增加推进周期',
                onPressed: cadence >= 365
                    ? null
                    : () => setState(() {
                        if (_type == GoalType.longTerm) {
                          _longCadenceDays++;
                        } else {
                          _shortCadenceDays++;
                        }
                      }),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _targetDateRow() {
    final palette = TargetPalette.of(context);
    return InkWell(
      key: const ValueKey('goalTargetDateField'),
      onTap: _pickTargetDate,
      borderRadius: AppRadius.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
        child: Row(
          children: [
            Text('目标日期', style: Theme.of(context).textTheme.bodyL),
            const SizedBox(width: AppSpace.s2),
            const _Tag(Copy.editorOptionalTag, emphasized: false),
            const Spacer(),
            Text(
              _targetDate?.isoString ?? '未设置',
              style: Theme.of(context).textTheme.bodyM.copyWith(
                color: _targetDate == null
                    ? palette.onSurfaceVariant
                    : palette.onSurface,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _firstPlanField() {
    final palette = TargetPalette.of(context);
    return TextField(
      key: const ValueKey('firstPlanField'),
      controller: _firstPlans[_type],
      maxLength: 50,
      decoration: InputDecoration(
        hintText: _type == GoalType.habit
            ? '例如：明天晚饭后散步 20 分钟'
            : '例如：完成 DSD 体验潜水',
        filled: true,
        fillColor: palette.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: palette.divider),
        ),
      ),
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

  Future<void> _pickTargetDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      firstDate: today.atStartOfDay,
      lastDate: DateTime(today.year + 10, 12, 31),
      initialDate: (_targetDate ?? today.addDays(90)).atStartOfDay,
    );
    if (picked != null) {
      setState(() => _targetDate = LocalDate.fromDateTime(picked));
    }
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
          width: 38,
          height: 38,
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
