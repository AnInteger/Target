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
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/features/goals/goal_detail.dart';
import 'package:target/features/goals/goals_view.dart';
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

class _JourneyHarness {
  _JourneyHarness(this.db, this.container);

  final AppDatabase db;
  final ProviderContainer container;
  bool _disposed = false;

  Future<void> dispose(WidgetTester tester) async {
    if (_disposed) return;
    _disposed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
    await db.close();
  }
}

Future<_JourneyHarness> _pumpApp(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db)? seed,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  await (db.update(db.settingsRows)..where((row) => row.id.equals(1))).write(
    const SettingsRowsCompanion(onboardingCompleted: Value(true)),
  );
  await seed?.call(db);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        notificationGatewayProvider.overrideWithValue(_NotificationGateway()),
        dayTickerProvider.overrideWith((ref) {}),
        dateProviderProvider.overrideWith(
          (ref) => FixedDateProvider(_today.atStartOfDay),
        ),
      ],
      child: const TargetApp(),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(TargetApp)),
  );
  final harness = _JourneyHarness(db, container);
  addTearDown(() => harness.dispose(tester));
  return harness;
}

Future<void> _createGoal(
  WidgetTester tester, {
  required String name,
  bool withDate = false,
  int? weeklyCount,
}) async {
  // 中央 FAB 退役（phase 1 · Task 7）：新建走目标页签头部按钮。
  await tester.tap(find.byKey(const ValueKey('navTab-/goals')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('goalsNewButton')));
  await tester.pumpAndSettle();
  if (withDate) {
    await tester.tap(find.byKey(const ValueKey('goalHasDateSwitch')));
    await tester.pumpAndSettle();
  }
  if (weeklyCount != null) {
    await tester.ensureVisible(find.byKey(const ValueKey('goalFrequencyField')));
    await tester.tap(find.byKey(const ValueKey('goalFrequencyField')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('weeklyCount-$weeklyCount')));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byKey(const ValueKey('goalNameField')), name);
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
  await tester.pumpAndSettle();
  expect(find.byType(GoalDetailPage), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('pageTopBarBack')));
  await tester.pumpAndSettle();
  // 新建动线自目标页签出发：返回后仍停留目标页签。
  expect(find.byType(GoalsView), findsOneWidget);
}

Future<void> _openGoalsAll(WidgetTester tester) async {
  // 目标页已是 dock 页签：直接切页签（任意分支下可用）。
  await tester.tap(find.byKey(const ValueKey('navTab-/goals')));
  await tester.pumpAndSettle();
  expect(find.byType(GoalsView), findsOneWidget);
}

Goal _goalNamed(List<Goal> goals, String name) =>
    goals.singleWhere((goal) => goal.name == name);

Future<Goal?> _goalById(AppDatabase db, String id) async {
  final matches = (await GoalRepository(
    db,
  ).getGoals()).where((goal) => goal.id == id).toList();
  return matches.isEmpty ? null : matches.single;
}

