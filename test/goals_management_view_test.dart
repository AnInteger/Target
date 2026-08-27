/// Task 6：紧凑目标管理页 + 状态感知菜单。
///
/// 覆盖：紧凑行与可见 overflow（无 Today 焦点卡）、状态筛选、
/// 菜单动作按状态显隐、生命周期动作（暂停/恢复/达成/重开/归档/
/// 反归档/确认删除）对仓库状态的持久化、归档保留子数据。
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/features/goals/goal_detail.dart';
import 'package:target/features/goals/goal_editor.dart';
import 'package:target/features/goals/goals_view.dart';

const _today = LocalDate(2026, 8, 25);

Future<void> _seed(AppDatabase db) async {
  final repo = GoalRepository(db);
  Future<void> add(
    String id,
    String name, {
    GoalStatus status = GoalStatus.active,
    DateTime? achievedAt,
    DateTime? archivedAt,
  }) => repo.create(
    Goal(
      id: id,
      name: name,
      goalType: GoalType.shortTerm,
      iconKey: 'menu_book',
      colorKey: '',
      createdAt: _today.addDays(-3),
      status: status,
      achievedAt: achievedAt,
      archivedAt: archivedAt,
    ),
  );

  await add('active', '学习摄影');
  await add('paused', '整理房间', status: GoalStatus.paused);
  await add(
    'achieved',
    '完成体检',
    status: GoalStatus.achieved,
    achievedAt: DateTime(2026, 8, 20, 9),
  );
  await add(
    'archived',
    '旧年度目标',
    status: GoalStatus.active,
    archivedAt: DateTime(2026, 8, 10, 9),
  );

  // active 带里程碑 + 打卡：验证摘要与最近进展排序。
  await repo.addStep(
    MilestoneStep(id: 'm1', goalId: 'active', title: '完成构图课', position: 0),
  );
  await CheckInRepository(db).add(
    'active',
    _today.addDays(-1),
    DateTime(2026, 8, 24, 10),
  );
}

