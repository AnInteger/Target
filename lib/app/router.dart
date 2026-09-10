/// v3 路由（006 IA）：/goals 默认 + /activity 分支 + push 详情/里程碑/
/// 编辑器/设置；旧路由 redirect 兜底；深链 target:// 同步。
/// v3.1：转场改 CupertinoPage（iOS 右进左出）。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/activity_view.dart';
import '../features/goals/goal_detail.dart';
import '../features/goals/goal_editor.dart';
import '../features/goals/goals_view.dart';
import '../features/settings/settings_view.dart';
import '../features/settings/widget_preview.dart';
import 'app.dart';

final routerProvider = Provider<GoRouter>((ref) => _build());

GoRouter _build() => GoRouter(
  initialLocation: '/goals',
  redirect: (context, state) => switch (state.uri.path) {
    '/today' ||
    '/review' ||
    '/progress' ||
    '/onboarding' ||
    '/profile' ||
    '/goals-all' => '/goals',
    _ => null,
  },
  routes: [
    GoRoute(
      path: '/goal-editor',
      pageBuilder: (context, state) => _cupertinoPush(
        state,
        GoalEditorPage(goalId: state.uri.queryParameters['id']),
      ),
    ),
    GoRoute(
      path: '/goal/:id',
      pageBuilder: (context, state) => _cupertinoPush(
        state,
        GoalDetailPage(goalId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _cupertinoPush(state, const SettingsView()),
    ),
    // 小组件设计预览（R13）：真机装机前在 Web 查看四种家族的渲染。
    GoRoute(
      path: '/widget-preview',
      pageBuilder: (context, state) =>
          _cupertinoPush(state, const WidgetPreviewPage()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/goals', builder: (_, _) => const GoalsView()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/activity', builder: (_, _) => const ActivityView()),
          ],
        ),
      ],
    ),
  ],
);

CupertinoPage<void> _cupertinoPush(GoRouterState state, Widget child) {
  return CupertinoPage<void>(key: state.pageKey, child: child);
}

/// target:// 深链 → 路由（goal 无 id 兜底 /goals）。
String? mapDeepLink(Uri uri) {
  switch (uri.host) {
    case 'goals':
    case 'today':
      return '/goals';
    case 'activity':
    case 'review':
    case 'progress':
      return '/activity';
    case 'record':
      return '/goals'; // 记录 sheet 由壳层记录钮承接（AppShell 监听）。
    case 'goal':
      final id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
      return id == null || id.isEmpty ? '/goals' : '/goal/$id';
  }
  return null;
}
