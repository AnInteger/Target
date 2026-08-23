/// go_router 路由表（004 T024 两分支改造：主栈 Today / Review 两分支，
/// ui-contract v2——我的页不再是页签，改根级全屏 push 子路由（今日页
/// 头像入口 push 进出，壳层 dock 被覆盖）；Editor / GoalDetail /
/// GoalsAll 仍为 today 分支子页——底部导航全程可见可点（FR-010，
/// research D5）；深链 target://today|review|goal/{id}，goal 无 id 兜底
/// /today）。
///
/// 导航壳层按 v2-today 冻结稿（004 T025 重做，R3 裁决 D2「黑色线条」）：
/// 底部全宽 dock = 今日 | 中央凸起圆形＋ | 回顾，当前页签黑字加粗 +
/// 16×3 短横线、FAB 中性墨面；壳层画四段底幕渐变，今日页透明叠在其上。
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
import '../features/goals/goals_all_view.dart';
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
  redirect: (context, state) => state.uri.path == '/goals' ? '/today' : null,
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
    // 我的页（004 T024）：根级全屏 push 子路由——壳层 dock 被覆盖，
    // 今日页头像 push 进 / pop 回（不再是页签分支）。
    GoRoute(path: '/settings', builder: (_, _) => const SettingsView()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => _AppShell(navigationShell: shell),
      branches: [
        // today 分支：今日页 + 编辑器/详情/全部目标子页（D5：挂分支内
        // 而非根路由，进入创建/详情动线时导航壳层不退场，FR-010 根因修复）。
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/today', builder: (_, _) => const TodayView()),
            GoRoute(
              path: '/goal-editor',
              builder: (_, s) => GoalEditorPage(
                goalId: s.uri.queryParameters['id'],
                template: s.extra is GoalTemplate
                    ? s.extra as GoalTemplate
                    : null,
              ),
            ),
            // 统一目标详情（T018：里程碑视图并入；步骤/倒计时/达成在此管理）。
            GoRoute(
              path: '/goal/:id',
              builder: (_, s) =>
                  GoalDetailPage(goalId: s.pathParameters['id']!),
            ),
            // 全部目标（T023 冻结稿全量换装：筛选/分组/长按管理）。
            GoRoute(
              path: '/goals-all',
              builder: (_, _) => const GoalsAllPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/review', builder: (_, _) => const ReviewView()),
          ],
        ),
      ],
    ),
  ],
);

/// 导航壳层：底幕渐变画布 + 底部 dock（004 T025 重做，D2 定稿几何）。
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
      bottomNavigationBar: _Dock(shell: navigationShell),
    );
  }
}

/// 底部导航页签描述。
class _NavDest {
  const _NavDest(this.location, this.label, this.glyph);

  final String location;
  final String label;
  final _DockGlyph glyph;
}

/// 页签字形（v2 冻结稿 dock 内嵌 SVG；今日为手绘点阵，非 Icons 字形）。
enum _DockGlyph { todayDots, cloudSnow }

const _navDests = [
  _NavDest('/today', Copy.todayNav, _DockGlyph.todayDots),
  _NavDest('/review', Copy.reviewNav, _DockGlyph.cloudSnow),
];

/// 底部 dock（004 T025 重做，v2-today 冻结稿 D2「黑色线条」定稿）：
/// 全宽近实卡底条（glass-card + 顶缘发丝线，.dock 84px · 顶 padding 8），
/// 今日 | 中央凸起圆形＋ | 回顾 三槽——两页签 Expanded 对称、FAB 恰在
/// 屏中线；当前页签 on-surface 加粗 + 标签下 16×3 短横线（深色自动
/// 反白，全条无彩色）；FAB 56px 中性（浅色墨底白＋/深色反白），上缘
/// 凸出底条 22px、带 glass-card 4px 描边环；任意壳层页恒定（FR-010）。
class _Dock extends StatelessWidget {
  const _Dock({required this.shell});

  final StatefulNavigationShell shell;

  /// FAB 上缘凸出量（冻结稿 .fab margin-top: -22px）。
  static const double _fabOverhang = 22;

