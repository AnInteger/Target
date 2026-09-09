import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/app.dart';
import 'package:target/app/controls.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/core/platform/widget_stub.dart';

class _FN implements NotificationGateway {
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

class _FS implements ShareGateway {
  @override
  Future<void> shareText(String text) async {}
  @override
  Future<void> exportFile({
    required String fileName,
    required List<int> bytes,
    required String mime,
  }) async {}
}

class _FF implements FilePickGateway {
  @override
  Future<PickedFile?> pickBackupFile() async => null;
}

void main() {
  testWidgets('诊断：无置顶时其他目标各行尺寸应一致', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        dayTickerProvider.overrideWithValue(null),
        notificationGatewayProvider.overrideWithValue(_FN()),
        widgetGatewayProvider.overrideWithValue(StubWidgetGateway()),
        shareGatewayProvider.overrideWithValue(_FS()),
        filePickGatewayProvider.overrideWithValue(_FF()),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    for (final i in [1, 2, 3]) {
      await container
          .read(goalRepoProvider)
          .createPlan(
            Goal(
              id: 'g$i',
              name: '无置顶目标$i',
              createdAt: const LocalDate(2026, 9, 1),
            ),
            const [],
          );
    }
    await container.read(goalsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TargetApp()),
    );
    await tester.pumpAndSettle();

    final finder = find.byType(AppCard);
    final n = finder.evaluate().length;
    final rects = [for (var i = 0; i < n; i++) tester.getRect(finder.at(i))];
    debugPrint('DIAG cards=$n');
    for (final (i, r) in rects.indexed) {
      debugPrint(
        'DIAG[$i] top=${r.top.toStringAsFixed(1)} h=${r.height.toStringAsFixed(1)}',
      );
    }
    expect(n, 3);
    // 行高恒等 + 行距恒等（无置顶时首行不再偏高）。
    expect(rects.first.height, rects[1].height);
    expect(rects[1].height, rects[2].height);
    expect(
      rects[1].top - (rects[0].top + rects[0].height),
      rects[2].top - (rects[1].top + rects[1].height),
    );
  });
}
