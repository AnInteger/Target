/// 忙碌模式（US4，FR-018）：一键降档所选活跃习惯（当周生效，
/// 豁免 FR-002 下一周期规则）+ 会话留痕；一键恢复原频率。
library;

import '../db/repositories.dart';
import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';

class BusyModeService {
  BusyModeService(this._goals);

  final GoalRepository _goals;

  /// 建议降档：每天 → 1 次；每周 N → N/2（下取整，≥1）；
  /// 指定日 → 次数减半（≥1）。已是最低档时返回原频率。
  FrequencyPattern suggestedDowngrade(FrequencyPattern p) => switch (p) {
        DailyFrequency() => const DailyFrequency(1),
        WeeklyFrequency(:final timesPerWeek) =>
          WeeklyFrequency(timesPerWeek <= 1 ? 1 : timesPerWeek ~/ 2),
        WeekdaysFrequency(:final days, :final targetPerDay) =>
          WeekdaysFrequency(days, targetPerDay <= 1 ? 1 : targetPerDay ~/ 2),
      };

  bool isFloor(FrequencyPattern p) => suggestedDowngrade(p) == p;

  /// 一键开启：降档版本（本周）+ 会话（留痕/今日页徽标）。
  Future<BusyModeSession> activate({
    required WeekStart week,
    required Map<String, FrequencyPattern> downgradedByGoal,
    required DateTime now,
  }) async {
    final entries = downgradedByGoal.entries
        .map((e) => BusyModeEntry(goalId: e.key, downgraded: e.value))
        .toList();
    final session = await _goals.openSession(week, entries, now);
    for (final e in entries) {
      await _goals.addBusyMode(e.goalId, week, e.downgraded);
    }
    return session;
  }

  /// 一键恢复：移除各目标当周降档版本 + 结束会话。
  Future<void> deactivate(BusyModeSession session, {required DateTime now}) async {
    for (final e in session.entries) {
      await _goals.removeBusyMode(e.goalId, session.weekStart);
    }
    await _goals.endSession(session, now);
  }
}
