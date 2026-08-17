/// 小组件桥条件出口：iOS → home_widget；其余 → 占位。
library;

export 'widget_boot_stub.dart' if (dart.library.io) 'widget_boot_native.dart';
