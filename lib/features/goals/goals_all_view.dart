/// GoalsAllPage · 全部目标（004 T022 过渡页）。
///
/// 「查看全部」入口先落地可达（今日页关注卡轮播 → /goals-all），
/// 本页为最简可达形态：大标题 + 全量目标行（tap → 详情）。T023 按
/// v2-goals-all.html 冻结稿全量实现：全部 + 十小类单选筛选、筛选
/// 空态、编辑/暂停恢复/删除全动线。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';

class GoalsAllPage extends ConsumerWidget {
  const GoalsAllPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final goalsAsync = ref.watch(goalsProvider);
    final goals = goalsAsync.value ?? const <Goal>[];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(Copy.goalsAllTitle),
      ),
      body: SafeArea(
        bottom: false,
        child: goalsAsync.hasValue && goals.isEmpty
            ? Center(
                child: Text(
                  Copy.todayEmptyTitle,
                  style: Theme.of(context).textTheme.bodyL
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppScreen.padX,
                  0,
                  AppScreen.padX,
                  AppSpace.s6,
                ),
                itemCount: goals.length,
                itemBuilder: (context, i) {
                  final goal = goals[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s3),
                    child: Material(
                      color: palette.glassCard,
                      borderRadius: AppRadius.rLg,
                      child: InkWell(
                        // 004 T022：行挂 key，T023 换装冻结稿前的测试锚点。
                        key: ValueKey('goalsAllRow-${goal.id}'),
                        onTap: () => context.push('/goal/${goal.id}'),
                        borderRadius: AppRadius.rLg,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.s4),
                          child: Row(
                            children: [
                              Icon(
                                GoalIconCatalog.byKey(goal.iconKey).icon,
                                size: 22,
                                color: palette.onSurface,
                              ),
                              const SizedBox(width: AppSpace.s3),
                              Expanded(
                                child: Text(
                                  goal.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleS,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
