import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/page_top_bar.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import 'profile.dart';

class ProfileHubPage extends ConsumerWidget {
  const ProfileHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value;
    final steps = ref.watch(allStepsProvider).value;
    final profile = ref.watch(profileProvider).value;
    final today = ref.watch(todayProvider);
    final palette = TargetPalette.of(context);

    if (goals == null || steps == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final active = goals.where((g) => g.isActive).length;
    final archived = goals.where((g) => g.isArchived).length;
    final monthDone = steps.where((step) {
      final at = step.doneAt?.toLocal();
      return step.isDone &&
          at != null &&
          at.year == today.year &&
          at.month == today.month;
    }).length;

    return Scaffold(
      key: const ValueKey('profileHub'),
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTopBar(
              title: Copy.profileTitle,
              titleKey: const ValueKey('profileTitle'),
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s4,
                  AppSpace.s2,
                  AppSpace.s4,
                  AppSpace.s8,
                ),
                children: [
                  _ProfileCard(profile: profile),
                  const SizedBox(height: AppSpace.s4),
                  _GoalSummary(
                    active: active,
                    monthDone: monthDone,
                    archived: archived,
                  ),
                  const _SectionLabel('目标'),
                  _HubGroup(
                    children: [
                      _HubRow(
                        key: const ValueKey('profileGoalManagement'),
                        icon: Icons.flag_outlined,
                        title: '目标管理',
                        subtitle: '查看、筛选与维护所有目标',
                        onTap: () => context.push('/goals-all'),
                      ),
                      _HubRow(
                        icon: Icons.add_circle_outline,
                        title: '新建目标',
                        subtitle: '从目标名称和第一步开始',
                        onTap: () => context.push('/goal-editor'),
                      ),
                    ],
                  ),
                  const _SectionLabel('通用'),
                  _HubGroup(
                    children: [
                      _HubRow(
                        key: const ValueKey('profileSettings'),
                        icon: Icons.settings_outlined,
                        title: '设置',
                        subtitle: '外观、通知、数据与关于',
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Material(
      color: palette.surface,
      borderRadius: AppRadius.rXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showProfileSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Row(
            children: [
              ProfileAvatar(profile: profile, size: 58),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileNicknameOf(profile),
                      style: Theme.of(context).textTheme.titleM,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '编辑个人资料',
                      style: Theme.of(context).textTheme.bodyS
                          .copyWith(color: palette.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({
    required this.active,
    required this.monthDone,
    required this.archived,
  });

  final int active;
  final int monthDone;
  final int archived;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(value: active, label: '进行中'),
        ),
        const SizedBox(width: AppSpace.s2),
        Expanded(
          child: _Metric(value: monthDone, label: '本月完成'),
        ),
        const SizedBox(width: AppSpace.s2),
        Expanded(
          child: _Metric(value: archived, label: '已归档'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleL),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelS
                .copyWith(color: palette.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s3,
        AppSpace.s5,
        AppSpace.s3,
        AppSpace.s2,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelS.copyWith(
          color: TargetPalette.of(context).onSurfaceVariant,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _HubGroup extends StatelessWidget {
  const _HubGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Material(
      color: palette.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0)
              Divider(height: 1, thickness: 1, color: palette.divider),
            child,
          ],
        ],
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s3,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.rMd,
              ),
              child: Icon(icon, size: 20, color: palette.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyL),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyS
                        .copyWith(color: palette.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: palette.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
