/// go_router 路由表（003 三 Tab 收敛，ui-contract.md：主栈 Today / Review / Mine；
/// Editor 与 GoalDetail 为 today 分支子页——底部胶囊全程可见可点（FR-010，
/// research D5）；深链 target://today|review|goal/{id}，goal 无 id 兜底 /today）。
///
/// 导航壳层按今日屏 R7 定稿（screen-today.html）：底部白色悬浮全圆角胶囊条，
/// 三页签（今日/回顾/我的），选中 = 墨色胶囊内图标上文字下；
/// 壳层画四段底幕渐变，今日页透明叠在其上。
///
/// /goals 页签与路由退役（目标页职能并入今日卡与详情，T015/T016）——
/// 存量入口（今日页旧「查看全部」、书签深链）经 redirect 落 /today。
///
/// Provider 形式：每个 ProviderScope（测试/应用）独立实例，避免跨用例状态残留。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/copy.dart';
import '../features/goals/goal_detail.dart';
import '../features/goals/goal_editor.dart';
import '../features/goals/goal_templates.dart';
import '../features/goals/onboarding.dart';
import '../features/settings/settings_view.dart';
import '../features/review/review_view.dart';
import '../features/today/today_view.dart';
import 'design_tokens.dart';

final routerProvider = Provider<GoRouter>((ref) => _build());

GoRouter _build() => GoRouter(
      initialLocation: '/today',
      // /goals 退役兜底：任何存量入口改落今日页（目标浏览即卡片列表）。
      redirect: (context, state) =>
          state.uri.path == '/goals' ? '/today' : null,
      routes: [
        GoRoute(
            path: '/onboarding', builder: (_, _) => const OnboardingPage()),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => _AppShell(navigationShell: shell),
          branches: [
            // today 分支：今日页 + 编辑器/详情子页（D5：挂分支内而非根路由，
            // 进入创建/详情动线时导航壳层不退场，FR-010 根因修复）。
            StatefulShellBranch(routes: [
              GoRoute(path: '/today', builder: (_, _) => const TodayView()),
              GoRoute(
                  path: '/goal-editor',
                  builder: (_, s) => GoalEditorPage(
                      goalId: s.uri.queryParameters['id'],
                      template: s.extra is GoalTemplate
                          ? s.extra as GoalTemplate
                          : null)),
              // 统一目标详情（T018：里程碑视图并入；步骤/倒计时/达成在此管理）。
              GoRoute(
                  path: '/goal/:id',
                  builder: (_, s) =>
                      GoalDetailPage(goalId: s.pathParameters['id']!)),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/review', builder: (_, _) => const ReviewView()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/settings',
                  builder: (_, _) => const SettingsView()),
            ]),
          ],
        ),
      ],
    );

/// 导航壳层：底幕渐变画布 + 底部胶囊导航（今日屏 R4 定稿几何）。
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Scaffold(
      body: DecoratedBox(
        // 四段粉紫底幕（浅）/ 暗紫（深），135deg 左上→右下。
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.bgGrad,
          ),
        ),
        child: navigationShell,
      ),
      bottomNavigationBar: _PillNav(shell: navigationShell),
    );
  }
}

/// 底部导航页签描述。
class _NavDest {
  const _NavDest(this.location, this.label, this.icon, this.activeIcon);

  final String location;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _navDests = [
  _NavDest('/today', Copy.todayNav, Icons.home_outlined, Icons.home_rounded),
  _NavDest('/review', Copy.reviewNav, Icons.insights_outlined, Icons.insights),
  _NavDest('/settings', Copy.mineNav, Icons.person_outline, Icons.person),
];

/// 悬浮全圆角胶囊导航条：navwrap inset 与内容列对齐（space-6），
/// 条内 space-1 呼吸；等分槽位，选中胶囊变宽不推挤邻页签。
class _PillNav extends StatelessWidget {
  const _PillNav({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(AppSpace.s6, AppSpace.s2, AppSpace.s6, 0),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s1),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.rFull,
            boxShadow: palette.shadowMid,
          ),
          child: Row(
            children: [
              for (final (i, dest) in _navDests.indexed)
                Expanded(
                  child: _NavTab(
                    dest: dest,
                    selected: shell.currentIndex == i,
                    onTap: () => shell.goBranch(i,
                        initialLocation: shell.currentIndex == i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  final _NavDest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final labelStyle = Theme.of(context).textTheme.labelS;
    final icon = Icon(selected ? dest.activeIcon : dest.icon,
        size: 20, color: selected ? palette.accentOn : palette.onSurfaceVariant);

    Widget content;
    if (selected) {
      // 选中胶囊：墨色实心，图标上文字下。
      content = Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s4, vertical: AppSpace.s1),
        decoration: BoxDecoration(
          color: palette.accent,
          borderRadius: AppRadius.rFull,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(dest.label,
                style: labelStyle.copyWith(color: palette.accentOn)),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(dest.label, style: labelStyle),
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: dest.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rFull,
        // 不用 Center 包裹：底部导航槽高度无上界，Center 会取
        // constraints.biggest 撑到无穷高（Column 本身已居中且按内容收缩）。
        child: content,
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
      // 小组件侧 widgetURL 形如 target://goal/{id}（host=goal，首段即 id）；
      // query id 仅作兜底；两处皆无 → 落今日（003 T015：原 '/goals' 退役）。
      // 注：旧判定 pathSegments.length > 1 对 host 式恒假，goal 卡深链
      // 从未真正命中 id 分支——本次随 /goals 兜底一并修正。
      final id = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : uri.queryParameters['id'];
      return (id == null || id.isEmpty) ? '/today' : '/goal/$id';
    default:
      return null;
  }
}
