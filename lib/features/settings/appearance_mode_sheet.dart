import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

Future<void> showAppearanceModeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AppearanceModeSheet(),
  );
}

String appearanceModeLabel(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => Copy.settingsThemeSystem,
  AppThemeMode.light => Copy.settingsThemeLight,
  AppThemeMode.dark => Copy.settingsThemeDark,
};

class _AppearanceModeSheet extends ConsumerWidget {
  const _AppearanceModeSheet();

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode mode,
  ) async {
    final repo = ref.read(settingsRepoProvider);
    final settings = await repo.get();
    await repo.update(settings.copyWith(themeMode: mode));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final selected =
        ref.watch(settingsProvider).value?.themeMode ?? AppThemeMode.system;
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('appearanceModeSheet'),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s3,
          AppSpace.s5,
          AppSpace.s5,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
          boxShadow: palette.shadowHigh,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpace.s4),
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: AppRadius.rFull,
                ),
              ),
            ),
            Text('外观', style: Theme.of(context).textTheme.titleM),
            const SizedBox(height: AppSpace.s2),
            Text(
              '选择应用的明暗显示方式',
              style: Theme.of(context).textTheme.bodyS
                  .copyWith(color: palette.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpace.s3),
            _ModeRow(
              key: const ValueKey('themeSystem'),
              icon: Icons.brightness_auto_outlined,
              label: Copy.settingsThemeSystem,
              selected: selected == AppThemeMode.system,
              onTap: () => _select(context, ref, AppThemeMode.system),
            ),
            _ModeRow(
              key: const ValueKey('themeLight'),
              icon: Icons.light_mode_outlined,
              label: Copy.settingsThemeLight,
              selected: selected == AppThemeMode.light,
              onTap: () => _select(context, ref, AppThemeMode.light),
            ),
            _ModeRow(
              key: const ValueKey('themeDark'),
              icon: Icons.dark_mode_outlined,
              label: Copy.settingsThemeDark,
              selected: selected == AppThemeMode.dark,
              onTap: () => _select(context, ref, AppThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Material(
      color: selected ? palette.surfaceAlt : Colors.transparent,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s3,
            vertical: AppSpace.s3,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: palette.onSurfaceVariant),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.bodyL),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? palette.accent : palette.divider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
