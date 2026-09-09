/// v3.1 App：CupertinoApp.router 主题三档 + 两 tab 壳（浮动 dock）+
/// 提醒 replan + 小组件快照传播 + Web 模拟通知 toast。
///
/// CupertinoApp 无 darkTheme/themeMode 参数——三档设置在此先行解析为
/// 唯一 theme（brightness 显式固定）。
library;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/platform/gateways.dart';
import '../core/platform/widgets/widget_snapshot.dart';
import '../features/shared/record_sheet.dart';
import 'design_tokens.dart';
import 'dock.dart';
import 'providers.dart';
import 'router.dart';
import 'toast.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class TargetApp extends ConsumerStatefulWidget {
  const TargetApp({super.key});

  @override
  ConsumerState<TargetApp> createState() => _TargetAppState();
}

class _TargetAppState extends ConsumerState<TargetApp> {
  StreamSubscription<NotificationBanner>? _banners;

  @override
  void initState() {
    super.initState();
    // Web 模拟通知：到点 toast（原生实现恒为空流）。
    _banners = ref.read(notificationGatewayProvider).banners.listen((b) {
      final overlayContext = rootNavigatorKey.currentContext;
      if (overlayContext != null) {
        // ignore: use_build_context_synchronously
        AppToast.show(overlayContext, '${b.title}\n${b.body}');
      }
    });
  }

  @override
  void dispose() {
    _banners?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 跨天 ticker 挂活（在 build 订阅——initState 中 ref.watch 不允许）。
    ref.watch(dayTickerProvider);
    final dark = switch (ref.watch(themeModeProvider)) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
    final palette = AppTheme.paletteOf(
      dark ? Brightness.dark : Brightness.light,
    );
    return CupertinoApp.router(
      title: 'Target',
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.cupertino(
        palette,
        dark ? Brightness.dark : Brightness.light,
      ),
      // GlobalMaterialLocalizations：Material ReorderableListView 的 debug
      // 断言需要（置顶排序沿用该 widgets 级组件）。
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
    );
  }
}

/// 两 tab 壳：头部渐变由各分支屏自绘；dock 悬浮于内容之上（R10），
/// 内容滑入 dock 区时经渐隐带淡入底色（页面底部自留滚动余量）。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // 数据/设置/提醒任一变化 → 全量重建 pending 通知 + 小组件快照。
    Future<void> replan() async {
      final goals = ref.read(goalsProvider).value ?? const [];
      final reminders = ref.read(remindersProvider).value ?? const [];
      final settings = ref.read(settingsProvider).value;
      await ref
          .read(reminderServiceProvider)
          .replan(
            goals: goals,
            reminders: reminders,
            enabled: settings?.remindersEnabled ?? true,
          );
      final records = ref.read(recordsProvider).value ?? const [];
      await ref
          .read(widgetGatewayProvider)
          .saveSnapshot(
            buildTodaySnapshot(
              goals: goals,
              records: records,
              today: ref.read(todayProvider),
              now: DateTime.now(),
            ),
          );
    }

    unawaited(replan());
    ref.listenManual(goalsProvider, (_, _) => unawaited(replan()));
    ref.listenManual(recordsProvider, (_, _) => unawaited(replan()));
    ref.listenManual(remindersProvider, (_, _) => unawaited(replan()));
    ref.listenManual(settingsProvider, (_, _) => unawaited(replan()));
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final onActivity = path == '/activity';
    final p = TargetPalette.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      resizeToAvoidBottomInset: false,
      child: Stack(
        children: [
          // 内容全高铺满：滚动时从 dock 后方穿过，由渐隐带柔和过渡；
          // 分支切换时新分支淡入 + 自切换方向轻移（R11b）。
          Positioned.fill(
            child: _BranchFade(
              index: widget.navigationShell.currentIndex,
              child: widget.navigationShell,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 渐隐过渡带（不拦截点按）：底色自透明 → 不透明。
                IgnorePointer(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.background.withValues(alpha: 0),
                          p.background,
                        ],
                      ),
                    ),
                  ),
                ),
                // dock 区同色衬底：内容滑入此高度即被底色完全盖住
                //（含 dock 左右两侧与胶囊/记录钮之间的空隙），与上方
                // 渐隐带无缝衔接——不再露出一圈矩形底缘（R11）。
                Container(
                  color: p.background,
                  child: SafeArea(
                    top: false,
                    child: AppDock(
                      tabs: const [
                        ('/goals', '目标', CupertinoIcons.scope),
                        ('/activity', '动态', CupertinoIcons.chart_bar),
                      ],
                      activePath: onActivity ? '/activity' : '/goals',
                      onTapTab: (p) => widget.navigationShell.goBranch(
                        p == '/activity' ? 1 : 0,
                        initialLocation:
                            p == (onActivity ? '/activity' : '/goals'),
                      ),
                      onRecord: () => showRecordSheet(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 分支切换过渡（R11b）：目标 ↔ 动态切换时，新分支淡入并自切换
/// 方向轻移进入（220ms）；启动首帧不播。
class _BranchFade extends StatefulWidget {
  const _BranchFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_BranchFade> createState() => _BranchFadeState();
}

class _BranchFadeState extends State<_BranchFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  var _fromRight = true;

  @override
  void initState() {
    super.initState();
    _controller.value = 1; // 首帧直接呈现，不播入场。
  }

  @override
  void didUpdateWidget(covariant _BranchFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _fromRight = widget.index > oldWidget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drift = (_fromRight ? 1.0 : -1.0) * 0.02;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(drift, 0),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
