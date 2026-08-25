import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/app.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/app/router.dart';
import 'package:target/core/db/app_database.dart'
    show AppDatabase, SettingsRowsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/features/goals/goal_editor.dart';
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
    // 无 inset 机型：底条恒为冻结稿 84px（005 D1 → 2026-08-25 收敛）。
    final bar = tester.getRect(find.byKey(const ValueKey('dockBar')));
    expect(bar.height, 84);
    expect(bar.bottom, 844);
    await _disposeTarget(tester, db);
  });

  testWidgets('dock absorbs home inset into the 84px bar breathing room', (
    tester,
  ) async {
    // iPhone Home 指示条 34px：31px 设计余量吸收 + 底条仅加高 3px，
    // 页签标签贴安全区边界——不再出现 68+inset 全额叠加的 49px 空带。
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((row) => row.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
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

    final bar = tester.getRect(find.byKey(const ValueKey('dockBar')));
    expect(bar.height, 87); // max(84, 8 + 45 + 34)
    expect(bar.bottom, 844); // 背景贴物理底边
    // 页签标签带底缘落在安全区边界（844 - 34）附近（±2px 字体度量容差），
    // 不再出现旧算法下 15px 额外空带。
    final tab = tester.getRect(find.byKey(const ValueKey('navTab-/today')));
    expect(tab.bottom, lessThanOrEqualTo(812));
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

  testWidgets('goal editor and detail use the shared fade-slide transition', (
    tester,
  ) async {
    // 2026-08-25：分支内创建/详情动线与根级 push 同款转场——同一时刻
    // 的横向位移一致（此前编辑器吃平台缺省转场，与「我的」不一致）。
    final editorDb = await _pumpTarget(tester);
    await tester.tap(find.byKey(const ValueKey('dockFab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final editorOffset = tester.getTopLeft(find.byType(GoalEditorPage));
    expect(editorOffset.dx, greaterThan(0));
    await tester.pumpAndSettle();
    await _disposeTarget(tester, editorDb);

    final goalsDb = await _pumpTarget(tester);
    await tester.tap(find.text('查看全部'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final goalsOffset = tester.getTopLeft(find.byType(GoalsAllPage));
    expect(goalsOffset.dx, closeTo(editorOffset.dx, .5));
    await _disposeTarget(tester, goalsDb);
  });

  testWidgets('goals all page paints an opaque background over the shell', (
    tester,
  ) async {
    // root 级 push：转场结束后下层 shell 不再绘制——透明底会露原始
    // 画布（iOS 黑屏感）。契约：底色 = palette.background（同我的/设置）。
    final db = await _pumpTarget(tester);
    await tester.tap(find.text('查看全部'));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(
      find
          .descendant(of: find.byType(GoalsAllPage), matching: find.byType(Scaffold))
          .first,
    );
    expect(scaffold.backgroundColor, TargetPalette.light.background);
    await _disposeTarget(tester, db);
  });

  testWidgets('goal detail menu sheet rests above the dock', (tester) async {
    // 分支页弹层挂分支导航器：呈现于壳层 body 内、止于 dock 顶缘——
    // dock 不被遮盖、sheet 底缘无 home 空带。
    final db = await _pumpTarget(tester);
    await tester.tap(find.byKey(const ValueKey('focusCard-g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalMoreButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('goalMenuSheet')), findsOneWidget);
    // dock 仍在场（弹层不再整屏遮盖导航条）；sheet 底缘贴壳层 body 底
    //＝ dock 占位顶（含 FAB 凸出带 22px：barTop - 22）。
    final barRect = tester.getRect(find.byKey(const ValueKey('dockBar')));
    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('goalMenuSheet')),
    );
    expect(sheetRect.bottom, closeTo(barRect.top - 22, .5));
    await _disposeTarget(tester, db);
  });
}
