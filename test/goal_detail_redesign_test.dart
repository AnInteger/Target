/// 2026-08-25 详情页重设计回归：里程碑卡（卡行 + 追加位序 + 拖拽重排 +
/// 达成日副题 + 空态）与标记达成双通道（轻点校验弹窗 / 长按填充快速
/// 标记），编辑目标/续期常驻行退役。
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/features/goals/goal_detail.dart';

const _today = LocalDate(2026, 8, 25);

Future<AppDatabase> _seed(
  WidgetTester tester, {
  bool withPendingStep = true,
  bool withDoneStep = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final db = AppDatabase(NativeDatabase.memory());
  final goals = GoalRepository(db);
  await goals.create(
    Goal(
      id: 'ow',
      name: '拿到 OW 潜水证',
      goalType: GoalType.shortTerm,
      iconKey: 'pool',
      colorKey: '',
      createdAt: const LocalDate(2026, 7, 1),
      deadline: _today.addDays(30),
    ),
  );
  var pos = 0;
  if (withPendingStep) {
    await goals.addStep(
      MilestoneStep(
        id: 'm1',
        goalId: 'ow',
        title: '预约泳池考试',
        position: pos++,
      ),
    );
  }
  if (withDoneStep) {
    final done = DateTime(2026, 8, 20, 9);
    await goals.addStep(
      MilestoneStep(
        id: 'm2',
        goalId: 'ow',
        title: '完成理论课程',
        position: pos++,
        isDone: true,
        doneAt: done,
      ),
    );
  }
  final router = GoRouter(
    initialLocation: '/goal/ow',
    routes: [
      GoRoute(
        path: '/today',
        builder: (_, _) => const Scaffold(
          key: ValueKey('todayFallback'),
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: '/goal/:id',
        builder: (context, state) =>
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
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _reveal(WidgetTester tester, Key key) async {
  final list = find.descendant(
    of: find.byType(GoalDetailPage),
    matching: find.byType(Scrollable),
  );
  for (var i = 0; i < 8 && find.byKey(key).evaluate().isEmpty; i++) {
    await tester.dragUntilVisible(find.byKey(key), list, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  expect(find.byKey(key), findsOneWidget);
}

void main() {
  test('reorderSteps：按传入顺序整体重写 position 并归一化历史空洞', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final goals = GoalRepository(db);
    await goals.create(
      Goal(
        id: 'g',
        name: '备考',
        goalType: GoalType.shortTerm,
        iconKey: 'menu_book',
        colorKey: '',
        createdAt: _today,
        deadline: _today.addDays(30),
      ),
    );
    // 历史脏数据：位序带洞且乱序。
    await goals.addStep(
      MilestoneStep(id: 'a', goalId: 'g', title: '一', position: 7),
    );
    await goals.addStep(
      MilestoneStep(id: 'b', goalId: 'g', title: '二', position: 2),
    );
    await goals.addStep(
      MilestoneStep(id: 'c', goalId: 'g', title: '三', position: 5),
    );

    await goals.reorderSteps('g', ['c', 'a', 'b']);
    final steps = await goals.stepsOf('g');
    expect(steps.map((s) => s.id), ['c', 'a', 'b']);
    expect(steps.map((s) => s.position), [0, 1, 2]);

    // 别目标的步骤不被误写。
    await goals.create(
      Goal(
        id: 'h',
        name: '另一目标',
        goalType: GoalType.shortTerm,
        iconKey: 'pool',
        colorKey: '',
        createdAt: _today,
        deadline: _today.addDays(30),
      ),
    );
    await goals.addStep(
      MilestoneStep(id: 'x', goalId: 'h', title: '他组', position: 9),
    );
    await goals.reorderSteps('g', ['a']);
    expect((await goals.stepsOf('h')).single.position, 9);
  });

  testWidgets('里程碑：空态引导 → 输入添加追加 → 点行勾选出达成日副题', (
    tester,
  ) async {
    final db = await _seed(tester, withPendingStep: false);

    await _reveal(tester, const ValueKey('stepAddRow'));
    expect(find.text(Copy.milestoneEmptyHint), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('stepInputField')),
      '完成平静水域练习',
    );
    await tester.pump(); // 加号钮随草稿起用（build 期求值）
    await tester.tap(find.byKey(const ValueKey('stepAddButton')));
    await tester.pumpAndSettle();
    // 追加位序：列表从空起 → position 0。
    final seeded = await GoalRepository(db).stepsOf('ow');
    expect(seeded.single.title, '完成平静水域练习');
    expect(seeded.single.position, 0);

    // 点行主区 = 勾选 → 划线 + 「M月d日达成」历史副题。
    await tester.tap(find.byKey(ValueKey('stepCheck-${seeded.single.id}')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.milestoneDoneAt(8, 25)), findsOneWidget);
    expect(
      (await GoalRepository(db).stepsOf('ow')).single.isDone,
      isTrue,
    );
    await db.close();
  });

  testWidgets('里程碑：拖柄重排落库，顺序持久', (tester) async {
    final db = await _seed(tester, withDoneStep: true);
    await _reveal(tester, const ValueKey('stepHandle-m1'));
    // m1（未完成，位 0）在 m2（已完成，位 1）之上。重排拖拽需按住起拖
    //（ReorderableDragStartListener = long-press 识别器），快甩不生效；
    // 且本测试绑定下计时自「起拖后第二帧」才累计——先锚一帧再按住。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('stepHandle-m1'))),
    );
    await tester.pump(const Duration(milliseconds: 50)); // 锚定起帧
    await tester.pump(const Duration(milliseconds: 600)); // 按住 >500ms 起拖
    // 换位阈值约在越过被换行中点 + 自身半高之后（实测 90px 不足，
    // 170px 落换；m2 行含达成日副题较高）。
    await gesture.moveBy(const Offset(0, 170));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    final order = (await GoalRepository(db).stepsOf('ow')).map((s) => s.id);
    expect(order, ['m2', 'm1']);
    await db.close();
  });

  testWidgets('达成 · 轻点：无未完成里程碑 → 温和确认；取消留在详情', (
    tester,
  ) async {
    final db = await _seed(tester, withPendingStep: false, withDoneStep: true);
    await _reveal(tester, const ValueKey('goalMarkAchievedButton'));
    expect(find.text(Copy.achieveHoldCaption), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('goalMarkAchievedButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalAchieveDialog')), findsOneWidget);
    expect(find.text(Copy.achieveConfirmTitle), findsOneWidget);
    expect(find.text(Copy.achieveConfirmBody('拿到 OW 潜水证')), findsOneWidget);

    await tester.tap(find.text(Copy.dialogCancel));
    await tester.pumpAndSettle();
    expect(find.byType(GoalDetailPage), findsOneWidget);
    expect(
      (await GoalRepository(db).getGoals()).single.status,
      GoalStatus.active,
    );
    await db.close();
  });

  testWidgets('达成 · 轻点：有未完成里程碑 → 警示文案 + 确认后落库跳转', (
    tester,
  ) async {
    final db = await _seed(tester); // m1 未完成
    await _reveal(tester, const ValueKey('goalMarkAchievedButton'));

    await tester.tap(find.byKey(const ValueKey('goalMarkAchievedButton')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.achievePendingTitle(1)), findsOneWidget);
    expect(find.text(Copy.achievePendingBody('拿到 OW 潜水证')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('goalAchieveConfirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('todayFallback')), findsOneWidget);
    expect(
      (await GoalRepository(db).getGoals()).single.status,
      GoalStatus.achieved,
    );
    await db.close();
  });

  testWidgets('达成 · 长按：填充完成直接标记（无未完成里程碑时免弹窗）', (
    tester,
  ) async {
    final db = await _seed(tester, withPendingStep: false, withDoneStep: true);
    await _reveal(tester, const ValueKey('goalMarkAchievedButton'));

    final center = tester.getCenter(
      find.byKey(const ValueKey('goalMarkAchievedButton')),
    );
    final gesture = await tester.startGesture(center);
    // 计时自第二帧累计：先锚一帧，再泵到 800ms 填满（1s > 800ms）。
    await tester.pump(const Duration(milliseconds: 50)); // 锚定起帧
    await tester.pump(const Duration(milliseconds: 1000)); // 填充完成
    await gesture.up();
    // 闪示 350ms 是纯 Timer（无帧调度）——pumpAndSettle 会提前停，
    // 需先显式推进到落库再结算导航。
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalAchieveDialog')), findsNothing);
    expect(find.byKey(const ValueKey('todayFallback')), findsOneWidget);
    expect(
      (await GoalRepository(db).getGoals()).single.status,
      GoalStatus.achieved,
    );
    await db.close();
  });

  testWidgets('达成 · 长按中途松手：回弹不清标记、轻点语义不被吞掉', (
    tester,
  ) async {
    final db = await _seed(tester, withPendingStep: false, withDoneStep: true);
    await _reveal(tester, const ValueKey('goalMarkAchievedButton'));

    final center = tester.getCenter(
      find.byKey(const ValueKey('goalMarkAchievedButton')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 50)); // 锚定起帧
    await tester.pump(const Duration(milliseconds: 400)); // 填充 ~0.4 过半
    await gesture.up(); // 中途松手 → 回弹，不达成
    await tester.pumpAndSettle(); // 回弹动画收敛
    expect(
      (await GoalRepository(db).getGoals()).single.status,
      GoalStatus.active,
    );

    // 松手后短促轻点仍应走弹窗通道（回弹不吞轻点）。
    await tester.tap(find.byKey(const ValueKey('goalMarkAchievedButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goalAchieveDialog')), findsOneWidget);
    await db.close();
  });

  testWidgets('退役回归：编辑目标/续期常驻行不再出现（⋯ 菜单保留编辑）', (
    tester,
  ) async {
    final db = await _seed(tester);
    await _reveal(tester, const ValueKey('goalMarkAchievedButton'));
    expect(find.byKey(const ValueKey('goalRenewButton')), findsNothing);
    // 详情正文不再有直达编辑入口（顶栏 ⋯ 菜单里的仍在）。
    expect(find.text(Copy.goalEdit), findsNothing);
    expect(find.byKey(const ValueKey('goalMoreButton')), findsOneWidget);
    await db.close();
  });
}
