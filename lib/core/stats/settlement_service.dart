/// 周结算（US4，FR-008 / research D11）。
///
/// 周一晨（dailyBrief 前）结算上一周：用统计引擎生成各目标
/// GoalWeekStat 快照存入 WeeklyReview（幂等：同周已存在则复用，
/// 不覆盖 settledAt）。回顾页展示时实时重算，快照仅留痕。
/// 决策落地：pause → 目标置 paused（adjust 003 起停写版本）。
library;

import '../db/repositories.dart';
import '../models/calendar_types.dart';
import '../models/entities.dart';
import 'stats_engine.dart';

class WeeklySettlementService {
  WeeklySettlementService(this._goals, this._checkIns, this._reviews);

  final GoalRepository _goals;
  final CheckInRepository _checkIns;
  final ReviewRepository _reviews;

  /// 结算 [today] 的上一周（幂等）。返回已存在的或新建的回顾。
  Future<WeeklyReview> settleLastWeekIfNeeded(
      {required LocalDate today, required DateTime now}) async {
    final lastWeek = today.weekStart.previous;
    final existing = (await _reviews.all())
        .where((r) => r.weekStart == lastWeek)
        .firstOrNull;
    if (existing != null) return existing;

    final stats = await _evaluate(today);
    final snapshot = <GoalWeekStat>[];
    for (final g in await _goals.getGoals()) {
      final w = stats.weekStatOf(g.id, lastWeek);
      if (w.totalChecks == 0) continue; // 整周未动（含未开始/整周暂停）
      snapshot.add(w);
    }
    final review = WeeklyReview(
      weekStart: lastWeek,
      settledAt: now.toUtc(),
      snapshot: snapshot,
    );
    await _reviews.save(review);
    return review;
  }

  /// 周回顾三选落地（单目标粒度，FR-008）。
  ///
  /// - adjust：003 T013 起频率版本停写——不再生成 userEdit 版本
  ///   （历史 adjust 决策随快照兼容读；频率编辑退役为提醒 cadence）；
  /// - pause：目标置 paused（FR-009）；
  /// - continue：无副作用。
  Future<void> applyDecision(
      String goalId, ReviewDecision decision, {required LocalDate today}) async {
    switch (decision) {
      case ContinueDecision():
      case AdjustDecision():
        break;
      case PauseDecision():
        final goal = (await _goals.getGoals())
            .where((g) => g.id == goalId)
            .firstOrNull;
        if (goal != null) {
          await _goals.update(goal.copyWith(status: GoalStatus.paused));
        }
    }
  }

  Future<StatsEvaluation> _evaluate(LocalDate today) async {
    return StatsEngine.evaluate(
      goals: await _goals.getGoals(),
      busySessions: await _goals.watchSessions().first,
      checkIns: await _checkIns.all(),
      today: today,
    );
  }
}
