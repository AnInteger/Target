/// T023：统计引擎口径规则测试（contracts/stats-engine.md R1–R9）。
///
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

/// 测试脚手架：goal + 版本 + 打卡一把梭。
class EngineFixture {
  EngineFixture()
      : goals = <Goal>[],
        versions = <FrequencyVersion>[],
        checkIns = <CheckIn>[];

  final List<Goal> goals;
  final List<FrequencyVersion> versions;
  final List<CheckIn> checkIns;

  Goal addHabit(
    String id, {
    FrequencyPattern pattern = const DailyFrequency(1),
    GoalStatus status = GoalStatus.active,
    LocalDate createdAt = const LocalDate(2026, 8, 3),
  }) {
    final g = Goal(
      id: id,
      name: '目标$id',
      kind: GoalKind.habit,
      iconKey: 'star',
      colorKey: 'teal',
      status: status,
      createdAt: createdAt,
    );
    goals.add(g);
    versions.add(FrequencyVersion(
      id: 'v-$id',
      goalId: id,
      effectiveFromWeek: WeekStart.of(createdAt),
      pattern: pattern,
      source: FrequencySource.initial,
    ));
    return g;
  }

  /// 进行中目标的用户编辑（下周一生效）。
  void addUserEdit(String goalId, FrequencyPattern pattern, WeekStart week) {
    versions.add(FrequencyVersion(
      id: 've-$goalId-${versions.length}',
      goalId: goalId,
      effectiveFromWeek: week,
      pattern: pattern,
      source: FrequencySource.userEdit,
    ));
  }

  void addBusyMode(String goalId, WeekStart week, FrequencyPattern downgraded) {
    versions.add(FrequencyVersion(
      id: 'vb-$goalId-${versions.length}',
      goalId: goalId,
      effectiveFromWeek: week,
      pattern: downgraded,
      source: FrequencySource.busyMode,
    ));
  }

  /// 当日打卡（createdAt = 当天 09:00 本地 → 非补签）。
  void checkIn(String goalId, LocalDate day, {bool revoked = false}) {
    checkIns.add(CheckIn(
      goalId: goalId,
      day: day,
      createdAt: DateTime(day.year, day.month, day.day, 9),
      status: revoked ? CheckInStatus.revoked : CheckInStatus.valid,
    ));
  }

  /// 补签：过去某日，操作时刻 = today 12:00（isBackfill 自动判定为 true）。
  void backfill(String goalId, LocalDate day) {
    checkIns.add(CheckIn(
      goalId: goalId,
      day: day,
      createdAt: DateTime(_today.year, _today.month, _today.day, 12),
    ));
  }

  StatsEvaluation evaluate({LocalDate? today}) => StatsEngine.evaluate(
        goals: goals,
        frequencyVersions: versions,
        busySessions: const [],
        checkIns: checkIns,
        today: today ?? _today,
      );
}

