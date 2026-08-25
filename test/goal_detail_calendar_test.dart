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
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/features/goals/goal_detail.dart';

const _today = LocalDate(2026, 8, 25);
final _recordedDay = _today.addDays(-2);

Future<AppDatabase> _pumpGoalDetail(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final db = AppDatabase(NativeDatabase.memory());
  final goals = GoalRepository(db);
  await goals.create(
    Goal(
      id: 'ow',
      name: '拿到 OW 潜水证',
      goalType: GoalType.longTerm,
      iconKey: 'pool',
      colorKey: '',
      createdAt: const LocalDate(2026, 7, 1),
      targetDate: const LocalDate(2026, 12, 31),
    ),
  );
  await goals.addStep(MilestoneStep(id: 'm1', goalId: 'ow', title: '完成理论课程'));
  await CheckInRepository(db).add(
    'ow',
    _recordedDay,
    _today.atStartOfDay.add(const Duration(hours: 9)),
    note: '已完成理论复习',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        dateProviderProvider.overrideWith(
          (ref) => FixedDateProvider(_today.atStartOfDay),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const GoalDetailPage(goalId: 'ow'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _disposeDetail(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  await db.close();
}

void main() {
  testWidgets('detail card exposes a recognizable seven-day calendar', (
    tester,
  ) async {
    final db = await _pumpGoalDetail(tester);

    expect(find.text('今日进展'), findsOneWidget);
    expect(find.text('最近 7 天'), findsOneWidget);
    expect(find.text('8月19日 – 8月25日'), findsOneWidget);
    expect(find.text('已记录'), findsWidgets);
    expect(find.text('可补记'), findsWidgets);
    expect(
      find.byKey(ValueKey('detailDay-${_today.isoString}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('detailDay-${_recordedDay.isoString}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('detailOpenCalendar')), findsOneWidget);
    await _disposeDetail(tester, db);
  });

  testWidgets('empty past days open backfill and recorded days open records', (
    tester,
  ) async {
    final db = await _pumpGoalDetail(tester);
    final emptyDay = _today.addDays(-1);

    await tester.tap(find.byKey(ValueKey('detailDay-${emptyDay.isoString}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('backfillSheet')), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('detailDay-${_recordedDay.isoString}')),
    );
    await tester.pumpAndSettle();
    final recordsSheet = find.byKey(const ValueKey('dayRecordsSheet'));
    expect(recordsSheet, findsOneWidget);
    expect(
      find.descendant(of: recordsSheet, matching: find.text('已完成理论复习')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: recordsSheet, matching: find.text('补记')),
      findsOneWidget,
    );
    await _disposeDetail(tester, db);
  });

  testWidgets('missing goal returns to today with a clear message', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final router = GoRouter(
      initialLocation: '/goal/missing',
      routes: [
        GoRoute(
          path: '/today',
          builder: (_, _) => const Scaffold(
            key: ValueKey('missingGoalFallback'),
            body: SizedBox.shrink(),
          ),
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
          dateProviderProvider.overrideWith(
            (ref) => FixedDateProvider(_today.atStartOfDay),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('missingGoalFallback')), findsOneWidget);
    expect(find.text('目标不存在或已删除'), findsOneWidget);
    await _disposeDetail(tester, db);
  });
}
