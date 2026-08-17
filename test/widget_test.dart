// App Shell 冒烟测试（T014 + T022）：内存库启动 → 空库首启进引导页（SC-001）。
import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/providers.dart';
import 'package:target/features/goals/goal_editor.dart';
import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase, SettingsRowsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/platform/gateways.dart';

/// 测试假通知网关：记录调度、零平台副作用。
class FakeNotificationGateway implements NotificationGateway {
  final scheduled = <int>[];

  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> get isPermissionGranted async => true;
  @override
  Future<void> scheduleDaily(
      {required int id,
      required LocalTime time,
      required String title,
      required String body}) async {
    scheduled.add(id);
  }

  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Stream<NotificationBanner> get banners => const Stream.empty();
}

void main() {
  testWidgets('空库首启 → 引导页（SC-001）', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.onboardingTitle), findsOneWidget);
    expect(find.text(Copy.onboardingSkip), findsOneWidget);
    await db.close();
  });

  testWidgets('已完成引导 → 直接今日页', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final settings = await (db.select(db.settingsRows)).get();
    expect(settings, isNotEmpty);
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
        const SettingsRowsCompanion(onboardingCompleted: Value(true)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // TodayView 空态：无活跃习惯 → 电量"—"（R9），底部导航三标签。
    expect(find.text(Copy.batteryEmpty), findsWidgets);
    expect(find.text(Copy.todayNav), findsOneWidget);
    await db.close();
  });

  testWidgets('US2 微缩验收：打卡 → 进度/成就即时刷新 → 撤销回退', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(Goal(
      name: '锻炼',
      kind: GoalKind.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      createdAt: today,
    ));
    await repo.addInitial(goal.id, const DailyFrequency(1), WeekStart.containing(today));
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1)))
        .write(const SettingsRowsCompanion(onboardingCompleted: Value(true)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日 0/1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 全部达标 → 成就态替换进度行（US2-6）。
    expect(find.text(Copy.allDoneTitle), findsOneWidget);

    // 撤销 → 统计即时回退（R7/SC-003）。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    expect(find.text('今日 0/1'), findsOneWidget);
    await db.close();
  });

  testWidgets('FR-001：输入模糊名当场出 SMART 建议，采用即替换（回归：输入需触发刷新）',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1)))
        .write(const SettingsRowsCompanion(onboardingCompleted: Value(true)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: GoalEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 输入"变健康"：不改任何其他控件，建议 chip 应立即可见。
    await tester.enterText(find.byType(TextField), '变健康');
    await tester.pumpAndSettle();
    expect(find.text(Copy.smartSuggest('每天散步 20 分钟')), findsOneWidget);

    // 一键采用 → 名称被替换为具体表述，chip 随之消失。
    await tester.tap(find.text(Copy.smartApply));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '每天散步 20 分钟'), findsOneWidget);
    expect(find.text(Copy.smartSuggest('每天散步 20 分钟')), findsNothing);
    await db.close();
  });

  testWidgets('V5：长按目标行 → 补签日历 → 补昨日 → 带"补"标记入库（FR-004/R6）',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(Goal(
      name: '好好吃饭',
      kind: GoalKind.habit,
      iconKey: 'meal',
      colorKey: 'coral',
      createdAt: today,
    ));
    await repo.addInitial(goal.id, const DailyFrequency(1), WeekStart.containing(today));
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1)))
        .write(const SettingsRowsCompanion(onboardingCompleted: Value(true)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 长按目标行 → 弹出补签日历（过去两周）。
    await tester.longPress(find.text('好好吃饭'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.backfillCalendarTitle), findsOneWidget);

    // 点昨天的格子 → 生成 isBackfill=true 的打卡，toast 确认。
    final yesterday = today.addDays(-1);
    final yesterdayCell = find.descendant(
        of: find.widgetWithText(GestureDetector, '周${yesterday.weekday.zhLabel}'),
        matching: find.text('${yesterday.day}'));
    await tester.tap(yesterdayCell.first);
    await tester.pumpAndSettle();

    expect(find.text(Copy.backfillDone(yesterday.isoString)), findsOneWidget);
    final saved = await CheckInRepository(db).all();
    expect(
        saved.where((c) =>
            c.day == yesterday && c.isValid && c.isBackfill),
        isNotEmpty);

    // 同一天已有有效打卡 → 格子不可重复补。
    await tester.tap(yesterdayCell.first);
    await tester.pump();
    expect((await CheckInRepository(db).all()).where((c) => c.isValid), hasLength(1));
    await db.close();
  });
}
