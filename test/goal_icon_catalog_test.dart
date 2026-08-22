import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/goal_icon_catalog.dart';

/// GoalIconCatalog 单测（003 · T008）——key 唯一性 / 领域覆盖 / 旧键映射
/// 完备性 / 与原型侧 goal-icons.js 的键名对账（防两侧漂移）。
/// 004 T005 增补：十领域 → 三大类归属对账 + Goal.major 派生兜底。
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

  test('十领域 → 三大类归属对账（004 T005·D4；social/pets→健康为 2026-08-23 用户裁定 B）', () {
    const expected = <GoalIconDomain, MajorCategory>{
      GoalIconDomain.fitness: MajorCategory.health,
      GoalIconDomain.health: MajorCategory.health,
      GoalIconDomain.mind: MajorCategory.health,
      GoalIconDomain.social: MajorCategory.health,
      GoalIconDomain.pets: MajorCategory.health,
      GoalIconDomain.life: MajorCategory.habit,
      GoalIconDomain.learning: MajorCategory.goal,
      GoalIconDomain.create: MajorCategory.goal,
      GoalIconDomain.travel: MajorCategory.goal,
      GoalIconDomain.finance: MajorCategory.goal,
    };
    // 十域逐一登记、无遗漏无多余。
    expect(GoalIconDomain.values.toSet(), expected.keys.toSet());
    for (final d in GoalIconDomain.values) {
      expect(d.major, expected[d], reason: '${d.name} 归属与裁决不符');
    }
    // 大类键名（冻结为未来持久化键）与中文界面名。
    expect(MajorCategory.values.map((m) => m.name), ['health', 'habit', 'goal']);
    expect(MajorCategory.values.map((m) => m.zhLabel), ['健康', '习惯', '目标']);
  });

  test('Goal.major 派生与未匹配 iconKey 兜底（004 T005）', () {
    Goal goalOf(String iconKey) => Goal(
        id: 'g',
        name: '样例',
        goalType: GoalType.habit,
        iconKey: iconKey,
        colorKey: '',
        createdAt: const LocalDate(2026, 8, 23));
    expect(goalOf('directions_run').major, MajorCategory.health); // 运动→健康
    expect(goalOf('savings').major, MajorCategory.goal); // 理财→目标
    expect(goalOf('home').major, MajorCategory.habit); // 生活→习惯
    expect(goalOf('pets').major, MajorCategory.health); // 宠物→健康（裁定 B）
    // 未匹配 → explore（travel 域）→ 目标大类。
    expect(goalOf('not_a_key').major, MajorCategory.goal);
    expect(goalOf('').major, MajorCategory.goal);
  });
}
