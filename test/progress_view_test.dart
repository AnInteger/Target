import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/features/progress/progress_view.dart';

const _today = LocalDate(2026, 8, 25);

Future<AppDatabase> _pumpProgress(
  WidgetTester tester, {
  bool seedGoal = true,
  bool seedProgress = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final db = AppDatabase(NativeDatabase.memory());
  if (seedGoal) {
    final goals = GoalRepository(db);
    await goals.create(
      Goal(
        id: 'g1',
        name: '拿到 OW 潜水证',
        goalType: GoalType.longTerm,
        iconKey: 'school',
        colorKey: '',
        createdAt: const LocalDate(2026, 7, 1),
        targetDate: const LocalDate(2026, 12, 31),
      ),
    );
    await goals.addStep(MilestoneStep(id: 'm1', goalId: 'g1', title: '完成理论课程'));
    if (seedProgress) {
      await CheckInRepository(db).add(
        'g1',
        _today.addDays(-1),
        _today.atStartOfDay.subtract(const Duration(hours: 12)),
        note: '完成潜水理论复习',
      );
    }
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        dateProviderProvider.overrideWith(
          (ref) => FixedDateProvider(_today.atStartOfDay),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const ProgressView()),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _disposeProgress(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('progress owns trend advice and attention', (tester) async {
    final db = await _pumpProgress(tester);
    addTearDown(db.close);

    expect(find.byKey(const ValueKey('progressTrendCard')), findsOneWidget);
    expect(find.text('近 7 天'), findsOneWidget);
    expect(find.text('需要关注'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('adviceToggle-goal')));
    await tester.pumpAndSettle();
    expect(find.textContaining('指标原理'), findsOneWidget);
    await _disposeProgress(tester);
  });

  testWidgets('progress shows honest empty states', (tester) async {
    final db = await _pumpProgress(tester, seedGoal: false);
    addTearDown(db.close);

    expect(find.byKey(const ValueKey('progressNoTrend')), findsOneWidget);
    expect(find.text('当前没有需要优先处理的计划。'), findsOneWidget);
    await _disposeProgress(tester);
  });

  testWidgets('an active goal without progress does not draw a false trend', (
    tester,
  ) async {
    final db = await _pumpProgress(tester, seedProgress: false);
    addTearDown(db.close);

    expect(find.byKey(const ValueKey('progressNoTrend')), findsOneWidget);
    expect(find.byKey(const ValueKey('progressTrendChart')), findsNothing);
    await _disposeProgress(tester);
  });
}
