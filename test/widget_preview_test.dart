/// R13 冒烟：小组件预览页（四家族渲染 + 数据源/亮暗切换）+
/// 置顶大卡新单栏布局（最近记录两端对齐行）。
library;

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/widgets/widget_snapshot.dart';
import 'package:target/features/settings/widget_preview.dart';
import 'package:target/features/shared/goal_card.dart';

import 'cupertino_shell_smoke_test.dart' show testContainer;

void main() {
  testWidgets('小组件预览页：四家族 + 示例/空态切换', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = await testContainer(db);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CupertinoApp(home: WidgetPreviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 标题 + 默认示例数据：小/中组件关键文案。
    expect(find.text('小组件预览'), findsOneWidget);
    expect(find.text('今天的进展记录'), findsOneWidget);
    expect(find.text('练习第一节课程'), findsOneWidget);
    expect(find.text('投入 95 分钟'), findsOneWidget);

    // 切到空态：中组件空文案出现，示例记录消失。
    await tester.tap(find.text('空态'));
    await tester.pumpAndSettle();
    expect(find.text('还没有记录'), findsOneWidget);
    expect(find.text('练习第一节课程'), findsNothing);
  });

  testWidgets('置顶大卡（R13 单栏）：最近记录标签/相对日两端对齐行', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = await testContainer(db);
    final today = container.read(todayProvider);
    await container
        .read(goalRepoProvider)
        .createPlan(
          Goal(
            id: 'g1',
            name: '学会电吉他',
            createdAt: today,
            pinned: true,
            colorKey: 'orange',
            iconKey: 'music',
          ),
          const [],
        );
    await container
        .read(recordRepoProvider)
        .add(
          ProgressRecord(
            goalId: 'g1',
            title: '练习第一节课程',
            body: '音阶模进与手指力量练习',
            day: today,
            createdAt: DateTime.now().toUtc(),
          ),
        );
    await container.read(goalsProvider.future);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: ListView(children: const [GoalCardTestData()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('学会电吉他'), findsOneWidget);
    expect(find.text('最近记录'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('练习第一节课程'), findsOneWidget);
    expect(find.text('音阶模进与手指力量练习'), findsOneWidget);
  });

  testWidgets('预览页目标翻页：示例多页可滑动切换', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = await testContainer(db);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CupertinoApp(home: WidgetPreviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 滚到翻页区：第一页（学会电吉他 · 里程碑行）可见，第二页未构建。
    await tester.scrollUntilVisible(
      find.textContaining('学完初阶课程'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('学完初阶课程'), findsOneWidget);
    expect(find.text('晨跑 8 公里，配速稳定'), findsNothing);

    // 横滑 PageView（整页宽度拖动）→ 第二页。
    final pagerCenter = tester.getCenter(find.byType(PageView));
    await tester.dragFrom(pagerCenter, const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('晨跑 8 公里，配速稳定'), findsOneWidget);
    expect(find.textContaining('完成一次 15 公里长距离'), findsOneWidget);
  });

  test('快照 v4：目标翻页数据页（归档隐去 · 预计算展示串）', () async {
    final today = LocalDate(2026, 9, 10);
    final goal = Goal(
      name: '学会电吉他',
      createdAt: today,
      pinned: true,
      colorKey: 'orange',
      iconKey: 'music_note',
    );
    final record = ProgressRecord(
      goalId: goal.id,
      title: '练习第一节课程',
      day: today,
      createdAt: DateTime(2026, 9, 10, 15, 30).toUtc(),
    );

    // buildTodaySnapshot 为纯函数：直接喂领域对象。
    final snapshot = buildTodaySnapshot(
      goals: [goal],
      records: [record],
      milestones: const [],
      today: today,
      now: DateTime(2026, 9, 10, 16),
    );
    final pages = snapshot['goals']! as List<Map<String, Object?>>;
    expect(pages, hasLength(1));
    expect(pages.first['id'], goal.id);
    expect(pages.first['name'], '学会电吉他');
    expect(pages.first['iconKey'], 'music_note');
    expect(pages.first['latestLabel'], '今天');
    expect(pages.first['latestTitle'], '练习第一节课程');
    expect(pages.first.containsKey('category'), isFalse);

    // 归档目标按契约从小组件隐去。
    final archived = buildTodaySnapshot(
      goals: [goal.copyWith(archivedAt: DateTime(2026, 9, 10).toUtc())],
      records: const [],
      milestones: const [],
      today: today,
      now: DateTime(2026, 9, 10, 16),
    );
    expect(archived['goals'], isEmpty);
  });
}

/// 直接内嵌 GoalCard（绕过整壳路由，聚焦布局）。
class GoalCardTestData extends StatelessWidget {
  const GoalCardTestData({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final goal = ref.watch(goalsProvider).value!.first;
        final records = ref.watch(recordsProvider).value ?? const [];
        return GoalCard(
          goal: goal,
          records: records,
          milestones: const [],
          today: ref.watch(todayProvider),
          onTap: () {},
          onLongPress: () {},
        );
      },
    );
  }
}
