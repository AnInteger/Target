// App Shell 冒烟测试（T014 + T022）：内存库启动 → 空库首启进引导页（SC-001）。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy, Value;
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
import 'package:target/features/goals/goals_all_view.dart';
import 'package:target/features/profile/profile.dart';
import 'package:target/features/settings/settings_view.dart';
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

/// 003 T038 终查：v2 存量库（goals 带 kind/envelope、关联表 v2 形态）。
/// 与 migration_test 的 _V2Database 同构——文件库升级启动走真实 onUpgrade。
class _LegacyV2Database extends AppDatabase {
  _LegacyV2Database(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "goals" ("id" TEXT NOT NULL '
        'PRIMARY KEY, "name" TEXT NOT NULL, "kind" TEXT NOT NULL, '
        '"icon_key" TEXT NOT NULL, "color_key" TEXT NOT NULL, '
        '"status" TEXT NOT NULL, "created_at" TEXT NOT NULL, '
        '"deadline" TEXT NULL, "motivation" TEXT NULL, '
        '"success_criterion" TEXT NULL, "cue_scene" TEXT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "reminders" ("id" TEXT NOT NULL '
        'PRIMARY KEY, "goal_id" TEXT NULL, "time" TEXT NOT NULL, '
        '"is_enabled" INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "settings_rows" ("id" INTEGER NOT '
        'NULL PRIMARY KEY, "daily_brief_time" TEXT NOT NULL, '
        '"onboarding_completed" INTEGER NOT NULL, '
        '"notification_denied_acknowledged" INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "frequency_versions" ("id" TEXT NOT '
        'NULL PRIMARY KEY, "goal_id" TEXT NOT NULL, '
        '"effective_from_week" TEXT NOT NULL, "pattern" TEXT NOT NULL, '
        '"source" TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS "check_ins" ("id" TEXT NOT NULL '
        'PRIMARY KEY, "goal_id" TEXT NOT NULL, "day" TEXT NOT NULL, '
        '"created_at" TEXT NOT NULL, "is_backfill" INTEGER NOT NULL, '
        '"status" TEXT NOT NULL)',
      );
      // 其余四表 v1..v4 形态未变——真实用户库九表齐全，App 启动即查，
      // 直接用 Migrator 生成 DDL（缺表会让启动查询抛错挂死）。
      await m.createTable(busyModeSessions);
      await m.createTable(busyModeEntries);
      await m.createTable(milestoneSteps);
      await m.createTable(weeklyReviews);
    },
  );
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

  /// 004 T022：进目标详情的今日页动线——翻到目标所在关注卡并点其
  /// 「记录打卡」白胶囊（露边轮播邻卡 onstage 但不可点，须逐页横滑
  /// 至 hitTestable 再点；卡序 = 最近互动降序，只会向后翻）。
  Future<void> openGoalFromFocus(WidgetTester tester, String goalId) async {
    final card = find.byKey(ValueKey('focusCard-$goalId'));
    // 双向兜底：今日页重进后 PageView 保留页位，目标可能在身后。
    for (final delta in [const Offset(-320, 0), const Offset(320, 0)]) {
      for (var i = 0; i < 12 && card.hitTestable().evaluate().isEmpty; i++) {
        await tester.drag(find.byType(PageView).first, delta);
        await tester.pumpAndSettle();
      }
      if (card.hitTestable().evaluate().isNotEmpty) break;
    }
    expect(card.hitTestable(), findsOneWidget);
    await tester.tap(
      find.descendant(of: card, matching: find.text(Copy.goalCheckInAction)),
    );
    await tester.pumpAndSettle();
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

    // v2 品牌屏：主张 + 单一主行动（无模板/跳过/条款/社交证明）。
    expect(find.text(Copy.onboardingTitle), findsOneWidget);
    expect(find.text(Copy.onboardingSubtitle), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingStart')), findsOneWidget);

    // 「开始使用」即完成引导 → 今日页（SC-005 ≤1 击）。
    await tester.tap(find.byKey(const ValueKey('onboardingStart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect((await SettingsRepository(db).get()).onboardingCompleted, true);
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

    // TodayView 空态（R7）：轮播节头隐藏 + 虚线邀请卡（正式语域）。
    expect(find.text(Copy.todayEmptyTitle), findsOneWidget);
    expect(find.text(Copy.focusSection), findsNothing);
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
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
    await seedVersion(
      db,
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

    // v2 关注卡（003「整卡可点/卡上无钮」裁决退役）：cap 行在场 +
    // 白胶囊主行动在卡上 + 状态标签待办（今日未记录）。
    expect(find.text(Copy.focusSection), findsOneWidget);
    // 单目标：卡上白胶囊即全场唯一「记录打卡」（旧断言语义面在
    // 003 卡上无钮，v2 直接以文本面断言在场）。
    expect(find.text(Copy.goalCheckInAction), findsOneWidget);
    expect(find.text('● ${Copy.focusTagTodo}'), findsOneWidget);
    await openGoalFromFocus(tester, goal.id);
    expect(find.byType(GoalDetailPage), findsOneWidget);

    // 详情页打卡（T017 保障段动线）→ toast + 落库。
    await tester.tap(find.text(Copy.goalCheckInAction));
    await tester.pumpAndSettle();
    expect(find.text(Copy.checkInDone), findsOneWidget);
    expect(
      (await CheckInRepository(db).all()).where((c) => c.isValid),
      hasLength(1),
    );

    // 返回今日 → 状态标签转「进行中」+ 全完成绽放（单目标）。
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('● ${Copy.focusTagActive}'), findsOneWidget);
    expect(find.text(Copy.celebrationTitle), findsOneWidget);

    // 撤销（toast 在根 ScaffoldMessenger，跨路由存活）→ 统计即时回退。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    expect(find.text('● ${Copy.focusTagTodo}'), findsOneWidget);
    await db.close();
  });

  testWidgets('T010 成就时刻：上升沿绽放、点按退场、离开全完成态后重臂（FR-004/R4）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    // 004 T022：今日列表换关注卡轮播，动线经卡上「记录打卡」——
    // 持 id 供 openGoalFromFocus 定位（名字 tap 不再导航）。
    final ids = <String>[];
    for (final (name, icon, color) in [
      ('锻炼', 'fitness', 'sage'),
      ('阅读', 'read', 'teal'),
    ]) {
      final g = await repo.create(
        Goal(
          name: name,
          goalType: GoalType.habit,
          iconKey: icon,
          colorKey: color,
          createdAt: today,
        ),
      );
      ids.add(g.id);
      await seedVersion(
        db,
        g.id,
        const DailyFrequency(1),
        WeekStart.containing(today),
      );
    }
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

    // v2 动线：关注卡「记录打卡」进详情打卡。先只记锻炼 → 部分进
    // 展，不绽放（露边邻卡 onstage → 标签断言用 findsWidgets）。
    await openGoalFromFocus(tester, ids[0]);
    await tester.tap(find.text(Copy.goalCheckInAction));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('● ${Copy.focusTagActive}'), findsWidgets);
    expect(find.text(Copy.celebrationTitle), findsNothing);

    // 补上阅读 → 上升沿，全屏成就时刻。
    await openGoalFromFocus(tester, ids[1]);
    await tester.tap(find.text(Copy.goalCheckInAction));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('● ${Copy.focusTagActive}'), findsWidgets);
    expect(find.text(Copy.celebrationTitle), findsOneWidget);

    // 点按屏幕中央 → 退场（淡出后内容摘树）。
    await tester.tapAt(const Offset(195, 422));
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsNothing);

    // 撤销阅读（toast 在根 ScaffoldMessenger，跨路由存活）→ 离开全完成
    // 态（重臂）→ 再进详情记一笔 → 再次绽放。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    await openGoalFromFocus(tester, ids[1]);
    await tester.tap(find.text(Copy.goalCheckInAction));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Copy.celebrationTitle), findsOneWidget);
    await db.close();
  });

  testWidgets('004 T022：轮播挂载——cap/查看全部/主行动动线/暂停经流移出+单卡退化', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goals = <Goal>[];
    for (final (name, icon) in [
      ('读诗', 'menu_book'),
      ('夜跑', 'directions_run'),
    ]) {
      final g = await repo.create(
        Goal(
          name: name,
          goalType: GoalType.habit,
          iconKey: icon,
          colorKey: 'sage',
          createdAt: today,
        ),
      );
      goals.add(g);
      await seedVersion(
        db,
        g.id,
        const DailyFrequency(1),
        WeekStart.containing(today),
      );
    }
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

    // cap 行 + 双卡页点。
    expect(find.text(Copy.focusSection), findsOneWidget);
    expect(find.text(Copy.focusSeeAll), findsOneWidget);
    expect(find.byKey(const ValueKey('focusDots')), findsOneWidget);

    // 「查看全部」→ /goals-all 过渡页（行可达 → 详情），返回今日。
    await tester.tap(find.text(Copy.focusSeeAll));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsAllPage), findsOneWidget);
    expect(find.byKey(ValueKey('goalsAllRow-${goals[0].id}')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 主行动白胶囊 → 该目标详情记录动线（次卡在页 2，helper 横滑）。
    await openGoalFromFocus(tester, goals[1].id);
    expect(find.byType(GoalDetailPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 暂停经 goalsProvider 流实时移出；余单卡 → 页点退化消失。
    await repo.update(goals[1].copyWith(status: GoalStatus.paused));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('focusCard-${goals[1].id}')), findsNothing);
    expect(find.byKey(const ValueKey('focusDots')), findsNothing);
    expect(
      find.byKey(ValueKey('focusCard-${goals[0].id}')).hitTestable(),
      findsOneWidget,
    );
    await db.close();
  });

  testWidgets('004 T023：全部目标页——筛选单选/计数联动/分组/筛选空态/长按管理全动线', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    // 两习惯跨两大类：夜跑（运动→健康）/ 读诗（学习→目标）。
    final nightRun = await repo.create(
      Goal(
        name: '夜跑',
        goalType: GoalType.habit,
        iconKey: 'directions_run',
        colorKey: 'sage',
        createdAt: today,
      ),
    );
    final poem = await repo.create(
      Goal(
        name: '读诗',
        goalType: GoalType.habit,
        iconKey: 'menu_book',
        colorKey: 'sage',
        createdAt: today,
      ),
    );
    for (final g in [nightRun, poem]) {
      await seedVersion(
        db,
        g.id,
        const DailyFrequency(1),
        WeekStart.containing(today),
      );
    }
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

    // 筛选行横向滚动（11 chips 超宽）：把目标 chip 拖到可点为止。
    Future<void> scrollFiltersTo(WidgetTester tester, Finder chip) async {
      for (final delta in [const Offset(-240, 0), const Offset(240, 0)]) {
        for (var i = 0; i < 6 && chip.hitTestable().evaluate().isEmpty; i++) {
          await tester.drag(find.byType(SingleChildScrollView), delta);
          await tester.pumpAndSettle();
        }
        if (chip.hitTestable().evaluate().isNotEmpty) return;
      }
      expect(chip.hitTestable(), findsOneWidget);
    }

    String countText() =>
        tester.widget<Text>(find.byKey(const ValueKey('goalsAllCount'))).data!;

    // 组头断言限定在列表内（「健康」也出现在筛选 chip 上，全树
    // find.text 会撞车）。
    Finder groupHead(String label) => find.descendant(
      of: find.byKey(const ValueKey('goalsAllList')),
      matching: find.text(label),
    );

    // 「查看全部」→ 全部目标页：三大类分组 + 计数 + 习惯徽章。
    await tester.tap(find.text(Copy.focusSeeAll));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsAllPage), findsOneWidget);
    expect(groupHead(MajorCategory.health.zhLabel), findsOneWidget);
    expect(groupHead(MajorCategory.goal.zhLabel), findsOneWidget);
    expect(find.byKey(ValueKey('goalsAllRow-${nightRun.id}')), findsOneWidget);
    expect(find.byKey(ValueKey('goalsAllRow-${poem.id}')), findsOneWidget);
    expect(countText(), '2');
    expect(find.text(Copy.typeBadgeHabit), findsNWidgets(2));

    // 筛选单选（运动）：仅夜跑、计数联动 1、组头退场（平铺）。
    await scrollFiltersTo(
      tester,
      find.byKey(const ValueKey('goalsAllFilter-fitness')),
    );
    await tester.tap(find.byKey(const ValueKey('goalsAllFilter-fitness')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('goalsAllRow-${nightRun.id}')), findsOneWidget);
    expect(find.byKey(ValueKey('goalsAllRow-${poem.id}')), findsNothing);
    expect(countText(), '1');
    expect(groupHead(MajorCategory.health.zhLabel), findsNothing);

    // 筛选空态（冥想无目标）：分类名明示 + 新建 CTA → 编辑器。
    await scrollFiltersTo(
      tester,
      find.byKey(const ValueKey('goalsAllFilter-mind')),
    );
    await tester.tap(find.byKey(const ValueKey('goalsAllFilter-mind')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('goalsAllRow-${nightRun.id}')), findsNothing);
    expect(find.text(Copy.goalsFilterEmptyTitle), findsOneWidget);
    expect(
      find.text(Copy.goalsFilterEmptyBody(GoalIconDomain.mind.zhLabel)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('goalsAllEmptyCta')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalEditorPage), findsOneWidget);
    // 编辑器返回键 = chevron 圆钮（Semantics「返回」无 Tooltip，pageBack
    // 的 Tooltip 探测不覆盖，按图标定位；下方 goals-all 已 offstage 不扰）。
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    // 回「全部」恢复全量；整卡进详情。
    await scrollFiltersTo(
      tester,
      find.byKey(const ValueKey('goalsAllFilter-all')),
    );
    await tester.tap(find.byKey(const ValueKey('goalsAllFilter-all')));
    await tester.pumpAndSettle();
    expect(countText(), '2');
    await tester.tap(find.byKey(ValueKey('goalsAllRow-${poem.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 长按管理：暂停 → 已暂停徽章 + 历史条数摘要；恢复 → 回习惯徽章。
    final nightRunRow = find.byKey(ValueKey('goalsAllRow-${nightRun.id}'));
    await tester.longPress(nightRunRow);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalsAllManageSheet')), findsOneWidget);
    expect(find.text(Copy.menuPauseGoal), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goalsAllMenu-pause')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.goalStatusPausedSuffix), findsOneWidget);
    expect(find.text(Copy.historyCountMeta(0)), findsOneWidget);

    await tester.longPress(nightRunRow);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalsAllMenu-resume')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goalsAllMenu-resume')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.goalStatusPausedSuffix), findsNothing);
    expect(find.text(Copy.typeBadgeHabit), findsNWidgets(2));

    // 删除动线：长按 → 二次确认 → 物理级联移出列表。
    await tester.longPress(nightRunRow);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalsAllMenu-delete')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalDeleteDialog')), findsOneWidget);
    await tester.tap(find.text(Copy.deleteConfirmYes));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('goalsAllRow-${nightRun.id}')), findsNothing);
    expect(find.byKey(ValueKey('goalsAllRow-${poem.id}')), findsOneWidget);
    expect(countText(), '1');
    await db.close();
  });

  testWidgets('T023 骨架：分组平铺+保存常驻+改型联动显隐+零行为说明句（FR-011/014/021）', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
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

    // 三组标题平铺在场（分类置顶，R2 裁决 1）+ 保存常驻（R3 裁决 2）。
    expect(find.text(Copy.editorSectionCategory), findsOneWidget);
    expect(find.text(Copy.editorSectionBasics), findsOneWidget);
    expect(find.text(Copy.editorSectionType), findsOneWidget);
    expect(find.text(Copy.editorSave), findsOneWidget);

    // 默认短期：截止日行在场、提醒开关不渲染。
    expect(find.text(Copy.editorDeadlineLabel), findsOneWidget);
    expect(find.byKey(const ValueKey('goalRemindSwitch')), findsNothing);

    // 切习惯：截止让位提醒开关，习惯默认开（v2 冻结稿板 1）。
    // 提醒卡在列表末尾（600px 测试视口之外），先滚到再断言。
    await tester.tap(find.text(Copy.typeBadgeHabit));
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorDeadlineLabel), findsNothing);
    await scrollTo(tester, find.byKey(const ValueKey('goalRemindSwitch')));
    expect(find.byKey(const ValueKey('goalRemindSwitch')), findsOneWidget);
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch')))
          .value,
      isTrue,
    );

    // 切长期：提醒默认关（类型卡滚出视口，先滚回）。
    await scrollTo(tester, find.byKey(const ValueKey('goalTypeSeg')));
    await tester.tap(find.text(Copy.typeBadgeLongTerm));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('goalRemindSwitch')));
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch')))
          .value,
      isFalse,
    );

    // B 案字段与行为说明句全退役（FR-014 / R3 裁决 3）。
    expect(find.text(Copy.editorWhyLabel), findsNothing);
    expect(find.text(Copy.editorCriterionLabel), findsNothing);
    expect(find.text(Copy.editorCueLabel), findsNothing);
    expect(find.text(Copy.editorIconColor), findsNothing);

    // 内容滚出视口后保存按钮仍在场（常驻底部，ListView 外）。
    // v2 编辑器含模板横滑条（也是 ListView），取纵列表 = 首个。
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
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
    navKey.currentState!.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const GoalEditorPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '三个月内考过日语 N2',
    );
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

  testWidgets('T023 编辑同构：类型锁定（004 v2 冻结稿）+ 未动字段原值继承', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '规律运动',
        goalType: GoalType.habit,
        iconKey: 'directions_run',
        colorKey: 'teal',
        createdAt: today,
      ),
    );
    final navKey = GlobalKey<NavigatorState>();
    Future<void> openEditor() async {
      navKey.currentState!.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => GoalEditorPage(goalId: goal.id),
        ),
      );
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

    // 004 T013：类型编辑锁定（v2 冻结稿板 4——003「类型可改」随之退役）。
    // 分段置灰不可点，保存后类型/截止/图标全部原值继承。
    await openEditor();
    expect(find.text(Copy.editorTypeLockedTag), findsOneWidget);
    await tester.tap(
      find.text(Copy.typeBadgeShortTerm),
      warnIfMissed: false,
    ); // IgnorePointer：点击落空
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorDeadlineLabel), findsNothing); // 改型未生效
    await scrollTo(tester, find.byKey(const ValueKey('goalRemindSwitch')));
    expect(find.byKey(const ValueKey('goalRemindSwitch')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    final g = (await repo.getGoals()).single;
    expect(g.goalType, GoalType.habit); // 锁定：编辑无改型路径
    expect(g.deadline, isNull); // 习惯截止恒空
    expect(g.iconKey, 'directions_run'); // 未动字段原值继承（FR-016）
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
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const GoalEditorPage(),
        ),
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
      navKey.currentState!.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const GoalEditorPage(),
        ),
      );
      await tester.pumpAndSettle();
    }

    // 习惯型：开关默认开 → 频率档（默认每天）+ 时间行（默认 09:00）。
    await openEditor();
    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '睡前读 5 页书',
    );
    await tester.tap(find.text(Copy.typeBadgeHabit));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch')))
          .value,
      isTrue,
    );
    expect(find.byKey(const ValueKey('goalCadenceSeg')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalRemindTimeField')), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedPill<Cadence>>(
            find.byKey(const ValueKey('goalCadenceSeg')),
          )
          .selected,
      Cadence.daily, // 004 v2：SegmentedPill 单值读态
    );

    // 切「隔三天」→ 保存 → Reminders 行（enabled/threeDay/09:00/goalId）。
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

    // 长期型：默认关；手动开 → 默认每天档。
    await openEditor();
    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '把冈仁波齐走完',
    );
    await tester.tap(find.text(Copy.typeBadgeLongTerm));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch')))
          .value,
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
    await tester.enterText(find.byKey(const ValueKey('goalNameField')), '好好吃饭');
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

  testWidgets('T025 编辑回填提醒行 + 类型锁定后原行原样续写（goal-type-model 口径）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final goal = await GoalRepository(db).create(
      Goal(
        name: '规律运动',
        goalType: GoalType.habit,
        iconKey: 'directions_run',
        colorKey: 'teal',
        createdAt: today,
      ),
    );
    final reminderId = (await ReminderRepository(db).upsert(
      Reminder(
        goalId: goal.id,
        time: const LocalTime(21, 30),
        isEnabled: true,
        cadence: Cadence.threeDay,
      ),
    )).id;
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
      navKey.currentState!.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => GoalEditorPage(goalId: goal.id),
        ),
      );
      await tester.pumpAndSettle();
    }

    // 回填：开关开、时间 21:30、档=隔三天。
    await openEditor();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch')))
          .value,
      isTrue,
    );
    expect(find.text('21:30'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedPill<Cadence>>(
            find.byKey(const ValueKey('goalCadenceSeg')),
          )
          .selected,
      Cadence.threeDay,
    );

    // 不动保存 → 原行续写（同 id，不重复建行）。
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    final rows = await ReminderRepository(db).all();
    expect(rows, hasLength(1));
    expect(rows.single.id, reminderId);

    // 004 T013：类型锁定后改型删行路径退役——二轮编辑原行原样保留。
    await openEditor();
    expect(find.text(Copy.editorTypeLockedTag), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    final rows2 = await ReminderRepository(db).all();
    expect(rows2, hasLength(1));
    expect(rows2.single.id, reminderId);
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

  testWidgets('T026 分类组：常用行 6 枚 + 「更多」弹窗全量按域分组，单选即存 iconKey（FR-011/015）', (
    tester,
  ) async {
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

    // 常用行 6 枚策展（冻结稿 COMMON）+「更多」格在场。
    const commonKeys = [
      'fitness_center',
      'menu_book',
      'favorite',
      'directions_bike',
      'brush',
      'savings',
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

    // 编辑 → 「更多」上滑弹层：标题 + 域组头「域 · 大类」+ 全量 38 枚。
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
    navKey.currentState!.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GoalEditorPage(goalId: created.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('goalIconMoreButton')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorPickCategoryTitle), findsOneWidget);
    expect(
      find.text(
        '${GoalIconDomain.travel.zhLabel} · '
        '${GoalIconDomain.travel.major.zhLabel}',
      ),
      findsOneWidget,
    );

    // 弹层内容（10 域 ≈ 1000px）长于 78% 屏高：分段滚动收集，38 枚全量可及。
    // 弹层打开时 Scrollable.last = 弹层内容（.first 仍是编辑器主列表）。
    final sheet = find.byType(Scrollable).last;
    final seen = <IconData>{};
    for (var i = 0; i < 30; i++) {
      for (final c in GoalIconCatalog.values) {
        if (find.byIcon(c.icon).evaluate().isNotEmpty) seen.add(c.icon);
      }
      if (seen.length == GoalIconCatalog.values.length) break;
      await tester.drag(sheet, const Offset(0, -300));
      await tester.pump();
    }
    expect(seen.length, GoalIconCatalog.values.length, reason: '弹层应能滚到全量图标');

    // scrim 点外关闭不选 → iconKey 不变（v2 弹层无 ✕ 键）。
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect((await GoalRepository(db).getGoals()).single.iconKey, 'menu_book');

    // 弹层选非常用图标 flight（旅行域）→ 点选即关 → 保存落库 flight。
    await tester.tap(find.byKey(const ValueKey('goalIconMoreButton')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      if (find
          .byIcon(Icons.flight_rounded)
          .hitTestable()
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.drag(sheet, const Offset(0, -120));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.flight_rounded));
    await tester.pumpAndSettle();
    expect(find.text(Copy.editorPickCategoryTitle), findsNothing); // 点选即关
    await scrollTo(tester, find.byKey(const ValueKey('goalSaveButton')));
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    expect((await GoalRepository(db).getGoals()).single.iconKey, 'flight');
    await db.close();
  });

  testWidgets('T029 到期询问：到点不终结——双入口在场 + 标记达成写 achievedAt（D4）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '三个月内考过日语 N2',
        goalType: GoalType.shortTerm,
        iconKey: 'school',
        colorKey: 'teal',
        createdAt: today,
        deadline: today, // 到日子了
      ),
    );
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
    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => GoalDetailPage(goalId: goal.id)),
    );
    await tester.pumpAndSettle();

    // 到期只提醒不判决：004 v2 到期卡退役，倒计时/截止日胶囊接管提醒，
    // 「到日子了怎么样」询问移交通知列表（notifDueTitle）。
    expect(find.text(Copy.deadlineCountdownMeta(0)), findsOneWidget);
    expect(find.text(Copy.deadlineDateMeta(today.isoString)), findsOneWidget);
    expect(
      find.byKey(const ValueKey('goalMarkAchievedButton')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('goalRenewButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('checkInNoteField')), findsOneWidget);

    // 标记达成 → 写 achievedAt（通知列达成事件源）+ pop 回 root。
    await tester.tap(find.byKey(const ValueKey('goalMarkAchievedButton')));
    await tester.pumpAndSettle();
    final saved = (await repo.getGoals()).single;
    expect(saved.status, GoalStatus.achieved);
    expect(saved.achievedAt, isNotNull);
    expect(find.text('root'), findsOneWidget);
    await db.close();
  });

  testWidgets('T029 超期：持续提示 + 仍可打卡 + 续期改 deadline（FR-018/D4）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '读完一本书',
        goalType: GoalType.shortTerm,
        iconKey: 'menu_book',
        colorKey: 'sky',
        createdAt: today.addDays(-10),
        deadline: today.addDays(-2), // 已过 2 天，不自动终结
      ),
    );
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
    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => GoalDetailPage(goalId: goal.id)),
    );
    await tester.pumpAndSettle();

    // 超期持续提示（倒计时胶囊「已过 N 天」）+ 打卡条可用。
    expect(find.text(Copy.deadlineCountdownMeta(-2)), findsOneWidget);
    expect(find.byKey(const ValueKey('checkInNoteField')), findsOneWidget);

    // 续期：日期选择器锚定今天 → 确认 → deadline 落库、卡仍在（温和询问）。
    await tester.tap(find.byKey(const ValueKey('goalRenewButton')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect((await repo.getGoals()).single.deadline, today); // -2 → 今天
    expect(find.text(Copy.milestonePostponed), findsOneWidget);
    expect(
      find.text(Copy.deadlineCountdownMeta(0)),
      findsOneWidget,
    ); // days=0 仍在

    // 超期仍可打卡（FR-018：到点不自动终结、记录不受影响）。
    await tester.tap(find.text(Copy.goalCheckInAction));
    await tester.pumpAndSettle();
    expect(
      (await CheckInRepository(db).all()).where((c) => c.isValid),
      hasLength(1),
    );
    await db.close();
  });

  test('T027 模板策展：三类型齐备 + iconKey 全 v3 值域 + 无颜色/频率载荷', () {
    // 三类型都有代表模板（003 三类型语言）。
    expect(kHabitTemplates, isNotEmpty);
    expect(kHabitTemplates.every((t) => t.goalType == GoalType.habit), isTrue);
    expect(kMilestoneTemplates.map((t) => t.goalType).toSet(), {
      GoalType.shortTerm,
      GoalType.longTerm,
    });
    // 图标键全部落在 v3 目录（不靠 byKey 兜底即命中）。
    for (final t in kAllTemplates) {
      expect(
        GoalIconCatalog.values.any((i) => i.key == t.iconKey),
        isTrue,
        reason: '「${t.name}」图标键 ${t.iconKey} 不在 v3 目录',
      );
      expect(t.name.length, lessThanOrEqualTo(40));
    }
  });

  testWidgets('US1 路由两分支（004 T024）：页签恰两枚、我的改头像 push、目标页签退役（FR-001）', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 004 T024 两分支：页签恰两枚（今日/回顾），我的页签退役（改
    // 今日页头像 → /settings 全屏 push）；目标页签仍不存在。
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);
    expect(find.text(Copy.mineNav), findsNothing);
    expect(find.text(Copy.goalsNav), findsNothing);

    // 头像入口 → 我的页全屏 push：dock 退场（根级路由覆盖壳层），
    // 返回键 pop 回今日。
    await tester.tap(find.byTooltip(Copy.mineNav));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screenTitle')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/today')), findsNothing);
    // 我的页返回键 = chevron 圆钮（Semantics「返回」无 Tooltip）。
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    await db.close();
  });

  testWidgets('US4 dock 重做（004 T025）：两页签+中央FAB 三槽恒定、FAB 直达编辑器、头部过渡＋退役', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 今日页：dock 三槽在场——两页签 + 中央 FAB（D2 黑线：当前页签带
    // 16×3 短横线 navTabMark，非选中无）；全屏唯一 Icons.add 即 FAB
    // 的＋（头部过渡＋退役），铃铛驻留头部（通知列表唯一入口）。
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTabMark-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTabMark-/review')), findsNothing);
    expect(find.byIcon(Icons.cloudy_snowing), findsOneWidget); // 回顾字形
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byTooltip(Copy.todayNewGoal), findsOneWidget); // FAB Tooltip
    expect(find.byTooltip(Copy.notificationTitle), findsOneWidget); // 铃铛

    // 中央按钮 ≤1 交互直达编辑器（SC-004），dock 恒定（FR-010）。
    await tester.tap(find.byKey(const ValueKey('dockFab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalNameField')), findsOneWidget);
    expect(find.byKey(const ValueKey('dockFab')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left)); // 编辑器返回（无 Tooltip）
    await tester.pumpAndSettle();

    // 回顾页：短横线随选中迁移；FAB 任意页恒定，同样直达。
    await tester.tap(find.byKey(const ValueKey('navTab-/review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navTabMark-/review')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTabMark-/today')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('dockFab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalNameField')), findsOneWidget);
    await db.close();
  });

  testWidgets('US4 导航与深链回归（004 T026）：映射不变、跨分支深链落详情、头像 ≤2 击达职能', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final goal = await GoalRepository(db).create(
      Goal(
        name: '锻炼',
        goalType: GoalType.habit,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: today,
      ),
    );
    await seedVersion(
      db,
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
          dayTickerProvider.overrideWith((ref) => {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 深链映射不变（FR-013 口径沿 003 T041）：today/review/goal/{id}，
    // goal 无 id 兜底今日。
    expect(mapDeepLink(Uri.parse('target://today')), '/today');
    expect(mapDeepLink(Uri.parse('target://review')), '/review');
    expect(
      mapDeepLink(Uri.parse('target://goal/${goal.id}')),
      '/goal/${goal.id}',
    );
    expect(mapDeepLink(Uri.parse('target://goal')), '/today');

    // 第三页签清退终态：dock 恰两枚（今日/回顾），我的零上屏（我的 =
    // 今日页头像 push）。goalsNav 哨兵不在此断言——本用例有种库，环区
    // 图例的「目标」大类与页签同文（空库哨兵见 US1 两分支用例）。
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);
    expect(find.text(Copy.mineNav), findsNothing);

    // 深链 E2E：回顾页经 widgetURL 动线 router.go(goal/{id}) 跨分支落
    // 详情（today 分支），dock 恒定（FR-010）。
    await tester.tap(find.byKey(const ValueKey('navTab-/review')));
    await tester.pumpAndSettle();
    final router = ProviderScope.containerOf(
      tester.element(find.byType(TargetApp)),
      listen: false,
    ).read(routerProvider);
    router.go(mapDeepLink(Uri.parse('target://goal/${goal.id}'))!);
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    // 兜底深链：无 id → 今日（不落详情）。
    router.go(mapDeepLink(Uri.parse('target://goal'))!);
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsNothing);

    // 头像 → 我的页职能 ≤2 击可达（US4 验收）：1 击 push 即达职能面
    //（资料编辑入口 meCard + 按目标提醒行 = 职能在场，无须二次导航）。
    await tester.tap(find.byTooltip(Copy.mineNav));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screenTitle')), findsOneWidget);
    expect(find.byKey(const ValueKey('meCard')), findsOneWidget);
    await scrollTo(tester, find.text(Copy.settingsGoalRemindersTitle));
    expect(find.text(Copy.settingsGoalRemindersTitle), findsOneWidget);
    await db.close();
  });

  testWidgets('US1 编辑器/详情落 today 分支：导航不退场 + /goals 兜底（FR-010）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
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
    // 编辑器整页在场而底部两页签仍可见（today 分支子页，非根路由全屏；
    // 004 T024 我的页签退役，dock = 今日/回顾）。
    expect(find.byKey(const ValueKey('goalNameField')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);
    expect(find.text(Copy.mineNav), findsNothing);

    // 存量 /goals 入口兜底落回今日（redirect）。
    router.go('/goals');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalNameField')), findsNothing);
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/today');

    // 深链：goal 无 id 兜底 /today；带 id 落详情（today 分支）；
    // today/review 映射不变（003 T041 全量走查）。
    expect(mapDeepLink(Uri.parse('target://goal')), '/today');
    expect(mapDeepLink(Uri.parse('target://goal/g1')), '/goal/g1');
    expect(mapDeepLink(Uri.parse('target://today')), '/today');
    expect(mapDeepLink(Uri.parse('target://review')), '/review');

    await db.close();
  });

  testWidgets('T030 SC-002 计步：今日页创建习惯（描述+类型+提醒+图标）≤8 次交互，页签全程在场', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();
    void tabsVisible() {
      expect(
        find.byKey(const ValueKey('navTab-/today')),
        findsOneWidget,
        reason: '底部页签应全程可见',
      );
      expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);
    }

    var taps = 0;
    tabsVisible();
    await tester.tap(find.byTooltip(Copy.todayNewGoal)); // 1 ＋ → 编辑器
    taps++;
    await tester.pumpAndSettle();
    tabsVisible(); // SC-002：编辑器是 today 分支子页，页签不退场

    await tester.tap(find.text(Copy.typeBadgeHabit)); // 2 切习惯
    taps++;
    await tester.pumpAndSettle();
    // 提醒四要素之「提醒」：切习惯默认开 + 频率/时间均有默认值——零交互就位。
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('goalRemindSwitch')))
          .value,
      isTrue,
    );

    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '饭后散步 20 分钟',
    ); // 3 一句话描述
    taps++;

    await tester.tap(
      find.byIcon(GoalIconCatalog.byKey('favorite').icon),
    ); // 4 常用行选图标
    taps++;
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('goalSaveButton'))); // 5 保存
    taps++;
    await tester.pumpAndSettle();
    tabsVisible();

    expect(taps, lessThanOrEqualTo(8));
    final g = (await GoalRepository(db).getGoals()).single;
    expect(g.goalType, GoalType.habit);
    expect(g.name, '饭后散步 20 分钟');
    expect(g.iconKey, 'favorite');
    final rows = await ReminderRepository(db).all();
    expect(rows.single.isEnabled, isTrue); // 提醒开关随保存落 Reminders 行
    await db.close();
  });

  testWidgets('T030 SC-005 走查：设置区 0 自然语言句式设置项（002 场景档语言退场）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
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
    router.go('/settings');
    await tester.pumpAndSettle();

    // 002 场景档词汇（早起后/午休时/晚饭后/睡前）与句式说明不再出现在设置区。
    for (final legacy in [
      Copy.cueEarly,
      Copy.cueMidday,
      Copy.cueEvening,
      Copy.cueNight,
      Copy.editorFrequencyLabel, // 「多久做一次？」问答体
      Copy.editorWhyLabel,
    ]) {
      expect(find.text(legacy), findsNothing, reason: '002 句式残留：$legacy');
    }
    // 新口径说明在场（003：提醒在编辑目标设置，按频率定时——短句非场景档语言）。
    expect(find.text(Copy.reminderGoalHint), findsOneWidget);
    await db.close();
  });

  testWidgets(
    'T031 回顾空态：概览整卡「—」+ 空态引导 + CTA ≤1 交互直达新建（FR-007/SC-004 · 004 v2）',
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
            notificationGatewayProvider.overrideWithValue(
              FakeNotificationGateway(),
            ),
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
      router.go('/review');
      await tester.pumpAndSettle();

      // v2 空周（冻结稿画板③同源）：概览整卡空态 + 引导块 + 主 CTA。
      // 大数字与环心双位示「—」、副行「该周暂无记录」、环比无可比较不出胶囊。
      expect(find.byKey(const ValueKey('weekAvgNum')), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text(Copy.reviewAvgEmpty), findsOneWidget);
      expect(find.byKey(const ValueKey('weekAvgDelta')), findsNothing);
      expect(find.byKey(const ValueKey('reviewEmptyState')), findsOneWidget);
      expect(find.text(Copy.reviewEmptyTitle), findsOneWidget);
      final cta = find.byKey(const ValueKey('reviewEmptyCta'));
      expect(cta, findsOneWidget);

      // SC-004：≤1 次交互直达新建——tap CTA → 编辑器（today 分支，页签不退场）。
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('goalNameField')), findsOneWidget);
      expect(find.text(Copy.todayNav), findsOneWidget);
      await db.close();
    },
  );

  testWidgets('T032 标题带对齐：今日/回顾同带（我的页 004 v2 改 push 顶栏）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
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

    // 今日屏基准：头部带（账号区）在带内左上——头像左缘 ≥ padX、
    // 顶部与回顾屏标题同带相容（差 < 一行）。
    final avatar = tester.getRect(find.byType(ProfileAvatar));
    expect(avatar.left, greaterThanOrEqualTo(24));

    router.go('/review');
    await tester.pumpAndSettle();
    final reviewTitle = tester.getRect(
      find.byKey(const ValueKey('screenTitle')),
    );

    // 回顾标题带左缘 ≥ padX；今日屏头像与其同带竖直相容。
    expect(reviewTitle.left, greaterThanOrEqualTo(24));
    expect(
      (avatar.top - reviewTitle.top).abs(),
      lessThan(16),
      reason: '今日屏头部带与标题带应竖直相容',
    );

    // 004 v2（T012）：我的页改 push 顶栏（返回键 + 我的），退出 003 三屏
    // 标题带约束——在场性与形态断言（T036 深色态用例另有覆盖）。
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screenTitle')), findsOneWidget);
    await db.close();
  });

  testWidgets('T033 US3 走查：空数据三屏全渲染无死角（今日空态/回顾空态 CTA/我的账号卡）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 今日：空态邀请卡在场（todayEmptyTitle），两页签齐（T024）。
    expect(find.text(Copy.todayEmptyTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);

    final router = ProviderScope.containerOf(
      tester.element(find.byType(TargetApp)),
      listen: false,
    ).read(routerProvider);

    // 回顾：空态竖直居中块 + CTA（T031 已细化断言，此处走查在场性）。
    router.go('/review');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reviewEmptyCta')), findsOneWidget);

    // 我的：账号卡（默认昵称兜底，头像首字兜底同文故按 key）+ 备份组照常渲染
    //（004 v2 外观组增高，数据组需滚动到缓存区内）。
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('meNickname')), findsOneWidget);
    await scrollTo(tester, find.text(Copy.backupExport));
    expect(find.text(Copy.backupExport), findsOneWidget);
    await db.close();
  });

  testWidgets('T034 设置四分组：账号卡真资料/目标活跃数行跳今日/补签只读/版本行（FR-009）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    for (final name in ['锻炼', '阅读']) {
      await repo.create(
        Goal(
          name: name,
          goalType: GoalType.habit,
          iconKey: 'fitness_center',
          colorKey: 'teal',
          createdAt: today,
        ),
      );
    }
    await repo.create(
      Goal(
        name: '已暂停目标',
        goalType: GoalType.habit,
        iconKey: 'menu_book',
        colorKey: 'sage',
        createdAt: today,
        status: GoalStatus.paused,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
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
    router.go('/settings');
    await tester.pumpAndSettle();

    // 四分组：外观/通知/目标在首屏直接断言（总开关标题「通知」与分组
    // 标签同文 → 分组标签按 findsNWidgets(2) 容纳两处；数据/关于被挤出
    // 首屏，滚动后顶部控件会被 ListView 销毁，滚动断言后置到用例尾）。
    expect(find.text(Copy.settingsSectionNotif), findsNWidgets(2));
    expect(find.text(Copy.settingsSectionGoals), findsOneWidget);

    // 账号卡：真资料（默认昵称兜底）+ 整卡（v2：编辑资料 + 箭头）→ sheet。
    // 昵称文本按 key 断言——今日页头部与头像首字兜底同渲染「我」（IndexedStack 常驻）。
    expect(find.byKey(const ValueKey('meNickname')), findsOneWidget);
    expect(find.text(Copy.settingsMeSub), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('meCard')));
    await tester.pumpAndSettle();
    // sheet 标题与卡片副题同文「编辑资料」（v2 冻结稿），两处在场即开层成功。
    expect(find.text(Copy.profileSheetTitle), findsNWidgets(2));
    await tester.tap(find.text(Copy.profileDone));
    await tester.pumpAndSettle();

    // 目标组：活跃数只计 active（2，不含暂停）+ 箭头行 tap → 今日页。
    expect(find.text(Copy.settingsGoalsActiveTitle), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text(Copy.settingsGoalsActiveTitle));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reviewEmptyCta')), findsNothing);
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);

    // 补签只读行（回到我的页断言）。
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(find.text(Copy.settingsBackfillTitle), findsOneWidget);
    expect(find.text(Copy.settingsBackfillSub), findsOneWidget);

    // 屏底分组：数据/关于 + 版本行（滚动断言）。
    await scrollTo(tester, find.text(Copy.settingsSectionData));
    expect(find.text(Copy.settingsSectionData), findsOneWidget);
    await scrollTo(tester, find.text(Copy.settingsSectionAbout));
    expect(find.text(Copy.settingsSectionAbout), findsOneWidget);
    await scrollTo(tester, find.text(Copy.settingsVersionValue));
    expect(find.text(Copy.settingsVersionValue), findsOneWidget);
    await db.close();
  });

  testWidgets('T035 通知迁入：总开关聚合全开全关 + 按目标提醒二级逐行开关（FR-006）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    final today = LocalDate.fromDateTime(DateTime.now());
    final goalRepo = GoalRepository(db);
    final reminderRepo = ReminderRepository(db);
    final ride = await goalRepo.create(
      Goal(
        name: '锻炼',
        goalType: GoalType.habit,
        iconKey: 'fitness_center',
        colorKey: 'teal',
        createdAt: today,
      ),
    );
    final read = await goalRepo.create(
      Goal(
        name: '阅读',
        goalType: GoalType.habit,
        iconKey: 'menu_book',
        colorKey: 'sage',
        createdAt: today,
      ),
    );
    await reminderRepo.upsert(
      Reminder(
        id: 'r-ride',
        goalId: ride.id,
        time: const LocalTime(9, 0),
        isEnabled: true,
        cadence: Cadence.daily,
      ),
    );
    await reminderRepo.upsert(
      Reminder(
        id: 'r-read',
        goalId: read.id,
        time: const LocalTime(22, 30),
        isEnabled: false,
        cadence: Cadence.weekly,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
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
    router.go('/settings');
    await tester.pumpAndSettle();

    /// 目标名与今日页卡片撞名（IndexedStack 常驻），行内查找限定 SettingsView。
    Finder rowSwitch(String title) => find.descendant(
      of: find.ancestor(
        of: find.descendant(
          of: find.byType(SettingsView),
          matching: find.text(title),
        ),
        matching: find.byType(InkWell),
      ),
      matching: find.byType(Switch),
    );

    /// 总开关行：v2 标题「通知」与分组标签同文，按行 key 定位。
    final masterSwitch = find.descendant(
      of: find.byKey(const ValueKey('notifMasterRow')),
      matching: find.byType(Switch),
    );

    // 通知三行：总开关（聚合开——锻炼行在开）+ 简报默认时间值 + 计数副题。
    expect(find.text(Copy.settingsNotifMasterSub), findsOneWidget);
    expect(find.text(Copy.settingsBriefSub), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text(Copy.settingsGoalRemindersSub(1)), findsOneWidget);

    // 展开二级 → 逐行「频率 · 时间」副题（今日页目标名不进断言，按行副题定位）。
    await tester.tap(find.text(Copy.settingsGoalRemindersTitle));
    await tester.pumpAndSettle();
    expect(find.text('每天 · 09:00'), findsOneWidget);
    expect(find.text('每周 · 22:30'), findsOneWidget);

    // 逐行开关：打开阅读行 → 落库 true，计数副题 1 → 2。
    await tester.tap(rowSwitch('阅读'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.settingsGoalRemindersSub(2)), findsOneWidget);
    expect(
      (await reminderRepo.all()).firstWhere((r) => r.id == 'r-read').isEnabled,
      isTrue,
    );

    // 总开关关 → 简报行 + 逐目标行全落 false；简报无行时视为默认开，
    // 故必须显式落一条简报行承载关闭态（否则聚合视图被拉回 true）。
    await tester.tap(masterSwitch);
    await tester.pumpAndSettle();
    final offRows = await reminderRepo.all();
    expect(offRows, isNotEmpty);
    expect(offRows.every((r) => !r.isEnabled), isTrue);
    expect(offRows.any((r) => r.isDailyBrief), isTrue);
    expect(find.text(Copy.settingsGoalRemindersSub(0)), findsOneWidget);

    // 总开关开 → 全部回 true（能力等价：一处恢复全部提醒）。
    await tester.tap(masterSwitch);
    await tester.pumpAndSettle();
    expect((await reminderRepo.all()).every((r) => r.isEnabled), isTrue);
    expect(find.text(Copy.settingsGoalRemindersSub(2)), findsOneWidget);
    await db.close();
  });

  testWidgets('T036 US4 走查：设置页行形态全标准 + 深色态全行齐备（FR-009）', (tester) async {
    usePhoneSurface(tester);
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    final today = LocalDate.fromDateTime(DateTime.now());
    final goal = await GoalRepository(db).create(
      Goal(
        name: '锻炼',
        goalType: GoalType.habit,
        iconKey: 'fitness_center',
        colorKey: 'teal',
        createdAt: today,
      ),
    );
    await ReminderRepository(
      db,
    ).upsert(Reminder(id: 'r-1', goalId: goal.id, time: const LocalTime(9, 0)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
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
    router.go('/settings');
    await tester.pumpAndSettle();

    // 深色态：darkTheme 注入的令牌确实生效（浅/深 palette 不同实例）。
    final palette = TargetPalette.of(tester.element(find.byType(SettingsView)));
    expect(identical(palette, TargetPalette.dark), isTrue);

    // 通知组三行（开关/值/二级）+ 展开后二级行——深色下照常渲染。
    // 总开关标题「通知」与分组标签同文（v2 冻结稿），按行 key 断言。
    expect(find.byKey(const ValueKey('notifMasterRow')), findsOneWidget);
    expect(find.text(Copy.settingsBriefTitle), findsOneWidget);
    expect(find.text(Copy.settingsGoalRemindersTitle), findsOneWidget);
    await tester.tap(find.text(Copy.settingsGoalRemindersTitle));
    await tester.pumpAndSettle();
    expect(find.text('每天 · 09:00'), findsOneWidget);

    // 屏下分组（目标/数据/关于）滚动走查：行全渲染不抛错。
    await scrollTo(tester, find.text(Copy.settingsSectionData));
    expect(find.text(Copy.backupExport), findsOneWidget);
    expect(find.text(Copy.backupImport), findsOneWidget);
    await scrollTo(tester, find.text(Copy.settingsVersionValue));
    expect(find.text(Copy.settingsVersionValue), findsOneWidget);
    await db.close();
  });

  testWidgets('T012 我的页换装：外观组主题三档单选即时生效并持久（FR-002）', (tester) async {
    usePhoneSurface(tester);
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    final db = AppDatabase(NativeDatabase.memory());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
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
    router.go('/settings');
    await tester.pumpAndSettle();

    TargetPalette palette() =>
        TargetPalette.of(tester.element(find.byType(SettingsView)));

    // 外观组三行在场；缺省跟随系统（platform dark → 深色令牌）。
    expect(find.text(Copy.settingsSectionAppearance), findsOneWidget);
    expect(find.text(Copy.settingsThemeSystem), findsOneWidget);
    expect(find.text(Copy.settingsThemeLight), findsOneWidget);
    expect(find.text(Copy.settingsThemeDark), findsOneWidget);
    expect(identical(palette(), TargetPalette.dark), isTrue);

    // 切浅色：MaterialApp.themeMode 即时翻转（palette 变浅）+ 落库持久。
    await tester.tap(find.byKey(const ValueKey('themeLight')));
    await tester.pumpAndSettle();
    expect(identical(palette(), TargetPalette.light), isTrue);
    final saved = await (db.select(db.settingsRows)).getSingle();
    expect(saved.themeMode, 'light');

    // 切回跟随系统：恢复深色（platform dark），落库回 system。
    await tester.tap(find.byKey(const ValueKey('themeSystem')));
    await tester.pumpAndSettle();
    expect(identical(palette(), TargetPalette.dark), isTrue);
    final saved2 = await (db.select(db.settingsRows)).getSingle();
    expect(saved2.themeMode, 'system');
    await db.close();
  });

  testWidgets('T021 详情：头部块/管理入口 + 打卡描述落库 + 历史行兜底 + 短期倒计时步骤', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '年底前跑一次 10km',
        goalType: GoalType.shortTerm,
        iconKey: 'fitness',
        colorKey: 'sage',
        createdAt: today,
        deadline: LocalDate(today.year, 12, 31),
        motivation: '为了夏天的约定',
        successCriterion: '完成一次 10km',
        cueScene: '早起后',
      ),
    );
    await repo.addStep(MilestoneStep(id: 's1', goalId: goal.id, title: '买跑鞋'));
    // 003 T038：提醒行真源 = Reminders 行（cueScene 场景档退役不上屏）。
    await ReminderRepository(db).upsert(
      Reminder(id: 'r-t21', goalId: goal.id, time: const LocalTime(8, 30)),
    );
    // 昨日一条无描述打卡 → 历史行兜底「完成打卡」。
    await CheckInRepository(db).add(goal.id, today.addDays(-1), DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GoalDetailPage(goalId: goal.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 头部块：描述 + 类型徽章（004 v2「类型 · 域 · 大类」；倒计时移交
    // 详情 meta 行）+ 提醒行；退役字段（为什么/怎样算）不上屏。
    // iconKey 'fitness' 非 38 键值域 → byKey 兜底 explore → 旅行域。
    expect(find.text('年底前跑一次 10km'), findsWidgets);
    expect(
      find.text(
        '${Copy.typeBadgeShortTerm} · ${GoalIconDomain.travel.zhLabel}'
        ' · ${GoalIconDomain.travel.major.zhLabel}',
      ),
      findsOneWidget,
    );
    // 短期 meta 冻结稿口径：倒计时 + 截止日胶囊；提醒胶囊属习惯/长期，
    // 短期不呈现（提醒信息在编辑器与我的页二级行）。
    final deadline = LocalDate(today.year, 12, 31);
    expect(
      find.text(Copy.deadlineCountdownMeta(deadline.differenceInDays(today))),
      findsOneWidget,
    );
    expect(
      find.text(Copy.deadlineDateMeta(deadline.isoString)),
      findsOneWidget,
    );
    expect(
      find.text(Copy.reminderMeta(Copy.cadenceDaily, '08:30')),
      findsNothing,
    );
    expect(find.text('为了夏天的约定'), findsNothing);
    expect(find.text('完成一次 10km'), findsNothing);
    expect(find.text('买跑鞋'), findsOneWidget);
    // 昨日记录：无描述 → 兜底文案（004 v2 历史行 = MM-DD + 描述）。
    // 历史卡在折叠线下：先滚到构建再断言。
    final y = today.addDays(-1);
    final ymd =
        '${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
    await scrollTo(tester, find.text(ymd));
    expect(find.text(ymd), findsOneWidget);
    expect(find.text(Copy.checkInDefaultNote), findsOneWidget);

    // 打卡动线：填描述 → 落库 note + 历史行今日一行带描述。
    await scrollTo(tester, find.byKey(const ValueKey('checkInNoteField')));
    await tester.enterText(
      find.byKey(const ValueKey('checkInNoteField')),
      '报名了首场比赛',
    );
    await tester.tap(find.text(Copy.goalCheckInAction));
    await tester.pumpAndSettle();
    expect(find.text(Copy.checkInDone), findsOneWidget);
    final saved = await CheckInRepository(db).all();
    expect(saved.where((c) => c.day == today).single.note, '报名了首场比赛');
    await scrollTo(tester, find.text('报名了首场比赛'));
    expect(find.text('报名了首场比赛'), findsOneWidget);

    // ⋯ 菜单：暂停目标 → 横幅出现 + 打卡动线隐藏；恢复回 active
    // （暂停态横幅也带「恢复」，按菜单 sheet 键收窄避免双命中）。
    await tester.tap(find.byTooltip(Copy.goalMoreActions));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('goalMenuSheet')),
        matching: find.text(Copy.menuPauseGoal),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.goalPausedBanner), findsOneWidget);
    expect(find.byKey(const ValueKey('checkInNoteField')), findsNothing);
    await tester.tap(find.byTooltip(Copy.goalMoreActions));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('goalMenuSheet')),
        matching: find.text(Copy.goalResumeAction),
      ),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('checkInNoteField')));
    expect(find.byKey(const ValueKey('checkInNoteField')), findsOneWidget);

    // 加一步：输入回车入库（加一步输入框以 hint 定位）。
    await scrollTo(
      tester,
      find.widgetWithText(TextFormField, Copy.milestoneStepHint),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, Copy.milestoneStepHint),
      '报名比赛',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect((await repo.stepsOf(goal.id)).length, 2);

    // 勾选第一步（004 v2 自绘圆勾，键 stepCheck-<id>）→ 进度 50%。
    await scrollTo(tester, find.byKey(const ValueKey('stepCheck-s1')));
    await tester.tap(find.byKey(const ValueKey('stepCheck-s1')));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    await db.close();
  });

  testWidgets('T021 极简详情不空：仅名称的长期目标仍有完整头部骨架', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '把英语捡回来',
        goalType: GoalType.longTerm,
        iconKey: 'read',
        colorKey: 'sky',
        createdAt: today,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GoalDetailPage(goalId: goal.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 无提醒/无记录：头部仍呈现 图标 + 描述 + 类型徽章（004 v2 组合式，
    // iconKey 'read' 旧键 → byKey 兜底 explore → 旅行域）+ 打卡动线。
    expect(find.text('把英语捡回来'), findsWidgets);
    expect(
      find.text(
        '${Copy.typeBadgeLongTerm} · ${GoalIconDomain.travel.zhLabel}'
        ' · ${GoalIconDomain.travel.major.zhLabel}',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('checkInNoteField')), findsOneWidget);
    // 004 v2：编辑目标为常驻行式卡（无 tooltip），⋯ 菜单保留 tooltip。
    expect(find.text(Copy.goalEdit), findsOneWidget);
    expect(find.byTooltip(Copy.goalMoreActions), findsOneWidget);
    await db.close();
  });

  // 004 T014：补签弹层（冻结稿板 3）——周点阵点过去日 → 14 天窗口日历
  // 单选 → 确认落库 isBackfill + 历史行「补签」标。
  testWidgets('T014 补签弹层：周点阵点过去日 → 日历单选 → 落库带补签标', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '晨间骑行',
        goalType: GoalType.habit,
        iconKey: 'directions_bike',
        colorKey: 'sage',
        createdAt: today,
      ),
    );
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
    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => GoalDetailPage(goalId: goal.id)),
    );
    await tester.pumpAndSettle();

    // 周点阵点 3 天前（整列可点）→ 弹层：题 + 确认按钮带初始日。
    final target = today.addDays(-3);
    await scrollTo(tester, find.byKey(const ValueKey('detailWeekDots')));
    await tester.tap(find.text('${target.day}'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('backfillSheet')), findsOneWidget);
    expect(find.text(Copy.backfillSheetTitle), findsOneWidget);
    expect(
      find.text(Copy.backfillConfirm(target.month, target.day)),
      findsOneWidget,
    );

    // 日历改选 5 天前（按弹层键收窄，避开周点阵同名日期）→ 确认。
    final target2 = today.addDays(-5);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('backfillSheet')),
        matching: find.text('${target2.day}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(Copy.backfillConfirm(target2.month, target2.day)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('backfillConfirmButton')));
    await tester.pumpAndSettle();

    // 落库：day = 改选日、isBackfill = true；toast + 历史行「补签」标。
    final rows = await CheckInRepository(db).all();
    expect(rows.single.day, target2);
    expect(rows.single.isBackfill, isTrue);
    expect(find.text(Copy.backfillDone(target2.isoString)), findsOneWidget);
    await scrollTo(tester, find.text(Copy.backfillTag));
    expect(find.text(Copy.backfillTag), findsOneWidget);
    await db.close();
  });

  // 004 T014：删除目标（冻结稿板 4 .dlg + FR-016）——二次确认；
  // 取消不动库；确认物理级联清 打卡/步骤/提醒/频率版本 并退出详情。
  testWidgets('T014 删除目标：二次确认 → 四子表级联清行 + 退出详情（FR-016）', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(
      Goal(
        name: '冈仁波齐徒步',
        goalType: GoalType.shortTerm,
        iconKey: 'flight',
        colorKey: 'teal',
        createdAt: today,
        deadline: today.addDays(90),
      ),
    );
    await repo.addStep(MilestoneStep(id: 's1', goalId: goal.id, title: '订机票'));
    await ReminderRepository(
      db,
    ).upsert(Reminder(id: 'r-d', goalId: goal.id, time: const LocalTime(9, 0)));
    await CheckInRepository(db).add(goal.id, today.addDays(-1), DateTime.now());
    await seedVersion(
      db,
      goal.id,
      const DailyFrequency(1),
      WeekStart.containing(today),
    );
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
    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => GoalDetailPage(goalId: goal.id)),
    );
    await tester.pumpAndSettle();

    // ⋯ → 删除目标 → 居中确认：取消 → 库不动。
    await tester.tap(find.byTooltip(Copy.goalMoreActions));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('goalMenuSheet')),
        matching: find.text(Copy.menuDeleteGoal),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalDeleteDialog')), findsOneWidget);
    expect(find.text(Copy.deleteConfirmBody(goal.name)), findsOneWidget);
    await tester.tap(find.text(Copy.dialogCancel));
    await tester.pumpAndSettle();
    expect((await repo.getGoals()), hasLength(1));

    // 再删 → 确认 → pop 回 root + 四子表与目标全清。
    await tester.tap(find.byTooltip(Copy.goalMoreActions));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('goalMenuSheet')),
        matching: find.text(Copy.menuDeleteGoal),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.deleteConfirmYes));
    await tester.pumpAndSettle();
    expect(find.text('root'), findsOneWidget);
    expect(await repo.getGoals(), isEmpty);
    expect(await CheckInRepository(db).all(), isEmpty);
    expect(await repo.stepsOf(goal.id), isEmpty);
    expect(await ReminderRepository(db).all(), isEmpty);
    expect(await db.select(db.frequencyVersions).get(), isEmpty);
    await db.close();
  });

  testWidgets('T019 V1 创建双路径：品牌屏开始 → 编辑器模板预填 → 落库 + 今日可见', (tester) async {
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

    // v2 品牌屏主行动 → 今日页；创建入口随 004 移至 dock FAB。
    await tester.tap(find.byKey(const ValueKey('onboardingStart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dockFab')));
    await tester.pumpAndSettle();

    // 模板路径：编辑器模板条选「饭后散步 20 分钟」→ 预填名称（自定义路径即不选模板直接写）。
    await tester.tap(find.text('饭后散步 20 分钟'));
    await tester.pumpAndSettle();
    final nameField = find.byKey(const ValueKey('goalNameField'));
    expect(
      (tester.widget(nameField) as TextField).controller!.text,
      '饭后散步 20 分钟',
    );

    // 003 动线：预填即保存（模板带习惯型；B 案为什么字段已退役）。
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    // 今日页出现该目标（V1：模板+确认即首个目标）。
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

  testWidgets('T021 周回顾 v2：‹ 周 › 切换 + 概览（周平均/环比/均分环），纯回看无决策控件（004 T028）', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final lastWeek = today.weekStart.previous;
    final repo = GoalRepository(db);
    final checkIns = CheckInRepository(db);

    // 三周前立两个习惯：上周 4+1 = 5 次留痕 / 14 应记 → 36%；
    // 上上周（创建周尾段）零留痕 → 0%；本周尚无留痕 → 0%。
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
    await seedVersion(
      db,
      goal.id,
      const DailyFrequency(1),
      WeekStart.containing(createdAt),
    );
    for (final d in [0, 1, 3, 4]) {
      await checkIns.add(goal.id, lastWeek.monday.addDays(d), DateTime.now());
    }
    final goal2 = await repo.create(
      Goal(
        name: '读书',
        goalType: GoalType.habit,
        iconKey: 'book',
        colorKey: 'teal',
        createdAt: createdAt,
      ),
    );
    await seedVersion(
      db,
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

    // 切到回顾页签（「回顾」与 dock 页签同文，按键定位）。
    await tester.tap(find.byKey(const ValueKey('navTab-/review')));
    await tester.pumpAndSettle();

    String rangeText(WeekStart w) =>
        '${w.monday.month} 月 ${w.monday.day} 日 – ${w.sunday.month} 月 ${w.sunday.day} 日';

    // 默认本周：0%（本周尚无留痕）+ 环比 ↓36（上周 36%）。
    expect(find.byKey(const ValueKey('screenTitle')), findsOneWidget);
    expect(find.byKey(const ValueKey('weekRange')), findsOneWidget);
    expect(find.text(rangeText(today.weekStart)), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('↓ 36%'), findsOneWidget);
    expect(find.text(Copy.reviewAvgSub(36)), findsOneWidget);
    // 三区块齐题（004 T029）+ 点阵本周零留痕（七格全「·」无对勾）+
    // 本周目标卡在场（两目标本周有应记；pc 分母随今日星期不写死）。
    expect(find.text(Copy.reviewDaysTitle), findsOneWidget);
    expect(find.text(Copy.reviewGoalsTitle), findsOneWidget);
    expect(find.text('·'), findsNWidgets(7));
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('锻炼'), findsOneWidget);
    expect(find.text('读书'), findsOneWidget);
    // 纯回看（R3 沿革）：决策动线不上屏。
    expect(find.textContaining('下周怎么走'), findsNothing);
    expect(find.textContaining('记下这一周'), findsNothing);

    // ‹ 切上周：5/14 → 36%，环比 ↑36（上上周 0%——已立未留痕）。
    await tester.tap(find.byKey(const ValueKey('weekPrev')));
    await tester.pumpAndSettle();
    expect(find.text(rangeText(lastWeek)), findsOneWidget);
    expect(find.text('36%'), findsOneWidget);
    expect(find.text('↑ 36%'), findsOneWidget);
    expect(find.text('36'), findsOneWidget); // 环心均分
    expect(find.text(Copy.reviewAvgSub(0)), findsOneWidget);
    // 上周点阵：留痕日 5（三/日为「·」），全部 partial（1/2）无 full 对勾；
    // 本周目标卡 x/y 与手工核算一致（4/7、1/7）。
    expect(find.text('·'), findsNWidgets(2));
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('4/7'), findsOneWidget);
    expect(find.text('1/7'), findsOneWidget);

    // › 回本周；已在本周时 › 置灰（前瞻钳制，点了不动）。
    await tester.tap(find.byKey(const ValueKey('weekNext')));
    await tester.pumpAndSettle();
    expect(find.text(rangeText(today.weekStart)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('weekNext')));
    await tester.pumpAndSettle();
    expect(find.text(rangeText(today.weekStart)), findsOneWidget);
    await db.close();
  });

  testWidgets('T029 每日活动点阵与本周目标卡：三档双编码/今日高亮/卡片与查看全部动线（004 US5）', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
    final today = LocalDate.fromDateTime(DateTime.now());
    final thisWeek = today.weekStart;
    final repo = GoalRepository(db);
    final checkIns = CheckInRepository(db);

    // 两目标三周前立：周一仅锻炼留痕（partial 1/2，描边圈无对勾）；
    // 今日双目标齐留痕（full → 实底对勾）；未来日本就零计数。
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
    await seedVersion(
      db,
      goal.id,
      const DailyFrequency(1),
      WeekStart.containing(createdAt),
    );
    await checkIns.add(goal.id, thisWeek.monday, DateTime.now());
    await checkIns.add(goal.id, today, DateTime.now());
    final goal2 = await repo.create(
      Goal(
        name: '读书',
        goalType: GoalType.habit,
        iconKey: 'book',
        colorKey: 'teal',
        createdAt: createdAt,
      ),
    );
    await seedVersion(
      db,
      goal2.id,
      const DailyFrequency(1),
      WeekStart.containing(createdAt),
    );
    await checkIns.add(goal2.id, today, DateTime.now());
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
    await tester.tap(find.byKey(const ValueKey('navTab-/review')));
    await tester.pumpAndSettle();

    // 点阵：唯一 full（今日）出对勾（FR-013 图形双编码——partial 只描
    // 边圈不靠色相）；下标 n = 当日全量打卡数（周一 1、今日 2），零记
    // 录日「·」×5；今日星期简称 accent 加粗（列首 Text w700）。
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // 周一 n
    expect(find.text('2'), findsOneWidget); // 今日 n
    expect(find.text('·'), findsNWidgets(5));
    final todayCol = find.byKey(ValueKey('dayCol-${today.weekdayIso - 1}'));
    final todayLbl = tester.widget<Text>(
      find.descendant(of: todayCol, matching: find.byType(Text)).first,
    );
    expect(todayLbl.style?.fontWeight, FontWeight.w700);

    // 本周目标卡 → 详情（周完成度卡整击）；返回后「查看全部 ›」→
    // /goals-all（today 分片子路由，dock 恒定两页签在场）。
    await tester.tap(find.byKey(ValueKey('reviewGoal-${goal.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.focusSeeAll));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalsAllList')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);
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
      final goal = await repo.create(
        Goal(
          name: '锻炼',
          goalType: GoalType.habit,
          iconKey: 'fitness',
          colorKey: 'sage',
          createdAt: createdAt,
        ),
      );
      await seedVersion(
        db,
        goal.id,
        const DailyFrequency(1),
        WeekStart.containing(createdAt),
      );
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
            filePickGatewayProvider.overrideWithValue(
              FakeFilePickGateway(utf8.encode(backupJson)),
            ),
            dayTickerProvider.overrideWith((ref) {}),
          ],
          child: const TargetApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 004 T024：我的页不再是页签——今日页头像（Tooltip「我的」）push 进。
      await tester.tap(find.byTooltip(Copy.mineNav));
      await tester.pumpAndSettle();

      // R2 骨架 → T034 四分组：账号卡（真资料昵称兜底「我」+ 编辑入口）
      // + 概要行副文 + 场景指引。
      // 标题「我的」与底部 nav 标签同文，断言至少一处即可。
      expect(find.text(Copy.settingsTitle), findsWidgets);
      expect(find.byKey(const ValueKey('meNickname')), findsOneWidget);
      expect(find.byKey(const ValueKey('meCard')), findsOneWidget);
      expect(find.text(Copy.settingsMeSub), findsOneWidget);
      expect(find.text(Copy.settingsBriefTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('notifMasterRow')), findsOneWidget);
      expect(find.text(Copy.reminderGoalHint), findsOneWidget);
      // T045 语域清查：隐私脚注（本地存储说明）不上屏（FR-021）。
      expect(find.textContaining('这台设备'), findsNothing);
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
      // v2 dlg：居中确认卡（标题与行同文「恢复备份」，按 key 断言）。
      expect(find.byKey(const ValueKey('restoreConfirmTitle')), findsOneWidget);
      await tester.tap(find.text(Copy.backupImportOverwrite));
      await tester.pumpAndSettle();
      expect(find.textContaining(Copy.backupImportDone), findsOneWidget);
      expect(find.textContaining('目标 1'), findsOneWidget);
      await db.close();
    },
  );

  // 003 T038 终查（SC-006）：v2 存量文件库升级启动 → 三 Tab + 目标详情
  // 全界面走查——旧字段（频率版本/颜色/为什么/怎样算/场景）零上屏；
  // 数据本身仍逐项保全（对账见 migration_test T038 用例）。
  testWidgets('T038 迁移终查：v2 存量升级启动，旧字段全界面零上屏（SC-006）', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    // testWidgets 的 FakeAsync 区内真实文件 IO 永不完成——库搭建整体
    // 走 runAsync（升级启动本身仍是真实 onUpgrade，见 migration_test）。
    final file = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('t038_ui');
      return File('${dir.path}/db.sqlite');
    }))!;
    addTearDown(
      () => tester.runAsync(() async {
        final dir = file.parent;
        if (await dir.exists()) await dir.delete(recursive: true);
      }),
    );
    await tester.runAsync(() async {
      final v2 = _LegacyV2Database(NativeDatabase(file));
      // gd：habit + envelope 全填 + daily 频率版本 + 提醒；gw：weekly 频率版本。
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at,motivation,success_criterion,cue_scene) VALUES "
        "('gd','好好吃饭','habit','meal','coral','active','2026-08-01',"
        "'为了晚上不胃胀','晚饭吃八分饱','晚饭后')",
      );
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('gw','跑步锻炼','habit','fitness','sage',"
        "'active','2026-08-01')",
      );
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at,deadline,motivation) VALUES ('gs','冈仁波齐徒步',"
        "'milestone','travel','indigo','active','2026-08-01',"
        "'2026-10-01','想亲眼看到日出')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-d','gd','2026-08-03',"
        "'{\"type\":\"daily\",\"targetPerDay\":1}','initial')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-w','gw','2026-08-03',"
        "'{\"type\":\"weekly\",\"timesPerWeek\":3}','initial')",
      );
      await v2.customStatement(
        "INSERT INTO reminders (id,goal_id,time,is_enabled) VALUES "
        "('r-d','gd','08:30',1)",
      );
      await v2.customStatement(
        "INSERT INTO check_ins (id,goal_id,day,created_at,is_backfill,"
        "status) VALUES ('c3','gd','2026-08-19',"
        "'2026-08-19T12:00:00.000Z',0,'valid')",
      );
      await v2.customStatement(
        "INSERT INTO settings_rows (id,daily_brief_time,"
        "onboarding_completed,notification_denied_acknowledged) VALUES "
        "(1,'08:00',1,0)",
      );
      await v2.close();
    });

    // 升级启动：同文件 v4 打开 → onUpgrade 补列 + D3 映射。
    final db = AppDatabase(NativeDatabase(file));
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

    // 今日 Tab：目标名上屏（映射后的新形态），直进主界面。
    expect(find.text('好好吃饭'), findsWidgets);
    // 004 T022：列表换轮播——末卡（短期）横滑到页才构建，终查覆盖
    // 得到卡面；一句话描述 = 怎样算做到/为什么（v2 合法内容，
    // 八分饱/亲眼移出旧字段哨兵）。
    final lastCard = find.byKey(const ValueKey('focusCard-gs'));
    for (var i = 0; i < 12 && lastCard.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(find.byType(PageView).first, const Offset(-320, 0));
      await tester.pumpAndSettle();
    }
    expect(lastCard.hitTestable(), findsOneWidget);
    expect(find.text('冈仁波齐徒步'), findsOneWidget);

    // 旧字段零上屏：被压制的 envelope 面（为什么/场景——怎样算做到
    // 已成卡面描述合法源）+ 频率版本（每周档）+ 旧图标域键名
    // （meal/fitness/travel 已换域，键名不得漏出）。
    final leaked = find.textContaining(
      RegExp(
        '胃胀|晚饭后|每周|timesPerWeek|targetPerDay|'
        'meal|fitness|travel|cue_scene|colorKey',
      ),
    );
    expect(leaked, findsNothing, reason: '旧字段不得在任何已构建分支上屏');

    // 回顾 Tab + 我的页（004 T024 头像 push，含滚动到底）同口径终查。
    await tester.tap(find.text(Copy.reviewNav));
    await tester.pumpAndSettle();
    expect(leaked, findsNothing);
    await tester.tap(find.byKey(const ValueKey('navTab-/today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Copy.mineNav));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(Copy.settingsGoalRemindersTitle));
    expect(leaked, findsNothing);

    // 目标详情：点开 gd 关注卡 → 详情页同口径（为什么/怎样算不得回潮）。
    // 我的页已是全屏 push（dock 退场），chevron 返回今日后再进卡。
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await openGoalFromFocus(tester, 'gd');
    expect(find.text('好好吃饭'), findsWidgets); // 详情页标题
    // 提醒真源 = 迁移补档后的 Reminders 行（daily 08:30 原样续用；
    // 004 v2 习惯目标 meta 胶囊「每天 · 08:30 提醒」）。
    expect(
      find.text(Copy.reminderMeta(Copy.cadenceDaily, '08:30')),
      findsOneWidget,
    );
    expect(leaked, findsNothing);
    await db.close();
  });

  // 003 T039：US5 场景 2/3 UI 呈现——升级库启动，今日页徽章直接可见
  // 「习惯」（每日 3 次档映射）与「短期」（004 v2 组合式徽章；旧键
  // mic/star 均兜底 explore → 旅行域）。
  testWidgets('T039 迁移呈现：每日 3 次→习惯徽章；带截止→短期徽章', (WidgetTester tester) async {
    usePhoneSurface(tester);
    final today = LocalDate.fromDateTime(DateTime.now());
    final file = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('t039_ui');
      return File('${dir.path}/db.sqlite');
    }))!;
    addTearDown(
      () => tester.runAsync(() async {
        final dir = file.parent;
        if (await dir.exists()) await dir.delete(recursive: true);
      }),
    );
    await tester.runAsync(() async {
      final v2 = _LegacyV2Database(NativeDatabase(file));
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at) VALUES ('g3','练声','habit','mic','coral','active',"
        "'${today.addDays(-10).isoString}')",
      );
      await v2.customStatement(
        "INSERT INTO frequency_versions (id,goal_id,effective_from_week,"
        "pattern,source) VALUES ('fv-3','g3',"
        "'${WeekStart.containing(today).isoString}',"
        "'{\"type\":\"daily\",\"targetPerDay\":3}','initial')",
      );
      await v2.customStatement(
        "INSERT INTO goals (id,name,kind,icon_key,color_key,status,"
        "created_at,deadline) VALUES ('gdl','考认证','milestone',"
        "'star','amber','active','${today.addDays(-10).isoString}',"
        "'${today.addDays(12).isoString}')",
      );
      // 昨日一条记录：今日卡「最近」行有内容。
      await v2.customStatement(
        "INSERT INTO check_ins (id,goal_id,day,created_at,is_backfill,"
        "status) VALUES ('c1','g3','${today.addDays(-1).isoString}',"
        "'2026-08-22T02:00:00.000Z',0,'valid')",
      );
      await v2.customStatement(
        "INSERT INTO settings_rows (id,daily_brief_time,"
        "onboarding_completed,notification_denied_acknowledged) VALUES "
        "(1,'08:00',1,0)",
      );
      await v2.close();
    });

    final db = AppDatabase(NativeDatabase(file));
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

    // 场景 2：每日 3 次频率档 → 习惯徽章（详情 hero 组合式
    // 「习惯 · 旅行 · 目标」；004 T022 起今日卡无徽章，断言移详情）。
    expect(find.text('练声'), findsWidgets);
    await openGoalFromFocus(tester, 'g3');
    expect(find.text('练声'), findsWidgets); // 详情标题
    expect(
      find.text(
        '${Copy.typeBadgeHabit} · ${GoalIconDomain.travel.zhLabel}'
        ' · ${GoalIconDomain.travel.major.zhLabel}',
      ),
      findsOneWidget,
    );
    // 场景 3：带截止 → 短期徽章（v2 组合式，倒计时移交详情 meta 行）。
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openGoalFromFocus(tester, 'gdl');
    expect(
      find.text(
        '${Copy.typeBadgeShortTerm} · ${GoalIconDomain.travel.zhLabel}'
        ' · ${GoalIconDomain.travel.major.zhLabel}',
      ),
      findsOneWidget,
    );
    await db.close();
  });

  // 003 T041：通知 tap 落地页——sheet 条目 tap → /goal/{id} 详情，
  // 落 today 分支（页签不退场）；小组件 widgetURL 同走 mapDeepLink
  // （上用例已断言），真机行为归 T043 清单。
  testWidgets('T041 通知落地：sheet 条目 tap → 目标详情，页签不退场', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final goal = await GoalRepository(db).create(
      Goal(
        name: '睡前拉伸',
        goalType: GoalType.habit,
        iconKey: 'self_improvement',
        colorKey: 'teal',
        createdAt: today,
      ),
    );
    await ReminderRepository(db).upsert(
      Reminder(id: 'r-stretch', goalId: goal.id, time: const LocalTime(9, 0)),
    );
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(onboardingCompleted: Value(true)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          dayTickerProvider.overrideWith((ref) {}),
        ],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 今日头部铃铛 → sheet：行提醒条目在场（标题 = 目标名）。
    await tester.tap(find.byTooltip(Copy.notificationTitle));
    await tester.pumpAndSettle();
    // 遮罩下今日卡同名：条目限定 sheet 内查找（今日/明日各一条行提醒）。
    final sheetEntries = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('睡前拉伸'),
    );
    expect(sheetEntries, findsNWidgets(2));

    // tap 条目 → 落地目标详情（打卡动线在场 = 详情页标识），页签不退场。
    await tester.tap(sheetEntries.first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checkInNoteField')), findsOneWidget);
    // 页签不退场（004 T024 两分支：今日/回顾 dock 恒定，我的已非页签）。
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(find.byKey(const ValueKey('navTab-/review')), findsOneWidget);
    await db.close();
  });

  // 004 T032（SC-001/SC-002）：深色全页走查——themeMode=dark 下今日/
  // 回顾/全部目标/详情四页逐页渲染，palette 身份断言（= TargetPalette.dark）
  // 证全链深色令牌安装无泄漏；关注卡/三区块/分组头身份 key 在场即
  // 「无残留旧风格组件」（token 契约禁字面色 → 主题切换全链自动生效）。
  testWidgets('T032 双主题走查：深色档四页身份渲染 + 深色令牌全链安装', (tester) async {
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
    await seedVersion(
      db,
      goal.id,
      const DailyFrequency(1),
      WeekStart.containing(today),
    );
    await CheckInRepository(db).add(goal.id, today, DateTime.now());
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
      const SettingsRowsCompanion(
        onboardingCompleted: Value(true),
        themeMode: Value('dark'),
      ),
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

    // 今日页：头部大标题 + 单环区 + 关注卡（深 palette 已安装）。
    expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
    expect(
      identical(
        TargetPalette.of(tester.element(find.text(Copy.todayNav).first)),
        TargetPalette.dark,
      ),
      isTrue,
    );
    expect(find.text('锻炼'), findsWidgets); // 关注卡在轮播
    expect(find.byKey(const ValueKey('dockBar')), findsOneWidget);

    // 回顾页：三区块身份（概览/每日活动/本周目标）逐块渲染。
    await tester.tap(find.byKey(const ValueKey('navTab-/review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weekAvgNum')), findsOneWidget);
    expect(find.byKey(const ValueKey('dayCol-0')), findsOneWidget);
    expect(find.byKey(ValueKey('reviewGoal-${goal.id}')), findsOneWidget);
    expect(
      identical(
        TargetPalette.of(
          tester.element(find.byKey(const ValueKey('weekAvgNum'))),
        ),
        TargetPalette.dark,
      ),
      isTrue,
    );

    // 全部目标页 + 详情页（「查看全部」tap 动线已由 T022/T029 覆盖，
    // 此处 router 直达，聚焦深色渲染身份）。
    final router = ProviderScope.containerOf(
      tester.element(find.byType(TargetApp)),
      listen: false,
    ).read(routerProvider);
    router.go('/goals-all');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalsAllList')), findsOneWidget);
    expect(find.byKey(ValueKey('goalsAllRow-${goal.id}')), findsOneWidget);

    // 详情页：hero/近 7 天点阵渲染（深 palette 至末页）。
    await tester.tap(find.byKey(ValueKey('goalsAllRow-${goal.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detailWeekDots')), findsOneWidget);
    expect(
      identical(
        TargetPalette.of(
          tester.element(find.byKey(const ValueKey('detailWeekDots'))),
        ),
        TargetPalette.dark,
      ),
      isTrue,
    );
    await db.close();
  });

  // 005 T002（US1/FR-001/002）：dock 安全区自消费——底幕背景高度
  // 84+inset 下延至物理底边（不再被外层 SafeArea 整条抬离露底），
  // 互动槽（页签/FAB）止于 inset 之上。dpr=1.0：物理值即逻辑值。
  testWidgets('005 T002 dock 安全区：inset=34 底幕贴物理底边、互动槽避让', (tester) async {
    usePhoneSurface(tester);
    tester.view.padding = const FakeViewPadding(bottom: 34);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
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

    // 底幕：贴物理底边（bottom=844），高 84+34=118（inset 区仅背景）。
    final bar = tester.getRect(find.byKey(const ValueKey('dockBar')));
    expect(bar.bottom, 844);
    expect(bar.height, 84 + 34);

    // 互动槽：页签与 FAB 整体止于 inset 之上（不侵入 Home 指示区）。
    expect(
      tester.getRect(find.byKey(const ValueKey('navTab-/today'))).bottom,
      lessThan(844 - 34),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('dockFab'))).bottom,
      lessThan(844 - 34),
    );

    // FAB 命中回归：tap 仍直达编辑器（凸出带占位不因 inset 缩水）。
    await tester.tap(find.byKey(const ValueKey('dockFab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalNameField')), findsOneWidget);
    await db.close();
  });

  // 005 T002 续：无 inset 机型（bottomPadding=0）几何与 004 版恒等——
  // 底条 84 高、FAB 凸出带 22、总高 106，无多余空隙。
  testWidgets('005 T002 dock 安全区：inset=0 几何与 004 版恒等', (tester) async {
    usePhoneSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeNotificationGateway();
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

    // 底条：84 高、贴屏底；FAB 上缘恰凸出底条顶 22（旧版几何）。
    final bar = tester.getRect(find.byKey(const ValueKey('dockBar')));
    expect(bar.bottom, 844);
    expect(bar.height, 84);
    final fab = tester.getRect(find.byKey(const ValueKey('dockFab')));
    expect(fab.top, bar.top - 22);
    await db.close();
  });
}
