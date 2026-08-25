import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart'
    show AppDatabase, SettingsRowsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/features/goals/goal_detail.dart';
import 'package:target/features/goals/goal_editor.dart';
import 'package:target/features/profile/profile.dart';
import 'package:target/features/profile/profile_hub.dart';
import 'package:target/features/progress/progress_view.dart';
import 'package:target/features/settings/settings_view.dart';
import 'package:target/features/today/today_view.dart';

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

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _completeOnboarding(AppDatabase db) async {
  await (db.update(db.settingsRows)..where((row) => row.id.equals(1))).write(
    const SettingsRowsCompanion(onboardingCompleted: Value(true)),
  );
}

Future<AppDatabase> _pumpTarget(
  WidgetTester tester, {
  bool onboardingCompleted = true,
  Future<void> Function(AppDatabase db)? seed,
}) async {
  _usePhoneSurface(tester);
  final db = AppDatabase(NativeDatabase.memory());
  if (onboardingCompleted) await _completeOnboarding(db);
  await seed?.call(db);
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

Future<void> _seedPlannedGoal(AppDatabase db) async {
  final goals = GoalRepository(db);
  await goals.create(
    Goal(
      id: 'ow',
      name: '拿到 OW 潜水证',
      goalType: GoalType.shortTerm,
      iconKey: 'pool',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      deadline: const LocalDate(2026, 10, 3),
    ),
  );
  await goals.addStep(
    MilestoneStep(id: 'theory', goalId: 'ow', title: '完成理论课程', position: 0),
  );
}

void main() {
  testWidgets('首次启动完成引导后进入首页', (tester) async {
    final db = await _pumpTarget(tester, onboardingCompleted: false);

    expect(find.byKey(const ValueKey('onboardingStart')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboardingStart')));
    await tester.pumpAndSettle();

    expect(find.byType(TodayView), findsOneWidget);
    expect(find.byKey(const ValueKey('goalStatusCard')), findsOneWidget);
    expect((await SettingsRepository(db).get()).onboardingCompleted, true);
    await _disposeTarget(tester, db);
  });

  testWidgets('首页空态可通过中央入口创建目标', (tester) async {
    final db = await _pumpTarget(tester);

    expect(find.text('还没有进行中的目标'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dockFab')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalEditorPage), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '完成产品设计课程',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(TodayView), findsOneWidget);
    expect(find.text('完成产品设计课程'), findsWidgets);
    expect((await GoalRepository(db).getGoals()).single.progressCadenceDays, 7);
    await _disposeTarget(tester, db);
  });

  testWidgets('关注卡记录进展可原子完成里程碑并创建下一步', (tester) async {
    final db = await _pumpTarget(tester, seed: _seedPlannedGoal);
    final card = find.byKey(const ValueKey('focusCard-ow'));
    expect(card, findsOneWidget);

    await tester.tap(find.descendant(of: card, matching: find.text('记录进展')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progressRecordSheet')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('progressNoteField')),
      '已完成理论课程',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('nextMilestoneField')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nextMilestoneField')),
      '预约平静水域课程',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存进展'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存进展'));
    await tester.pumpAndSettle();

    final checkIns = await CheckInRepository(db).all();
    final steps = await GoalRepository(db).stepsOf('ow');
    expect(checkIns.single.note, '已完成理论课程');
    expect(steps.first.isDone, true);
    expect(steps.last.title, '预约平静水域课程');
    await _disposeTarget(tester, db);
  });

  testWidgets('头像进入我的页，设置使用单行外观入口', (tester) async {
    final db = await _pumpTarget(tester);

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileHubPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profileSettings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsView), findsOneWidget);
    expect(find.byKey(const ValueKey('appearanceRow')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('appearanceRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('themeLight')));
    await tester.pumpAndSettle();
    expect((await SettingsRepository(db).get()).themeMode, AppThemeMode.light);
    await _disposeTarget(tester, db);
  });

  testWidgets('进展是独立分支并可返回今日', (tester) async {
    final db = await _pumpTarget(tester);

    await tester.tap(find.byKey(const ValueKey('navTab-/progress')));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressView), findsOneWidget);
    expect(find.byKey(const ValueKey('progressNoTrend')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navTab-/today')));
    await tester.pumpAndSettle();
    expect(find.byType(TodayView), findsOneWidget);
    await _disposeTarget(tester, db);
  });

  testWidgets('目标详情从关注卡进入并保留记录进展入口', (tester) async {
    final db = await _pumpTarget(tester, seed: _seedPlannedGoal);

    await tester.tap(find.byKey(const ValueKey('focusCard-ow')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);
    expect(find.byKey(const ValueKey('recordProgressButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pageTopBarBack')));
    await tester.pumpAndSettle();
    expect(find.byType(TodayView), findsOneWidget);
    await _disposeTarget(tester, db);
  });
}
