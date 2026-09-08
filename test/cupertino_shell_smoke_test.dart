/// v3.1 Cupertino 壳冒烟测试：CupertinoApp.router 启动 / 双 tab dock /
/// 空态渲染 / 主题三档切换（浅/深令牌生效）。
///
/// DB 以 NativeDatabase.memory 注入（providers.dart 头注的测试模式）；
/// 平台网关全部换 no-op 假件，避免插件通道。
library;

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/app.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/core/platform/widget_stub.dart';

class _FakeNotificationGateway implements NotificationGateway {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> get isPermissionGranted async => true;

  @override
  Future<void> scheduleDaily({
    required int id,
    required LocalTime time,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleOccurrences({
    required int baseId,
    required List<DateTime> fireOns,
    required String title,
    required String body,
  }) async {}

  @override
  Stream<NotificationBanner> get banners => const Stream.empty();
}

class _FakeShareGateway implements ShareGateway {
  @override
  Future<void> shareText(String text) async {}

  @override
  Future<void> exportFile({
    required String fileName,
    required List<int> bytes,
    required String mime,
  }) async {}
}

class _FakeFilePickGateway implements FilePickGateway {
  @override
  Future<PickedFile?> pickBackupFile() async => null;
}

Future<ProviderContainer> _container(AppDatabase db) async {
  final container = ProviderContainer(
    overrides: [
      dbProvider.overrideWithValue(db),
      // 跨天 ticker 会留宿午夜 Timer（宿主测试环境禁止挂起计时器）。
      dayTickerProvider.overrideWithValue(null),
      notificationGatewayProvider
          .overrideWithValue(_FakeNotificationGateway()),
      widgetGatewayProvider.overrideWithValue(StubWidgetGateway()),
      shareGatewayProvider.overrideWithValue(_FakeShareGateway()),
      filePickGatewayProvider.overrideWithValue(_FakeFilePickGateway()),
    ],
  );
  // 预热设置/领域流，避免首帧 loading 态。
  await container.read(settingsProvider.future);
  await container.read(goalsProvider.future);
  return container;
}

void main() {
  testWidgets('CupertinoApp 壳：dock 双 tab + 目标空态 + 深色切换', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = await _container(db);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Cupertino 根 + 浅色令牌。
    final app = tester.widget<CupertinoApp>(find.byType(CupertinoApp));
    expect(app.theme?.brightness, Brightness.light);
    expect(app.theme?.scaffoldBackgroundColor, TargetPalette.light.background);

    // dock 双 tab 与目标页空态 CTA。
    expect(find.text('目标'), findsOneWidget);
    expect(find.text('动态'), findsOneWidget);
    expect(find.text('新建目标'), findsOneWidget);

    // 设置主题 = 深色 → 流更新 → CupertinoApp 重建为深色令牌。
    await container
        .read(settingsRepoProvider)
        .update((await container.read(settingsProvider.future))
            .copyWith(themeMode: 'dark'));
    await tester.pumpAndSettle();

    final darkApp = tester.widget<CupertinoApp>(find.byType(CupertinoApp));
    expect(darkApp.theme?.brightness, Brightness.dark);
    expect(darkApp.theme?.scaffoldBackgroundColor, TargetPalette.dark.background);
  });
}
