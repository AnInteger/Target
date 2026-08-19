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
import 'package:target/core/db/app_database.dart'
    show AppDatabase, SettingsRowsCompanion;
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
  Future<void> scheduleDaily({
    required int id,
    required LocalTime time,
    required String title,
    required String body,
  }) async {
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
  /// 设计以 390×844 手机为基准；默认 800×600 测试窗更矮，仪表盘
  /// 首屏内容（顶栏/大标题/英雄卡）会把目标卡挤出视口（超出缓存
  /// 范围即不构建，find 不可见）。
  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

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
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final settings = await (db.select(db.settingsRows)).get();
    expect(settings, isNotEmpty);
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
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

    // TodayView 空态（新语言）：display 转提问 + 虚线邀请卡，仪表盘整体让位。
    expect(find.text(Copy.todayEmptyTitle), findsOneWidget);
    expect(find.text(Copy.todayNav), findsOneWidget);
    await db.close();
  });

  testWidgets('US2 微缩验收：打卡 → 进度/成就即时刷新 → 撤销回退', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '锻炼',
        kind: GoalKind.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: today,
      ),
    );
    await repo.addInitial(
      goal.id,
      const DailyFrequency(1),
      WeekStart.containing(today),
    );
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );

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

    expect(find.text(Copy.todayPillActions(0)), findsOneWidget);
    // 记录钮的 glyph 是自绘＋/对勾（非 Icons.add），按语义标签定位。
    await tester.tap(find.bySemanticsLabel(Copy.todayCheckAction));
    await tester.pumpAndSettle();

    // 每个目标都有记录 → display 转全部进展态；胶囊与成就徽章副文同串
    // （celebrationNote = todayPillActions），故 findsWidgets。
    expect(find.text(Copy.todayPillActions(1)), findsWidgets);
    expect(find.text(Copy.todayDisplayAllProgress), findsOneWidget);

    // 撤销 → 统计即时回退（R7/SC-003）。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    expect(find.text(Copy.todayPillActions(0)), findsOneWidget);
    await db.close();
  });

  testWidgets('T010 成就时刻：上升沿绽放、点按退场、离开全完成态后重臂（FR-004/R4）',
      (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    for (final (name, icon, color) in [
      ('锻炼', 'fitness', 'sage'),
      ('阅读', 'read', 'teal'),
    ]) {
      final g = await repo.create(Goal(
        name: name,
        kind: GoalKind.habit,
        iconKey: icon,
        colorKey: color,
        createdAt: today,
      ));
      await repo.addInitial(g.id, const DailyFrequency(1), WeekStart.containing(today));
    }
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

    // 两枚记录钮：树序靠前 = 锻炼，靠后 = 阅读。第二卡在 390×844 下
    // 位于底导航之下（已构建但不可命中），先滚动进视口再点。
    final checkButtons = find.bySemanticsLabel(Copy.todayCheckAction);

    // 只记锻炼 → 部分进展，不绽放。
    await tester.tap(checkButtons.first);
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsNothing);

    // 补上阅读 → 上升沿，全屏成就时刻。
    await tester.scrollUntilVisible(
      checkButtons.last,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(checkButtons.last);
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsOneWidget);

    // 点按屏幕中央 → 退场（淡出后内容摘树）。
    await tester.tapAt(const Offset(195, 422));
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsNothing);

    // 撤销阅读 → 离开全完成态（重臂）→ 再记 → 再次绽放。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    await tester.tap(checkButtons.last);
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsOneWidget);
    await db.close();
  });

  testWidgets('US2 忙碌态区分：降档会话活跃 → display 转忙碌 + 横幅在场（FR-018）',
      (tester) async {
    usePhoneSurface(tester);
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
    await repo.addInitial(goal.id, const DailyFrequency(3), WeekStart.containing(today));
    await repo.openSession(
      WeekStart.containing(today),
      [BusyModeEntry(goalId: goal.id, downgraded: const DailyFrequency(1))],
      DateTime.now(),
    );
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

    expect(find.text(Copy.todayDisplayBusy), findsOneWidget);
    expect(find.text(Copy.todayBusyBanner), findsOneWidget);
    expect(find.text(Copy.todayDisplayTypical), findsNothing);
    await db.close();
  });

  testWidgets('FR-001：输入模糊名当场出 SMART 建议，采用即替换（回归：输入需触发刷新）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
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

  testWidgets('V5：长按目标行 → 补签日历 → 补昨日 → 带"补"标记入库（FR-004/R6）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '好好吃饭',
        kind: GoalKind.habit,
        iconKey: 'meal',
        colorKey: 'coral',
        createdAt: today,
      ),
    );
    await repo.addInitial(
      goal.id,
      const DailyFrequency(1),
      WeekStart.containing(today),
    );
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );

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
    // .last：卡内图标中文标签（meal=好好吃饭）与目标名同名，标题在树序靠后。
    await tester.longPress(find.text('好好吃饭').last);
    await tester.pumpAndSettle();
    expect(find.text(Copy.backfillCalendarTitle), findsOneWidget);

    // 点昨天的格子 → 生成 isBackfill=true 的打卡，toast 确认。
    final yesterday = today.addDays(-1);
    final yesterdayCell = find.descendant(
      of: find.widgetWithText(GestureDetector, '周${yesterday.weekday.zhLabel}'),
      matching: find.text('${yesterday.day}'),
    );
    await tester.tap(yesterdayCell.first);
    await tester.pumpAndSettle();

    expect(find.text(Copy.backfillDone(yesterday.isoString)), findsOneWidget);
    final saved = await CheckInRepository(db).all();
    expect(
      saved.where((c) => c.day == yesterday && c.isValid && c.isBackfill),
      isNotEmpty,
    );

    // 同一天已有有效打卡 → 格子不可重复补。
    await tester.tap(yesterdayCell.first);
    await tester.pump();
    expect(
      (await CheckInRepository(db).all()).where((c) => c.isValid),
      hasLength(1),
    );
    await db.close();
  });
}
