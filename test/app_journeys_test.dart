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
import 'package:target/core/platform/gateways.dart';
import 'package:target/features/goals/goal_detail.dart';
import 'package:target/features/goals/goals_all_view.dart';
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
  required GoalType type,
  required String name,
}) async {
  await tester.tap(find.byKey(const ValueKey('dockFab')));
  await tester.pumpAndSettle();
  if (type != GoalType.shortTerm) {
    await tester.tap(find.text(type == GoalType.longTerm ? '长期' : '习惯'));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byKey(const ValueKey('goalNameField')), name);
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
  await tester.pumpAndSettle();
  expect(find.byType(TodayView), findsOneWidget);
}

Future<void> _openGoalsAll(WidgetTester tester) async {
  await tester.tap(find.text('查看全部'));
  await tester.pumpAndSettle();
  expect(find.byType(GoalsAllPage), findsOneWidget);
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

    await _createGoal(tester, type: GoalType.longTerm, name: '拿到 OW 潜水证');
    await _createGoal(tester, type: GoalType.shortTerm, name: '完成作品集');
    await _createGoal(tester, type: GoalType.habit, name: '每周骑行');

    final goals = await GoalRepository(app.db).getGoals();
    final long = _goalNamed(goals, '拿到 OW 潜水证');
    final short = _goalNamed(goals, '完成作品集');
    final habit = _goalNamed(goals, '每周骑行');
    expect(long.targetDate, isNull, reason: '长期目标日期是可选项');
    expect(long.progressCadenceDays, 14);
    expect(short.deadline, _today.addDays(39));
    expect(short.progressCadenceDays, 7);
    expect(habit.habitTargetPerWeek, 5);

    await _openGoalsAll(tester);
    for (final name in ['拿到 OW 潜水证', '完成作品集', '每周骑行']) {
      await tester.scrollUntilVisible(
        find.text(name),
        180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('goalsAllList')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(name), findsOneWidget);
    }
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

    final managedCard = find.byKey(const ValueKey('goalCard-manage'));
    await tester.longPress(managedCard);
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
    expect(find.byType(TodayView), findsOneWidget);
    expect((await _goalById(app.db, 'manage'))!.name, '拿到 OW 潜水证');

    await _openGoalsAll(tester);

    await tester.longPress(find.byKey(const ValueKey('goalCard-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-pause-manage')));
    await tester.pumpAndSettle();
    expect((await _goalById(app.db, 'manage'))!.status, GoalStatus.paused);
    expect(find.text('已暂停'), findsOneWidget);

    await tester.longPress(find.byKey(const ValueKey('goalCard-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-resume-manage')));
    await tester.pumpAndSettle();
    expect((await _goalById(app.db, 'manage'))!.status, GoalStatus.active);

    await tester.tap(find.byKey(const ValueKey('goalCard-manage')));
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

    await _openGoalsAll(tester);
    await tester.longPress(find.byKey(const ValueKey('goalCard-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-delete-delete')));
    await tester.pumpAndSettle();
    final dialog = find.byKey(const ValueKey('goalDeleteDialog'));
    await tester.tap(find.descendant(of: dialog, matching: find.text('删除')));
    await tester.pumpAndSettle();
    expect(await _goalById(app.db, 'delete'), isNull);
    expect(find.byKey(const ValueKey('goalCard-delete')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pageTopBarBack')));
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
