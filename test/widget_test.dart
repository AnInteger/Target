// App Shell 冒烟测试（T014 + T022）：内存库启动 → 空库首启进引导页（SC-001）。
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/app/router.dart';
import 'package:target/features/goals/goal_detail.dart';
import 'package:target/features/goals/goal_editor.dart';
import 'package:target/features/goals/goal_templates.dart';
import 'package:target/core/backup/backup_exporter.dart';
import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart'
    show AppDatabase, SettingsRowsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/models/goal_icon_catalog.dart';
import 'package:target/core/platform/gateways.dart';

import 'version_seed.dart';

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

/// 测试假分享网关：记录导出、零平台副作用。
class FakeShareGateway implements ShareGateway {
  final exported = <String>[];

  @override
  Future<void> shareText(String text) async {}

  @override
  Future<void> exportFile({
    required String fileName,
    required List<int> bytes,
    required String mime,
  }) async {
    exported.add(fileName);
  }
}

/// 测试假文件选择：固定返回预置备份字节。
class FakeFilePickGateway implements FilePickGateway {
  FakeFilePickGateway(this.bytes);

  final List<int> bytes;

  @override
  Future<PickedFile?> pickBackupFile() async =>
      PickedFile(name: 'backup.targetbackup', bytes: bytes);
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

