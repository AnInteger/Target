/// 小组件网关 iOS 实现（home_widget）。
///
/// 快照 key 契约见 specs/001-life-goal-tracker/contracts/widget-intent.md；
/// 数据经 App Group UserDefaults（group.com.target.shared）供
/// TargetWidgets 扩展读取。交互式打卡的 AppIntent 回调注册在
/// main.dart（需独立函数引用，T014）。
library;

import 'dart:async';
import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import 'gateways.dart';

class HomeWidgetGateway implements WidgetGateway {
  static const appGroupId = 'group.com.target.shared';
  static const iosWidgetName = 'TodayWidget';

  /// 快照整体 JSON 落在单键下（home_widget 只存基元；key 内部结构
  /// 仍遵循 contracts/widget-intent.md 的字段名，Swift 侧解码）。
  static const snapshotKey = 'snapshot';

  final _clicked = StreamController<Uri>.broadcast();

  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _clicked.add(uri);
    });
  }

  @override
  Future<void> saveSnapshot(Map<String, Object?> snapshot) async {
    await HomeWidget.saveWidgetData<String>(
        snapshotKey, jsonEncode(snapshot));
    await HomeWidget.updateWidget(iOSName: iosWidgetName);
  }

  @override
  Stream<Uri> get widgetClicked => _clicked.stream;
}

WidgetGateway createWidgetGateway() => HomeWidgetGateway();
