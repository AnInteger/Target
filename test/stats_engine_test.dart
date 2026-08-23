/// 统计引擎口径测试（003 收敛版，contracts/goal-type-model.md）。
///
/// 只生产四输出：streak 连续留痕 / 周留痕天数 / 周记录数 / 全完成日；
/// 今日环 = 当日 ≥1 次打卡（0→1 封顶）；适用日/达标判定已退役。
/// 纯函数 + 注入 today（时间旅行）；引擎是所有数字的唯一事实来源。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/stats/stats_engine.dart';

/// 固定时间旅行锚点：2026-08-19 周三（当周周一 2026-08-17）。
final LocalDate _today = const LocalDate(2026, 8, 19);
final WeekStart _thisWeek = WeekStart.containing(_today); // 周一 2026-08-17
final WeekStart _lastWeek = _thisWeek.previous; // 周一 2026-08-10

/// 测试脚手架：goal + 打卡一把梭（003 起引擎不消费频率版本）。
class EngineFixture {
  EngineFixture()
    : goals = <Goal>[],
      checkIns = <CheckIn>[],
      busySessions = <BusyModeSession>[];

  final List<Goal> goals;
  final List<CheckIn> checkIns;
  final List<BusyModeSession> busySessions;

  Goal addGoal(
    String id, {
    GoalType type = GoalType.habit,
    GoalStatus status = GoalStatus.active,
    LocalDate createdAt = const LocalDate(2026, 8, 3),
    LocalDate? deadline,
  }) {
    final g = Goal(
      id: id,
      name: '目标$id',
      goalType: type,
      iconKey: 'star',
      colorKey: 'teal',
      status: status,
      createdAt: createdAt,
      deadline: type == GoalType.shortTerm
          ? (deadline ?? const LocalDate(2026, 10, 1))
          : null,
    );
    goals.add(g);
    return g;
  }

  /// 当日打卡（createdAt = 当天 09:00 本地 → 非补签）。
  void checkIn(String goalId, LocalDate day, {bool revoked = false}) {
    checkIns.add(
      CheckIn(
        goalId: goalId,
        day: day,
        createdAt: DateTime(day.year, day.month, day.day, 9),
        status: revoked ? CheckInStatus.revoked : CheckInStatus.valid,
      ),
    );
  }

  /// 补签：过去某日，操作时刻 = today 12:00（isBackfill 自动判定为 true）。
  void backfill(String goalId, LocalDate day) {
    checkIns.add(
      CheckIn(
        goalId: goalId,
        day: day,
        createdAt: DateTime(_today.year, _today.month, _today.day, 12),
      ),
    );
  }

  StatsEvaluation evaluate({LocalDate? today}) => StatsEngine.evaluate(
    goals: goals,
    busySessions: busySessions,
    checkIns: checkIns,
    today: today ?? _today,
  );
}

