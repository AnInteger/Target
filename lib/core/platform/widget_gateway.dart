/// 小组件网关条件出口：iOS（原生）→ home_widget；其余 → 占位。
library;

export 'widget_stub.dart' if (dart.library.io) 'widget_ios.dart';
