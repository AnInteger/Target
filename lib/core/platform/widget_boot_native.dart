/// iOS 小组件桥启动：App Group、交互回调（AppIntent 经 home_widget 回传）、
/// 点击深链流。回调本体在 widgets/widget_checkin.dart
/// （顶层函数 + @pragma('vm:entry-point')，T030 打卡闭环）。
library;

import 'package:home_widget/home_widget.dart';

import 'widget_ios.dart';
import 'widgets/widget_checkin.dart';

Future<void> bootWidgetBridge(void Function(Uri) onWidgetClicked) async {
  await HomeWidget.setAppGroupId(HomeWidgetGateway.appGroupId);
  HomeWidget.widgetClicked.listen((uri) {
    if (uri != null) onWidgetClicked(uri);
  });
  await HomeWidget.registerInteractivityCallback(widgetCheckInCallback);
}
