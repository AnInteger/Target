import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/app.dart';
import 'package:target/app/providers.dart';
import 'package:target/app/router.dart';
import 'package:target/core/db/app_database.dart'
    show AppDatabase, SettingsRowsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/features/goals/goals_all_view.dart';
import 'package:target/features/profile/profile.dart';

class _NotificationGateway implements NotificationGateway {
  @override
  Stream<NotificationBanner> get banners => const Stream.empty();

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> get isPermissionGranted async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDaily({
    required int id,
    required LocalTime time,
    required String title,
    required String body,
  }) async {}
}

Future<AppDatabase> _pumpTarget(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  await (db.update(db.settingsRows)..where((row) => row.id.equals(1))).write(
    const SettingsRowsCompanion(onboardingCompleted: Value(true)),
  );
  await GoalRepository(db).create(
    Goal(
      id: 'g1',
      name: '拿到 OW 潜水证',
      goalType: GoalType.longTerm,
      iconKey: 'pool',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      targetDate: const LocalDate(2026, 12, 31),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        notificationGatewayProvider.overrideWithValue(_NotificationGateway()),
        dayTickerProvider.overrideWith((ref) {}),
      ],
      child: const TargetApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _disposeTarget(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  await db.close();
}

void main() {
  test('deep links recognize progress and reject review', () {
    expect(mapDeepLink(Uri.parse('target://progress')), '/progress');
    expect(mapDeepLink(Uri.parse('target://review')), isNull);
  });

  testWidgets('dock contains today and progress with compact geometry', (
    tester,
  ) async {
    final db = await _pumpTarget(tester);

    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsNothing);
    expect(tester.getRect(find.byKey(const ValueKey('dockBar'))).height, 68);
    await _disposeTarget(tester, db);
  });

  testWidgets('goals all and profile share the root push transition', (
    tester,
  ) async {
    final goalsDb = await _pumpTarget(tester);
    await tester.tap(find.text('查看全部'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final goalsOffset = tester.getTopLeft(find.byType(GoalsAllPage));
    expect(goalsOffset.dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dockBar')), findsNothing);
    await _disposeTarget(tester, goalsDb);

    final profileDb = await _pumpTarget(tester);
    await tester.tap(find.byType(ProfileAvatar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final profileOffset = tester.getTopLeft(
      find.byKey(const ValueKey('profileHub')),
    );
    expect(profileOffset.dx, closeTo(goalsOffset.dx, .5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dockBar')), findsNothing);
    await _disposeTarget(tester, profileDb);
  });
}
