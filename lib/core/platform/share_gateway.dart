/// 分享网关：文本走 share_plus（全平台）；文件导出按平台分派。
library;

import 'package:share_plus/share_plus.dart';

import 'export_helper.dart';
import 'gateways.dart';

class ShareGatewayImpl implements ShareGateway {
  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  @override
  Future<void> exportFile({
    required String fileName,
    required List<int> bytes,
    required String mime,
  }) =>
      exportFileBytes(fileName: fileName, bytes: bytes, mime: mime);
}

ShareGateway createShareGateway() => ShareGatewayImpl();
