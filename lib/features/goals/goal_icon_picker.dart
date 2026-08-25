library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/goal_icon_catalog.dart';

Future<GoalIconCatalog?> showGoalIconPicker(
  BuildContext context, {
  required String selectedKey,
}) {
  final palette = TargetPalette.of(context);
  return showModalBottomSheet<GoalIconCatalog>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // 编辑器为壳层分支页：弹层止于 dock 之上。
    useRootNavigator: false,
    backgroundColor: Colors.transparent,
    barrierColor: palette.scrim,
    builder: (_) => _GoalIconPicker(selectedKey: selectedKey),
  );
}

class _GoalIconPicker extends StatelessWidget {
  const _GoalIconPicker({required this.selectedKey});

  final String selectedKey;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .55,
      maxChildSize: .94,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: palette.shadowHigh,
        ),
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '选择目标图标',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: '关闭',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            for (final domain in GoalIconDomain.values) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: MajorColors.byKey(domain.major.name)
                              .of(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(domain.zhLabel, style: theme.textTheme.titleSmall),
                      const SizedBox(width: 8),
                      Text(
                        domain.major.zhLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .92,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final icon = GoalIconCatalog.byDomain[domain]![index];
                    final selected = icon.key == selectedKey;
                    final label = goalIconLabel(icon);
                    return Semantics(
                      label: '$label，${domain.zhLabel}分类',
                      selected: selected,
                      button: true,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(icon),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.accent.withValues(alpha: .10)
                                : palette.surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? palette.accent
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon.icon,
                                color: selected
                                    ? palette.accent
                                    : palette.onSurface,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: GoalIconCatalog.byDomain[domain]!.length),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

String goalIconLabel(GoalIconCatalog icon) => switch (icon) {
  GoalIconCatalog.directionsBike => '骑行',
  GoalIconCatalog.directionsRun => '跑步',
  GoalIconCatalog.pool => '游泳',
  GoalIconCatalog.hiking => '徒步',
  GoalIconCatalog.fitnessCenter => '力量训练',
  GoalIconCatalog.menuBook => '阅读',
  GoalIconCatalog.school => '学习',
  GoalIconCatalog.translate => '语言',
  GoalIconCatalog.autoStories => '课程',
  GoalIconCatalog.favorite => '健康',
  GoalIconCatalog.monitorHeart => '心率',
  GoalIconCatalog.bedtime => '睡眠',
  GoalIconCatalog.waterDrop => '饮水',
  GoalIconCatalog.brush => '绘画',
  GoalIconCatalog.camera => '摄影',
  GoalIconCatalog.palette => '创作',
  GoalIconCatalog.musicNote => '音乐',
  GoalIconCatalog.flight => '飞行',
  GoalIconCatalog.luggage => '旅行',
  GoalIconCatalog.map => '地图',
  GoalIconCatalog.cabin => '度假',
  GoalIconCatalog.explore => '探索',
  GoalIconCatalog.savings => '储蓄',
  GoalIconCatalog.trendingUp => '增长',
  GoalIconCatalog.accountBalanceWallet => '预算',
  GoalIconCatalog.paid => '收入',
  GoalIconCatalog.home => '居家',
  GoalIconCatalog.restaurant => '饮食',
  GoalIconCatalog.cleaningServices => '清洁',
  GoalIconCatalog.eco => '生活方式',
  GoalIconCatalog.selfImprovement => '冥想',
  GoalIconCatalog.spa => '放松',
  GoalIconCatalog.air => '呼吸',
  GoalIconCatalog.forest => '自然',
  GoalIconCatalog.groups => '家人与朋友',
  GoalIconCatalog.volunteerActivism => '公益',
  GoalIconCatalog.forum => '交流',
  GoalIconCatalog.pets => '宠物',
};