void main() {
  test('R1：23:59 与 00:01 分属两日，补签标记随自然日切换', () {
    final f = EngineFixture()..addHabit('g');
    // 08-18 当天 23:59 打卡 → 归属 18 日、非补签。
    f.checkIns.add(CheckIn(
      goalId: 'g',
      day: const LocalDate(2026, 8, 18),
      createdAt: DateTime(2026, 8, 18, 23, 59),
    ));
    // 08-19 00:01 为 18 日补卡 → 归属 18 日、补签。
    f.checkIns.add(CheckIn(
      goalId: 'g',
      day: const LocalDate(2026, 8, 18),
      createdAt: DateTime(2026, 8, 19, 0, 1),
    ));

    final r = f.evaluate();
    final d18 = r.dayStatusOf('g', const LocalDate(2026, 8, 18));
    expect(d18.doneCount, 2);
    expect(d18.backfilledCount, 1);
    expect(r.dayStatusOf('g').doneCount, 0); // 今天（19 日）无卡
  });

  test('R2：频率版本切换——本周用新版本、上周仍按旧口径', () {
    final f = EngineFixture()
      ..addHabit('g', pattern: const DailyFrequency(2))
      ..addUserEdit('g', const DailyFrequency(1), _thisWeek);
    final r = f.evaluate();
    expect(r.dayStatusOf('g').targetCount, 1); // 本周 daily(1)
    expect(r.dayStatusOf('g', const LocalDate(2026, 8, 16)).targetCount, 2);
  });

  test('R3：当日完成度封顶；电量 = 活跃习惯均值', () {
    final f = EngineFixture()..addHabit('a', pattern: const DailyFrequency(3));
    for (var i = 0; i < 5; i++) {
      f.checkIn('a', _today);
    }
    f.addHabit('b', pattern: const DailyFrequency(2));
    f.checkIn('b', _today); // 1/2 = 50%

    final r = f.evaluate();
    final st = r.dayStatusOf('a');
    expect(st.doneCount, 5); // 超额计入次数
    expect(st.met, isTrue);
    expect(r.battery.percent, 75); // (100 + 50) / 2
  });

  group('R5：连击', () {
    test('今天未达标不 retro 扣（连击截至昨天）', () {
      final f = EngineFixture()..addHabit('g');
      f.checkIn('g', const LocalDate(2026, 8, 17));
      f.checkIn('g', const LocalDate(2026, 8, 18));
      final r = f.evaluate();
      expect(r.streakOf('g'), 2);
      f.checkIn('g', _today);
      expect(f.evaluate().streakOf('g'), 3);
    });

    test('适用日缺卡断链', () {
      final f = EngineFixture()..addHabit('g');
      f.checkIn('g', _today);
      f.checkIn('g', const LocalDate(2026, 8, 16)); // 昨天(18)无卡 → 断
      expect(f.evaluate().streakOf('g'), 1);
    });

    test('非适用日跳过不断链（weekdays 周一三五）', () {
      final f = EngineFixture()
        ..addHabit('g',
            pattern: WeekdaysFrequency(
                {Weekday.mon, Weekday.wed, Weekday.fri}, 1));
      f.checkIn('g', _today); // 周三
      // 周二(18)非适用日跳过
      f.checkIn('g', const LocalDate(2026, 8, 17)); // 周一
      expect(f.evaluate().streakOf('g'), 2);
    });

    test('weekly：达标周内的休整日不断链', () {
      // 今天 = 周六 08-22；本周一/二/三打卡满 weekly(3)，周四五休整。
      final saturday = const LocalDate(2026, 8, 22);
      final f = EngineFixture()..addHabit('g', pattern: const WeeklyFrequency(3));
      f.checkIn('g', const LocalDate(2026, 8, 17));
      f.checkIn('g', const LocalDate(2026, 8, 18));
      f.checkIn('g', const LocalDate(2026, 8, 19));
      expect(f.evaluate(today: saturday).streakOf('g'), 3);
    });
  });

  test('R6：补签计入其归属日，断链接回', () {
    final f = EngineFixture()..addHabit('g');
    f.checkIn('g', _today);
    f.backfill('g', const LocalDate(2026, 8, 18)); // 昨天补签
    final r = f.evaluate();
    expect(r.streakOf('g'), 2);
    expect(r.dayStatusOf('g', const LocalDate(2026, 8, 18)).backfilledCount, 1);
    expect(r.weekStatOf('g', _thisWeek).backfillCount, 1);
  });

  test('R7：撤销记录不计入任何统计，即时回退', () {
    final f = EngineFixture()..addHabit('g');
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
    expect(r.battery.percent, 100); // 今天仍达标
  });

  test('R9：无活跃 habit（里程碑/暂停）→ 电量空态', () {
    final f = EngineFixture()
      ..addHabit('paused', status: GoalStatus.paused);
    f.goals.add(Goal(
      id: 'm',
      name: '去旅行',
      kind: GoalKind.milestone,
      iconKey: 'travel',
      colorKey: 'sky',
      createdAt: const LocalDate(2026, 8, 3),
      deadline: const LocalDate(2026, 10, 1),
    ));
    f.checkIn('paused', _today); // 暂停目标打卡也不计入
    expect(f.evaluate().battery.percent, isNull);
  });

  group('R4/R8：周结算', () {
    test('weekly(N)：适用 7 天、达标日数 ≥ N；过往周实时重算', () {
      final f = EngineFixture()
        ..addHabit('g', pattern: const WeeklyFrequency(3));
      f.checkIn('g', const LocalDate(2026, 8, 17));
      f.checkIn('g', const LocalDate(2026, 8, 18));
      f.checkIn('g', _today);
      final r = f.evaluate();
      final ws = r.weekStatOf('g', _thisWeek);
      expect(ws.applicableDays, 3); // 已过的适用日（周一至周三）
      expect(ws.metDays, 3);
      expect(ws.completionRate, 1.0);

      // 上周：2 次打卡 → metDays 2 / 7 天。
      f.checkIn('g', const LocalDate(2026, 8, 10));
      f.checkIn('g', const LocalDate(2026, 8, 12));
      final last = f.evaluate().weekStatOf('g', _lastWeek);
      expect(last.applicableDays, 7);
      expect(last.metDays, 2);
      expect(last.completionRate, closeTo(2 / 7, 1e-9));
    });

    test('本周完成率只算已过适用日（不因周末未到而稀释）', () {
      final f = EngineFixture()..addHabit('g');
      f.checkIn('g', const LocalDate(2026, 8, 17));
      f.checkIn('g', const LocalDate(2026, 8, 18));
      final ws = f.evaluate().weekStatOf('g', _thisWeek);
      expect(ws.applicableDays, 3);
      expect(ws.metDays, 2);
      expect(ws.completionRate, closeTo(2 / 3, 1e-9));
    });

    test('R8：busyMode 版本口径 + busyModeApplied 标注', () {
      final f = EngineFixture()
        ..addHabit('g', pattern: const DailyFrequency(2))
        ..addBusyMode('g', _thisWeek, const WeeklyFrequency(1));
      final r = f.evaluate();
      final st = r.dayStatusOf('g');
      expect(st.busyMode, isTrue);
      expect(st.targetCount, 1); // weekly 口径：当日 ≥1 次
      expect(st.applicable, isTrue);
      expect(r.weekStatOf('g', _thisWeek).busyModeApplied, isTrue);
      // 上周不受影响。
      expect(r.weekStatOf('g', _lastWeek).busyModeApplied, isFalse);
    });

    test('目标创建前的周 → 无适用日，完成率 null（非 0）', () {
      final f = EngineFixture()
        ..addHabit('g', createdAt: const LocalDate(2026, 8, 17));
      final ws = f.evaluate().weekStatOf('g', _lastWeek);
      expect(ws.applicableDays, 0);
      expect(ws.completionRate, isNull);
    });
  });
}
