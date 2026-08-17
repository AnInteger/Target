/// 平台条件出口：Web → WasmDatabase；原生（iOS/Android）→ NativeDatabase。
///
/// 两实现都提供 `QueryExecutor openConnection()`。
/// 测试直接 `AppDatabase(NativeDatabase.memory())`（见 test/ 各处），
/// 不经此文件。
library;

export 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
