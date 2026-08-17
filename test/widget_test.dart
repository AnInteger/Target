// App Shell 冒烟测试（T014 + T022）：内存库启动 → 空库首启进引导页（SC-001）。
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase, SettingsRowsCompanion;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';

void main() {
  testWidgets('空库首启 → 引导页（SC-001）', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.onboardingTitle), findsOneWidget);
    expect(find.text(Copy.onboardingSkip), findsOneWidget);
    await db.close();
  });

  testWidgets('已完成引导 → 直接今日页', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final settings = await (db.select(db.settingsRows)).get();
    expect(settings, isNotEmpty);
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1))).write(
        const SettingsRowsCompanion(onboardingCompleted: Value(true)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // TodayView 空态：无活跃习惯 → 电量"—"（R9），底部导航三标签。
    expect(find.text(Copy.batteryEmpty), findsWidgets);
    expect(find.text(Copy.todayNav), findsOneWidget);
    await db.close();
  });

  testWidgets('US2 微缩验收：打卡 → 进度/成就即时刷新 → 撤销回退', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final today = LocalDate.fromDateTime(DateTime.now());
    final repo = GoalRepository(db);
    final goal = await repo.create(Goal(
      name: '锻炼',
      kind: GoalKind.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      createdAt: today,
    ));
    await repo.addInitial(goal.id, const DailyFrequency(1), WeekStart.containing(today));
    await (db.update(db.settingsRows)..where((t) => t.id.equals(1)))
        .write(const SettingsRowsCompanion(onboardingCompleted: Value(true)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日 0/1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 全部达标 → 成就态替换进度行（US2-6）。
    expect(find.text(Copy.allDoneTitle), findsOneWidget);

    // 撤销 → 统计即时回退（R7/SC-003）。
    await tester.tap(find.text(Copy.undoCheckIn));
    await tester.pumpAndSettle();
    expect(find.text('今日 0/1'), findsOneWidget);
    await db.close();
  });
}
