/// 原生平台（iOS/Android）连接：path_provider 默认文档目录 + NativeDatabase。
///
/// 注：research D3 原文写 App Group 容器，实现时修正为默认目录——
/// home_widget 后台回调在 App 进程内运行 FlutterEngine，共享应用沙盒，
/// 无需跨进程读库；小组件快照走 home_widget 自己的 App Group UserDefaults。
library;

import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase, QueryExecutor;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/target.sqlite');
      return NativeDatabase.createInBackground(file);
    });
