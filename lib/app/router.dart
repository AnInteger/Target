/// go_router 路由表（ui-contract.md：主栈 Today → Goals → Editor/Milestone；
/// Review/Busy/Settings 模态；深链 target://today|review|goal/{id}，research D14）。
///
/// Provider 形式：每个 ProviderScope（测试/应用）独立实例，避免跨用例状态残留。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/copy.dart';
import '../features/goals/goal_editor.dart';
import '../features/goals/goal_templates.dart';
import '../features/goals/goals_view.dart';
import '../features/goals/onboarding.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) => _build());

GoRouter _build() => GoRouter(
  initialLocation: '/today',
  routes: [
    GoRoute(
        path: '/onboarding', builder: (_, _) => const OnboardingPage()),
    GoRoute(path: '/today', builder: (_, _) => const _TodayPlaceholder()),
    GoRoute(path: '/goals', builder: (_, _) => const GoalsView()),
    GoRoute(
        path: '/goal-editor',
        builder: (_, s) => GoalEditorPage(
            goalId: s.uri.queryParameters['id'],
            template: s.extra is GoalTemplate ? s.extra as GoalTemplate : null)),
    GoRoute(
        path: '/milestone/:id',
        builder: (_, s) => _Placeholder('里程碑 ${s.pathParameters['id']}')),
    GoRoute(
        path: '/review', builder: (_, _) => const _Placeholder(Copy.reviewTitle)),
    GoRoute(path: '/busy', builder: (_, _) => const _Placeholder(Copy.busyTitle)),
    GoRoute(
        path: '/settings',
        builder: (_, _) => const _Placeholder(Copy.settingsTitle)),
  ],
);

/// 今日占位（T014/T015 骨架）：订阅 Settings 流——真实打开 drift
/// WasmDatabase/IndexedDB，页面呈现"每日概要时间"即持久化基座工作的证据。
class _TodayPlaceholder extends ConsumerWidget {
  const _TodayPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.appName)),
      body: Center(
        child: settings.hasValue
            ? Text(
                '${Copy.dailyBriefTimeLabel} ${settings.value!.dailyBriefTime}',
                style: Theme.of(context).textTheme.headlineSmall)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// 深链 target:// → 内部路由。
String? mapDeepLink(Uri uri) {
  switch (uri.host.isEmpty ? uri.path : uri.host) {
    case 'today':
      return '/today';
    case 'review':
      return '/review';
    case 'goal':
      final id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : uri.queryParameters['id'];
      return id == null ? '/goals' : '/milestone/$id';
    default:
      return null;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
      );
}
