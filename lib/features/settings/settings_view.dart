/// 设置页（003 R3 定稿 · T034 四分组重构：账号卡 + 通知/目标/数据/关于）。
///
/// 行形态全标准（图标 + 标题 + 行尾值|开关|箭头，FR-009）：账号卡复用
/// 资料编辑 sheet；通知组（T035：总开关聚合 Reminders 行 isEnabled，切换
/// 全开/全关——与排程器「Reminders 行 = 唯一真源」一致，零 schema 变更；
/// 简报时间值行 + 按目标提醒二级展开逐行开关）；目标组活跃数 → 今日页 +
/// 补签只读；数据组备份导出/导入；关于组版本。
/// 权限被拒不反复弹窗（FR-007）：未开启只说明一次，「知道了」后不再打扰。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/backup/backup_exporter.dart';
import '../../core/backup/backup_importer.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../profile/profile.dart';
import 'debug_clock.dart';

/// dailyBrief 提醒行固定 id（goalId=null ⇔ 概要）。
const _briefRowId = 'daily-brief';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  /// 通知权限态（null = 还没查到）；只在 iOS 实机上存在，Web 恒视为已授权。
  bool? _granted;

  /// 「按目标提醒」二级列表展开态。
  bool _goalsExpanded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      ref
          .read(notificationGatewayProvider)
          .isPermissionGranted
          .then((v) => _setGranted(v));
    }
  }

  void _setGranted(bool v) {
    if (mounted) setState(() => _granted = v);
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final settings = ref.watch(settingsProvider).value;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final activeCount =
        goals.where((g) => g.status == GoalStatus.active).length;

    final briefRow = reminders.where((r) => r.isDailyBrief).firstOrNull;
    final briefTime =
        briefRow?.time ?? settings?.dailyBriefTime ?? const LocalTime(8, 0);
    final briefEnabled = briefRow?.isEnabled ?? true;

    // 按目标提醒二级列表：只列活跃目标的行（排程器同口径跳过暂停/孤儿行）。
    final activeById = {
      for (final g in goals)
        if (g.status == GoalStatus.active) g.id: g,
    };
    final goalRows = [
      for (final r in reminders)
        if (!r.isDailyBrief && activeById.containsKey(r.goalId)) r,
    ];
    final enabledCount = goalRows.where((r) => r.isEnabled).length;

    // 总开关 = 简报与逐目标行的聚合视图：任一在开即视为开（含无行默认开）。
    final masterOn = briefEnabled || enabledCount > 0;

    // 权限卡可见 = 非 Web、已知未开启、未「知道了」；此时提示换成开关说明（画板②）。
    final permCardVisible = !kIsWeb &&
        _granted == false &&
        (settings?.notificationDeniedAcknowledged ?? true) == false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.s6, 0, AppSpace.s6, AppSpace.s12),
          children: [
            // FR-008 三屏标题带同构（今日屏基准）：左缘 24、顶垫 8、44px 带。
            ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: AppScreen.titleBand),
              child: Padding(
                padding: const EdgeInsets.only(top: AppScreen.titleTop),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(Copy.settingsTitle,
                      key: const ValueKey('screenTitle'),
                      style: Theme.of(context).textTheme.displayS),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s2),
            const _MeCard(),

            // ---- 分组·通知（T035：总开关 + 简报时间 + 按目标提醒二级）----
            const _SectionLabel(Copy.settingsSectionNotif),
            if (permCardVisible) _PermCard(onRequest: _requestPermission),
            _GroupCard(children: [
              _SettingsRow(
                icon: Icons.notifications_outlined,
                title: Copy.settingsNotifMasterTitle,
                sub: Copy.settingsNotifMasterSub,
                switchValue: masterOn,
                onSwitch: _setMasterAll,
              ),
              _SettingsRow(
                icon: Icons.access_time_outlined,
                title: Copy.settingsBriefTitle,
                sub: Copy.settingsBriefSub,
                time: briefTime,
                showChevron: true,
                onTap: () => _pickBriefTime(context, briefTime),
              ),
              _SettingsRow(
                icon: Icons.checklist_outlined,
                title: Copy.settingsGoalRemindersTitle,
                sub: goalRows.isEmpty
                    ? Copy.settingsGoalRemindersNoneSub
                    : Copy.settingsGoalRemindersSub(enabledCount),
                showChevron: true,
                expanded: _goalsExpanded,
                onTap: () => setState(() => _goalsExpanded = !_goalsExpanded),
              ),
              if (_goalsExpanded)
                Container(
                  // 二级嵌套浅底（原型 s-nest）：整幅 surfaceAlt，行内容缩进。
                  color: TargetPalette.of(context).surfaceAlt,
                  padding: const EdgeInsets.only(left: AppSpace.s4),
                  child: Column(children: [
                    for (final r in goalRows)
                      _SettingsRow(
                        icon: GoalIconCatalog.byKey(
                                activeById[r.goalId]!.iconKey)
                            .icon,
                        title: activeById[r.goalId]!.name,
                        sub: Copy.settingsGoalReminderLine(
                            _cadenceLabel(r.effectiveCadence),
                            r.time.isoString),
                        switchValue: r.isEnabled,
                        onSwitch: (v) => _setGoalReminder(r, v),
                      ),
                  ]),
                ),
            ]),
            _Hints(hints: permCardVisible
                ? const [Copy.notifOffHint]
                : const [Copy.reminderMondayHint, Copy.reminderGoalHint]),

            // ---- 分组·目标：活跃数（→今日页）+ 补签只读说明 ----
            const _SectionLabel(Copy.settingsSectionGoals),
            _GroupCard(children: [
              _SettingsRow(
                icon: Icons.flag_outlined,
                title: Copy.settingsGoalsActiveTitle,
                sub: Copy.settingsGoalsActiveSub,
                value: '$activeCount',
                showChevron: true,
                onTap: () => context.go('/today'),
              ),
              const _SettingsRow(
                icon: Icons.event_outlined,
                title: Copy.settingsBackfillTitle,
                sub: Copy.settingsBackfillSub,
              ),
            ]),

            // ---- 分组·数据 ----
            const _SectionLabel(Copy.settingsSectionData),
            const _BackupCard(),

            // ---- 分组·关于 ----
            const _SectionLabel(Copy.settingsSectionAbout),
            const _GroupCard(children: [
              _SettingsRow(
                icon: Icons.info_outline,
                title: Copy.settingsVersionTitle,
                value: Copy.settingsVersionValue,
              ),
            ]),
            // 003 T045 语域清查：隐私脚注移除——本地存储说明不上屏（FR-021）。
            if (kDebugMode) ...[
              const SizedBox(height: AppSpace.s4),
              const _SectionLabel(Copy.debugClock),
              _GroupCard(children: const [DebugClockTile()]),
            ],
            if (kIsWeb) ...[
              const SizedBox(height: AppSpace.s4),
              Text(
                Copy.widgetIosOnly,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyS
                    .copyWith(color: TargetPalette.of(context).onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission() async {
    _setGranted(await ref.read(notificationGatewayProvider).requestPermission());
  }

  /// 总开关：全开/全关所有 Reminders 行。简报无行时排程器视为默认开
  /// （reminder_service 契约），故无论开/关都显式落一条简报行承载总开关
  /// 态——否则关掉逐目标行后聚合视图仍被「默认开」的简报拉回 true。
  Future<void> _setMasterAll(bool on) async {
    final repo = ref.read(reminderRepoProvider);
    final rows = await repo.all();
    for (final r in rows) {
      await repo.upsert(r.copyWith(isEnabled: on));
    }
    if (!rows.any((r) => r.isDailyBrief)) {
      await repo.upsert(Reminder(
          id: _briefRowId,
          goalId: null,
          time: ref.read(settingsProvider).value?.dailyBriefTime ??
              const LocalTime(8, 0),
          isEnabled: on));
    }
  }

  Future<void> _setGoalReminder(Reminder r, bool on) async {
    await ref.read(reminderRepoProvider).upsert(r.copyWith(isEnabled: on));
  }

  String _cadenceLabel(Cadence c) => switch (c) {
        Cadence.daily => Copy.cadenceDaily,
        Cadence.threeDay => Copy.cadenceThreeDay,
        Cadence.weekly => Copy.cadenceWeekly,
      };

  Future<void> _pickBriefTime(BuildContext context, LocalTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    final repo = ref.read(reminderRepoProvider);
    final existing =
        (await repo.all()).where((r) => r.isDailyBrief).firstOrNull;
    await repo.upsert(Reminder(
        id: existing?.id ?? _briefRowId,
        goalId: null,
        time: LocalTime(picked.hour, picked.minute),
        isEnabled: existing?.isEnabled ?? true));
    final s = await ref.read(settingsRepoProvider).get();
    await ref.read(settingsRepoProvider)
        .update(s.copyWith(dailyBriefTime: LocalTime(picked.hour, picked.minute)));
  }
}

/// 账号卡（003 R3）：真资料头像 + 昵称 + 「本地资料」+「编辑」→ sheet。
class _MeCard extends ConsumerWidget {
  const _MeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final profile = ref.watch(profileProvider).value;
    return Material(
      color: palette.glassCard,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rLg,
          border: Border.all(color: palette.divider),
          boxShadow: palette.shadowLow,
        ),
        child: Row(
          children: [
            ProfileAvatar(profile: profile, size: 44),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      profile?.nickname ?? Copy.profileDefaultNickname,
                      key: const ValueKey('meNickname'),
                      style: Theme.of(context).textTheme.titleS),
                  const SizedBox(height: 2),
                  Text(
                    Copy.settingsMeSub,
                    style: Theme.of(context)
                        .textTheme
                        .bodyS
                        .copyWith(color: palette.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showProfileSheet(context),
              child: const Text(Copy.settingsEdit),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分组小标：labelS + 字距。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s1, AppSpace.s3, AppSpace.s1, AppSpace.s1),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelS.copyWith(
            letterSpacing: 0.9,
            color: TargetPalette.of(context).onSurfaceVariant),
      ),
    );
  }
}

/// 组卡：玻璃容器，行间细分隔。
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    // Material 承色 + Container 描边投影（goals 卡同款习惯，墨迹可见）。
    return Material(
      color: palette.glassCard,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.rLg,
          border: Border.all(color: palette.divider),
          boxShadow: palette.shadowLow,
        ),
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: palette.divider),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// 通用设置行：32 图标格 + 标题/副文 + 行尾（值 | 时间 | 开关 | 箭头）。
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.sub,
    this.value,
    this.time,
    this.switchValue,
    this.onSwitch,
    this.showChevron = false,
    this.expanded = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final String? value;
  final LocalTime? time;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;

  /// 行尾箭头（值行/二级入口）；已展开时箭头转向下（原型 chev 旋转语义）。
  final bool showChevron;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s4, vertical: AppSpace.s3),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.rMd,
              ),
              child: Icon(icon, size: 16, color: palette.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyL),
                  if (sub case final s? when s.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      s,
                      style: Theme.of(context)
                          .textTheme
                          .bodyS
                          .copyWith(color: palette.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (value case final v?) ...[
              const SizedBox(width: AppSpace.s2),
              Text(
                v,
                style: Theme.of(context).textTheme.bodyM.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
            if (time case LocalTime t) ...[
              const SizedBox(width: AppSpace.s2),
              Text(
                t.isoString,
                style: Theme.of(context).textTheme.bodyM.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
            if (switchValue case bool v) ...[
              const SizedBox(width: AppSpace.s2),
              Switch(
                value: v,
                onChanged: onSwitch,
                activeThumbColor: palette.positiveFill,
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: AppSpace.s1),
              Icon(expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20, color: palette.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

/// 提示行（场景指引）：卡外小字，bodyS。
class _Hints extends StatelessWidget {
  const _Hints({required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.s1, AppSpace.s2, AppSpace.s1, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final h in hints) ...[
            Text(
              h,
              style: Theme.of(context)
                  .textTheme
                  .bodyS
                  .copyWith(color: palette.onSurfaceVariant, height: 1.6),
            ),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}

/// 通知权限卡（FR-007）：未开启只说明一次，「知道了」后不再打扰。
/// 可见性由父级判定（与提示文案联动），这里只负责展示与两个动作。
class _PermCard extends ConsumerWidget {
  const _PermCard({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s2),
      child: Material(
        color: palette.glassCard,
        borderRadius: AppRadius.rLg,
        clipBehavior: Clip.antiAlias,
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
              Text(Copy.notifDeniedTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleS
                      .copyWith(color: palette.warning, height: 1)),
              const SizedBox(height: AppSpace.s2),
              Text(
                Copy.notifDeniedBody,
                style: Theme.of(context)
                    .textTheme
                    .bodyS
                    .copyWith(color: palette.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: AppSpace.s3),
              Row(
                children: [
                  InkWell(
                    onTap: onRequest,
                    borderRadius: AppRadius.rMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s4, vertical: AppSpace.s2),
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: AppRadius.rMd,
                        boxShadow: palette.shadowMid,
                      ),
                      child: Text(
                        Copy.notifEnable,
                        style: Theme.of(context).textTheme.bodyM.copyWith(
                            color: palette.accentOn,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final s = await ref.read(settingsRepoProvider).get();
                      await ref.read(settingsRepoProvider).update(s.copyWith(
                          notificationDeniedAcknowledged: true));
                    },
                    child: Text(
                      Copy.notifAck,
                      style: Theme.of(context)
                          .textTheme
                          .bodyM
                          .copyWith(color: palette.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 备份卡（FR-015）：导出（Web 下载 / iOS 分享面板）、导入（校验 →
/// 冲突弹窗「覆盖本地/取消」→ 原子替换 → 摘要）。
class _BackupCard extends ConsumerStatefulWidget {
  const _BackupCard();

  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  static const _entityLabels = {
    'goals': '目标',
    'frequencyVersions': '频率版本',
    'busySessions': '忙碌记录',
    'checkIns': '打卡',
    'milestoneSteps': '里程碑步骤',
    'reminders': '提醒',
    'weeklyReviews': '周回顾',
  };

  @override
  Widget build(BuildContext context) {
    return _GroupCard(children: [
      _SettingsRow(
        icon: Icons.file_upload_outlined,
        title: Copy.backupExport,
        sub: Copy.backupExportSub,
        onTap: _export,
      ),
      _SettingsRow(
        icon: Icons.file_download_outlined,
        title: Copy.backupImport,
        sub: Copy.backupImportSub,
        onTap: _import,
      ),
    ]);
  }

  Future<void> _export() async {
    final now = DateTime.now();
    final json =
        await BackupExporter(ref.read(dbProvider)).exportString(now: now);
    await ref.read(shareGatewayProvider).exportFile(
          fileName: backupFileName(now),
          bytes: utf8.encode(json),
          mime: 'application/json',
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(Copy.backupExported)));
  }

  Future<void> _import() async {
    final picked = await ref.read(filePickGatewayProvider).pickBackupFile();
    if (picked == null) return;
    final importer = BackupImporter(ref.read(dbProvider));
    final BackupData data;
    try {
      data = importer.parse(utf8.decode(picked.bytes));
    } on BackupFormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Copy.backupImportCorrupt}：${e.message}')));
      return;
    }

    // 本地已有数据 → 必须显式选择覆盖，绝不静默合并（FR-015）。
    if (await importer.hasLocalData()) {
      if (!mounted) return;
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(Copy.backupImportConflictTitle),
          content: const Text(Copy.backupImportConflictBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(Copy.backupImportCancel)),
            FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(Copy.backupImportOverwrite)),
          ],
        ),
      );
      if (overwrite != true) return;
    }

    final summary = await importer.apply(data, overwriteLocal: true);
    if (!mounted) return;
    final detail = summary.counts.entries
        .where((e) => e.value > 0)
        .map((e) => '${_entityLabels[e.key] ?? e.key} ${e.value}')
        .join(' · ');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${Copy.backupImportDone}：$detail')));
  }
}

