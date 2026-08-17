/// US4 周结算与忙碌模式（T036，R4/R8 + research D11）：
/// weekly 全周口径、结算幂等、忙碌降档结算与回落、决策三选落地。
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
      kind: GoalKind.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      status: status,
      createdAt: _lastWeek.monday,
    ));
    await goals.addInitial(g.id, pattern, _lastWeek);
    return g;
  }

  Future<void> checkInOn(String goalId, LocalDate day) =>
      checkIns.add(goalId, day, DateTime(day.year, day.month, day.day, 9));

  Future<StatsEvaluation> evaluateLive(LocalDate today) async =>
      StatsEngine.evaluate(
        goals: await goals.getGoals(),
        frequencyVersions: await goals.watchAllVersions().first,
        busySessions: await goals.watchSessions().first,
        checkIns: await checkIns.all(),
        today: today,
      );

  Future<void> close() => db.close();
}

void main() {
  test('R4：weekly(3) 全周适用（7 日），达标日=当日≥1 次', () async {
    final env = Env();
    addTearDown(env.close);
    final g = await env.habit('运动', pattern: const WeeklyFrequency(3));
    // 周内 3 天各 1 次 → metDays=3、applicableDays=7。
    for (final d
        in [_lastWeek.monday, _lastWeek.monday.addDays(2), _lastWeek.sunday]) {
      await env.checkInOn(g.id, d);
    }
    final stats = await env.evaluateLive(_monday);
    final w = stats.weekStatOf(g.id, _lastWeek);
    expect(w.applicableDays, 7);
    expect(w.metDays, 3);
    expect(w.completionRate, closeTo(3 / 7, 0.001));
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

    // 再次结算 → 复用同一行（幂等）。
    final r2 = await env.settlement.settleLastWeekIfNeeded(
        today: _monday, now: DateTime(2026, 8, 17, 9));
    final rows = await env.reviews.all();
    expect(rows, hasLength(1));
    expect(r2.id, r1.id);
    expect(rows.single.settledAt, r1.settledAt);
  });

  test('R8：忙碌周按降档口径结算 busyModeApplied；恢复后回落原频率', () async {
    final env = Env();
    addTearDown(env.close);
    final g = await env.habit('锻炼', pattern: const DailyFrequency(3));
    // 上周开启忙碌降档：每日 3 → 1。
    await env.goals.addBusyMode(g.id, _lastWeek, const DailyFrequency(1));
    for (var i = 0; i < 5; i++) {
      await env.checkInOn(g.id, _lastWeek.monday.addDays(i));
    }
    final stats = await env.evaluateLive(_monday);
    final w = stats.weekStatOf(g.id, _lastWeek);
    expect(w.busyModeApplied, true);
    expect(w.metDays, 5); // 降档口径每日 1 次即达标

    // 恢复 = 移除开启那一周的 busyMode 版本 → 本周回落原频率 3。
    await env.goals.removeBusyMode(g.id, _lastWeek);
    final after = await env.evaluateLive(_monday);
    expect(after.dayStatusOf(g.id, _monday).targetCount, 3);
  });

  test('decision=adjust → 生成下周 userEdit 版本，本周口径不变', () async {
    final env = Env();
    addTearDown(env.close);
    final g = await env.habit('阅读');
    await env.settlement.settleLastWeekIfNeeded(
        today: _monday, now: DateTime(2026, 8, 17, 8));

    await env.settlement.applyDecision(g.id,
        AdjustDecision(const DailyFrequency(2)),
        today: _monday);

    final versions = await env.goals.versionsOf(g.id);
    final edit = versions
        .where((v) => v.source == FrequencySource.userEdit)
        .single;
    expect(edit.effectiveFromWeek, WeekStart.containing(_monday).next);
    expect(edit.pattern, const DailyFrequency(2));

    // 本周仍按 initial 口径（FR-002）。
    final stats = await env.evaluateLive(_monday);
    expect(stats.dayStatusOf(g.id, _monday).targetCount, 1);
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

  test('快照仅含该周有适用日的习惯目标（里程碑/未开始剔除）', () async {
    final env = Env();
    addTearDown(env.close);
    await env.habit('吃饭');
    await env.goals.create(Goal(
      name: '旅行',
      kind: GoalKind.milestone,
      iconKey: 'travel',
      colorKey: 'sky',
      createdAt: _lastWeek.monday,
    ));
    // 创建于结算周之后的目标不入快照。
    final late = await env.goals.create(Goal(
      name: '新习惯',
      kind: GoalKind.habit,
      iconKey: 'book',
      colorKey: 'indigo',
      createdAt: _monday,
    ));
    await env.goals.addInitial(late.id, const DailyFrequency(1),
        WeekStart.containing(_monday));

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
      expect(during.dayStatusOf(g.id, _monday).targetCount, 1); // 当周即生效
      expect(during.dayStatusOf(g.id, _monday).busyMode, true);

      await service.deactivate(session, now: DateTime(2026, 8, 18, 9));
      final after = await env.evaluateLive(_monday.addDays(1));
      expect(after.dayStatusOf(g.id, _monday.addDays(1)).targetCount, 3);
      final sessions = await env.goals.watchSessions().first;
      expect(sessions.single.isActive, isFalse);
    });
  });
}
