/// v3 设置页（与我的合并，R2 定稿入口=动态页头部）：
/// 资料卡 / 外观三档 / 提醒总开关 / 备份与数据 / 关于 / 冲突确认。
/// v3.1：Cupertino 组件重写——CupertinoListSection/ListTile 分组、
/// CupertinoSlidingSegmentedControl、CupertinoSwitch、
/// CupertinoAlertDialog、AppToast。
library;

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../app/toast.dart';
import '../../core/backup/backup_exporter.dart';
import '../../core/backup/backup_importer.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    final settings = ref.watch(settingsProvider).value ??
        const AppSettings();
    final mode = settings.themeMode ?? 'system';

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 16),
              child: Row(
                children: [
                  CircleIconButton(
                    size: 40,
                    iconSize: 14,
                    icon: CupertinoIcons.chevron_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
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
                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.s4),
                    onTap: () => _editProfile(context, ref, settings),
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
                                  .copyWith(color: CupertinoColors.white),
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
                        Icon(CupertinoIcons.chevron_forward,
                            size: 14,
                            color: p.onSurfaceTertiary
                                .withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                  _groupLabel(context, Copy.appearanceGroup),
                  _section(
                    context,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 13, 16, 13),
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: mode,
                        onValueChanged: (s) => ref
                            .read(settingsRepoProvider)
                            .update(settings.copyWith(
                                themeMode:
                                    s == 'system' ? null : s)),
                        children: {
                          'system': Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 2),
                            child: Text(Copy.themeSystem),
                          ),
                          'light': Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 2),
                            child: Text(Copy.themeLight),
                          ),
                          'dark': Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 2),
                            child: Text(Copy.themeDark),
                          ),
                        },
                      ),
                    ),
                  ),
                  _groupLabel(context, Copy.reminderGroupSettings),
                  _section(
                    context,
                    child: Column(
                      children: [
                        CupertinoListTile(
                          title: Text(Copy.reminderPush),
                          leading: Icon(CupertinoIcons.bell,
                              size: 20, color: p.onSurface),
                          trailing: CupertinoSwitch(
                            value: settings.remindersEnabled,
                            activeTrackColor: p.accent,
                            onChanged: (v) => ref
                                .read(settingsRepoProvider)
                                .update(
                                    settings.copyWith(remindersEnabled: v)),
                          ),
                          backgroundColor: p.surface,
                        ),
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
                  _section(
                    context,
                    child: Column(
                      children: [
                        CupertinoListTile(
                          title: Text(Copy.backupExport),
                          leading: Icon(CupertinoIcons.tray_arrow_up,
                              size: 20, color: p.onSurface),
                          backgroundColor: p.surface,
                          onTap: () => _export(context, ref),
                        ),
                        CupertinoListTile(
                          title: Text(Copy.backupImport),
                          leading: Icon(CupertinoIcons.tray_arrow_down,
                              size: 20, color: p.onSurface),
                          backgroundColor: p.surface,
                          onTap: () => _import(context, ref),
                        ),
                      ],
                    ),
                  ),
                  _groupLabel(context, Copy.aboutGroup),
                  _section(
                    context,
                    child: CupertinoListTile(
                      title: Text(Copy.versionRow),
                      additionalInfo: Text(
                        '3.0.0',
                        style: text.bodyM,
                      ),
                      backgroundColor: p.surface,
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

  Widget _section(BuildContext context, {required Widget child}) {
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

  // ---- 动作 ----

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final controller =
        TextEditingController(text: settings.nickname ?? '');
    final saved = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(Copy.editProfileHint),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            maxLength: 12,
            placeholder: '昵称',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(Copy.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(Copy.save),
          ),
        ],
      ),
    );
    if (saved == true) {
      await ref
          .read(settingsRepoProvider)
          .update(settings.copyWith(nickname: controller.text.trim()));
      if (context.mounted) {
        AppToast.show(context, Copy.profileSavedToast);
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
      AppToast.show(context, '已导出 $name');
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await ref.read(filePickGatewayProvider).pickBackupFile();
    if (picked == null) return;
    try {
      final content = utf8.decode(picked.bytes);
      if (!context.mounted) return;
      // 先确认（覆盖式恢复，不可撤销），再执行导入。
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(Copy.restoreConfirmTitle),
          content: const Text(
            '当前设备数据将被备份内容覆盖，此操作不可撤销。',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(Copy.cancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(Copy.restoreOverwrite),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      final db = ref.read(dbProvider);
      final summary = await BackupImporter(db).importString(content);
      if (context.mounted) {
        AppToast.show(
          context,
          '已恢复 ${summary.goals} 个目标 / ${summary.records} 条记录',
        );
      }
    } on BackupFormatException catch (e) {
      if (context.mounted) {
        AppToast.show(context, '$e');
      }
    }
  }
}
