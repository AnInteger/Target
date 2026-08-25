import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/providers.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/features/goals/progress_record_sheet.dart';

void main() {
  testWidgets(
    'record sheet keeps milestone completion and next plan together',
    (tester) async {
      const today = LocalDate(2026, 8, 25);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final goal = Goal(
        id: 'g',
        name: '拿到 OW 潜水证',
        goalType: GoalType.longTerm,
        iconKey: 'pool',
        colorKey: '',
        createdAt: const LocalDate(2026, 8, 1),
      );
      final current = MilestoneStep(
        id: 'm1',
        goalId: 'g',
        title: '完成 DSD 体验潜水',
      );
      final goals = GoalRepository(db);
      await goals.create(goal);
      await goals.addStep(current);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            dateProviderProvider.overrideWith(
              (ref) => FixedDateProvider(today.atStartOfDay),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showProgressRecordSheet(
                    context,
                    goal: goal,
                    currentStep: current,
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('记录进展'), findsOneWidget);
      expect(find.byKey(const ValueKey('nextMilestoneField')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('progressNoteField')),
        '完成 DSD',
      );
      await tester.tap(find.text('同时完成当前里程碑'));
      await tester.pumpAndSettle();
      expect(find.text('完成 DSD 体验潜水'), findsOneWidget);
      expect(find.byKey(const ValueKey('nextMilestoneField')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('nextMilestoneField')),
        '完成理论课程',
      );
      await tester.tap(find.text('保存进展'));
      await tester.pumpAndSettle();

      expect((await CheckInRepository(db).all()).single.note, '完成 DSD');
      final savedSteps = await goals.stepsOf('g');
      expect(savedSteps.first.isDone, isTrue);
      expect(savedSteps.last.title, '完成理论课程');
    },
  );

  testWidgets('failed save keeps the sheet and entered text', (tester) async {
    const today = LocalDate(2026, 8, 25);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final goal = Goal(
      id: 'g',
      name: '拿到 OW 潜水证',
      goalType: GoalType.longTerm,
      iconKey: 'pool',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
    );
    final missingStep = MilestoneStep(
      id: 'missing',
      goalId: 'g',
      title: '不会丢失的输入',
    );
    await GoalRepository(db).create(goal);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          dateProviderProvider.overrideWith(
            (ref) => FixedDateProvider(today.atStartOfDay),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showProgressRecordSheet(
                  context,
                  goal: goal,
                  currentStep: missingStep,
                ),
                child: const Text('打开失败场景'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开失败场景'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('progressNoteField')),
      '不会丢失的输入',
    );
    await tester.tap(find.text('同时完成当前里程碑'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存进展'));
    await tester.tap(find.text('保存进展'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('progressRecordSheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('progressSaveError')), findsOneWidget);
    expect(find.text('不会丢失的输入'), findsWidgets);
  });
}
