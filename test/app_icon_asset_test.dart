import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('marketing icon is 1024 square and fully opaque', () async {
    final file = File('design/brand/icon-progress-white-1024.png');
    expect(file.existsSync(), isTrue);
    final decoded = img.decodePng(await file.readAsBytes());
    expect(decoded, isNotNull);
    expect((decoded!.width, decoded.height), (1024, 1024));
    expect(decoded.every((pixel) => pixel.a == 255), isTrue);
    final corner = decoded.getPixel(0, 0);
    expect((corner.r, corner.g, corner.b), (255, 255, 255));
  });

  test('adaptive foreground keeps transparent safe-zone corners', () async {
    final file = File('design/brand/icon-progress-foreground-1024.png');
    expect(file.existsSync(), isTrue);
    final decoded = img.decodePng(await file.readAsBytes());
    expect(decoded, isNotNull);
    expect((decoded!.width, decoded.height), (1024, 1024));
    expect(decoded.getPixel(0, 0).a, 0);
    expect(decoded.any((pixel) => pixel.a == 255), isTrue);
  });

  test('generated platform launcher assets are present', () {
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
        'Icon-App-1024x1024@1x.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
          .existsSync(),
      isTrue,
    );
    expect(
      File(
        'android/app/src/main/res/drawable-xxxhdpi/'
        'ic_launcher_foreground.png',
      ).existsSync(),
      isTrue,
    );
  });
}
