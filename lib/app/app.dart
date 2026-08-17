/// MaterialApp：主题、路由、Web 模拟通知横幅（ui-contract.md）。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/copy.dart';
import '../core/platform/gateways.dart';
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

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: Copy.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
      );
}
