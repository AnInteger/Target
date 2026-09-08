/// v3 App：主题三档 + 两 tab 壳（Liquid Glass dock）+ 提醒 replan +
/// 小组件快照传播 + Web 模拟通知横幅。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/platform/gateways.dart';
import '../core/platform/widgets/widget_snapshot.dart';
import '../features/shared/record_sheet.dart';
import 'design_tokens.dart';
import 'dock.dart';
import 'providers.dart';
import 'router.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
    ref.watch(dayTickerProvider);
    // Web 模拟通知：到点横幅（原生实现恒为空流）。
    _banners = ref.read(notificationGatewayProvider).banners.listen((b) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('${b.title}\n${b.body}')),
      );
    });
  }

  @override
  void dispose() {
    _banners?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Target',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// 两 tab 壳：头部渐变由各分支屏自绘；dock 悬浮其上。
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiquidGlassDock(
            tabs: const [
              ('/goals', '目标', Icons.track_changes_outlined),
              ('/activity', '动态', Icons.bar_chart),
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
