/// 应用入口：ProviderScope + 平台桥启动（通知/小组件，均不阻塞启动）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/platform/widget_boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 小组件桥（iOS：App Group + 交互回调 + 点击深链；Web/其余平台 no-op）。
  // 深链 target://today|review|goal/{id} 经 mapDeepLink 落到 go_router（T040）。
  final container = ProviderContainer();
  await bootWidgetBridge((uri) {
    final route = mapDeepLink(uri);
    if (route != null) container.read(routerProvider).go(route);
  });

  runApp(UncontrolledProviderScope(
    container: container,
    child: const TargetApp(),
  ));
}
