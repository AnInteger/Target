/// 原生文件导出：走系统分享面板（XFile 临时封装）。
library;

import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> exportFileBytes({
  required String fileName,
  required List<int> bytes,
  required String mime,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: mime,
      )],
    ),
  );
}
