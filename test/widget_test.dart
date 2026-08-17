// App Shell 冒烟测试（T014 + T022）：内存库启动 → 空库首启进引导页（SC-001）。
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart';

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

    expect(find.textContaining(Copy.dailyBriefTimeLabel), findsOneWidget);
    await db.close();
  });
}