  /// 底条高（冻结稿 .dock height: 84px）。
  static const double _barHeight = 84;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    Widget tab(int i) => Expanded(
      child: Padding(
        // 页签起于底条顶 padding 8 之后（22 + 8 = 30）。
        padding: const EdgeInsets.only(top: _fabOverhang + AppSpace.s2),
        child: _NavTab(
          dest: _navDests[i],
          selected: shell.currentIndex == i,
          onTap: () =>
              shell.goBranch(i, initialLocation: shell.currentIndex == i),
        ),
      ),
    );
    return SafeArea(
      top: false,
      child: SizedBox(
        // 高出底条的 22px = FAB 凸出带：视觉透明但占位命中（凸出部分
        // 的点击须落在 dock 自身区域而非 body，才能稳定命中 FAB）。
        height: _barHeight + _fabOverhang,
        child: Stack(
          children: [
            // 底条本体：近实卡底 + 顶缘发丝线（冻结稿 .dock）。
            Positioned(
              top: _fabOverhang,
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                key: const ValueKey('dockBar'),
                decoration: BoxDecoration(
                  color: palette.glassCard,
                  border: Border(top: BorderSide(color: palette.divider)),
                ),
              ),
            ),
            // 三槽行：FAB 起于 0（凸出 22），两页签起于 30。
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tab(0),
                  _DockFab(onTap: () => context.push('/goal-editor')),
                  tab(1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 中央凸起圆形＋（冻结稿 .fab）：56px 墨面圆 + glass-card 4px 描边环 +
/// 中层投影；直达 /goal-editor（SC-004 ≤1 交互）。Tooltip 沿用「新建目标」
/// ——今日页头部过渡＋退役（T025），测试动线无感迁移。
class _DockFab extends StatelessWidget {
  const _DockFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Tooltip(
      message: Copy.todayNewGoal,
      child: InkWell(
        key: const ValueKey('dockFab'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.onSurface,
            border: Border.all(color: palette.glassCard, width: 4),
            boxShadow: palette.shadowMid,
          ),
          child: Icon(Icons.add, size: 24, color: palette.surface),
        ),
      ),
    );
  }
}

/// 页签（冻结稿 .tab：88px 槽位列布局，图标 22 + 缝 3 + labelS；
/// D2 选中态 = on-surface 加粗 + 标签下 16×3 短横线，非选中弱化灰）。
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
    final color = selected ? palette.onSurface : palette.onSurfaceVariant;
    final Widget icon = switch (dest.glyph) {
      // 今日：手绘点阵字形（两列各三枚大点 + 中列上段两枚小点）。
      _DockGlyph.todayDots => CustomPaint(
        size: const Size.square(22),
        painter: _TodayGlyphPainter(color: color),
      ),
      // 回顾：云雪字形（Material Symbols cloudy_snowing 同源）。
      _DockGlyph.cloudSnow => Icon(
        Icons.cloudy_snowing,
        size: 22,
        color: color,
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: dest.label,
      child: InkWell(
        // 004 T020：今日页大标题与页签同文「今日」，测试以 key 定位页签。
        key: ValueKey('navTab-${dest.location}'),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(
              dest.label,
              style: Theme.of(context).textTheme.labelS.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : null,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 3),
              Container(
                key: ValueKey('navTabMark-${dest.location}'),
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: palette.onSurface,
                  borderRadius: AppRadius.rFull,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 今日页签点阵字形（v2 冻结稿 dock SVG 同形复刻）：960 画布，两列
/// （x 233/730）各三枚 r73 大点（y 153/480/807）+ 中列（x 480）上段
/// 两枚 r33 小点（y 226/387），绘制到 22px 槽。
class _TodayGlyphPainter extends CustomPainter {
  const _TodayGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 960;
    final paint = Paint()..color = color;
    void dot(double x, double y, double r) =>
        canvas.drawCircle(Offset(x * scale, y * scale), r * scale, paint);
    for (final x in [233.0, 730.0]) {
      for (final y in [153.0, 480.0, 807.0]) {
        dot(x, y, 73);
      }
    }
    dot(480, 226, 33);
    dot(480, 387, 33);
  }

  @override
  bool shouldRepaint(_TodayGlyphPainter old) => old.color != color;
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
