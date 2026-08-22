/// US4 周结算与忙碌模式（T036，R4/R8 + research D11）——003 口径收敛版：
/// 周统计 = 留痕天数 + 记录数（不看频率版本）、结算幂等、忙碌周标注与
/// 回落、决策三选落地。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/stats/busy_mode_service.dart';
import 'package:target/core/stats/settlement_service.dart';
import 'package:target/core/stats/stats_engine.dart';

import 'version_seed.dart';

LocalDate _date(int y, int m, int d) => LocalDate(y, m, d);

/// 2026-08-17 周一锚点：结算周 = 上周 08-10 ~ 08-16。
final LocalDate _monday = _date(2026, 8, 17);
final WeekStart _lastWeek = WeekStart.containing(_monday).previous;

class Env {
  final db = AppDatabase(NativeDatabase.memory());
  late final goals = GoalRepository(db);
  late final checkIns = CheckInRepository(db);
  late final reviews = ReviewRepository(db);
  late final settlement = WeeklySettlementService(goals, checkIns, reviews);

  Future<Goal> habit(String name,
      {FrequencyPattern pattern = const DailyFrequency(1),
      GoalStatus status = GoalStatus.active}) async {
    final g = await goals.create(Goal(
      name: name,
      goalType: GoalType.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      status: status,
      createdAt: _lastWeek.monday,
    ));
    // T013 停写：仓储不再建版本；夹具直插存量行（仿真旧库），
    // 供「版本在库也不影响统计口径」断言。
    await seedVersion(db, g.id, pattern, _lastWeek);
    return g;
  }

  Future<void> checkInOn(String goalId, LocalDate day) =>
      checkIns.add(goalId, day, DateTime(day.year, day.month, day.day, 9));

  Future<StatsEvaluation> evaluateLive(LocalDate today) async =>
      StatsEngine.evaluate(
        goals: await goals.getGoals(),
        busySessions: await goals.watchSessions().first,
        checkIns: await checkIns.all(),
        today: today,
      );

  Future<void> close() => db.close();
}

