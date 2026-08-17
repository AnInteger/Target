/// 文件导出条件出口：Web → 浏览器下载；原生 → 分享面板。
library;

export 'export_helper_web.dart'
    if (dart.library.io) 'export_helper_native.dart';
