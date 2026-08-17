/// 小组件交互回调（AppIntent → home_widget BackgroundIntent → 本函数）。
///
/// 仅原生侧（widget_boot_native.dart）引用——本文件 import home_widget
/// （其内部用 dart:io），不得被 Web 可达代码直接 import。
/// 顶层函数 + @pragma('vm:entry-point')：在 App 进程内无 UI 上下文运行，
/// 独立开一条 drift 连接（同进程多连接安全）。当前实现打卡写入；
/// 快照回写（battery/goals/weekProgress）在 T024 统计引擎就绪后于 T030 补全。
library;

import 'package:home_widget/home_widget.dart';

import '../db/app_database.dart';
import '../db/connection.dart';
import '../db/repositories.dart';
import '../models/calendar_types.dart';

@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  if (uri == null) return;
  // target://checkin?goalId=<id>
  if (uri.host != 'checkin') return;
  final goalId = uri.queryParameters['goalId'];
  if (goalId == null) return;

  final db = AppDatabase(openConnection());
  try {
    final now = DateTime.now();
    await CheckInRepository(db)
        .add(goalId, LocalDate.fromDateTime(now), now);
    await HomeWidget.updateWidget(iOSName: 'TodayWidget');
  } finally {
    await db.close();
  }
}
