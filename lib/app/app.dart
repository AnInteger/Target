/// MaterialApp：主题、路由、Web 模拟通知横幅（ui-contract.md）、首启引导、
/// 小组件快照传播（T031）。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/copy.dart';
import '../core/models/calendar_types.dart';
import '../core/models/entities.dart';
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

/// Web 模拟通知横幅的宿主 key：MaterialApp 自建 ScaffoldMessenger，
/// App 根 context 取不到（maybeOf 恒 null）——必须经 root key 显示。
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class _TargetAppState extends ConsumerState<TargetApp> {
  StreamSubscription<NotificationBanner>? _banners;
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    // Web 模拟通知：到点横幅（原生实现恒为空流，等价无操作）。
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

  /// US3/US4：数据/设置/提醒行任一变化 → 周结算（幂等，概要内容
  /// 依赖其留痕判断）→ 全量重建 pending 通知（T033 已达标剔除；
  /// 跨天由 dayTicker invalidate statsProvider 走同路）。
  Future<void> _replanReminders() async {
    final stats = ref.read(statsProvider);
    final goals = ref.read(goalsProvider).value;
    final settings = ref.read(settingsProvider).value;
    if (stats == null || goals == null || settings == null) return;
    final now = DateTime.now();
    final today = ref.read(todayProvider);
    await ref
        .read(reminderServiceProvider)
        .replan(
          settings: settings,
          goals: goals,
          stats: stats,
          today: today,
          nowTime: LocalTime.fromDateTime(now),
        );
  }

  /// T044：里程碑步骤属另一张表，先取全（同步闭包喂给快照构建），
  /// 再写快照 + 重建提醒。
  Future<void> _writeSnapshot(List<Goal> goals) async {
    final stats = ref.read(statsProvider);
    if (stats == null) return;
    final repo = ref.read(goalRepoProvider);
    final stepsByGoal = <String, List<MilestoneStep>>{};
    for (final g in goals.where(
      (g) => g.isShortTerm && g.status == GoalStatus.active,
    )) {
      stepsByGoal[g.id] = await repo.stepsOf(g.id);
    }
    if (!mounted) return;
    await writeTodaySnapshot(
      gateway: ref.read(widgetGatewayProvider),
      goals: goals,
      stats: stats,
      today: ref.read(todayProvider),
      now: DateTime.now(),
      stepsOf: (id) => stepsByGoal[id] ?? const <MilestoneStep>[],
    );
    await _replanReminders();
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
    ref.listen(remindersProvider, (_, _) => _replanReminders());
    ref.listen(settingsProvider, (_, _) => _replanReminders());
    ref.listen(statsProvider, (_, next) {
      final goals = ref.read(goalsProvider).value;
      if (next == null || goals == null) return;
      _writeSnapshot(goals);
    });
    return MaterialApp.router(
      title: Copy.appName,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // 004 T004（D2）：主题三档（system|light|dark），持久化于
      // Settings.themeMode，缺省跟随系统。
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
