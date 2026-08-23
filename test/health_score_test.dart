/// T018：三大类健康度纯函数——contracts/health-score.md 全量对账。
/// 口径：100−3×近 7 天零记录活跃目标数，clamp(0,100)；窗口含今日
/// 滚动 7 天；补签同计；撤销行不计；暂停不参与；类内零活跃 = 无数据。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/providers.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/goal_icon_catalog.dart';
import 'package:target/core/models/health_score.dart';

LocalDate _date(int y, int m, int d) => LocalDate(y, m, d);

/// 2026-08-19 周三锚点（与其余测试同锚）。
final LocalDate _today = _date(2026, 8, 19);

Goal _goal(
  String id, {
  required String iconKey,
  GoalStatus status = GoalStatus.active,
}) {
  return Goal(
    id: id,
    name: id,
    goalType: GoalType.habit,
    iconKey: iconKey,
    colorKey: 'teal',
    status: status,
    createdAt: _today.addDays(-30),
  );
}

CheckIn _check(String goalId, LocalDate day) => CheckIn(
  goalId: goalId,
  day: day,
  createdAt: day.atStartOfDay.add(const Duration(hours: 9)),
);

void main() {
  group('① 契约验收对账（quickstart 造数同款）', () {
    test('健康 2（其一 7 天前末次）/ 习惯 1 今日 / 目标 1 暂停 → 97/100/无数据', () {
      final goals = [
        _goal('h1', iconKey: 'directions_run'), // 健康 · 活跃有记录
        _goal('h2', iconKey: 'self_improvement'), // 健康 · 末次记录 t-7（窗外）
        _goal('b1', iconKey: 'home'), // 习惯 · 今日打卡
        _goal('g1', iconKey: 'menu_book', status: GoalStatus.paused),
      ];
      final checks = [
        _check('h1', _today),
        _check('h2', _today.addDays(-7)), // 恰在窗口外
        _check('b1', _today),
      ];
      final s = evaluateHealth(goals: goals, checkIns: checks, today: _today);
      expect(s.byCategory[MajorCategory.health]!.score, 97);
      expect(s.byCategory[MajorCategory.habit]!.score, 100);
      expect(s.byCategory[MajorCategory.goal]!.hasData, isFalse); // 暂停不参与
      expect(s.isEmpty, isFalse); // 库内有活跃
    });

    test('打卡即清零：给零记录目标补一行 → 类分即时回升 100', () {
      final goals = [_goal('h1', iconKey: 'directions_run')];
      final s0 = evaluateHealth(
        goals: goals,
        checkIns: const [],
        today: _today,
      );
      expect(s0.byCategory[MajorCategory.health]!.score, 97);
      final s1 = evaluateHealth(
        goals: goals,
        checkIns: [_check('h1', _today)],
        today: _today,
      );
      expect(s1.byCategory[MajorCategory.health]!.score, 100);
    });
  });

  group('② 零记录判定', () {
    test('窗口边界：t-6 计入、t-7 移出（含今日滚动 7 天）', () {
      final goals = [_goal('h1', iconKey: 'directions_run')];
      final inner = evaluateHealth(
        goals: goals,
        checkIns: [_check('h1', _today.addDays(-6))],
        today: _today,
      );
      expect(inner.byCategory[MajorCategory.health]!.score, 100);
      final outer = evaluateHealth(
        goals: goals,
        checkIns: [_check('h1', _today.addDays(-7))],
        today: _today,
      );
      expect(outer.byCategory[MajorCategory.health]!.score, 97);
    });

    test('补签同计：过去日一行即非零；撤销行不构成记录', () {
      final goals = [_goal('h1', iconKey: 'directions_run')];
      final backfilled = evaluateHealth(
        goals: goals,
        checkIns: [_check('h1', _today.addDays(-5))],
        today: _today,
      );
      expect(backfilled.byCategory[MajorCategory.health]!.score, 100);
      final revoked = evaluateHealth(
        goals: goals,
        checkIns: [_check('h1', _today).revoked()],
        today: _today,
      );
      expect(revoked.byCategory[MajorCategory.health]!.score, 97);
    });
  });

  group('③ 阶梯与穿底', () {
    test('N 个零记录 → 100−3N（97/94/91…）', () {
      final goals = [
        for (var i = 0; i < 5; i++) _goal('h$i', iconKey: 'directions_run'),
      ];
      // 仅 h0 有窗口内记录 → 4 个零记录 → 100−12。
      final s = evaluateHealth(
        goals: goals,
        checkIns: [_check('h0', _today)],
        today: _today,
      );
      expect(s.byCategory[MajorCategory.health]!.zeroRecordGoals, 4);
      expect(s.byCategory[MajorCategory.health]!.score, 88);
    });

    test('穿底夹 0：34 个零记录（100−102）→ 0 不为负', () {
      final goals = [
        for (var i = 0; i < 34; i++) _goal('h$i', iconKey: 'directions_run'),
      ];
      final s = evaluateHealth(goals: goals, checkIns: const [], today: _today);
      expect(s.byCategory[MajorCategory.health]!.score, 0);
    });
  });

  group('④ 参与集合', () {
    test('暂停/归档/已达成均不参与扣分也不占活跃位', () {
      final goals = [
        _goal('p1', iconKey: 'directions_run', status: GoalStatus.paused),
        _goal('a1', iconKey: 'self_improvement', status: GoalStatus.archived),
        _goal('d1', iconKey: 'favorite', status: GoalStatus.achieved),
      ];
      final s = evaluateHealth(goals: goals, checkIns: const [], today: _today);
      expect(s.byCategory[MajorCategory.health]!.hasData, isFalse);
      expect(s.isEmpty, isTrue); // 全库零活跃 → 环区让位空态
    });

    test('恢复暂停目标且 7 天零记录 → 环出现且 97（契约验收 4）', () {
      final goals = [
        _goal('g1', iconKey: 'menu_book', status: GoalStatus.paused),
      ];
      final paused = evaluateHealth(
        goals: goals,
        checkIns: const [],
        today: _today,
      );
      expect(paused.byCategory[MajorCategory.goal]!.hasData, isFalse);
      final resumed = evaluateHealth(
        goals: [_goal('g1', iconKey: 'menu_book')],
        checkIns: const [],
        today: _today,
      );
      expect(resumed.byCategory[MajorCategory.goal]!.score, 97);
    });
  });

  group('⑤ 大类归属（FR-014 静态映射）', () {
    test('十领域分桶：5 健康 / 1 习惯 / 4 目标', () {
      final goals = [
        _goal('fit', iconKey: 'directions_run'), // 运动 → 健康
        _goal('hea', iconKey: 'favorite'), // 健康 → 健康
        _goal('mind', iconKey: 'spa'), // 冥想 → 健康
        _goal('soc', iconKey: 'groups'), // 社交 → 健康
        _goal('pet', iconKey: 'pets'), // 宠物 → 健康
        _goal('life', iconKey: 'restaurant'), // 生活 → 习惯
        _goal('learn', iconKey: 'menu_book'), // 学习 → 目标
        _goal('cre', iconKey: 'brush'), // 创作 → 目标
        _goal('tra', iconKey: 'flight'), // 旅行 → 目标
        _goal('fin', iconKey: 'savings'), // 理财 → 目标
      ];
      final s = evaluateHealth(goals: goals, checkIns: const [], today: _today);
      expect(s.byCategory[MajorCategory.health]!.activeGoals, 5);
      expect(s.byCategory[MajorCategory.habit]!.activeGoals, 1);
      expect(s.byCategory[MajorCategory.goal]!.activeGoals, 4);
      // 全零记录时的分：100−15 / 97 / 88。
      expect(s.byCategory[MajorCategory.health]!.score, 85);
      expect(s.byCategory[MajorCategory.habit]!.score, 97);
      expect(s.byCategory[MajorCategory.goal]!.score, 88);
    });
  });

  group('⑥ 跨天窗口右移', () {
    test('昨日边界记录随跨天移出窗口 → 类分回落', () {
      final goals = [_goal('h1', iconKey: 'directions_run')];
      final atEdge = _check('h1', _today.addDays(-6)); // 恰在今日窗口左缘
      final today = evaluateHealth(
        goals: goals,
        checkIns: [atEdge],
        today: _today,
      );
      expect(today.byCategory[MajorCategory.health]!.score, 100);
      // 跨天：窗口整体右移一天，原左缘记录落在窗外。
      final tomorrow = evaluateHealth(
        goals: goals,
        checkIns: [atEdge],
        today: _today.addDays(1),
      );
      expect(tomorrow.byCategory[MajorCategory.health]!.score, 97);
    });

    test('长期零记录目标保持扣分（跨天不自动回升）', () {
      final goals = [_goal('h1', iconKey: 'directions_run')];
      for (final offset in [0, 1, 7]) {
        final s = evaluateHealth(
          goals: goals,
          checkIns: const [],
          today: _today.addDays(offset),
        );
        expect(s.byCategory[MajorCategory.health]!.score, 97);
      }
    });
  });

  group('⑦ healthScoreProvider（T019 接线：流变化失效重算 + 跨天联动）', () {
    test('未就绪 null → 到齐出分 → 打卡回流即回升 → 跨天窗口右移', () async {
      final goals = StreamController<List<Goal>>.broadcast(sync: true);
      final checks = StreamController<List<CheckIn>>.broadcast(sync: true);
      final container = ProviderContainer(
        overrides: [
          goalsProvider.overrideWith((ref) => goals.stream),
          checkInsProvider.overrideWith((ref) => checks.stream),
          // 时钟锚到测试日期（SystemDateProvider 会读到真实系统日，窗口错位）。
          dateProviderProvider.overrideWith(
            (ref) => FixedDateProvider(
              _today.atStartOfDay.add(const Duration(hours: 8)),
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        goals.close();
        checks.close();
      });

      // 两流任一未就绪 → null（三环加载态）。
      expect(container.read(healthScoreProvider), isNull);
      goals.add([_goal('h1', iconKey: 'directions_run')]);
      await pumpEventQueue();
      expect(container.read(healthScoreProvider), isNull); // checkIns 仍缺
      checks.add(const <CheckIn>[]); // 流就绪但零记录 → 97（100−3×1）
      await pumpEventQueue();
      expect(
        container
            .read(healthScoreProvider)!
            .byCategory[MajorCategory.health]!
            .score,
        97,
      );

      // checkIns 流变化（新打卡行替换全表）→ 失效重算：扣分目标回升。
      checks.add([_check('h1', _today.addDays(-6))]); // 恰在窗口左缘
      await pumpEventQueue();
      expect(
        container
            .read(healthScoreProvider)!
            .byCategory[MajorCategory.health]!
            .score,
        100,
      );

      // dayTicker 语义：dateProvider 切换 → todayProvider 变化 → 窗口
      // 整体右移，原左缘记录移出 → 类分回落。
      container.read(dateProviderProvider.notifier).state = FixedDateProvider(
        _today.addDays(1).atStartOfDay.add(const Duration(hours: 8)),
      );
      await pumpEventQueue();
      expect(
        container
            .read(healthScoreProvider)!
            .byCategory[MajorCategory.health]!
            .score,
        97,
      );
    });
  });
}
