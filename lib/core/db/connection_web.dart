/// Web 连接：WasmDatabase（sqlite3.wasm + drift_worker.js 需位于 web/ 下）。
///
/// 优先 OPFS（多标签安全），回退 IndexedDB，最差 inMemory（内存态）；
/// chosenImplementation/missingFeatures 由调用方按需读取（T015 验证用）。
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection() => DatabaseConnection.delayed(
      Future(() async {
        final result = await WasmDatabase.open(
          databaseName: 'target',
          sqlite3Uri: Uri.parse('sqlite3.wasm'),
          driftWorkerUri: Uri.parse('drift_worker.js'),
        );
        return result.resolvedExecutor;
      }),
    );
