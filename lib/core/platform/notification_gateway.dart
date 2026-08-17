/// 通知网关条件出口：原生 → flutter_local_notifications；Web → 页内横幅模拟。
library;

export 'notification_web.dart'
    if (dart.library.io) 'notification_native.dart';
