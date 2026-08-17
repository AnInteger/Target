/// 设置页（US3 T034/T035）：通知权限降级说明（不反复弹窗）、
/// 每日概要时间与开关、逐目标提醒开关与时间。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/backup/backup_exporter.dart';
import '../../core/backup/backup_importer.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import 'debug_clock.dart';

/// dailyBrief 提醒行固定 id（goalId=null ⇔ 概要）。
const _briefRowId = 'daily-brief';

/// 新开目标提醒的默认时间（晚间轻提醒）。
const LocalTime _defaultGoalTime = LocalTime(20, 0);

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final habits = goals
        .where((g) => g.isHabit && g.status == GoalStatus.active)
        .toList();
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final settings = ref.watch(settingsProvider).value;

    final briefRow = reminders.where((r) => r.isDailyBrief).firstOrNull;
    final briefTime = briefRow?.time ?? settings?.dailyBriefTime ?? const LocalTime(8, 0);
    final briefEnabled = briefRow?.isEnabled ?? true;

    return Scaffold(
      appBar: AppBar(title: Text(Copy.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PermissionCard(),
          const SizedBox(height: 16),
          _SectionTitle(Copy.dailyBriefTimeLabel),
          Card(
            child: Column(children: [
              ListTile(
                title: Text(Copy.dailyBriefTitle),
                subtitle: Text(briefTime.isoString,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Switch(
                  value: briefEnabled,
                  onChanged: (v) => _saveBrief(ref, briefTime, v),
                ),
                onTap: () => _pickBriefTime(context, ref, briefTime, briefEnabled),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(Copy.reminderMondayHint,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _SectionTitle(Copy.remindersHeader),
          if (habits.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(Copy.goalsEmpty,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final g in habits)
                    _GoalReminderTile(
                      goal: g,
                      reminder: reminders
                          .where((r) => r.goalId == g.id)
                          .firstOrNull,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(Copy.reminderGoalHint,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _SectionTitle(Copy.backupHeader),
          const _BackupCard(),
          const SizedBox(height: 16),
          const _DataRiskCard(),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            _SectionTitle(Copy.debugClock),
            Card(child: const DebugClockTile()),
          ],
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            Text(Copy.widgetIosOnly,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Future<void> _pickBriefTime(
      BuildContext context, WidgetRef ref, LocalTime current, bool enabled) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    await _saveBrief(ref, LocalTime(picked.hour, picked.minute), enabled);
  }

  Future<void> _saveBrief(WidgetRef ref, LocalTime time, bool enabled) async {
    final repo = ref.read(reminderRepoProvider);
    await repo.upsert(Reminder(
        id: _briefRowId, goalId: null, time: time, isEnabled: enabled));
    final s = await ref.read(settingsRepoProvider).get();
    await ref
        .read(settingsRepoProvider)
        .update(s.copyWith(dailyBriefTime: time));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

/// 备份卡（T045/T046，FR-015）：导出（Web 下载 / iOS 分享面板）、
/// 导入（校验 → 冲突弹窗"覆盖本地/取消" → 原子替换 → 摘要）。
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
    return Card(
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: Text(Copy.backupExport),
          subtitle: Text(Copy.dataRiskNote.split('。').first),
          onTap: _export,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: Text(Copy.backupImport),
          onTap: _import,
        ),
      ]),
    );
  }

  Future<void> _export() async {
    final now = DateTime.now();
    final json = await BackupExporter(ref.read(dbProvider))
        .exportString(now: now);
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

/// 数据风险与隐私说明卡（T048，FR-014）。
class _DataRiskCard extends StatelessWidget {
  const _DataRiskCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lock_outline),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(Copy.dataRiskTitle,
                      style: Theme.of(context).textTheme.titleSmall)),
            ]),
            const SizedBox(height: 6),
            Text(Copy.dataRiskNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// 通知权限卡（T034，FR-007）：被拒 → 全功能可用 + 开启指引，
/// 绝不自动重复弹权限（仅用户点击才请求）。
class _PermissionCard extends ConsumerStatefulWidget {
  const _PermissionCard();

  @override
  ConsumerState<_PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends ConsumerState<_PermissionCard> {
  Future<bool>? _grantedFuture;

  @override
  Widget build(BuildContext context) {
    // Web 模拟网关恒授权，不展示权限卡。
    if (kIsWeb) return const SizedBox.shrink();
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final acknowledged = settings.notificationDeniedAcknowledged;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<bool>(
          future: _grantedFuture ??
              ref.read(notificationGatewayProvider).isPermissionGranted,
          builder: (context, snap) {
            final granted = snap.data ?? false;
            if (granted) {
              return Row(children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(Copy.notifEnabled)),
              ]);
            }
            if (acknowledged) {
              return Row(children: [
                const Icon(Icons.notifications_off_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(Copy.notifDeniedTitle)),
              ]);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Copy.notifDeniedTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                const SizedBox(height: 4),
                Text(Copy.notifDeniedBody),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  FilledButton.tonal(
                    onPressed: _request,
                    child: Text(Copy.notifEnable),
                  ),
                  TextButton(
                    onPressed: () async {
                      final s = await ref.read(settingsRepoProvider).get();
                      await ref.read(settingsRepoProvider).update(s.copyWith(
                          notificationDeniedAcknowledged: true));
                    },
                    child: Text(Copy.notifAck),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _request() async {
    setState(() {
      _grantedFuture =
          ref.read(notificationGatewayProvider).requestPermission();
    });
    await _grantedFuture;
    if (mounted) setState(() {});
  }
}

class _GoalReminderTile extends ConsumerWidget {
  const _GoalReminderTile({required this.goal, this.reminder});

  final Goal goal;
  final Reminder? reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = reminder?.isEnabled ?? false;
    final time = reminder?.time ?? _defaultGoalTime;
    final color = GoalColor.byKey(goal.colorKey).of(context);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration:
            BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
        child: Icon(GoalIcon.byKey(goal.iconKey).icon, color: color, size: 20),
      ),
      title: Text(goal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: enabled
          ? Text(time.isoString,
              style: const TextStyle(fontWeight: FontWeight.w600))
          : null,
      trailing: Switch(
        value: enabled,
        onChanged: (v) => _save(ref, time, v),
      ),
      onTap: enabled
          ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: time.hour, minute: time.minute),
              );
              if (picked != null) {
                await _save(ref, LocalTime(picked.hour, picked.minute), true);
              }
            }
          : null,
    );
  }

  Future<void> _save(WidgetRef ref, LocalTime time, bool enabled) {
    return ref.read(reminderRepoProvider).upsert(Reminder(
          id: 'goal-${goal.id}',
          goalId: goal.id,
          time: time,
          isEnabled: enabled,
        ));
  }
}
