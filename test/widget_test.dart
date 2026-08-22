// App Shell 冒烟测试（T014 + T022）：内存库启动 → 空库首启进引导页（SC-001）。
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/providers.dart';
import 'package:target/features/goals/goal_detail.dart';
import 'package:target/features/goals/goal_editor.dart';
import 'package:target/core/backup/backup_exporter.dart';
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
        goalType: GoalType.habit,
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
        goalType: GoalType.habit,
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
    final nameField = find.byKey(const ValueKey('goalNameField'));
    await tester.enterText(nameField, '变健康');
    await tester.pumpAndSettle();
    expect(find.text(Copy.smartSuggest('每天散步 20 分钟')), findsOneWidget);

    // 一键采用 → 名称被替换为具体表述，chip 随之消失；
    // 未手改过的「怎样算做到」随名称自动重拟（T014 B 案）。
    await tester.tap(find.text(Copy.smartApply));
    await tester.pumpAndSettle();
    expect(
      (tester.widget(nameField) as TextField).controller!.text,
      '每天散步 20 分钟',
    );
    final criterionField = find.byKey(const ValueKey('goalCriterionField'));
    await scrollTo(tester, criterionField);
    expect(
      (tester.widget(criterionField) as TextField).controller!.text,
      '每天散步 20 分钟',
    );
    expect(find.text(Copy.smartSuggest('每天散步 20 分钟')), findsNothing);
    await db.close();
  });

  testWidgets('T017 B 案创建动线：为什么必填拦截 → 场景/一次性 → 落库含新维度', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('root')),
        ),
      ),
    );
    navKey.currentState!.push(MaterialPageRoute(
        fullscreenDialog: true, builder: (_) => const GoalEditorPage()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('goalNameField')), '变健康');
    await tester.pump();

    // 一次性开关（表单序在频率之后、「为什么」之前）→ 频率让位截止日快选。
    await scrollTo(tester, find.text(Copy.editorOnceLabel));
    await tester.tap(find.text(Copy.editorOnceLabel));
    await tester.pump();
    expect(find.text(Copy.editorDdlThisYear), findsOneWidget);
    expect(find.text('每天'), findsNothing); // 频率分段按钮已隐去

    // 「为什么」为空直接保存 → 行内错误，不落库。
    await scrollTo(tester, find.text(Copy.editorSaveCreate));
    await tester.tap(find.text(Copy.editorSaveCreate));
    await tester.pump();
    expect(find.text(Copy.editorWhyRequired), findsOneWidget);
    expect(await GoalRepository(db).getGoals(), isEmpty);

    // 补一句为什么 + 选提醒场景（预览文案出现）。
    final whyField = find.byKey(const ValueKey('goalWhyField'));
    await scrollTo(tester, whyField);
    await tester.enterText(whyField, '为了晚上不胃胀');
    await scrollTo(tester, find.text('晚饭后'));
    await tester.tap(find.text('晚饭后'));
    await tester.pump();
    expect(find.text(Copy.editorCuePreview('晚饭后')), findsOneWidget);

    await scrollTo(tester, find.text(Copy.editorSaveCreate));
    await tester.tap(find.text(Copy.editorSaveCreate));
    await tester.pumpAndSettle();
    expect(find.text('root'), findsOneWidget); // 保存后返回

    final g = (await GoalRepository(db).getGoals()).single;
    expect(g.goalType, GoalType.shortTerm);
    expect(g.deadline, const LocalDate(2026, 12, 31));
    expect(g.motivation, '为了晚上不胃胀');
    expect(g.successCriterion, '每天散步 20 分钟'); // 未手改 → 按名称自动拟
    expect(g.cueScene, '晚饭后');
    await db.close();
  });

  testWidgets('T017 列表语言：为什么第二行 + 渐进补全邀请 + 暂停恢复', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final eat = await repo.create(Goal(
      name: '好好吃饭',
      goalType: GoalType.habit,
      iconKey: 'meal',
      colorKey: 'coral',
      createdAt: today,
      motivation: '为了晚上不胃胀',
      cueScene: '晚饭后',
    ));
    await repo.addInitial(
        eat.id, const DailyFrequency(1), WeekStart.containing(today));
    final sleep = await repo.create(Goal(
      name: '早睡',
      goalType: GoalType.habit,
      iconKey: 'sleep',
      colorKey: 'indigo',
      createdAt: today,
    ));
    await repo.addInitial(
        sleep.id, const DailyFrequency(1), WeekStart.containing(today));
    final sport = await repo.create(Goal(
      name: '规律运动',
      goalType: GoalType.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      createdAt: today,
      status: GoalStatus.paused,
    ));
    await repo.addInitial(
        sport.id, const WeeklyFrequency(3), WeekStart.containing(today));
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
    await tester.tap(find.text(Copy.goalsNav));
    await tester.pumpAndSettle();

    // 第二行「为什么」带出；空维度目标显虚线邀请（点卡片即渐进补全入口）。
    expect(find.text('为了晚上不胃胀'), findsOneWidget);
    expect(find.text(Copy.goalsInviteWhy), findsOneWidget);
    // 暂停区：虚线行 + 记录保留说明（与目标名拼为一行）+ 恢复按钮。
    expect(find.textContaining(Copy.goalsPausedNote), findsOneWidget);
    expect(find.text(Copy.goalsResume), findsOneWidget);

    await tester.tap(find.text(Copy.goalsResume));
    await tester.pumpAndSettle();
    expect(find.textContaining(Copy.goalsPausedNote), findsNothing);
    // R2 列表语言：分节头「进行中 N/5」被小结行「N 个目标 · 本周…」取代。
    expect(find.textContaining('3 个目标'), findsOneWidget);
    await db.close();
  });

  testWidgets('T018 统一详情：这一诺呈现 + 一次性倒计时 + 步骤增改勾', (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(home: GoalDetailPage(goalId: goal.id)),
      ),
    );
    await tester.pumpAndSettle();

    // 这一诺：动机/成功标准/提醒场景 + 倒计时 + 已有步骤。
    expect(find.text(Copy.goalVowLabel), findsOneWidget);
    expect(find.text('为了夏天的约定'), findsOneWidget);
    expect(find.text('完成一次 10km'), findsOneWidget);
    expect(find.text('早起后'), findsOneWidget);
    expect(
        find.text(Copy.milestoneCountdown(
            LocalDate(today.year, 12, 31).differenceInDays(today))),
        findsOneWidget);
    expect(find.text('买跑鞋'), findsOneWidget);

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

    // 模板路径：引导页选「好好吃饭」→ 统一编辑器预填名称（自定义路径即不选模板直接写）。
    await tester.tap(find.text('好好吃饭'));
    await tester.pumpAndSettle();
    final nameField = find.byKey(const ValueKey('goalNameField'));
    expect((tester.widget(nameField) as TextField).controller!.text, '好好吃饭');

    // B 案：补一句为什么 → 立下这个心愿。
    final whyField = find.byKey(const ValueKey('goalWhyField'));
    await scrollTo(tester, whyField);
    await tester.enterText(whyField, '为了晚上不胃胀');
    await scrollTo(tester, find.text(Copy.editorSaveCreate));
    await tester.tap(find.text(Copy.editorSaveCreate));
    await tester.pumpAndSettle();

    // 引导视为完成 → 今日页出现该目标（V1：模板+确认即首个目标）。
    final goals = await GoalRepository(db).getGoals();
    expect(goals.single.name, '好好吃饭');
    expect(goals.single.goalType, GoalType.habit);
    expect(goals.single.motivation, '为了晚上不胃胀');
    expect((await SettingsRepository(db).get()).onboardingCompleted, true);
    expect(find.text(Copy.onboardingTitle), findsNothing);
    expect(find.text('好好吃饭'), findsWidgets);
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
    await repo.addInitial(
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
    await repo.addInitial(
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
    await repo.addInitial(
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
