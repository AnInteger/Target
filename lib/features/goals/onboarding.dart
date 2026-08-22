/// 首启引导（SC-001 · 002 T018 跟随新语言）：从一句熟悉的话开始。
///
/// 触发条件在 app 层（settings.onboardingCompleted == false 且无目标）；
/// 模板一句话 chip → GoalEditor 预填（编辑器内还有一行「从一句熟悉的话开始」）；
/// 「写一句自己的」空草稿直入编辑器；"先随便看看"或建完即视为完成。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/goal_icon_catalog.dart';
import 'goal_templates.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  Future<void> _complete() async {
    final repo = ref.read(settingsRepoProvider);
    final s = await repo.get();
    await repo.update(s.copyWith(onboardingCompleted: true));
  }

  Future<void> _skip() async {
    await _complete();
    if (!mounted) return;
    context.go('/today');
  }

  /// 模板或空草稿 → 统一编辑器；返回即视为完成引导。
  Future<void> _start({GoalTemplate? template}) async {
    if (template == null) {
      await context.push('/goal-editor');
    } else {
      await context.push('/goal-editor', extra: template);
    }
    if (mounted) {
      await _complete();
      if (mounted) context.go('/today');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Text(Copy.onboardingTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(Copy.onboardingSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            // 数据风险首启明示（FR-014）：本地存储、不上传。
            Text(Copy.onboardingDataNote,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            // 与编辑器同一语言：v3 图标 + 一句话（无颜色步，FR-015）。
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in kAllTemplates)
                  ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor:
                          TargetPalette.of(context).surfaceAlt,
                      radius: 10,
                      child: Icon(GoalIconCatalog.byKey(t.iconKey).icon,
                          size: 12,
                          color: TargetPalette.of(context).onSurfaceVariant),
                    ),
                    label: Text(t.name),
                    onPressed: () => _start(template: t),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => _start(),
              child: const Text(Copy.goalsEmptyOwn),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _skip,
                child: const Text(Copy.onboardingSkip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
