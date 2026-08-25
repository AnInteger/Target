import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/features/goals/goal_editor.dart';

Future<AppDatabase> pumpEditor(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: MaterialApp(theme: AppTheme.light(), home: const GoalEditorPage()),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

void main() {
  testWidgets(
    'editor starts with the required goal name and no template copy',
    (tester) async {
      final db = await pumpEditor(tester);
      addTearDown(db.close);
      expect(find.text('目标名称'), findsOneWidget);
      expect(find.textContaining('模板'), findsNothing);
      expect(find.text('为什么想完成'), findsNothing);
      expect(find.text('一句话描述'), findsNothing);
    },
  );

  testWidgets('type switch shows relevant fields and keeps per-type drafts', (
    tester,
  ) async {
    final db = await pumpEditor(tester);
    addTearDown(db.close);

    await tester.tap(find.text('长期'));
    await tester.pumpAndSettle();
    expect(find.text('目标日期'), findsOneWidget);
    expect(find.text('每 14 天检查一次进展'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('firstPlanField')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('firstPlanField')),
      '完成 DSD 体验潜水',
    );

    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('习惯'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('habitFrequencyField')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('执行频率'), findsOneWidget);
    expect(find.text('每周 5 次'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('长期'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('firstPlanField')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('完成 DSD 体验潜水'), findsOneWidget);
  });

  testWidgets(
    'icon selection shows inferred category and a correction action',
    (tester) async {
      final db = await pumpEditor(tester);
      addTearDown(db.close);
      expect(find.textContaining('自动分类'), findsOneWidget);
      expect(find.text('更正'), findsOneWidget);
      expect(find.byKey(const ValueKey('goalIconMoreButton')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('goalIconMoreButton')));
      await tester.pumpAndSettle();
      expect(find.text('选择目标图标'), findsOneWidget);
      expect(find.text('骑行'), findsOneWidget);
      expect(find.text('学习'), findsWidgets);
    },
  );

  testWidgets('save persists short cadence and a nonblank first milestone', (
    tester,
  ) async {
    final db = await pumpEditor(tester);
    addTearDown(db.close);
    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '拿到 OW 潜水证',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('firstPlanField')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('firstPlanField')),
      '完成 DSD 体验潜水',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    final goal = (await GoalRepository(db).getGoals()).single;
    expect(goal.progressCadenceDays, 7);
    expect(goal.deadline, isNotNull);
    expect(
      (await GoalRepository(db).stepsOf(goal.id)).single.title,
      '完成 DSD 体验潜水',
    );
    expect(await ReminderRepository(db).all(), isEmpty);
  });

  testWidgets('深链直达新建目标后保存会回首页', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final router = GoRouter(
      initialLocation: '/goal-editor',
      routes: [
        GoRoute(
          path: '/today',
          builder: (_, _) => const Scaffold(body: Text('首页')),
        ),
        GoRoute(
          path: '/goal-editor',
          builder: (_, _) => const GoalEditorPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('goalNameField')),
      '拿到 OW 潜水证',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