void main() {
  testWidgets('journey: creates long short and habit goals through the app', (
    tester,
  ) async {
    final app = await _pumpApp(tester);

    await _createGoal(tester, name: '拿到 OW 潜水证');
    await _createGoal(tester, name: '完成作品集', withDate: true);
    await _createGoal(tester, name: '每周骑行', weeklyCount: 3);

    final goals = await GoalRepository(app.db).getGoals();
    final long = _goalNamed(goals, '拿到 OW 潜水证');
    final short = _goalNamed(goals, '完成作品集');
    final habit = _goalNamed(goals, '每周骑行');
    expect(long.targetDate, isNull, reason: '目标日期是可选项');
    expect(long.progressCadenceDays, 14);
    expect(short.targetDate, _today.addDays(90));
    expect(short.progressCadenceDays, 7);
    expect(habit.habitTargetPerWeek, 3);

    await _openGoalsAll(tester);
    for (final name in ['拿到 OW 潜水证', '完成作品集', '每周骑行']) {
      await tester.scrollUntilVisible(
        find.text(name),
        180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('goalsList')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(name), findsOneWidget);
    }
    await app.dispose(tester);
  });

  testWidgets('journey: create combined goal then manage lifecycle from Goals tab', (
    tester,
  ) async {
    // Phase 1 收口旅程：名称 + 日期 + 每周频率 + 里程碑 + 提醒一次配齐，
    // 再从目标页 overflow 走完 暂停→恢复→达成→重开→归档→反归档 全周期。
    final app = await _pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('navTab-/goals')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalsNewButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '21 天跑步计划',
    );
    await tester.tap(find.byKey(const ValueKey('goalHasDateSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalTargetDateField')));
    await tester.pumpAndSettle();
    // 开关缺省 +90 天（2026-11-23），弹窗初始停在 11 月——回退三个月
    // 到 8 月再选 30 日。
    final dateDialog = find.byType(DatePickerDialog);
    for (var i = 0; i < 3; i++) {
      await tester.tap(
        find.descendant(of: dateDialog, matching: find.byIcon(Icons.chevron_left)).first,
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('30'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('goalFrequencyField')));
    await tester.tap(find.byKey(const ValueKey('goalFrequencyField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('每周若干次'));
    await tester.tap(find.byKey(const ValueKey('weeklyCount-3')));
    await tester.pumpAndSettle();

    for (final title in ['坚持 7 天', '坚持 21 天']) {
      await tester.ensureVisible(
        find.byKey(const ValueKey('milestoneDraftInput')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('milestoneDraftInput')),
        title,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('milestoneDraftAdd')));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('goalReminderSwitch')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('goalReminderSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalReminderSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    final goal = (await GoalRepository(app.db).getGoals()).singleWhere(
      (g) => g.name == '21 天跑步计划',
    );
    final plan = await app.container.read(goalPlanRepoProvider).load(goal.id);
    expect(goal.targetDate, const LocalDate(2026, 8, 30));
    expect(goal.frequency, const WeeklyFrequency(3));
    expect(plan!.milestones.map((m) => m.title), ['坚持 7 天', '坚持 21 天']);
    expect(plan.reminder!.isEnabled, isTrue);

    await tester.tap(find.byKey(const ValueKey('pageTopBarBack')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('goalListRow-${goal.id}')), findsOneWidget);
    expect(find.textContaining('当前：坚持 7 天'), findsOneWidget);

    Future<void> action(String name) async {
      await tester.tap(find.byKey(ValueKey('goalOverflow-${goal.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('goalAction-$name-${goal.id}')));
      await tester.pumpAndSettle();
    }

    await action('pause');
    expect((await _goalById(app.db, goal.id))!.status, GoalStatus.paused);
    await action('resume');
    expect((await _goalById(app.db, goal.id))!.status, GoalStatus.active);
    await action('achieve');
    expect((await _goalById(app.db, goal.id))!.status, GoalStatus.achieved);
    await action('reopen');
    expect((await _goalById(app.db, goal.id))!.status, GoalStatus.active);
    await action('archive');
    expect((await _goalById(app.db, goal.id))!.isArchived, isTrue);

    await tester.tap(find.byKey(const ValueKey('goalFilter-archived')));
    await tester.pumpAndSettle();
    await action('unarchive');
    final restored = await app.container.read(goalPlanRepoProvider).load(goal.id);
    expect(restored!.goal.isArchived, isFalse);
    expect(restored.milestones.map((m) => m.title), ['坚持 7 天', '坚持 21 天']);
    expect(restored.reminder!.isEnabled, isTrue);
    await app.dispose(tester);
  });

  testWidgets(
    'journey: recording progress refreshes score trend and planning',
    (tester) async {
      final app = await _pumpApp(
        tester,
        seed: (db) async {
          final repo = GoalRepository(db);
          await repo.create(
            Goal(
              id: 'dive',
              name: '拿到 OW 潜水证',
              goalType: GoalType.longTerm,
              iconKey: 'pool',
              colorKey: '',
              progressCadenceDays: 7,
              createdAt: _today.addDays(-30),
            ),
          );
          await repo.addStep(
            MilestoneStep(id: 'dsd', goalId: 'dive', title: '完成 DSD 体验潜水'),
          );
        },
      );
      final before = app.container.read(goalProgressProvider)!;
      final beforeScore = before.evaluation.byGoal['dive']!.total;
      final beforeTrend =
          before.evaluation.dailyPoints.last.dimensions.values.single;

      final card = find.byKey(const ValueKey('focusCard-dive'));
      await tester.tap(find.descendant(of: card, matching: find.text('记录进展')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('progressNoteField')),
        '已完成 DSD 体验潜水',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('nextMilestoneField')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('nextMilestoneField')),
        '预约平静水域课程',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('保存进展'));
      await tester.tap(find.text('保存进展'));
      await tester.pumpAndSettle();

      final after = app.container.read(goalProgressProvider)!;
      expect(after.evaluation.byGoal['dive']!.total, greaterThan(beforeScore));
      expect(
        after.evaluation.dailyPoints.last.dimensions.values.single,
        greaterThan(beforeTrend),
      );
      final steps = await GoalRepository(app.db).stepsOf('dive');
      expect(steps.first.isDone, true);
      expect(steps.last.title, '预约平静水域课程');

      await tester.tap(find.byKey(const ValueKey('navTab-/progress')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('progressPage')), findsOneWidget);
      expect(find.text('确认一个可以开始的下一步'), findsNothing);
      await app.dispose(tester);
    },
  );

  testWidgets('journey: backfill refreshes calendar history and score', (
    tester,
  ) async {
    final app = await _pumpApp(
      tester,
      seed: (db) async {
        final repo = GoalRepository(db);
        await repo.create(
          Goal(
            id: 'reading',
            name: '完成阅读计划',
            goalType: GoalType.longTerm,
            iconKey: 'menu_book',
            colorKey: '',
            progressCadenceDays: 7,
            createdAt: _today.addDays(-30),
          ),
        );
        await repo.addStep(
          MilestoneStep(id: 'chapter', goalId: 'reading', title: '读完第一章'),
        );
      },
    );
    final before = app.container
        .read(goalProgressProvider)!
        .evaluation
        .byGoal['reading']!
        .total;
    await tester.tap(find.byKey(const ValueKey('focusCard-reading')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);

    final yesterday = _today.addDays(-1);
    await tester.tap(find.byKey(ValueKey('detailDay-${yesterday.isoString}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('backfillConfirmButton')));
    await tester.pumpAndSettle();

    final check = (await CheckInRepository(app.db).all()).single;
    expect(check.day, yesterday);
    expect(check.isBackfill, true);
    expect(
      app.container
          .read(goalProgressProvider)!
          .evaluation
          .byGoal['reading']!
          .total,
      greaterThan(before),
    );
    expect(find.byType(GoalDetailPage), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
    final detailList = find.descendant(
      of: find.byType(GoalDetailPage),
      matching: find.byType(ListView),
    );
    for (var i = 0; i < 4 && find.text('补签').evaluate().isEmpty; i++) {
      await tester.drag(detailList, const Offset(0, -260));
      await tester.pumpAndSettle();
    }
    expect(find.text('补签'), findsOneWidget);
    await tester.drag(detailList, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('detailDay-${yesterday.isoString}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dayRecordsSheet')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('journey: management actions converge across every surface', (
    tester,
  ) async {
    final app = await _pumpApp(
      tester,
      seed: (db) async {
        final repo = GoalRepository(db);
        for (final (id, name) in [('manage', '完成潜水课程'), ('delete', '待删除目标')]) {
          await repo.create(
            Goal(
              id: id,
              name: name,
              goalType: GoalType.shortTerm,
              iconKey: 'pool',
              colorKey: '',
              createdAt: _today.addDays(-1),
              deadline: _today.addDays(30),
            ),
          );
        }
      },
    );
    await _openGoalsAll(tester);

    await tester.tap(find.byKey(const ValueKey('goalOverflow-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-edit-manage')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '拿到 OW 潜水证',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();
    // 编辑保存按 pop 语义回到来源页（goals-all）。
    expect(find.byType(GoalsView), findsOneWidget);
    expect((await _goalById(app.db, 'manage'))!.name, '拿到 OW 潜水证');

    await tester.tap(find.byKey(const ValueKey('goalOverflow-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-pause-manage')));
    await tester.pumpAndSettle();
    expect((await _goalById(app.db, 'manage'))!.status, GoalStatus.paused);
    // 行内徽章（筛选 chips 有同文「已暂停」，须限定行范围断言）。
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('goalListRow-manage')),
        matching: find.text('已暂停'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('goalOverflow-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-resume-manage')));
    await tester.pumpAndSettle();
    expect((await _goalById(app.db, 'manage'))!.status, GoalStatus.active);

    await tester.tap(find.byKey(const ValueKey('goalListRow-manage')));
    await tester.pumpAndSettle();
    final detailList = find.descendant(
      of: find.byType(GoalDetailPage),
      matching: find.byType(ListView),
    );
    for (
      var i = 0;
      i < 5 &&
          find
              .byKey(const ValueKey('goalMarkAchievedButton'))
              .evaluate()
              .isEmpty;
      i++
    ) {
      await tester.drag(detailList, const Offset(0, -260));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('goalMarkAchievedButton')));
    await tester.pumpAndSettle();
    // 2026-08-25：达成改双通道——轻点先出校验弹窗（无里程碑时温和
    // 确认；有未完成里程碑时警示），确认后才落库跳转。
    final achieveDialog = find.byKey(const ValueKey('goalAchieveDialog'));
    expect(achieveDialog, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goalAchieveConfirm')));
    await tester.pumpAndSettle();
    expect(find.byType(TodayView), findsOneWidget);
    expect((await _goalById(app.db, 'manage'))!.status, GoalStatus.achieved);
    expect(
      app.container.read(goalProgressProvider)!.evaluation.byGoal,
      isNot(contains('manage')),
    );
    // 达成庆祝 SnackBar 由真实 Timer 驱动 ~4s 自退（pumpAndSettle 只等
    // 帧）；浮在 root overlay 会遮住后续底部弹层菜单的末尾条目——
    // 快进使其退场再继续删除动线。
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await _openGoalsAll(tester);
    await tester.tap(find.byKey(const ValueKey('goalOverflow-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-delete-delete')));
    await tester.pumpAndSettle();
    final dialog = find.byKey(const ValueKey('goalDeleteDialog'));
    await tester.tap(find.descendant(of: dialog, matching: find.text('删除')));
    await tester.pumpAndSettle();
    expect(await _goalById(app.db, 'delete'), isNull);
    expect(find.byKey(const ValueKey('goalListRow-delete')), findsNothing);

    // 目标页签无返回钮（dock 顶层）：切回今日验证收敛。
    await tester.tap(find.byKey(const ValueKey('navTab-/today')));
    await tester.pumpAndSettle();
    expect(find.byType(TodayView), findsOneWidget);
    expect(find.text('待删除目标'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('navTab-/progress')));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressView), findsOneWidget);
    expect(find.text('拿到 OW 潜水证'), findsNothing);
    expect(find.text('待删除目标'), findsNothing);
    await app.dispose(tester);
  });
}
