/// 设置页（US5 · T026 R2 重写 · 2026-08-21 screen-settings.html 定稿）。
///
/// R2 裁决「聚焦 App 本身」：身份卡（无目标统计）+ 提醒组（概要一行 +
/// 场景指引两条——逐目标提醒行全删，目标提醒时刻在编辑器选场景）+
/// 备份与数据（导出/导入，导入冲突显式确认）+ 隐私脚注。
/// 权限被拒不反复弹窗（FR-007）：未开启只说明一次，「知道了」后不再打扰。
library;

import 'dart:convert';
import 'dart:math' as math;

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

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  /// 通知权限态（null = 还没查到）；只在 iOS 实机上存在，Web 恒视为已授权。
  bool? _granted;

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

    final briefRow = reminders.where((r) => r.isDailyBrief).firstOrNull;
    final briefTime =
        briefRow?.time ?? settings?.dailyBriefTime ?? const LocalTime(8, 0);
    final briefEnabled = briefRow?.isEnabled ?? true;

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
              AppSpace.s6, AppSpace.s2, AppSpace.s6, AppSpace.s12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s1, vertical: AppSpace.s2),
              child: Text(Copy.settingsTitle,
                  style: Theme.of(context).textTheme.displayS),
            ),
            const _MeCard(),
            const _SectionLabel(Copy.dailyBriefTimeLabel),
            if (permCardVisible) _PermCard(onRequest: _requestPermission),
            _GroupCard(children: [
              _SettingsRow(
                icon: Icons.notifications_outlined,
                title: Copy.dailyBriefTitle,
                sub: Copy.dailyBriefSub,
                time: briefTime,
                switchValue: briefEnabled,
                onSwitch: (v) => _saveBrief(ref, briefTime, v),
                onTap: () =>
                    _pickBriefTime(context, briefTime, briefEnabled),
              ),
            ]),
            _Hints(hints: permCardVisible
                ? const [Copy.notifOffHint]
                : const [Copy.reminderMondayHint, Copy.reminderGoalHint]),
            const _SectionLabel(Copy.backupHeader),
            const _BackupCard(),
            const SizedBox(height: AppSpace.s2),
            const _PrivacyFoot(),
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

  Future<void> _pickBriefTime(
      BuildContext context, LocalTime current, bool enabled) async {
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

/// 身份卡：44 头像（装饰渐变）+ 名字；R2 裁决不带目标统计。
class _MeCard extends StatelessWidget {
  const _MeCard();

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
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
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAvatarGradA, kAvatarGradB],
              ),
            ),
            child: Center(
              child: Text(
                Copy.settingsMeName.characters.first,
                style: Theme.of(context)
                    .textTheme
                    .titleS
                    .copyWith(color: Colors.white, height: 1),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          Text(Copy.settingsMeName, style: Theme.of(context).textTheme.titleS),
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

/// 通用设置行：32 图标格 + 标题/副文 + 时间 + 开关。
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.sub,
    this.time,
    this.switchValue,
    this.onSwitch,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final LocalTime? time;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;
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
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: Theme.of(context)
                        .textTheme
                        .bodyS
                        .copyWith(color: palette.onSurfaceVariant),
                  ),
                ],
              ),
            ),
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

/// 隐私脚注：虚线卡 + 锁图标。
class _PrivacyFoot extends StatelessWidget {
  const _PrivacyFoot();

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
          color: palette.divider, radius: AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s4, vertical: AppSpace.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.lock_outline,
                  size: 14, color: palette.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpace.s2),
            Expanded(
              child: Text(
                Copy.privacyFoot,
                style: Theme.of(context)
                    .textTheme
                    .bodyS
                    .copyWith(color: palette.onSurfaceVariant, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 虚线圆角容器描边（与各屏空态同一语言）。
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