void main() {
  test('自然日归属：23:59 与 00:01 分属两日，补签标记随自然日切换', () {
    final f = EngineFixture()..addGoal('g');
    // 08-18 当天 23:59 打卡 → 归属 18 日、非补签。
    f.checkIns.add(
      CheckIn(
        goalId: 'g',
        day: const LocalDate(2026, 8, 18),
        createdAt: DateTime(2026, 8, 18, 23, 59),
      ),
    );
    // 08-19 00:01 为 18 日补卡 → 归属 18 日、补签。
    f.checkIns.add(
      CheckIn(
        goalId: 'g',
        day: const LocalDate(2026, 8, 18),
        createdAt: DateTime(2026, 8, 19, 0, 1),
      ),
    );

    final r = f.evaluate();
    final d18 = r.dayStatusOf('g', const LocalDate(2026, 8, 18));
    expect(d18.doneCount, 2);
    expect(d18.backfilledCount, 1);
    expect(r.dayStatusOf('g').doneCount, 0); // 今天（19 日）无卡
  });

  test('今日环 0→1 封顶：当日 ≥1 次即 done，超额如实计数', () {
    final f = EngineFixture()..addGoal('g');
    final r0 = f.evaluate();
    expect(r0.dayStatusOf('g').done, isFalse);

    f.checkIn('g', _today);
    f.checkIn('g', _today);
    final st = f.evaluate().dayStatusOf('g');
    expect(st.doneCount, 2);
    expect(st.done, isTrue);
  });

  test('三类型均打卡：longTerm/shortTerm 打卡同样计入留痕与电量', () {
    final f = EngineFixture()
      ..addGoal('h')
      ..addGoal('l', type: GoalType.longTerm)
      ..addGoal('s', type: GoalType.shortTerm);
    f.checkIn('h', _today);
    f.checkIn('s', _today);

    final r = f.evaluate();
    expect(r.dayStatusOf('h').done, isTrue);
    expect(r.dayStatusOf('l').done, isFalse);
    expect(r.dayStatusOf('s').done, isTrue);
    expect(r.battery.percent, 67); // 2/3
  });

  group('streak 连续留痕', () {
    test('今天未留痕不 retro 扣（自昨天起算）', () {
      final f = EngineFixture()..addGoal('g');
      f.checkIn('g', const LocalDate(2026, 8, 17));
      f.checkIn('g', const LocalDate(2026, 8, 18));
      final r = f.evaluate();
      expect(r.streakOf('g'), 2);
      f.checkIn('g', _today);
      expect(f.evaluate().streakOf('g'), 3);
    });

    test('中间缺卡日断链', () {
      final f = EngineFixture()..addGoal('g');
      f.checkIn('g', _today);
      f.checkIn('g', const LocalDate(2026, 8, 16)); // 昨天(18)无卡 → 断
      expect(f.evaluate().streakOf('g'), 1);
    });

    test('总 streak：任一目标留痕即续链（跨目标互补）', () {
      final f = EngineFixture()
        ..addGoal('a')
        ..addGoal('b');
      f.checkIn('a', const LocalDate(2026, 8, 17));
      f.checkIn('b', const LocalDate(2026, 8, 18));
      f.checkIn('a', _today);
      final r = f.evaluate();
      expect(r.totalStreak, 3);
      expect(r.streakOf('a'), 1); // 单目标各自断链口径不变
      expect(r.streakOf('b'), 1);
    });
  });

  test('补签计入其归属日，断链接回', () {
    final f = EngineFixture()..addGoal('g');
    f.checkIn('g', _today);
    f.backfill('g', const LocalDate(2026, 8, 18)); // 昨天补签
    final r = f.evaluate();
    expect(r.streakOf('g'), 2);
    expect(r.dayStatusOf('g', const LocalDate(2026, 8, 18)).backfilledCount, 1);
    expect(r.weekStatOf('g', _thisWeek).backfillCount, 1);
  });

  test('撤销记录不计入任何统计，即时回退', () {
    final f = EngineFixture()..addGoal('g');
    f.checkIn('g', _today);
    f.checkIn('g', const LocalDate(2026, 8, 18));
    var r = f.evaluate();
    expect(r.streakOf('g'), 2);
    expect(r.battery.percent, 100);

    // 昨天的卡被撤销 → 连击与电量回退。
    f.checkIns[1] = f.checkIns[1].revoked();
    r = f.evaluate();
    expect(r.dayStatusOf('g', const LocalDate(2026, 8, 18)).doneCount, 0);
    expect(r.streakOf('g'), 1);
    expect(r.battery.percent, 100); // 今天仍留痕
  });

  test('无活跃目标（暂停/归档）→ 电量空态；暂停目标打卡不计入', () {
    final f = EngineFixture()..addGoal('paused', status: GoalStatus.paused);
    f.checkIn('paused', _today);
    expect(f.evaluate().battery.percent, isNull);
  });

  group('周统计：留痕天数 + 记录数', () {
    test('metDays=留痕日数、totalChecks=总次数；同日多次只计 1 留痕日', () {
      final f = EngineFixture()..addGoal('g');
      f.checkIn('g', const LocalDate(2026, 8, 17));
      f.checkIn('g', const LocalDate(2026, 8, 18));
      f.checkIn('g', const LocalDate(2026, 8, 18)); // 同日第二次
      final ws = f.evaluate().weekStatOf('g', _thisWeek);
      expect(ws.metDays, 2);
      expect(ws.totalChecks, 3);
    });

    test('本周只算已过天数（不因周末未到稀释）', () {
      final f = EngineFixture()..addGoal('g');
      f.checkIn('g', const LocalDate(2026, 8, 10));
      f.checkIn('g', const LocalDate(2026, 8, 11));
      f.checkIn('g', const LocalDate(2026, 8, 17));
      f.checkIn('g', const LocalDate(2026, 8, 18));
      final r = f.evaluate();
      expect(r.weekStatOf('g', _thisWeek).metDays, 2);
      final last = r.weekStatOf('g', _lastWeek);
      expect(last.metDays, 2);
      expect(last.totalChecks, 2);
    });

    test('总周统计：跨目标留痕日去重、记录数累加', () {
      final f = EngineFixture()
        ..addGoal('a')
        ..addGoal('b');
      f.checkIn('a', const LocalDate(2026, 8, 17));
      f.checkIn('b', const LocalDate(2026, 8, 17)); // 同日两目标 → 1 留痕日
      f.checkIn('b', const LocalDate(2026, 8, 18));
      final w = f.evaluate().totalWeekStat(_thisWeek);
      expect(w.metDays, 2);
      expect(w.totalChecks, 3);
    });

    test('busyModeApplied：活跃忙碌会话标注该周（003 起仅留痕标注）', () {
      final f = EngineFixture()..addGoal('g');
      f.busySessions.add(
        BusyModeSession(
          weekStart: _thisWeek,
          entries: [
            BusyModeEntry(goalId: 'g', downgraded: const WeeklyFrequency(1)),
          ],
          startedAt: DateTime(2026, 8, 17, 8),
        ),
      );
      final r = f.evaluate();
      expect(r.weekStatOf('g', _thisWeek).busyModeApplied, isTrue);
      expect(r.weekStatOf('g', _lastWeek).busyModeApplied, isFalse);
    });

    test('目标创建前的周 → 零记录零留痕', () {
      final f = EngineFixture()
        ..addGoal('g', createdAt: const LocalDate(2026, 8, 17));
      final ws = f.evaluate().weekStatOf('g', _lastWeek);
      expect(ws.metDays, 0);
      expect(ws.totalChecks, 0);
    });
  });

  test('全完成日：全部活跃目标当日均留痕（无活跃 → false）', () {
    final f = EngineFixture()
      ..addGoal('a')
      ..addGoal('b');
    expect(f.evaluate().allCompleteToday, isFalse);
    f.checkIn('a', _today);
    expect(f.evaluate().allCompleteToday, isFalse);
    f.checkIn('b', _today);
    expect(f.evaluate().allCompleteToday, isTrue);

    // 无活跃目标：不庆祝。
    final empty = EngineFixture();
    expect(empty.evaluate().allCompleteToday, isFalse);
  });

  group('周视图派生（004 US5：概览环比 / 每日活动 / 单目标完成度）', () {
    test('周平均完成率与手工核算一致：2 目标跨 3 天 = 5/6 → 83%', () {
      final f = EngineFixture()
        ..addGoal('a')
        ..addGoal('b');
      // 上周：a 留 2 天、b 留 1 天 → 3/14 → 21%。
      f.checkIn('a', const LocalDate(2026, 8, 10));
      f.checkIn('a', const LocalDate(2026, 8, 11));
      f.checkIn('b', const LocalDate(2026, 8, 10));
      // 本周（截至今日周三）：a 留 3 天、b 留 2 天（18 日两次打卡
      // 留痕仍只计 1 天）→ 5/6 → 83%；环比 +62。
      f.checkIn('a', const LocalDate(2026, 8, 17));
      f.checkIn('a', const LocalDate(2026, 8, 18));
      f.checkIn('a', _today);
      f.checkIn('b', const LocalDate(2026, 8, 17));
      f.checkIn('b', const LocalDate(2026, 8, 18));
      f.checkIn('b', const LocalDate(2026, 8, 18));

      final ov = f.evaluate().weekOverview(_thisWeek);
      expect(ov.rate, 83); // 5/6 = 83.33 → 83
      expect(ov.lastRate, 21); // 3/14 = 21.43 → 21
      expect(ov.delta, 62);
    });

    test('上周零应记 → 环比无可比较；零应记周 → 该周暂无记录', () {
      // 两目标本周一才创建：上周应记 0。
      final f = EngineFixture()
        ..addGoal('a', createdAt: const LocalDate(2026, 8, 17))
        ..addGoal('b', createdAt: const LocalDate(2026, 8, 17));
      f.checkIn('a', const LocalDate(2026, 8, 17));

      final ov = f.evaluate().weekOverview(_thisWeek);
      expect(ov.rate, 17); // 1/6
      expect(ov.lastRate, isNull);
      expect(ov.delta, isNull); // 无可比较
      // 切到上周直接看：该周零应记 → rate null。
      expect(f.evaluate().weekOverview(_lastWeek).rate, isNull);
    });

    test('概览只数当前活跃目标：暂停目标留痕不灌入分子分母', () {
      final f = EngineFixture()
        ..addGoal('a')
        ..addGoal('p', status: GoalStatus.paused);
      f.checkIn('p', const LocalDate(2026, 8, 17)); // 暂停目标本周有留痕
      final ov = f.evaluate().weekOverview(_thisWeek);
      // 活跃池只有 a（0/3）→ 0%，不因 p 的留痕抬高。
      expect(ov.rate, 0);
    });

    test('WeekStart 参数化周切换：同一评估切周各取各的数', () {
      final f = EngineFixture()..addGoal('g');
      f.checkIn('g', const LocalDate(2026, 8, 10)); // 上周
      f.checkIn('g', const LocalDate(2026, 8, 17)); // 本周
      final r = f.evaluate();
      expect(r.weekRateOf('g', _lastWeek).metDays, 1);
      expect(r.weekRateOf('g', _thisWeek).metDays, 1);
      expect(
        r.weekOverview(_thisWeek).lastRate,
        r.weekOverview(_lastWeek).rate,
      );
    });

    test('单目标周完成度：本周截至今日；创建日钳起；无应记 → fraction null', () {
      final f = EngineFixture()..addGoal('g');
      f.checkIn('g', const LocalDate(2026, 8, 18));
      final r = f.evaluate();
      // 本周（8-17 起，今日 8-19）应记 3 天，留 1 天 → 1/3。
      expect(r.weekRateOf('g', _thisWeek).expectedDays, 3);
      expect(r.weekRateOf('g', _thisWeek).metDays, 1);
      expect(r.weekRateOf('g', _thisWeek).fraction, closeTo(1 / 3, 1e-9));
      // 上周整周应记 7 天。
      expect(r.weekRateOf('g', _lastWeek).expectedDays, 7);
      // 周二才创建的目标：上周无应记。
      final mid = EngineFixture()
        ..addGoal('m', createdAt: const LocalDate(2026, 8, 18));
      final rm = mid.evaluate();
      expect(rm.weekRateOf('m', _lastWeek).expectedDays, 0);
      expect(rm.weekRateOf('m', _lastWeek).fraction, isNull);
      expect(rm.weekRateOf('m', _thisWeek).expectedDays, 2); // 周二、三
    });

    test('每日活动点阵：full/partial/none 三档 + checks 全量计数 + 未来日不完成', () {
      final f = EngineFixture()
        ..addGoal('a')
        ..addGoal('b')
        ..addGoal('c', createdAt: const LocalDate(2026, 8, 18)) // 周二创建
        ..addGoal('p', status: GoalStatus.paused);
      f.checkIn('a', const LocalDate(2026, 8, 17));
      f.checkIn('b', const LocalDate(2026, 8, 17));
      f.checkIn('p', const LocalDate(2026, 8, 17)); // 暂停目标留痕只进 checks
      f.checkIn('a', const LocalDate(2026, 8, 18));
      f.checkIn('b', const LocalDate(2026, 8, 18));
      f.checkIn('b', const LocalDate(2026, 8, 18)); // 同日双卡
      f.checkIn('a', _today);

      final days = f.evaluate().dayActivities(_thisWeek);
      expect(days, hasLength(7));
      // 周一：应记 {a,b}（c 未创建、p 暂停）全留痕 → full；checks 含 p。
      expect(days[0].fill, DayFill.full);
      expect(days[0].checks, 3);
      expect(days[0].activeGoals, 2);
      // 周二：应记 {a,b,c}，a/b 留痕 → partial 2/3；checks 3。
      expect(days[1].fill, DayFill.partial);
      expect(days[1].checks, 3);
      // 周三（今日）：应记 3，仅 a → partial 1/3。
      expect(days[2].fill, DayFill.partial);
      expect(days[2].doneGoals, 1);
      // 周四→周日：未来日不完成态（无着色），应记仍 3 但零留痕。
      for (final d in days.sublist(3)) {
        expect(d.isFuture, isTrue);
        expect(d.fill, DayFill.none);
        expect(d.checks, 0);
      }
    });

    test('空库 / 全暂停 → 点阵七天全 none、概览 rate null', () {
      final f = EngineFixture()..addGoal('p', status: GoalStatus.paused);
      f.checkIn('p', _today);
      final r = f.evaluate();
      expect(
        r.dayActivities(_thisWeek).every((d) => d.fill == DayFill.none),
        isTrue,
      );
      expect(r.weekOverview(_thisWeek).rate, isNull);
      // checks 仍如实计数（历史活动不抹除）。
      expect(r.dayActivities(_thisWeek)[2].checks, 1);
    });
  });
}
