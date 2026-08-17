/// 首启引导（T022，SC-001）：模板引导创建第一个目标。
///
/// 触发条件在 app 层（settings.onboardingCompleted == false 且无目标）；
/// 选模板 → GoalEditor 预填；"先随便看看"或建完目标即视为完成（落库，
/// 下次启动不再打扰）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
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

  Future<void> _pick(GoalTemplate t) async {
    await context.push('/goal-editor', extra: t);
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(Copy.onboardingTitle, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(Copy.onboardingSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    for (final t in kHabitTemplates)
                      _TemplateTile(template: t, onTap: () => _pick(t)),
                  ],
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(Copy.onboardingSkip),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                // 数据风险首启明示（FR-014）：本地存储、不上传。
                child: Text(Copy.onboardingDataNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.onTap});

  final GoalTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = GoalColor.byKey(template.colorKey).of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(GoalIcon.byKey(template.iconKey).icon,
                color: color, size: 32),
            const SizedBox(height: 8),
            Text(template.name, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
