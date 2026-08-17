// App Shell 冒烟测试（T014）：内存库 + 启动到今日页占位。
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/app.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/db/app_database.dart';

void main() {
  testWidgets('boots to Today placeholder', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const TargetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Target'), findsWidgets);
    await db.close();
  });
}
