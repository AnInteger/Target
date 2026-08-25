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
import 'package:target/features/today/today_view.dart';

Future<AppDatabase> pumpToday(WidgetTester tester, {Size? size}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const today = LocalDate(2026, 8, 25);
  final db = AppDatabase(NativeDatabase.memory());
  final goals = GoalRepository(db);
  await goals.create(
    Goal(
      id: 'g1',
      name: '拿到 OW 潜水证',
      goalType: GoalType.longTerm,
      iconKey: 'pool',
      colorKey: '',
      createdAt: const LocalDate(2026, 7, 1),
      targetDate: const LocalDate(2026, 12, 31),
    ),
  );
  await goals.create(
    Goal(
      id: 'g2',
      name: '完成产品设计课程',
      goalType: GoalType.shortTerm,
      iconKey: 'school',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      deadline: const LocalDate(2026, 10, 1),
    ),
  );
  await goals.addStep(
    MilestoneStep(
      id: 'm1',
      goalId: 'g1',
      title: '完成 DSD 体验潜水',
      isDone: true,
      doneAt: DateTime.utc(2026, 8, 20),
    ),
  );
  await goals.addStep(
    MilestoneStep(id: 'm2', goalId: 'g1', title: '完成理论课程', position: 1),
  );
  await CheckInRepository(db).add(
    'g1',
    today,
    today.atStartOfDay.add(const Duration(hours: 9)),
    note: '完成潜水理论复习',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        dateProviderProvider.overrideWith(
          (ref) => FixedDateProvider(today.atStartOfDay),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const TodayView()),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('home orders status, focus, progress and attention', (
    tester,
  ) async {
    final db = await pumpToday(tester);
    addTearDown(db.close);
    expect(find.byKey(const ValueKey('goalStatusCard')), findsOneWidget);
    expect(find.text('关注'), findsOneWidget);
    expect(find.text('进展'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('需要关注'),
      240,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(find.text('需要关注'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  });

  testWidgets('focus carousel has a visible inter-card gap', (tester) async {
    final db = await pumpToday(tester);
    addTearDown(db.close);
    final first = find.byKey(const ValueKey('focusCard-g1'));
    final second = find.byKey(const ValueKey('focusCard-g2'));
    final gap = tester.getTopLeft(second).dx - tester.getTopRight(first).dx;
    expect(gap, greaterThanOrEqualTo(12));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  });

  testWidgets('compact width scrolls without overflow', (tester) async {
    final db = await pumpToday(tester, size: const Size(320, 700));
    addTearDown(db.close);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  });
}
