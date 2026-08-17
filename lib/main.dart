/// 应用入口：ProviderScope + 平台桥启动（通知/小组件，均不阻塞启动）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/platform/widget_boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 小组件桥（iOS：App Group + 交互回调 + 点击深链；Web/其余平台 no-op）。
  // 深链先走 go_router 的 target:// 映射，路由未建全前仅记录。
  await bootWidgetBridge((uri) {});

  runApp(const ProviderScope(child: TargetApp()));
}
