/// v3 提醒调度（006 FR-009）：逐目标「时间 + 频率档」，
/// 全局总开关关闭 → 全量取消；未授权静默跳过（V8 精神）。
///
/// 排程口径：按频率档预排未来 14 次一次性通知（daily=逐日、
/// threeDay=每 3 日、weekly=每 7 日）；数据/设置任一变化全量重建。
library;

import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/platform/gateways.dart';

class ReminderService {
  ReminderService(this._gateway);

  final NotificationGateway _gateway;

  static const int _occurrences = 14;
  static const int _idStride = 100;

  /// 全量重建 pending 提醒（app 层在数据/设置变化后调用）。
  Future<void> replan({
    required List<Goal> goals,
    required List<Reminder> reminders,
    required bool enabled,
  }) async {
    await _gateway.cancelAll();
    if (!enabled) return;
    final granted = await _gateway.isPermissionGranted;
    if (!granted) return;

    final goalsById = {for (final g in goals) g.id: g};
    var base = 1000;
    for (final r in reminders) {
      if (!r.isEnabled) continue;
      final goal = goalsById[r.goalId];
      // 仅进行中目标排程（暂停/达成/归档静默跳过）。
      if (goal == null || goal.status != GoalStatus.active) continue;
      await _gateway.scheduleOccurrences(
        baseId: base,
        fireOns: _nextOccurrences(r.time, r.cadence),
        title: goal.name,
        body: '今天还没有记录。',
      );
      base += _idStride;
    }
  }

  /// 未来 [_occurrences] 次落点（本地时区；首点严格晚于现在）。
  List<DateTime> _nextOccurrences(LocalTime time, Cadence cadence) {
    final stepDays = switch (cadence) {
      Cadence.daily => 1,
      Cadence.threeDay => 3,
      Cadence.weekly => 7,
    };
    final now = DateTime.now();
    var day = LocalDate.fromDateTime(now);
    final first = time.on(day);
    if (!first.isAfter(now)) {
      day = day.addDays(stepDays);
    }
    return [
      for (var i = 0; i < _occurrences; i++) time.on(day.addDays(stepDays * i)),
    ];
  }
}
