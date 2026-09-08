/// 头像选图网关（相册 / 拍照）。
///
/// image_picker 跨平台（iOS/Android/Web）单实现：
/// - iOS 相册走 PHPicker（系统相册选择器，无需相册权限）；
/// - 相机需要 NSCameraUsageDescription（Info.plist 已声明）；
/// - 输出统一压到 512×512 / 质量 80 的 JPEG 字节，供 base64 入库
///   （settings.avatarKey，形如 data:image/jpeg;base64,…）。
library;

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ImagePickGateway {
  final ImagePicker _picker = ImagePicker();

  /// 相册选图；取消返回 null。
  Future<Uint8List?> fromGallery() => _pick(ImageSource.gallery);

  /// 拍照；取消返回 null。
  Future<Uint8List?> fromCamera() => _pick(ImageSource.camera);

  Future<Uint8List?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