  /// 编辑器表单长于视口：交互前滚到目标可点（已可点则跳过）。
  /// scrollUntilVisible 只要控件"被构建"就停——中心可能仍在屏外，tap 会落空；
  /// 这里用 hitTestable 判定逐轮拖动（先向下，找不到再向上兜底）。
  /// Scrollable.first = 页面主 ListView。
  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 40; i++) {
      if (f.hitTestable().evaluate().isNotEmpty) return;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pump();
    }
    for (var i = 0; i < 40; i++) {
      if (f.hitTestable().evaluate().isNotEmpty) return;
      await tester.drag(scrollable, const Offset(0, 200));
      await tester.pump();
    }
    fail('滚动后仍找不到: $f');
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

    // TodayView 空态（R7）：节头隐藏 + 虚线邀请卡（正式语域）。
    expect(find.text(Copy.todayEmptyTitle), findsOneWidget);
    expect(find.text(Copy.todaySection), findsNothing);
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
        goalType: GoalType.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: today,
      ),
    );
    await seedVersion(db, 
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

    // R7 统一卡：整卡可点进详情，卡上无打卡钮。
    expect(find.text(Copy.todayRecordedNote(0, 1)), findsOneWidget);
    expect(find.bySemanticsLabel(Copy.todayCheckAction), findsNothing);
    await tester.tap(find.text('锻炼'));
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);

    // 详情页打卡（T017 保障段动线）→ toast + 落库。
    await tester.tap(find.text(Copy.todayCheckAction));
    await tester.pumpAndSettle();
    expect(find.text(Copy.checkInDone), findsOneWidget);
    expect((await CheckInRepository(db).all()).where((c) => c.isValid),
        hasLength(1));

    // 返回今日 → 节注刷新 + 全完成绽放（单目标）。
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Copy.todayRecordedNote(1, 1)), findsOneWidget);
    expect(find.text(Copy.celebrationTitle), findsOneWidget);

    // 撤销（toast 在根 ScaffoldMessenger，跨路由存活）→ 统计即时回退。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    expect(find.text(Copy.todayRecordedNote(0, 1)), findsOneWidget);
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
        goalType: GoalType.habit,
        iconKey: icon,
        colorKey: color,
        createdAt: today,
      ));
      await seedVersion(db, g.id, const DailyFrequency(1), WeekStart.containing(today));
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

    // R7 动线：整卡进详情打卡。先只记锻炼 → 部分进展，不绽放。
    await tester.tap(find.text('锻炼'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.todayCheckAction));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Copy.todayRecordedNote(1, 2)), findsOneWidget);
    expect(find.text(Copy.celebrationTitle), findsNothing);

    // 补上阅读 → 上升沿，全屏成就时刻。
    await tester.tap(find.text('阅读'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.todayCheckAction));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Copy.todayRecordedNote(2, 2)), findsOneWidget);
    expect(find.text(Copy.celebrationTitle), findsOneWidget);

    // 点按屏幕中央 → 退场（淡出后内容摘树）。
    await tester.tapAt(const Offset(195, 422));
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsNothing);

    // 撤销阅读（toast 在根 ScaffoldMessenger，跨路由存活）→ 离开全完成
    // 态（重臂）→ 再进详情记一笔 → 再次绽放。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    await tester.tap(find.text('阅读'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.todayCheckAction));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsOneWidget);
    await db.close();
  });


  testWidgets('T023 骨架：分组平铺+保存常驻+改型联动显隐+零行为说明句（FR-011/014/021）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light(), home: const GoalEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 三组标题平铺在场（分类置顶，R2 裁决 1）+ 保存常驻（R3 裁决 2）。
    expect(find.text(Copy.editorSectionCategory), findsOneWidget);
    expect(find.text(Copy.editorSectionBasics), findsOneWidget);
    expect(find.text(Copy.editorSectionType), findsOneWidget);
    expect(find.text(Copy.editorSave), findsOneWidget);

    // 默认短期：截止日行在场、提醒开关不渲染。
    expect(find.text(Copy.editorDeadlineLabel), findsOneWidget);
    expect(find.byKey(const ValueKey('goalRemindSwitch')), findsNothing);

    // 切习惯：截止让位提醒开关，习惯默认开（原型画板③）。
    await tester.tap(find.text(Copy.typeBadgeHabit));
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorDeadlineLabel), findsNothing);
    expect(find.byKey(const ValueKey('goalRemindSwitch')), findsOneWidget);
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch'))).value,
      isTrue,
    );

    // 切长期：提醒默认关。
    await tester.tap(find.text(Copy.typeBadgeLongTerm));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch'))).value,
      isFalse,
    );

    // B 案字段与行为说明句全退役（FR-014 / R3 裁决 3）。
    expect(find.text(Copy.editorWhyLabel), findsNothing);
    expect(find.text(Copy.editorCriterionLabel), findsNothing);
    expect(find.text(Copy.editorCueLabel), findsNothing);
    expect(find.text(Copy.editorIconColor), findsNothing);

    // 内容滚出视口后保存按钮仍在场（常驻底部，ListView 外）。
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorSave), findsOneWidget);
    await db.close();
  });

  testWidgets('T023 创建动线：一句话 → 默认短期直接保存落库（B 案字段无写入路径）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          navigatorKey: navKey,
          home: const Scaffold(body: Text('root')),
        ),
      ),
    );
    navKey.currentState!.push(MaterialPageRoute(
        fullscreenDialog: true, builder: (_) => const GoalEditorPage()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('goalNameField')), '三个月内考过日语 N2');
    await tester.pump();

    // 默认短期：截止日带默认值（today+39），直接保存即落库。
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    expect(find.text('root'), findsOneWidget); // 保存后返回

    final g = (await GoalRepository(db).getGoals()).single;
    expect(g.goalType, GoalType.shortTerm);
    expect(g.deadline, LocalDate.fromDateTime(DateTime.now()).addDays(39));
    expect(g.motivation, isNull); // FR-014：为什么/怎样算无写入路径
    expect(g.successCriterion, isNull);
    expect(g.cueScene, isNull);
    await db.close();
  });

  testWidgets('T023 编辑同构：类型可改，deadline 随型成对获值/清空（ui-contract）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(Goal(
      name: '规律运动',
      goalType: GoalType.habit,
      iconKey: 'directions_run',
      colorKey: 'teal',
      createdAt: today,
    ));
    final navKey = GlobalKey<NavigatorState>();
    Future<void> openEditor() async {
      navKey.currentState!.push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => GoalEditorPage(goalId: goal.id)));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          navigatorKey: navKey,
          home: const Scaffold(body: Text('root')),
        ),
      ),
    );

    // 第一轮：习惯 → 长期（提醒区在场）→ 短期，保存 = 改型 + 截止成对获值。
    await openEditor();
    expect(find.byKey(const ValueKey('goalRemindSwitch')), findsOneWidget);
    await tester.tap(find.text(Copy.typeBadgeLongTerm));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.typeBadgeShortTerm));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    var g = (await repo.getGoals()).single;
    expect(g.goalType, GoalType.shortTerm);
    expect(g.deadline, today.addDays(39));
    expect(g.iconKey, 'directions_run'); // 未动字段原值继承

    // 第二轮：短期 → 习惯，保存 = deadline 成对清空。
    await openEditor();
    await tester.tap(find.text(Copy.typeBadgeHabit));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    g = (await repo.getGoals()).single;
    expect(g.goalType, GoalType.habit);
    expect(g.deadline, isNull);
    await db.close();
  });

  testWidgets('T024 基础信息：一句话 40 字上限+完整短句示范，无心理字段（FR-014/D8）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light(), home: const GoalEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('goalNameField'));
    final tf = tester.widget<TextField>(field);
    expect(tf.maxLength, 40); // research D8：~40 字上限
    expect(tf.decoration?.hintText, Copy.editorNameHint); // 完整短句示范

    // 超长输入截到 40 字（frame 层强制）。
    await tester.enterText(field, '字' * 45);
    expect((tester.widget(field) as TextField).controller!.text.length, 40);

    // 「为什么想做 / 怎样算做到」字段与写入路径不存在（FR-014）。
    expect(find.byKey(const ValueKey('goalWhyField')), findsNothing);
    expect(find.byKey(const ValueKey('goalCriterionField')), findsNothing);
    expect(find.text(Copy.editorWhyLabel), findsNothing);
    expect(find.text(Copy.editorCriterionLabel), findsNothing);
    await db.close();
  });

  testWidgets('T025 提醒组：习惯默认开→三档→保存写 Reminders；关开关不建行（FR-013）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          navigatorKey: navKey,
          home: const Scaffold(body: Text('root')),
        ),
      ),
    );

    Future<void> openEditor() async {
      navKey.currentState!.push(MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => const GoalEditorPage()));
      await tester.pumpAndSettle();
    }

    // 习惯型：开关默认开 → 频率档（默认一天一次）+ 时间行（默认 09:00）。
    await openEditor();
    await tester.enterText(
        find.byKey(const ValueKey('goalNameField')), '睡前读 5 页书');
    await tester.tap(find.text(Copy.typeBadgeHabit));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch'))).value,
      isTrue,
    );
    expect(find.byKey(const ValueKey('goalCadenceSeg')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalRemindTimeField')), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<Cadence>>(
              find.byKey(const ValueKey('goalCadenceSeg')))
          .selected,
      {Cadence.daily},
    );

    // 切「三天一次」→ 保存 → Reminders 行（enabled/threeDay/09:00/goalId）。
    await scrollTo(tester, find.text(Copy.cadenceThreeDay));
    await tester.tap(find.text(Copy.cadenceThreeDay));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    final goals = await GoalRepository(db).getGoals();
    final rows = await ReminderRepository(db).all();
    expect(rows, hasLength(1));
    expect(rows.single.goalId, goals.single.id);
    expect(rows.single.isEnabled, isTrue);
    expect(rows.single.cadence, Cadence.threeDay);
    expect(rows.single.time, const LocalTime(9, 0));

    // 长期型：默认关；手动开 → 默认一天一次档。
    await openEditor();
    await tester.enterText(
        find.byKey(const ValueKey('goalNameField')), '把冈仁波齐走完');
    await tester.tap(find.text(Copy.typeBadgeLongTerm));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch'))).value,
      isFalse,
    );
    expect(find.byKey(const ValueKey('goalCadenceSeg')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('goalRemindSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    final rows2 = await ReminderRepository(db).all();
    expect(rows2, hasLength(2));
    expect(rows2.last.isEnabled, isTrue);
    expect(rows2.last.cadence, Cadence.daily);

    // 习惯型但开关关 → 不建行。
    await openEditor();
    await tester.enterText(
        find.byKey(const ValueKey('goalNameField')), '好好吃饭');
    await tester.tap(find.text(Copy.typeBadgeHabit));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalRemindSwitch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalCadenceSeg')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    expect(await ReminderRepository(db).all(), hasLength(2));
    await db.close();
  });

  testWidgets('T025 编辑回填提醒行 + 改型短期删行（goal-type-model 口径）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final goal = await GoalRepository(db).create(Goal(
      name: '规律运动',
      goalType: GoalType.habit,
      iconKey: 'directions_run',
      colorKey: 'teal',
      createdAt: today,
    ));
    final reminderId = (await ReminderRepository(db).upsert(Reminder(
      goalId: goal.id,
      time: const LocalTime(21, 30),
      isEnabled: true,
      cadence: Cadence.threeDay,
    )))
        .id;
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          navigatorKey: navKey,
          home: const Scaffold(body: Text('root')),
        ),
      ),
    );

    Future<void> openEditor() async {
      navKey.currentState!.push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => GoalEditorPage(goalId: goal.id)));
      await tester.pumpAndSettle();
    }

    // 回填：开关开、时间 21:30、档=三天一次。
    await openEditor();
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch'))).value,
      isTrue,
    );
    expect(find.text('21:30'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<Cadence>>(
              find.byKey(const ValueKey('goalCadenceSeg')))
          .selected,
      {Cadence.threeDay},
    );

    // 不动保存 → 原行续写（同 id，不重复建行）。
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    final rows = await ReminderRepository(db).all();
    expect(rows, hasLength(1));
    expect(rows.single.id, reminderId);

    // 改型短期 → cadence 恒不适用 → 行删除。
    await openEditor();
    await tester.tap(find.text(Copy.typeBadgeShortTerm));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    expect(await ReminderRepository(db).all(), isEmpty);
    await db.close();
  });

  testWidgets('T025 短期截止行：倒计时预告在场，tap 弹日期选择器（FR-012）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const GoalEditorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 创建态默认 today+39 → 倒计时预告。
    expect(find.text(Copy.editorCountdownPreview(39)), findsOneWidget);

    // tap 截止行 → 系统日期选择器弹出，确认关闭后预告仍在。
    await tester.tap(find.byKey(const ValueKey('goalDeadlineField')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byKey(const ValueKey('goalCountdownPreview')), findsOneWidget);

    // 提醒时间选择器（习惯型开关开后）。
    await tester.tap(find.text(Copy.typeBadgeHabit));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('goalRemindTimeField')));
    await tester.tap(find.byKey(const ValueKey('goalRemindTimeField')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('09:00'), findsOneWidget); // 取消不改值
    await db.close();
  });

  testWidgets('T026 分类组：常用行 6 枚 + 「更多」弹窗全量按域分组，单选即存 iconKey（FR-011/015）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const GoalEditorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 无颜色步：表单不出现任何颜色选择（FR-015）。
    expect(find.text(Copy.editorIconColor), findsNothing);

    // 常用行 6 枚策展（原型 COMMON_ICONS）+「更多」格在场。
    const commonKeys = [
      'fitness_center', 'menu_book', 'favorite',
      'self_improvement', 'brush', 'savings',
    ];
    for (final k in commonKeys) {
      expect(find.byIcon(GoalIconCatalog.byKey(k).icon), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('goalIconMoreButton')), findsOneWidget);

    // 点常用格 → 保存落库该 iconKey。
    await tester.enterText(find.byKey(const ValueKey('goalNameField')), '读点书');
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    final created = (await GoalRepository(db).getGoals()).single;
    expect(created.iconKey, 'menu_book');

    // 编辑 → 「更多」弹窗：标题 + 领域分组标签 + 全量 38 枚（含非常用 flight）。
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          navigatorKey: navKey,
          home: const Scaffold(body: Text('root')),
        ),
      ),
    );
    navKey.currentState!.push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GoalEditorPage(goalId: created.id)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('goalIconMoreButton')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorPickCategoryTitle), findsOneWidget);
    expect(find.text(GoalIconDomain.travel.zhLabel), findsOneWidget);
    for (final icon in GoalIconCatalog.values) {
      expect(find.byIcon(icon.icon), findsWidgets);
    }

    // ✕ 关闭不选 → iconKey 不变。
    await tester.tap(find.byKey(const ValueKey('goalIconPickerClose')));
    await tester.pumpAndSettle();
    expect((await GoalRepository(db).getGoals()).single.iconKey, 'menu_book');

    // 弹窗选非常用图标 flight（旅行域）→ 点选即关 → 保存落库 flight。
    await tester.tap(find.byKey(const ValueKey('goalIconMoreButton')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byIcon(Icons.flight_rounded));
    await tester.tap(find.byIcon(Icons.flight_rounded));
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorPickCategoryTitle), findsNothing); // 点选即关
    await scrollTo(tester, find.byKey(const ValueKey('goalSaveButton')));
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    expect((await GoalRepository(db).getGoals()).single.iconKey, 'flight');
    await db.close();
  });

  test('T027 模板策展：三类型齐备 + iconKey 全 v3 值域 + 无颜色/频率载荷', () {
    // 三类型都有代表模板（003 三类型语言）。
    expect(kHabitTemplates, isNotEmpty);
    expect(kHabitTemplates.every((t) => t.goalType == GoalType.habit), isTrue);
    expect(kMilestoneTemplates.map((t) => t.goalType).toSet(),
        {GoalType.shortTerm, GoalType.longTerm});
    // 图标键全部落在 v3 目录（不靠 byKey 兜底即命中）。
    for (final t in kAllTemplates) {
      expect(GoalIconCatalog.values.any((i) => i.key == t.iconKey), isTrue,
          reason: '「${t.name}」图标键 ${t.iconKey} 不在 v3 目录');
      expect(t.name.length, lessThanOrEqualTo(40));
    }
  });

  testWidgets('US1 路由三分支：页签恰三枚、目标页签退役（FR-001）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 三页签恰三枚：今日/回顾/我的；目标页签不再存在。
    expect(find.text(Copy.todayNav), findsOneWidget);
    expect(find.text(Copy.reviewNav), findsOneWidget);
    expect(find.text(Copy.mineNav), findsOneWidget);
    expect(find.text(Copy.goalsNav), findsNothing);
    await db.close();
  });

  testWidgets('US1 编辑器/详情落 today 分支：导航不退场 + /goals 兜底（FR-010）',
      (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(
      tester.element(find.byType(TargetApp)),
      listen: false,
    ).read(routerProvider);
    router.go('/goal-editor');
    await tester.pumpAndSettle();
    // 编辑器整页在场而底部三页签仍可见（today 分支子页，非根路由全屏）。
    expect(find.byKey(const ValueKey('goalNameField')), findsOneWidget);
    expect(find.text(Copy.todayNav), findsOneWidget);
    expect(find.text(Copy.mineNav), findsOneWidget);

    // 存量 /goals 入口兜底落回今日（redirect）。
    router.go('/goals');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalNameField')), findsNothing);
    expect(find.text(Copy.todayNav), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/today');

    // 深链：goal 无 id 兜底 /today；带 id 落详情（today 分支）。
    expect(mapDeepLink(Uri.parse('target://goal')), '/today');
    expect(mapDeepLink(Uri.parse('target://goal/g1')), '/goal/g1');

    await db.close();
  });

  testWidgets('T021 详情：头部块/管理入口 + 打卡描述落库 + 历史行兜底 + 短期倒计时步骤',
      (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(Goal(
      name: '年底前跑一次 10km',
      goalType: GoalType.shortTerm,
      iconKey: 'fitness',
      colorKey: 'sage',
      createdAt: today,
      deadline: LocalDate(today.year, 12, 31),
      motivation: '为了夏天的约定',
      successCriterion: '完成一次 10km',
      cueScene: '早起后',
    ));
    await repo.addStep(
        MilestoneStep(id: 's1', goalId: goal.id, title: '买跑鞋'));
    // 昨日一条无描述打卡 → 历史行兜底「完成打卡」。
    await CheckInRepository(db)
        .add(goal.id, today.addDays(-1), DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
            theme: AppTheme.light(), home: GoalDetailPage(goalId: goal.id)),
      ),
    );
    await tester.pumpAndSettle();

    // 头部块：描述 + 类型徽章 + 提醒行；退役字段（为什么/怎样算）不上屏。
    expect(find.text('年底前跑一次 10km'), findsWidgets);
    expect(
        find.text(
            '${Copy.typeBadgeShortTerm} · ${Copy.milestoneCountdown(LocalDate(today.year, 12, 31).differenceInDays(today))}'),
        findsOneWidget);
    expect(find.text(Copy.goalReminderLine('早起后')), findsOneWidget);
    expect(find.text('为了夏天的约定'), findsNothing);
    expect(find.text('完成一次 10km'), findsNothing);
    expect(find.text('买跑鞋'), findsOneWidget);
    // 昨日记录：无描述 → 兜底文案。
    expect(
        find.text('${Copy.notifDayYesterday} - ${Copy.checkInDefaultNote}'),
        findsOneWidget);

    // 打卡动线：填描述 → 落库 note + 历史行「今天 - 描述」。
    await tester.enterText(
        find.byKey(const ValueKey('checkInNoteField')), '报名了首场比赛');
    await tester.tap(find.text(Copy.todayCheckAction));
    await tester.pumpAndSettle();
    expect(find.text(Copy.checkInDone), findsOneWidget);
    final saved = await CheckInRepository(db).all();
    expect(saved.where((c) => c.day == today).single.note, '报名了首场比赛');
    expect(find.text('${Copy.notifDayToday} - 报名了首场比赛'), findsOneWidget);

    // ⋯ 动作面板：暂停 → 状态行出现 + 打卡动线隐藏；恢复回 active。
    await tester.tap(find.byTooltip(Copy.goalMoreActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暂停'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.goalsPausedNote), findsOneWidget);
    expect(find.byKey(const ValueKey('checkInNoteField')), findsNothing);
    await tester.tap(find.byTooltip(Copy.goalMoreActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checkInNoteField')), findsOneWidget);

    // 加一步：输入回车入库（加一步输入框以 hint 定位）。
    await tester.enterText(
        find.widgetWithText(TextFormField, Copy.milestoneStepHint), '报名比赛');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect((await repo.stepsOf(goal.id)).length, 2);

    // 勾选第一步（步骤名是可编辑框，直接点复选框）→ done/total 变 1/2。
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('1/2'), findsOneWidget);
    await db.close();
  });

  testWidgets('T021 极简详情不空：仅名称的长期目标仍有完整头部骨架', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(Goal(
      name: '把英语捡回来',
      goalType: GoalType.longTerm,
      iconKey: 'read',
      colorKey: 'sky',
      createdAt: today,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
            theme: AppTheme.light(), home: GoalDetailPage(goalId: goal.id)),
      ),
    );
    await tester.pumpAndSettle();

    // 无提醒/无记录：头部仍呈现 图标 + 描述 + 「∞ 长期」徽章 + 打卡动线。
    expect(find.text('把英语捡回来'), findsWidgets);
    expect(find.text(Copy.typeBadgeLongTerm), findsOneWidget);
    expect(find.byKey(const ValueKey('checkInNoteField')), findsOneWidget);
    expect(find.byTooltip(Copy.goalEdit), findsOneWidget);
    expect(find.byTooltip(Copy.goalMoreActions), findsOneWidget);
    await db.close();
  });

  testWidgets('T019 V1 创建双路径：引导选模板 → 编辑器预填 → 落库 + 今日可见', (tester) async {
    usePhoneSurface(tester);
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

    // 模板路径：引导页选「饭后散步 20 分钟」→ 统一编辑器预填名称（自定义路径即不选模板直接写）。
    await tester.tap(find.text('饭后散步 20 分钟'));
    await tester.pumpAndSettle();
    final nameField = find.byKey(const ValueKey('goalNameField'));
    expect((tester.widget(nameField) as TextField).controller!.text,
        '饭后散步 20 分钟');

    // 003 动线：预填即保存（模板带习惯型；B 案为什么字段已退役）。
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    // 引导视为完成 → 今日页出现该目标（V1：模板+确认即首个目标）。
    final goals = await GoalRepository(db).getGoals();
    expect(goals.single.name, '饭后散步 20 分钟');
    expect(goals.single.goalType, GoalType.habit);
    expect(goals.single.iconKey, 'directions_run'); // 模板带 v3 图标键
    expect(goals.single.motivation, isNull);
    expect((await SettingsRepository(db).get()).onboardingCompleted, true);
    expect(find.text(Copy.onboardingTitle), findsNothing);
    expect(find.text('饭后散步 20 分钟'), findsWidgets);
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
        goalType: GoalType.habit,
        iconKey: 'meal',
        colorKey: 'coral',
        createdAt: today,
      ),
    );
    await seedVersion(db, 
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

    // 长按目标卡 → 弹出补签日历（过去两周）。R7 统一卡不含图标中文名，
    // 目标名在今日页唯一。
    await tester.longPress(find.text('好好吃饭'));
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

  testWidgets('T021 周回顾 R3：纯回看语言——周摘要/图例/节奏条/观察语，无决策控件',
      (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final lastWeek = today.weekStart.previous;
    final repo = GoalRepository(db);
    final checkIns = CheckInRepository(db);

    // 三周前立的习惯，上周 7 天适用、留下 4 次（一/二/四/五）。
    final createdAt = today.addDays(-21);
    final goal = await repo.create(
      Goal(
        name: '锻炼',
        goalType: GoalType.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: createdAt,
      ),
    );
    await seedVersion(db, 
      goal.id,
      const DailyFrequency(1),
      WeekStart.containing(createdAt),
    );
    for (final d in [0, 1, 3, 4]) {
      await checkIns.add(goal.id, lastWeek.monday.addDays(d), DateTime.now());
    }
    // 第二个习惯：上周只留 1 次（低档观察语 + 横滑第二卡）。
    final goal2 = await repo.create(
      Goal(
        name: '读书',
        goalType: GoalType.habit,
        iconKey: 'book',
        colorKey: 'teal',
        createdAt: createdAt,
      ),
    );
    await seedVersion(db, 
      goal2.id,
      const DailyFrequency(1),
      WeekStart.containing(createdAt),
    );
    await checkIns.add(goal2.id, lastWeek.monday.addDays(5), DateTime.now());
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

    // 切到回顾页签。
    await tester.tap(find.text(Copy.reviewNav));
    await tester.pumpAndSettle();

    // 周摘要 + 三态图例 + N/M 节奏数（努力语言，无完成率百分比）。
    expect(find.text(Copy.reviewTitle), findsOneWidget);
    expect(find.text(Copy.reviewWeekSum(5, 2)), findsOneWidget);
    expect(find.text(Copy.reviewLegendRecorded), findsOneWidget);
    expect(find.text(Copy.reviewLegendMissed), findsOneWidget);
    expect(find.text(Copy.reviewLegendNa), findsOneWidget);
    expect(find.text('4/7'), findsOneWidget);
    expect(find.text(Copy.goalsDaysRecorded), findsOneWidget);
    // 观察语（okay 档，4/7 = 57%）。
    expect(find.text(Copy.reviewCoachOkay), findsOneWidget);
    // R3 裁决：决策动线与保存不再上屏。
    expect(find.textContaining('下周怎么走'), findsNothing);
    expect(find.textContaining('记下这一周'), findsNothing);

    // 横滑到第二卡：低档观察语（1/7 = 14%）。
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('读书'), findsOneWidget);
    expect(find.text('1/7'), findsOneWidget);
    expect(find.text(Copy.reviewCoachLow), findsOneWidget);
    await db.close();
  });

  testWidgets(
      'T026 设置 R2 + V7 备份回归：身份卡/提醒/隐私脚注 + 导出 toast + 冲突弹层 → 覆盖 → 计数 toast',
      (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final createdAt = today.addDays(-7);
    final goal = await repo.create(Goal(
      name: '锻炼',
      goalType: GoalType.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      createdAt: createdAt,
    ));
    await seedVersion(db, 
        goal.id, const DailyFrequency(1), WeekStart.containing(createdAt));
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );

    // V7 往返：备份文件 = 从同一库导出的 JSON。
    final backupJson = await BackupExporter(db).exportString();
    final sharer = FakeShareGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(gateway),
          shareGatewayProvider.overrideWithValue(sharer),
          filePickGatewayProvider
              .overrideWithValue(FakeFilePickGateway(utf8.encode(backupJson))),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Copy.mineNav));
    await tester.pumpAndSettle();

    // R2 骨架：身份卡（无目标统计）+ 概要行副文 + 场景指引 + 隐私脚注。
    // 标题「我的」与底部 nav 标签同文，断言至少一处即可。
    expect(find.text(Copy.settingsTitle), findsWidgets);
    expect(find.text(Copy.settingsMeName), findsOneWidget);
    expect(find.text(Copy.dailyBriefSub), findsOneWidget);
    expect(find.text(Copy.reminderGoalHint), findsOneWidget);
    expect(find.text(Copy.privacyFoot), findsOneWidget);
    // 聚焦 App 本身：目标内容不上设置屏（旧版逐目标提醒行已删）。
    expect(find.text('锻炼'), findsNothing);

    // V7 导出：走分享网关 + 备份已生成 toast。
    await scrollTo(tester, find.text(Copy.backupExport));
    await tester.tap(find.text(Copy.backupExport));
    await tester.pumpAndSettle();
    expect(sharer.exported.length, 1);
    expect(find.text(Copy.backupExported), findsOneWidget);

    // V7 导入：本地有数据 → 必显式确认，不静默合并（FR-015）。
    await tester.pump(const Duration(seconds: 4)); // 等 toast 退场
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(Copy.backupImport));
    await tester.tap(find.text(Copy.backupImport));
    await tester.pumpAndSettle();
    expect(find.text(Copy.backupImportConflictTitle), findsOneWidget);
    await tester.tap(find.text(Copy.backupImportOverwrite));
    await tester.pumpAndSettle();
    expect(find.textContaining(Copy.backupImportDone), findsOneWidget);
    expect(find.textContaining('目标 1'), findsOneWidget);
    await db.close();
  });
}
