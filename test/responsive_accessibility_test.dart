import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart'
    show AppDatabase, SettingsRowsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/features/goals/goal_detail.dart';
import 'package:target/features/progress/progress_view.dart';
import 'package:target/features/today/today_view.dart';

const _today = LocalDate(2026, 8, 25);

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

Future<AppDatabase> _seedDatabase({bool onboarding = false}) async {
  final db = AppDatabase(NativeDatabase.memory());
  if (onboarding) {
    await (db.update(db.settingsRows)..where((row) => row.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
  }
  final goals = GoalRepository(db);
  await goals.create(
    Goal(
      id: 'responsive',
      name: '拿到 OW 潜水证',
      goalType: GoalType.longTerm,
      iconKey: 'pool',
      colorKey: '',
      progressCadenceDays: 7,
      createdAt: _today.addDays(-30),
      targetDate: const LocalDate(2026, 12, 31),
    ),
  );
  await goals.addStep(
    MilestoneStep(
      id: 'responsive-step',
      goalId: 'responsive',
      title: '完成 DSD 体验潜水',
    ),
  );
  await CheckInRepository(db).add(
    'responsive',
    _today.addDays(-2),
    _today.atStartOfDay.subtract(const Duration(days: 2)),
    note: '完成潜水理论复习',
  );
  return db;
}

List<Override> _overrides(AppDatabase db) => [
  dbProvider.overrideWithValue(db),
  dateProviderProvider.overrideWith(
    (ref) => FixedDateProvider(_today.atStartOfDay),
  ),
];

ThemeData _theme(Brightness brightness) =>
    brightness == Brightness.light ? AppTheme.light() : AppTheme.dark();

Future<void> _pumpDirect(
  WidgetTester tester,
  AppDatabase db,
  Brightness brightness,
  Widget page,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(db),
      child: MaterialApp(theme: _theme(brightness), home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectHitTarget(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44));
  expect(size.height, greaterThanOrEqualTo(44));
}

void main() {
  testWidgets('today progress and detail survive the width and theme matrix', (
    tester,
  ) async {
    for (final width in [320.0, 375.0, 430.0]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        final db = await _seedDatabase();

        await _pumpDirect(tester, db, brightness, const TodayView());
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await _pumpDirect(tester, db, brightness, const ProgressView());
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await _pumpDirect(
          tester,
          db,
          brightness,
          const GoalDetailPage(goalId: 'responsive'),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle(const Duration(milliseconds: 1));
        await db.close();
      }
    }
    tester.view.reset();
  });

  testWidgets(
    'primary navigation and insight actions expose accessible targets',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = await _seedDatabase(onboarding: true);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overrides(db),
            notificationGatewayProvider.overrideWithValue(
              _NotificationGateway(),
            ),
            dayTickerProvider.overrideWith((ref) {}),
          ],
          child: const TargetApp(),
        ),
      );
      await tester.pumpAndSettle();

      final todayTab = find.byKey(const ValueKey('navTab-/today'));
      final progressTab = find.byKey(const ValueKey('navTab-/progress'));
      expect(tester.getSemantics(todayTab).label, '今日');
      expect(tester.getSemantics(progressTab).label, '进展');
      _expectHitTarget(tester, todayTab);
      _expectHitTarget(tester, progressTab);

      final profile = find.byKey(const ValueKey('profileButton'));
      expect(tester.getSemantics(profile).label, '我的');
      _expectHitTarget(tester, profile);
      final allGoals = find.byKey(const ValueKey('todayViewAllGoals'));
      expect(tester.getSemantics(allGoals).label, '查看全部');
      _expectHitTarget(tester, allGoals);

      await tester.tap(progressTab);
      await tester.pumpAndSettle();
      final advice = find.byKey(const ValueKey('adviceToggle-health'));
      expect(tester.getSemantics(advice).label, '健康类目标建议');
      _expectHitTarget(tester, advice);

      await tester.tap(find.byKey(const ValueKey('navTab-/today')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('focusCard-responsive')));
      await tester.pumpAndSettle();
      final calendar = find.byKey(const ValueKey('detailOpenCalendar'));
      expect(tester.getSemantics(calendar).label, '查看日历');
      _expectHitTarget(tester, calendar);
      final yesterday = find.byKey(
        ValueKey('detailDay-${_today.addDays(-1).isoString}'),
      );
      expect(tester.getSemantics(yesterday).label, contains('可补记'));
      _expectHitTarget(tester, yesterday);

      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle(const Duration(milliseconds: 1));
      await db.close();
    },
  );
}
