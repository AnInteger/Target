/// MaterialApp：主题、路由、Web 模拟通知横幅（ui-contract.md）、首启引导、
/// 小组件快照传播（T031）。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/copy.dart';
import '../core/platform/gateways.dart';
import '../core/platform/widgets/widget_snapshot.dart';
import 'design_tokens.dart';
import 'providers.dart';
import 'router.dart';

class TargetApp extends ConsumerStatefulWidget {
  const TargetApp({super.key});

  @override
  ConsumerState<TargetApp> createState() => _TargetAppState();
}

class _TargetAppState extends ConsumerState<TargetApp> {
  StreamSubscription<NotificationBanner>? _banners;
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    // Web 模拟通知：到点横幅（原生实现恒为空流，等价无操作）。
    final messenger = ScaffoldMessenger.maybeOf(context);
    _banners = ref.read(notificationGatewayProvider).banners.listen((b) {
      messenger?.showSnackBar(
        SnackBar(content: Text('${b.title}\n${b.body}')),
      );
    });
  }

  @override
  void dispose() {
    _banners?.cancel();
    super.dispose();
  }

  /// 首启引导（SC-001）：未完成 + 无目标 → 进引导页（一次性判定）。
  void _maybeShowOnboarding() {
    if (_onboardingChecked) return;
    final settings = ref.read(settingsProvider).value;
    final goals = ref.read(goalsProvider).value;
    if (settings == null || goals == null) return; // 数据未就绪，等下一次流事件
    _onboardingChecked = true;
    if (!settings.onboardingCompleted && goals.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(routerProvider).go('/onboarding');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (_, _) => _maybeShowOnboarding());
    ref.listen(goalsProvider, (_, _) => _maybeShowOnboarding());
    _maybeShowOnboarding();
    // T031：数据变更 → 小组件快照重写（跨天由 dayTicker invalidate 触发
    // statsProvider 重算，走同一监听）。Web 网关为 no-op。
    ref.watch(dayTickerProvider);
    ref.listen(statsProvider, (_, next) {
      final goals = ref.read(goalsProvider).value;
      if (next == null || goals == null) return;
      writeTodaySnapshot(
        gateway: ref.read(widgetGatewayProvider),
        goals: goals,
        stats: next,
        today: ref.read(todayProvider),
        now: DateTime.now(),
      );
    });
    return MaterialApp.router(
      title: Copy.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
