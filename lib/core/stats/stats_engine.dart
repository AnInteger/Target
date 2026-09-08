/// v3 统计引擎（006 FR-005/007）：投入时长口径的纯函数实现。
///
/// 旧评分/健康分/建议/连击/周结算 API 全部退役（spec 3.3 删除清单）。
/// 口径：投入分钟数仅累计 durationMinutes 非空的记录；无时长记录
/// 计入「记录数」但不计入分钟数。
library;

import '../models/calendar_types.dart';
import '../models/entities.dart';

/// 一周投入汇总（动态页统计卡）。
class WeekInvestment {
  const WeekInvestment({
    required this.totalMinutes,
    required this.recordCount,
    required this.perDayMinutes,
  });

  final int totalMinutes;

  /// 周内全部记录数（含无时长记录与达成事件）。
  final int recordCount;

  /// 周一→周日逐日投入分钟（长度恒 7）。
  final List<int> perDayMinutes;

  int get hours => totalMinutes ~/ 60;

  int get remainderMinutes => totalMinutes % 60;
}

/// 里程碑汇总（动态页里程碑卡：本周达成 / 全部待达成）。
class MilestoneSummary {
  const MilestoneSummary({
    required this.achievedThisWeek,
    required this.pendingAll,
  });

  final int achievedThisWeek;
  final int pendingAll;
}

/// 单日投入（日历视图数据源）。
class DailyInvestment {
  const DailyInvestment({
    required this.day,
    required this.minutes,
    required this.recordCount,
  });

  final LocalDate day;
  final int minutes;
  final int recordCount;
}

/// 动态 feed 条目（记录 + 达成事件混排；goal 名由 UI 目标表补充）。
class FeedItem {
  const FeedItem({
    required this.record,
    required this.goalId,
    required this.goalName,
  });

  final ProgressRecord record;
  final String goalId;
  final String goalName;

  bool get isMilestone => record.kind == RecordKind.milestoneAchievement;
}

abstract final class StatsEngine {
  /// 周投入（FR-005）：分钟只累计带 durationMinutes 的记录。
  /// 周索引 = ISO weekday − 1（周一=0 … 周日=6；contains 已保证同周）。
  static WeekInvestment weekInvestment(
    List<ProgressRecord> records,
    WeekStart week,
  ) {
    final perDay = List<int>.filled(7, 0);
    var total = 0, count = 0;
    for (final r in records) {
      if (!week.contains(r.day)) continue;
      count++;
      final m = r.durationMinutes;
      if (m != null) {
        total += m;
        perDay[r.day.weekdayIso - 1] += m;
      }
    }
    return WeekInvestment(
      totalMinutes: total,
      recordCount: count,
      perDayMinutes: perDay,
    );
  }

  /// 里程碑汇总：本周达成（doneAt 落周内）/ 全部待达成。
  static MilestoneSummary milestoneSummary(
    List<Milestone> milestones,
    WeekStart week,
  ) {
    var achieved = 0, pending = 0;
    for (final m in milestones) {
      if (!m.isDone) {
        pending++;
      } else {
        final at = m.doneAt;
        if (at != null && week.contains(LocalDate.fromDateTime(at))) {
          achieved++;
        }
      }
    }
    return MilestoneSummary(achievedThisWeek: achieved, pendingAll: pending);
  }

  /// 月度逐日投入（FR-007 日历）：返回该自然月有记录的天
  /// （「范围所有日期」由 UI 按月导航逐月调用）。
  static List<DailyInvestment> dailyInvestment(
    List<ProgressRecord> records,
    int year,
    int month,
  ) {
    final byDay = <LocalDate, List<int>>{}; // [minutes, count]
    for (final r in records) {
      if (r.day.year != year || r.day.month != month) continue;
      final slot = byDay.putIfAbsent(r.day, () => [0, 0]);
      slot[0] += r.durationMinutes ?? 0;
      slot[1]++;
    }
    final days = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in days)
        DailyInvestment(
          day: e.key,
          minutes: e.value[0],
          recordCount: e.value[1],
        ),
    ];
  }

  /// 当月峰值分钟数（日历环 = 当日投入 / 当月峰值；峰值 0 时环为空轨）。
  static int monthPeak(List<DailyInvestment> days) =>
      days.fold(0, (m, d) => d.minutes > m ? d.minutes : m);

  /// 动态 feed：全记录创建时刻倒序（达成事件混排）。
  static List<FeedItem> activityFeed(
    List<ProgressRecord> records,
    Map<String, String> goalNames,
  ) {
    final items = [
      for (final r in records)
        FeedItem(
          record: r,
          goalId: r.goalId,
          goalName: goalNames[r.goalId] ?? '',
        ),
    ];
    items.sort((a, b) => b.record.createdAt.compareTo(a.record.createdAt));
    return items;
  }
}
