import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/models/goal_icon_catalog.dart';

/// GoalIconCatalog 单测（003 · T008）——key 唯一性 / 领域覆盖 / 旧键映射
/// 完备性 / 与原型侧 goal-icons.js 的键名对账（防两侧漂移）。
void main() {
  test('key 唯一（snake_case 即持久化值域）', () {
    final keys = GoalIconCatalog.values.map((i) => i.key).toList();
    expect(keys.toSet().length, keys.length);
    expect(keys.every((k) => RegExp(r'^[a-z][a-z_0-9]+$').hasMatch(k)), isTrue);
  });

  test('领域覆盖 ≥9 且每领域非空', () {
    final byDomain = GoalIconCatalog.byDomain;
    expect(byDomain.length, greaterThanOrEqualTo(9));
    expect(byDomain.values.every((list) => list.isNotEmpty), isTrue);
    expect(byDomain.length, GoalIconDomain.values.length); // 无空域遗漏
  });

  test('总量约 40 枚（38）', () {
    expect(GoalIconCatalog.values.length, 38);
  });

  test('旧 v2 12 键映射完备且目标都在库内', () {
    const legacyKeys = [
      'meal', 'fitness', 'sleep', 'screenRest', 'project', 'travel',
      'read', 'water', 'meditate', 'health', 'family', 'star',
    ];
    expect(legacyIconKeyMap.keys.toSet(), legacyKeys.toSet());
    final inCatalog = GoalIconCatalog.values.map((i) => i.key).toSet();
    for (final target in legacyIconKeyMap.values) {
      expect(inCatalog.contains(target), isTrue,
          reason: '映射目标 $target 不在目录内');
    }
  });

  test('byKey 未知/空键兜底 explore', () {
    expect(GoalIconCatalog.byKey('not_a_key'), GoalIconCatalog.explore);
    expect(GoalIconCatalog.byKey(null), GoalIconCatalog.explore);
    expect(GoalIconCatalog.byKey('directions_bike').icon,
        isNotNull);
  });

  test('migrateIconKey 全路径', () {
    expect(migrateIconKey('meal'), 'restaurant');
    expect(migrateIconKey('star'), 'explore');
    expect(migrateIconKey('unknown_legacy'), 'explore');
    expect(migrateIconKey(null), 'explore');
  });

  test('与原型侧 goal-icons.js 键名对账（直读真文件，38 枚逐一一致）', () {
    // 直读 design/prototypes/goal-icons.js 的 GOAL_ICONS 键清单
    // （flutter test 的 cwd = 包根）。若两侧任一侧增删图标，此测试
    // 失败——迫使同步（D1 零漂移契约）。
    final js = File('design/prototypes/goal-icons.js').readAsStringSync();
    final jsKeys = RegExp(r'^  ([a-z][a-z_0-9]*): \{ domain:', multiLine: true)
        .allMatches(js)
        .map((m) => m.group(1)!)
        .toSet();
    expect(jsKeys, isNotEmpty, reason: '未能从 goal-icons.js 解析出键（文件被移动？）');
    final dartKeys = GoalIconCatalog.values.map((i) => i.key).toSet();
    expect(dartKeys.containsAll(jsKeys), isTrue,
        reason: 'Dart 目录缺：${jsKeys.difference(dartKeys).toList()}');
    expect(jsKeys.containsAll(dartKeys), isTrue,
        reason: 'goal-icons.js 缺：${dartKeys.difference(jsKeys).toList()}');
  });
}
