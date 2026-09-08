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
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
    );
  }
}

/// 两 tab 壳：头部渐变由各分支屏自绘；dock 悬浮其上（内容自留底部空隙）。
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
      await ref.read(reminderServiceProvider).replan(
            goals: goals,
            reminders: reminders,
            enabled: settings?.remindersEnabled ?? true,
          );
      final records = ref.read(recordsProvider).value ?? const [];
      await ref.read(widgetGatewayProvider).saveSnapshot(
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
      child: Column(
        children: [
          Expanded(child: widget.navigationShell),
          AppDock(
            tabs: const [
              ('/goals', '目标', CupertinoIcons.scope),
              ('/activity', '动态', CupertinoIcons.chart_bar),
            ],
            activePath: onActivity ? '/activity' : '/goals',
            onTapTab: (p) => widget.navigationShell.goBranch(
                  p == '/activity' ? 1 : 0,
                  initialLocation: p == (onActivity ? '/activity' : '/goals'),
                ),
            onRecord: () => showRecordSheet(context),
          ),
        ],
      ),
    );
  }
}
