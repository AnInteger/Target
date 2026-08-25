import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/features/profile/profile_hub.dart';
import 'package:target/features/settings/appearance_mode_sheet.dart';
import 'package:target/features/settings/settings_view.dart';

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

void main() {
  testWidgets('我的页是个人与目标管理入口', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final goals = GoalRepository(db);
    await goals.create(
      Goal(
        id: 'active',
        name: '拿到 OW 潜水证',
        goalType: GoalType.longTerm,
        iconKey: 'pool',
        colorKey: '',
        createdAt: const LocalDate(2026, 7, 1),
      ),
    );
    await goals.create(
      Goal(
        id: 'archived',
        name: '旧目标',
        goalType: GoalType.shortTerm,
        iconKey: 'flag',
        colorKey: '',
        status: GoalStatus.archived,
        createdAt: const LocalDate(2026, 5, 1),
        deadline: const LocalDate(2026, 6, 1),
      ),
    );
    await goals.addStep(
      MilestoneStep(
        id: 'done',
        goalId: 'active',
        title: '完成 DSD 体验潜水',
        isDone: true,
        doneAt: DateTime.utc(2026, 8, 20),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProfileHubPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('本月完成'), findsOneWidget);
    expect(find.text('已归档'), findsOneWidget);
    expect(find.text('目标管理'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  });

  testWidgets('外观使用传统单行入口和底部单选面板', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAppearanceModeSheet(context),
                child: const Text('外观'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('外观'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('appearanceModeSheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('themeSystem')), findsOneWidget);
    expect(find.byKey(const ValueKey('themeLight')), findsOneWidget);
    expect(find.byKey(const ValueKey('themeDark')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('themeLight')));
    await tester.pumpAndSettle();
    expect((await SettingsRepository(db).get()).themeMode, AppThemeMode.light);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  });

  testWidgets('设置页深色模式不混入浅色底幕', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(_NotificationGateway()),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const SettingsView()),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final palette = TargetPalette.of(tester.element(find.byType(SettingsView)));
    expect(scaffold.backgroundColor, palette.background);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  });
}
