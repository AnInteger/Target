/// 忙碌模式（US4，FR-018）：一键降档所选活跃习惯 + 会话留痕；
/// 一键恢复。003 T013 起频率版本停写——降档只记会话条目（周留痕
/// busyModeApplied 标注取自会话），不再写 FrequencyVersions 行。
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

  /// 一键开启：会话（本周降档留痕/今日页徽标）。
  Future<BusyModeSession> activate({
    required WeekStart week,
    required Map<String, FrequencyPattern> downgradedByGoal,
    required DateTime now,
  }) async {
    final entries = downgradedByGoal.entries
        .map((e) => BusyModeEntry(goalId: e.key, downgraded: e.value))
        .toList();
    return _goals.openSession(week, entries, now);
  }

  /// 一键恢复：结束会话（该周标注随之消失，历史打卡留痕不动）。
  Future<void> deactivate(BusyModeSession session, {required DateTime now}) =>
      _goals.endSession(session, now);
}