void main() {
  test('R4：周统计只看打卡留痕（频率版本不影响口径）', () async {
    final env = Env();
    addTearDown(env.close);
    // weekly(3) 与 daily(1) 的版本差异不再改变周统计：留痕天数 + 记录数。
    final g = await env.habit('运动', pattern: const WeeklyFrequency(3));
    for (final d
        in [_lastWeek.monday, _lastWeek.monday.addDays(2), _lastWeek.sunday]) {
      await env.checkInOn(g.id, d);
    }
    await env.checkInOn(g.id, _lastWeek.sunday); // 同日第二次
    final w = await env.evaluateLive(_monday).then((s) => s.weekStatOf(g.id, _lastWeek));
    expect(w.metDays, 3);
    expect(w.totalChecks, 4);
  });

  test('周一晨结算：快照入库且幂等防重', () async {
    final env = Env();
    addTearDown(env.close);
    final g = await env.habit('吃饭');
    await env.checkInOn(g.id, _lastWeek.monday);

    final r1 = await env.settlement.settleLastWeekIfNeeded(
        today: _monday, now: DateTime(2026, 8, 17, 8));
    expect(r1.weekStart, _lastWeek);
    expect(r1.snapshot, hasLength(1));
    expect(r1.snapshot.single.goalId, g.id);
    expect(r1.snapshot.single.metDays, 1);
    expect(r1.snapshot.single.totalChecks, 1);

    // 再次结算 → 复用同一行（幂等）。
    final r2 = await env.settlement.settleLastWeekIfNeeded(
        today: _monday, now: DateTime(2026, 8, 17, 9));
    final rows = await env.reviews.all();
    expect(rows, hasLength(1));
    expect(r2.id, r1.id);
    expect(rows.single.settledAt, r1.settledAt);
  });

  test('R8：忙碌周结算标 busyModeApplied；一键恢复后回落（标注消失）', () async {
    final env = Env();
    addTearDown(env.close);
    final g = await env.habit('锻炼', pattern: const DailyFrequency(3));
    // 上周开启忙碌模式（会话 + 降档版本一体）。
    final service = BusyModeService(env.goals);
    await service.activate(
      week: _lastWeek,
      downgradedByGoal: {g.id: const DailyFrequency(1)},
      now: DateTime(2026, 8, 10, 20),
    );
    for (var i = 0; i < 5; i++) {
      await env.checkInOn(g.id, _lastWeek.monday.addDays(i));
    }
    final w = await env
        .evaluateLive(_monday)
        .then((s) => s.weekStatOf(g.id, _lastWeek));
    expect(w.busyModeApplied, true);
    expect(w.metDays, 5); // 留痕口径：每日 1 次即留痕

    // 恢复 = 会话结束 + 版本移除 → 该周标注随之消失。
    final session = (await env.goals.watchSessions().first).single;
    await service.deactivate(session, now: DateTime(2026, 8, 17, 9));
    final after = await env
        .evaluateLive(_monday)
        .then((s) => s.weekStatOf(g.id, _lastWeek));
    expect(after.busyModeApplied, false);
    expect(after.metDays, 5, reason: '历史打卡留痕不受忙碌开关影响');
  });

  test('decision=adjust → 003 停写：不再生成 userEdit 版本', () async {
    final env = Env();
    addTearDown(env.close);
    final g = await env.habit('阅读');
    await env.settlement.settleLastWeekIfNeeded(
        today: _monday, now: DateTime(2026, 8, 17, 8));

    await env.settlement.applyDecision(g.id,
        AdjustDecision(const DailyFrequency(2)),
        today: _monday);

    // 版本表停写：只剩夹具直插的 initial 存量行，无 userEdit。
    final versions = await env.goals.versionsOf(g.id);
    expect(versions.where((v) => v.source == FrequencySource.userEdit),
        isEmpty);
    expect(versions, hasLength(1));

    // 引擎不消费版本：本周统计仍是纯打卡口径。
    final stats = await env.evaluateLive(_monday);
    expect(stats.dayStatusOf(g.id, _monday).doneCount, 0);
  });

  test('decision=pause → 目标置 paused', () async {
    final env = Env();
    addTearDown(env.close);
    final g = await env.habit('喝水');
    await env.settlement.applyDecision(g.id, const PauseDecision(),
        today: _monday);
    final after = (await env.goals.getGoals())
        .where((x) => x.id == g.id)
        .single;
    expect(after.status, GoalStatus.paused);
  });

  test('快照仅含该周有打卡的目标（无留痕/创建于周后剔除）', () async {
    final env = Env();
    addTearDown(env.close);
    await env.habit('吃饭');
    await env.goals.create(Goal(
      name: '旅行',
      goalType: GoalType.longTerm,
      iconKey: 'travel',
      colorKey: 'sky',
      createdAt: _lastWeek.monday,
    ));
    await env.checkInOn(
        (await env.goals.getGoals()).firstWhere((x) => x.name == '吃饭').id,
        _lastWeek.monday);
    // 创建于结算周之后的目标不入快照。
    final late = await env.goals.create(Goal(
      name: '新习惯',
      goalType: GoalType.habit,
      iconKey: 'book',
      colorKey: 'indigo',
      createdAt: _monday,
    ));

    final r = await env.settlement.settleLastWeekIfNeeded(
        today: _monday, now: DateTime(2026, 8, 17, 8));
    expect(r.snapshot.map((s) => s.goalId), isNot(contains(late.id)));
    expect(r.snapshot, hasLength(1));
  });

  group('BusyModeService（FR-018 当周生效/一键恢复）', () {
    test('降档建议口径', () {
      final s = BusyModeService(Env().goals);
      expect(s.suggestedDowngrade(const DailyFrequency(3)), const DailyFrequency(1));
      expect(s.suggestedDowngrade(const WeeklyFrequency(3)), const WeeklyFrequency(1));
      expect(s.suggestedDowngrade(const WeeklyFrequency(5)), const WeeklyFrequency(2));
      expect(s.isFloor(const DailyFrequency(1)), isTrue);
      expect(s.isFloor(const DailyFrequency(3)), isFalse);
    });

    test('一键开启当周生效 → 一键恢复回落', () async {
      final env = Env();
      addTearDown(env.close);
      final g = await env.habit('锻炼', pattern: const DailyFrequency(3));
      final service = BusyModeService(env.goals);
      final thisWeek = WeekStart.containing(_monday);

      final session = await service.activate(
        week: thisWeek,
        downgradedByGoal: {g.id: const DailyFrequency(1)},
        now: DateTime(2026, 8, 17, 20),
      );
      expect(session.isActive, isTrue);
      final during = await env.evaluateLive(_monday);
      expect(during.weekStatOf(g.id, thisWeek).busyModeApplied, true); // 当周即生效

      await service.deactivate(session, now: DateTime(2026, 8, 18, 9));
      final after = await env.evaluateLive(_monday.addDays(1));
      expect(after.weekStatOf(g.id, thisWeek).busyModeApplied, false);
      final sessions = await env.goals.watchSessions().first;
      expect(sessions.single.isActive, isFalse);
    });
  });
}
