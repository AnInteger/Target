/// 习惯频率模式（FR-002）。
///
/// 纯 Dart 值对象；持久化时序列化为 JSON（drift TEXT 列 / 备份文件复用同一编码）。
/// 适用日语义见 contracts/stats-engine.md R4：
/// - daily：每天适用；
/// - weekdays：仅指定星期几适用；
/// - weekly：日分布自由——该周全部 7 天皆为"潜在适用日"，
///   周达标 = 周内达标日数 ≥ N（达标日 = 该日有 ≥1 次有效打卡）。
library;

import 'dart:convert';

import 'calendar_types.dart';

sealed class FrequencyPattern {
  const FrequencyPattern();

  Map<String, dynamic> toJson();

  factory FrequencyPattern.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'daily':
        return DailyFrequency(json['targetPerDay'] as int);
      case 'weekly':
        return WeeklyFrequency(json['timesPerWeek'] as int);
      case 'weekdays':
        return WeekdaysFrequency(
          (json['days'] as List).map((e) => Weekday.fromIso(e as int)).toSet(),
          json['targetPerDay'] as int,
        );
      default:
        throw FormatException('未知频率类型 "$type"');
    }
  }

  factory FrequencyPattern.fromJsonString(String s) =>
      FrequencyPattern.fromJson(
          Map<String, dynamic>.from(jsonDecode(s) as Map));

  /// [day] 是否为适用日（R4）。weekly 恒为 true（潜在适用日），
  /// 其"是否计入 N"由统计引擎按打卡记录判定。
  bool isApplicableOn(LocalDate day);

  String toJsonString() => jsonEncode(toJson());
}

/// 每天 N 次（N ≥ 1）。
class DailyFrequency extends FrequencyPattern {
  const DailyFrequency(this.targetPerDay) : assert(targetPerDay >= 1);

  final int targetPerDay;

  @override
  bool isApplicableOn(LocalDate day) => true;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'daily', 'targetPerDay': targetPerDay};

  @override
  String toString() => '每天 $targetPerDay 次';

  @override
  bool operator ==(Object other) =>
      other is DailyFrequency && other.targetPerDay == targetPerDay;

  @override
  int get hashCode => targetPerDay;
}

/// 每周 N 次，日分布自由（1 ≤ N ≤ 7）。
class WeeklyFrequency extends FrequencyPattern {
  const WeeklyFrequency(this.timesPerWeek) : assert(timesPerWeek >= 1);

  final int timesPerWeek;

  @override
  bool isApplicableOn(LocalDate day) => true; // 潜在适用日（R4）

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'weekly', 'timesPerWeek': timesPerWeek};

  @override
  String toString() => '每周 $timesPerWeek 次';

  @override
  bool operator ==(Object other) =>
      other is WeeklyFrequency && other.timesPerWeek == timesPerWeek;

  @override
  int get hashCode => timesPerWeek;
}

/// 指定星期几，每天 N 次。
///
/// 不变量：days 非空（UI 表单保证至少勾选一天；const 断言无法求值
/// Set.isEmpty，故不在此处检查）。
class WeekdaysFrequency extends FrequencyPattern {
  const WeekdaysFrequency(this.days, this.targetPerDay)
      : assert(targetPerDay >= 1);

  final Set<Weekday> days;
  final int targetPerDay;

  @override
  bool isApplicableOn(LocalDate day) => days.contains(day.weekday);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'weekdays',
        'days': days.map((d) => d.isoNumber).toList()..sort(),
        'targetPerDay': targetPerDay,
      };

  @override
  String toString() {
    final labels = days.map((d) => '周${d.zhLabel}').join('、');
    return '$labels 每天 $targetPerDay 次';
  }

  @override
  bool operator ==(Object other) =>
      other is WeekdaysFrequency &&
      other.targetPerDay == targetPerDay &&
      other.days.length == days.length &&
      other.days.containsAll(days);

  // Set 迭代顺序不稳定，先按 ISO 编号排序再哈希，保证相等集合哈希一致。
  List<int> get _sortedIso => days.map((d) => d.isoNumber).toList()..sort();

  @override
  int get hashCode => Object.hashAll(_sortedIso) ^ targetPerDay;
}
