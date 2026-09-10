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

  /// R13 目标翻页小组件（GoalPagesWidget · systemMedium）——与今日
  /// 小组件共用同一份快照（单键 JSON，schema v4 的 goals 字段）。
  static const iosGoalPagesWidgetName = 'GoalPagesWidget';

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
    await HomeWidget.saveWidgetData<String>(snapshotKey, jsonEncode(snapshot));
    // 两个小组组件各自 reload timeline（读同一快照单键）。
    await HomeWidget.updateWidget(iOSName: iosWidgetName);
    await HomeWidget.updateWidget(iOSName: iosGoalPagesWidgetName);
  }

  @override
  Stream<Uri> get widgetClicked => _clicked.stream;
}

WidgetGateway createWidgetGateway() => HomeWidgetGateway();
