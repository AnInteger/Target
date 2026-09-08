/// v3 设置页（与我的合并，R2 定稿入口=动态页头部）：
/// 资料卡 / 外观三档 / 提醒总开关 / 备份与数据 / 关于 / 冲突确认。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import 'dart:convert';

import '../../core/backup/backup_exporter.dart';
import '../../core/backup/backup_importer.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider).value ??
        const AppSettings();

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  _circleBtn(context, Icons.chevron_left,
                      () => Navigator.of(context).pop()),
                  Expanded(
                    child: Center(
                        child: Text(Copy.settingsTitle, style: text.titleM)),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  // ---- 资料卡 ----
                  Material(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: () => _editProfile(context, ref, settings),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.s4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          boxShadow: p.shadowLow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFAF52DE),
                                    Color(0xFFFF2D55),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (settings.nickname == null ||
                                          settings.nickname!.isEmpty)
                                      ? '我'
                                      : settings.nickname!.characters.first,
                                  style: text.titleL
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.nickname == null ||
                                            settings.nickname!.isEmpty
                                        ? '我'
                                        : settings.nickname!,
                                    style: text.titleM,
                                  ),
                                  Text(
                                    Copy.editProfileHint,
                                    style: text.bodyS.copyWith(
                                        color: p.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 14,
                                color: p.onSurfaceTertiary
                                    .withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _groupLabel(context, Copy.appearanceGroup),
                  _card(
                    context,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 13, 16, 13),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                              value: 'system', label: Text(Copy.themeSystem)),
                          ButtonSegment(
                              value: 'light', label: Text(Copy.themeLight)),
                          ButtonSegment(
                              value: 'dark', label: Text(Copy.themeDark)),
                        ],
                        selected: {settings.themeMode ?? 'system'},
                        onSelectionChanged: (s) => ref
                            .read(settingsRepoProvider)
                            .update(settings.copyWith(
                                themeMode: s.first == 'system'
                                    ? null
                                    : s.first)),
                      ),
                    ),
                  ),
                  _groupLabel(context, Copy.reminderGroupSettings),
                  _card(
                    context,
                    child: Column(
                      children: [
                        _row(
                          context,
                          icon: Icons.notifications_outlined,
                          label: Copy.reminderPush,
                          trailWidget: Switch(
                            value: settings.remindersEnabled,
                            onChanged: (v) => ref
                                .read(settingsRepoProvider)
                                .update(
                                    settings.copyWith(remindersEnabled: v)),
                          ),
                        ),
                        Divider(height: 1, color: p.divider),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Copy.reminderPerGoalHint,
                              style: text.bodyM.copyWith(
                                  color: p.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _groupLabel(context, Copy.backupGroup),
                  _card(
                    context,
                    child: Column(
                      children: [
                        _row(
                          context,
                          icon: Icons.upload_outlined,
                          label: Copy.backupExport,
                          onTap: () => _export(context, ref),
                        ),
                        Divider(height: 1, color: p.divider),
                        _row(
                          context,
                          icon: Icons.download_outlined,
                          label: Copy.backupImport,
                          onTap: () => _import(context, ref),
                        ),
                      ],
                    ),
                  ),
                  _groupLabel(context, Copy.aboutGroup),
                  _card(
                    context,
                    child: _row(
                      context,
                      label: Copy.versionRow,
                      trailWidget: Text(
                        '3.0.0',
                        style: text.bodyM
                            .copyWith(color: p.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      Copy.settingsFoot,
                      style: text.bodyS
                          .copyWith(color: p.onSurfaceTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 组件 ----

  Widget _circleBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final p = TargetPalette.of(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: p.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 14, color: p.onSurface),
        ),
      ),
    );
  }

  Widget _groupLabel(BuildContext context, String s) {
    final p = TargetPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        s,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: p.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final p = TargetPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: p.shadowLow,
      ),
      child: child,
    );
  }

  Widget _row(
    BuildContext context, {
    IconData? icon,
    required String label,
    Widget? trailWidget,
    VoidCallback? onTap,
  }) {
    final p = TargetPalette.of(context);
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: p.onSurface),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(label, style: text.bodyL)),
            ?trailWidget,
          ],
        ),
      ),
    );
  }

  // ---- 动作 ----

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final controller =
        TextEditingController(text: settings.nickname ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Copy.editProfileHint),
        content: TextField(
          controller: controller,
          maxLength: 12,
          decoration: const InputDecoration(hintText: '昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(Copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(Copy.save),
          ),
        ],
      ),
    );
    if (saved == true) {
      await ref
          .read(settingsRepoProvider)
          .update(settings.copyWith(nickname: controller.text.trim()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(Copy.profileSavedToast)));
      }
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final exporter = BackupExporter(db);
    final content = await exporter.exportString();
    final name = backupFileName(DateTime.now());
    await ref.read(shareGatewayProvider).shareText(content);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导出 $name')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await ref.read(filePickGatewayProvider).pickBackupFile();
    if (picked == null) return;
    try {
      final content = utf8.decode(picked.bytes);
      if (!context.mounted) return;
      // 先确认（覆盖式恢复，不可撤销），再执行导入。
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(Copy.restoreConfirmTitle),
          content: const Text(
            '当前设备数据将被备份内容覆盖，此操作不可撤销。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(Copy.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(Copy.restoreOverwrite),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      final db = ref.read(dbProvider);
      final summary = await BackupImporter(db).importString(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '已恢复 ${summary.goals} 个目标 / ${summary.records} 条记录'),
          ),
        );
      }
    } on BackupFormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
