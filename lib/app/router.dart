/// go_router 路由表：Today / Progress 两个壳层分支；我的、设置和全部目标
/// 走同一根级全屏 push，进入后隐藏 dock。深链支持
/// target://today|progress|goal/{id}，goal 无 id 兜底 /today。
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
import 'dock_glyphs.dart';
import '../features/goals/goal_detail.dart';
import '../features/goals/goal_editor.dart';
import '../features/goals/goals_all_view.dart';
import '../features/goals/goal_templates.dart';
import '../features/goals/onboarding.dart';
import '../features/profile/profile_hub.dart';
import '../features/progress/progress_view.dart';
import '../features/settings/settings_view.dart';
import '../features/today/today_view.dart';
import 'design_tokens.dart';

final routerProvider = Provider<GoRouter>((ref) => _build());

GoRouter _build() => GoRouter(
  initialLocation: '/today',
  // /goals 退役兜底：任何存量入口改落今日页（目标浏览即卡片列表）。
  redirect: (context, state) => state.uri.path == '/goals' ? '/today' : null,
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
    GoRoute(
      path: '/profile',
      pageBuilder: (_, state) =>
          buildRootPushPage(state, const ProfileHubPage()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (_, state) => buildRootPushPage(state, const SettingsView()),
    ),
    GoRoute(
      path: '/goals-all',
      pageBuilder: (_, state) => buildRootPushPage(state, const GoalsAllPage()),
    ),
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
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/progress', builder: (_, _) => const ProgressView()),
          ],
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> buildRootPushPage(
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  transitionDuration: AppMotion.base,
  reverseTransitionDuration: AppMotion.base,
  child: child,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeStandard,
      reverseCurve: AppMotion.easeStandard,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.08, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
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
        // 005 D4：分支切换 fade-through 包 shell（push 页不经此件）。
        child: _FadeThrough(
          index: navigationShell.currentIndex,
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: _Dock(shell: navigationShell),
    );
  }
}

/// 005 D4（FR-005/006）：分支切换 fade-through。go_router 的
/// StatefulShellRoute.indexedStack 无内建分支转场——本件以双段透明度
/// 近似：索引变即 base 250ms（AppMotion.base · easeStandard）前半
/// 1→0、后半 0→1，中点最暗帧回壳层底幕，旧新内容交换叠在亮度连续的
/// 渐暗渐亮上，视觉等效 fade-through 且无残影。不换子树 Key/不重建
/// 分支——「分支状态保留」语义零改动；dock 在 FadeTransition 外，
/// 快速连点 goBranch 照常、终态由 IndexedStack 决定（不错页）。
class _FadeThrough extends StatefulWidget {
  const _FadeThrough({required this.index, required this.child});

  /// 监听的分支索引（shell.currentIndex）——变化即触发一轮过渡。
  final int index;

  /// 过渡本体（navigationShell；同一子树身份，仅内部 IndexedStack 翻页）。
  final Widget child;

  @override
  State<_FadeThrough> createState() => _FadeThroughState();
}

class _FadeThroughState extends State<_FadeThrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: AppMotion.base,
    vsync: this,
  );

  /// 双段透明度：前半 1→0（渐暗）、后半 0→1（渐亮），各段 easeStandard。
  late final Animation<double> _opacity = _controller.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: AppMotion.easeStandard)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: AppMotion.easeStandard)),
        weight: 50,
      ),
    ]),
  );

  @override
  void didUpdateWidget(_FadeThrough oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅分支切换触发（初始 build 不播，停留态恒透明度 1）。
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      // 005 T006：转场件挂 key——双段透明度/终态测试锚点。
      key: const ValueKey('shellFade'),
      opacity: _opacity,
      child: widget.child,
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
enum _DockGlyph { targetRing, progressTrend }

const _navDests = [
  _NavDest('/today', Copy.todayNav, _DockGlyph.targetRing),
  _NavDest('/progress', Copy.progressNav, _DockGlyph.progressTrend),
];

/// 底部 dock（004 T025 重做，v2-today 冻结稿 D2「黑色线条」定稿）：
/// 全宽近实卡底条（glass-card + 顶缘发丝线，.dock 84px · 顶 padding 8），
/// 今日 | 中央凸起圆形＋ | 回顾 三槽——两页签 Expanded 对称、FAB 恰在
/// 屏中线；当前页签 on-surface 加粗 + 标签下 16×3 短横线（深色自动
/// 反白，全条无彩色）；FAB 56px 中性（浅色墨底白＋/深色反白），上缘
/// 凸出底条 22px、带 glass-card 4px 描边环；任意壳层页恒定（FR-010）。
///
/// 005 D1 安全区：dock 自消费 `MediaQuery.paddingOf.bottom`——底幕背景
/// 下延至屏幕物理底边（84+inset，inset 区仅背景），页签/FAB 互动槽
/// 整体止于 inset 之上；不再用外层 SafeArea（其会把整条含背景抬离
/// 底边，inset 区露底色断层）。inset=0 机型几何与 004 版恒等。
class _Dock extends StatelessWidget {
  const _Dock({required this.shell});

  final StatefulNavigationShell shell;

  /// FAB 上缘凸出量（冻结稿 .fab margin-top: -22px）。
  static const double _fabOverhang = 22;

  /// 互动内容区高度；系统底部 inset 仅在其外延伸背景。
  static const double _barHeight = 68;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
    return SizedBox(
      // 高出底条的 22px = FAB 凸出带：视觉透明但占位命中（凸出部分
      // 的点击须落在 dock 自身区域而非 body，才能稳定命中 FAB）；
      // 底部叠加安全区 inset——仅背景延伸，互动槽不上抬整条。
      height: _barHeight + _fabOverhang + bottomInset,
      child: Stack(
        children: [
          // 底条本体：近实卡底 + 顶缘发丝线（冻结稿 .dock）——高度
          // 84+inset 贴至物理底边，inset 区纯背景无互动元素。
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
          // 三槽行：FAB 起于 0（凸出 22），两页签起于 30；整行止于
          // inset 之上（Home 指示条避让，命中区不缩小）。
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomInset,
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
      _DockGlyph.targetRing => CustomPaint(
        size: const Size.square(22),
        painter: TargetRingGlyphPainter(color: color),
      ),
      _DockGlyph.progressTrend => CustomPaint(
        size: const Size.square(22),
        painter: ProgressTrendGlyphPainter(color: color),
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

/// 深链 target:// → 内部路由。
String? mapDeepLink(Uri uri) {
  switch (uri.host.isEmpty ? uri.path : uri.host) {
    case 'today':
      return '/today';
    case 'progress':
      return '/progress';
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
