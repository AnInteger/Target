/// 日历值类型：LocalDate / LocalTime / WeekStart / Weekday
///
/// 纯 Dart、无 Flutter/平台依赖（plan.md Structure Decision #2）。
/// 时间戳 → 自然日的换算由调用方（DateProvider，注入时钟）按设备本地时区完成，
/// 本文件只做"无时区的日历日"运算（R1，contracts/stats-engine.md）。
library;

/// 星期几。ISO 8601 编号：周一 = 1 … 周日 = 7。
enum Weekday {
  mon(1, '一'),
  tue(2, '二'),
  wed(3, '三'),
  thu(4, '四'),
  fri(5, '五'),
  sat(6, '六'),
  sun(7, '日');

  const Weekday(this.isoNumber, this.zhLabel);

  final int isoNumber;
  final String zhLabel;

  static Weekday fromIso(int n) {
    final v = Weekday.values.where((w) => w.isoNumber == n).firstOrNull;
    if (v == null) {
      throw ArgumentError('ISO weekday must be 1..7, got $n');
    }
    return v;
  }
}

/// 无时区的日历日（YYYY-MM-DD）。打卡归属、周期计算均用此类型（R1）。
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  /// 由本地时区的 [DateTime] 取其自然日（跨天归属的换算入口）。
  factory LocalDate.fromDateTime(DateTime dt) =>
      LocalDate(dt.year, dt.month, dt.day);

  /// 解析 ISO 字符串 "YYYY-MM-DD"；严格校验（备份导入的明确报错依赖于此）。
  factory LocalDate.parse(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m == null) {
      throw FormatException('LocalDate 必须是 YYYY-MM-DD，得到 "$s"');
    }
    final d = LocalDate(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
    d._validate();
    return d;
  }

  factory LocalDate._fromUtc(DateTime utc) =>
      LocalDate(utc.year, utc.month, utc.day);

  void _validate() {
    // 借助 DateTime.utc 的规范化做月/日合法性校验（如 2 月 30 日会被拒绝）。
    final probe = DateTime.utc(year, month, day);
    if (probe.year != year || probe.month != month || probe.day != day) {
      throw ArgumentError('$year-$month-$day 不是合法的日历日');
    }
  }

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 该日零点（本地时区），供与提醒时刻等组合使用。
  DateTime get atStartOfDay => DateTime(year, month, day);

  /// ISO 编号 1..7（周一..周日）。
  int get weekdayIso => _utc.weekday;

  Weekday get weekday => Weekday.fromIso(weekdayIso);

  /// 该日所属周的周一（周 = 周一至周日，R2）。
  WeekStart get weekStart => WeekStart._(addDays(-(weekdayIso - 1)));

  LocalDate addDays(int n) => LocalDate._fromUtc(_utc.add(Duration(days: n)));

  /// 与 [other] 的天数差（this - other）。
  int differenceInDays(LocalDate other) =>
      _utc.difference(other._utc).inDays;

  bool isBefore(LocalDate o) => compareTo(o) < 0;
  bool isAfter(LocalDate o) => compareTo(o) > 0;
  bool isSameOrBefore(LocalDate o) => compareTo(o) <= 0;
  bool isSameOrAfter(LocalDate o) => compareTo(o) >= 0;

  @override
  int compareTo(LocalDate o) {
    if (year != o.year) return year - o.year;
    if (month != o.month) return month - o.month;
    return day - o.day;
  }

  String get isoString =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  String toString() => isoString;

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// 无时区时刻（HH:mm），提醒与每日概要使用。
class LocalTime implements Comparable<LocalTime> {
  const LocalTime(this.hour, this.minute);

  final int hour;
  final int minute;

  factory LocalTime.parse(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m == null) {
      throw FormatException('LocalTime 必须是 HH:mm，得到 "$s"');
    }
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h < 0 || h > 23 || min < 0 || min > 59) {
      throw FormatException('LocalTime 超出范围："$s"');
    }
    return LocalTime(h, min);
  }

  factory LocalTime.fromDateTime(DateTime dt) => LocalTime(dt.hour, dt.minute);

  Duration get sinceMidnight => Duration(hours: hour, minutes: minute);

  /// 落在 [day] 这天的具体 [DateTime]（本地时区）。
  DateTime on(LocalDate day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  @override
  int compareTo(LocalTime o) => sinceMidnight.compareTo(o.sinceMidnight);

  String get isoString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  String toString() => isoString;

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// 周锚点：必须是周一的 [LocalDate]（周 = 周一至周日，R2 / FR-002）。
class WeekStart implements Comparable<WeekStart> {
  const WeekStart._(this.monday);

  final LocalDate monday;

  /// 直接以周一构造；非周一抛错（防呆——数据库与备份都依赖此不变量）。
  factory WeekStart.of(LocalDate monday) {
    if (monday.weekdayIso != 1) {
      throw ArgumentError('WeekStart 必须是周一，得到 ${monday.isoString}');
    }
    return WeekStart._(monday);
  }

  /// [day] 所在周的周一。
  factory WeekStart.containing(LocalDate day) => day.weekStart;

  factory WeekStart.parse(String s) => WeekStart.of(LocalDate.parse(s));

  LocalDate get sunday => monday.addDays(6);

  bool contains(LocalDate day) =>
      day.isSameOrAfter(monday) && day.isSameOrBefore(sunday);

  WeekStart addWeeks(int n) => WeekStart._(monday.addDays(7 * n));

  WeekStart get next => addWeeks(1);
  WeekStart get previous => addWeeks(-1);

  /// [day] 是否属于本周之后的周（用于"下周一生效"判断）。
  bool isAfterWeekOf(LocalDate day) => monday.isAfter(day.weekStart.monday);

  @override
  int compareTo(WeekStart o) => monday.compareTo(o.monday);

  String get isoString => monday.isoString;

  @override
  String toString() => isoString;

  @override
  bool operator ==(Object other) => other is WeekStart && other.monday == monday;

  @override
  int get hashCode => monday.hashCode;
}