Future<AppDatabase> pumpGoals(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  await _seed(db);
  final router = GoRouter(
    initialLocation: '/goals',
    routes: [
      GoRoute(path: '/goals', builder: (_, _) => const GoalsView()),
      GoRoute(
        path: '/goal-editor',
        builder: (_, state) =>
            GoalEditorPage(goalId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/goal/:id',
        builder: (_, state) =>
            GoalDetailPage(goalId: state.pathParameters['id']!),
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
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// drift 流取消会挂零时长 Timer；先卸树并泵空再关库，让清理定时器
/// 在 timersPending 校验前触发（同 app_journeys harness 口径）。
Future<void> disposeGoals(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  await db.close();
}

Future<Goal?> goalById(AppDatabase db, String id) async {
  final matches = (await GoalRepository(
    db,
  ).getGoals()).where((goal) => goal.id == id).toList();
  return matches.isEmpty ? null : matches.single;
}

void main() {
  testWidgets('renders compact rows with visible overflow and no focus card', (
    tester,
  ) async {
    final db = await pumpGoals(tester);
    expect(find.byKey(const ValueKey('goalListRow-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalOverflow-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('focusCard-active')), findsNothing);
  await disposeGoals(tester, db);
  });

  testWidgets('status filters separate active paused achieved and archived', (
    tester,
  ) async {
    final db = await pumpGoals(tester);

    await tester.tap(find.byKey(const ValueKey('goalFilter-archived')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalListRow-archived')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalListRow-active')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('goalFilter-achieved')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalListRow-achieved')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalListRow-archived')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('goalFilter-paused')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalListRow-paused')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('goalFilter-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalListRow-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalListRow-archived')), findsOneWidget);
  await disposeGoals(tester, db);
  });

  testWidgets('overflow menu exposes state-valid actions', (tester) async {
    final db = await pumpGoals(tester);
    await tester.tap(find.byKey(const ValueKey('goalOverflow-active')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalAction-edit-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-pause-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-achieve-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-archive-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-delete-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-resume-active')), findsNothing);
  await disposeGoals(tester, db);
  });

  testWidgets('paused goals offer resume first', (tester) async {
    final db = await pumpGoals(tester);
    await tester.tap(find.byKey(const ValueKey('goalFilter-paused')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalOverflow-paused')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalAction-resume-paused')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-edit-paused')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-pause-paused')), findsNothing);
  await disposeGoals(tester, db);
  });

  testWidgets('achieved goals offer reopen and archive', (tester) async {
    final db = await pumpGoals(tester);
    await tester.tap(find.byKey(const ValueKey('goalFilter-achieved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalOverflow-achieved')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalAction-reopen-achieved')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-archive-achieved')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-edit-achieved')), findsNothing);
  await disposeGoals(tester, db);
  });

  testWidgets('archived goals offer unarchive and delete only', (tester) async {
    final db = await pumpGoals(tester);
    await tester.tap(find.byKey(const ValueKey('goalFilter-archived')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalOverflow-archived')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalAction-unarchive-archived')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-delete-archived')), findsOneWidget);
    expect(find.byKey(const ValueKey('goalAction-edit-archived')), findsNothing);
    expect(find.byKey(const ValueKey('goalAction-archive-archived')), findsNothing);
  await disposeGoals(tester, db);
  });

  testWidgets('lifecycle actions persist through the menu', (tester) async {
    final db = await pumpGoals(tester);

    Future<void> action(String name, String id) async {
      await tester.tap(find.byKey(ValueKey('goalOverflow-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('goalAction-$name-$id')));
      await tester.pumpAndSettle();
    }

    await action('pause', 'active');
    expect((await goalById(db, 'active'))!.status, GoalStatus.paused);
    await action('resume', 'active');
    expect((await goalById(db, 'active'))!.status, GoalStatus.active);
    await action('achieve', 'active');
    expect((await goalById(db, 'active'))!.status, GoalStatus.achieved);
    await action('reopen', 'active');
    final reopened = await goalById(db, 'active');
    expect(reopened!.status, GoalStatus.active);
    expect(reopened.achievedAt, isNull);
    await action('archive', 'active');
    expect((await goalById(db, 'active'))!.isArchived, isTrue);
  await disposeGoals(tester, db);
  });

  testWidgets('unarchive restores prior lifecycle state and keeps children', (
    tester,
  ) async {
    final db = await pumpGoals(tester);

    await tester.tap(find.byKey(const ValueKey('goalOverflow-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-archive-active')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('goalFilter-archived')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalOverflow-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-unarchive-active')));
    await tester.pumpAndSettle();

    final restored = await goalById(db, 'active');
    expect(restored!.isArchived, isFalse);
    expect(restored.status, GoalStatus.active);
    expect((await GoalRepository(db).stepsOf('active')).single.title, '完成构图课');
  await disposeGoals(tester, db);
  });

  testWidgets('delete requires explicit confirmation', (tester) async {
    final db = await pumpGoals(tester);

    await tester.tap(find.byKey(const ValueKey('goalOverflow-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalAction-delete-active')));
    await tester.pumpAndSettle();
    expect(await goalById(db, 'active'), isNotNull); // 未确认不删除

    final dialog = find.byKey(const ValueKey('goalDeleteDialog'));
    expect(dialog, findsOneWidget);
    await tester.tap(find.descendant(of: dialog, matching: find.text('删除')));
    await tester.pumpAndSettle();
    expect(await goalById(db, 'active'), isNull);
  await disposeGoals(tester, db);
  });

  testWidgets('summary prefers current milestone then recent record', (
    tester,
  ) async {
    final db = await pumpGoals(tester);

    await tester.tap(find.byKey(const ValueKey('goalFilter-active')));
    await tester.pumpAndSettle();
    expect(find.textContaining('当前：完成构图课'), findsOneWidget);

    // paused 无里程碑无记录 → 空态文案。
    await tester.tap(find.byKey(const ValueKey('goalFilter-paused')));
    await tester.pumpAndSettle();
    expect(find.text('尚无进展记录'), findsOneWidget);
  await disposeGoals(tester, db);
  });

  testWidgets('row opens detail and new button opens editor', (tester) async {
    final db = await pumpGoals(tester);

    await tester.tap(find.byKey(const ValueKey('goalListRow-active')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pageTopBarBack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalsNewButton')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalEditorPage), findsOneWidget);
  await disposeGoals(tester, db);
  });
}
