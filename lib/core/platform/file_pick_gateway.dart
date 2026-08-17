/// 文件选择网关：file_picker（全平台，Web 为浏览器文件选择）。
library;

import 'package:file_picker/file_picker.dart';

import 'gateways.dart';

class FilePickGatewayImpl implements FilePickGateway {
  @override
  Future<PickedFile?> pickBackupFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'targetbackup'],
    );
    final file = files.firstOrNull;
    if (file == null) return null;
    return PickedFile(
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }
}

FilePickGateway createFilePickGateway() => FilePickGatewayImpl();
