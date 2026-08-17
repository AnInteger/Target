/// 小组件网关占位实现（Web 等）。
///
/// Web 无桌面小组件概念：设置页呈现"iOS 专属"说明文案（research D15），
/// 本实现仅保证接口可用。
library;

import 'dart:async';

import 'gateways.dart';

class StubWidgetGateway implements WidgetGateway {
  @override
  Future<void> saveSnapshot(Map<String, Object?> snapshot) async {}

  @override
  Stream<Uri> get widgetClicked => const Stream.empty();
}

WidgetGateway createWidgetGateway() => StubWidgetGateway();
