import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/goal_plan_repository.dart';
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/models/goal_plan.dart';
import 'package:target/features/goals/goal_editor.dart';

const _today = LocalDate(2026, 8, 25);

Future<AppDatabase> pumpEditor(
  WidgetTester tester, {
  String? goalId,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: GoalEditorPage(goalId: goalId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<AppDatabase> pumpRoutedEditor(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: '/goal-editor',
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: Column(children: [const Text('目标'), Expanded(child: child)]),
        ),
        routes: [
          GoRoute(path: '/goals', builder: (_, _) => const Text('目标列表')),
          GoRoute(
            path: '/goal-editor',
            builder: (_, state) =>
                GoalEditorPage(goalId: state.uri.queryParameters['id']),
          ),
          GoRoute(
            path: '/goal/:id',
            builder: (_, state) => Text('详情 ${state.pathParameters['id']}'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(_today),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _openWeeklyCount(WidgetTester tester, int count) async {
  await tester.tap(find.byKey(const ValueKey('goalFrequencyField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('每周若干次'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('weeklyCount-$count')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('only the name is required and no type or template control exists', (
    tester,
  ) async {
    final db = await pumpEditor(tester);
    addTearDown(db.close);
    expect(find.byKey(const ValueKey('goalTypeSeg')), findsNothing);
    expect(find.textContaining('模板'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '学习摄影',
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const ValueKey('goalSaveButton')),
      ).onPressed,
      isNotNull,
    );
  });

  testWidgets('date and frequency can be enabled together', (tester) async {
    final db = await pumpEditor(tester);
    addTearDown(db.close);
    await tester.tap(find.byKey(const ValueKey('goalHasDateSwitch')));
    await tester.pumpAndSettle();
    await _openWeeklyCount(tester, 3);
    expect(find.byKey(const ValueKey('goalTargetDateField')), findsOneWidget);
    expect(find.text('每周 3 次'), findsOneWidget);
  });

  testWidgets('milestones are editable for every goal configuration', (
    tester,
  ) async {
    final db = await pumpEditor(tester);
    addTearDown(db.close);
    await tester.enterText(
      find.byKey(const ValueKey('milestoneDraftInput')),
      '完成理论课程',
    );
    await tester.tap(find.byKey(const ValueKey('milestoneDraftAdd')));
    await tester.pumpAndSettle();
    expect(find.text('完成理论课程'), findsOneWidget);
    expect(find.byKey(const ValueKey('milestoneDraftHandle-0')), findsOneWidget);
  });

  testWidgets('create persists the unified goal plan snapshot', (tester) async {
    final db = await pumpRoutedEditor(tester);
    addTearDown(db.close);
    await tester.enterText(find.byKey(const ValueKey('goalNameField')), '学习摄影');
    await tester.tap(find.byKey(const ValueKey('goalHasDateSwitch')));
    await tester.pumpAndSettle();
    await _openWeeklyCount(tester, 3);
    await tester.enterText(
      find.byKey(const ValueKey('milestoneDraftInput')),
      '完成理论课程',
    );
    await tester.tap(find.byKey(const ValueKey('milestoneDraftAdd')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('goalReminderSwitch')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalReminderSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    final goalId = (await GoalRepository(db).getGoals()).single.id;
    final snapshot = await GoalPlanRepository(db).load(goalId);
    expect(snapshot!.goal.name, '学习摄影');
    expect(snapshot.goal.targetDate, _today.addDays(90));
    expect(snapshot.goal.frequency, const WeeklyFrequency(3));
    expect(snapshot.milestones.single.title, '完成理论课程');
    expect(snapshot.reminder!.isEnabled, isTrue);
    expect(snapshot.reminder!.time, const LocalTime(9, 0));
    expect(find.textContaining('详情 '), findsOneWidget);
  });

  testWidgets('edit can clear optional planning without losing milestone completion', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = GoalPlanRepository(db);
    final doneAt = DateTime.utc(2026, 8, 24, 10);
    final created = await repo.create(
      GoalPlanInput(
        goal: Goal(
          id: 'edit-goal',
          name: '学习摄影',
          iconKey: 'menu_book',
          colorKey: '',
          createdAt: _today.addDays(-1),
          targetDate: _today.addDays(30),
          frequency: const WeeklyFrequency(3),
        ),
        milestones: [
          MilestoneDraft(
            id: 'done-step',
            title: '完成理论课程',
            isDone: true,
            doneAt: doneAt,
          ),
        ],
        reminder: const ReminderDraft(
          id: 'edit-reminder',
          enabled: true,
          time: LocalTime(9, 0),
          cadence: Cadence.daily,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(_today),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GoalEditorPage(goalId: created.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(db.close);

    await tester.tap(find.byKey(const ValueKey('goalHasDateSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalFrequencyField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不设置'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('goalReminderSwitch')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('goalReminderSwitch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('milestoneTitleField-0')),
      '完成进阶课程',
    );
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    final snapshot = await repo.load(created.id);
    expect(snapshot!.goal.targetDate, isNull);
    expect(snapshot.goal.frequency, isNull);
    expect(snapshot.reminder, isNull);
    expect(snapshot.milestones.single.id, 'done-step');
    expect(snapshot.milestones.single.title, '完成进阶课程');
    expect(snapshot.milestones.single.isDone, isTrue);
    expect(snapshot.milestones.single.doneAt, doneAt);
  });
}
