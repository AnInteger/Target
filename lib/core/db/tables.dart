/// drift 持久化 schema —— 与领域实体 1:1 映射，不含业务规则。
///
/// 存储约定（见 specs/001-life-goal-tracker/data-model.md + backup-format.md）：
/// - LocalDate / WeekStart → TEXT "YYYY-MM-DD"（ISO，严格解析）
/// - LocalTime            → TEXT "HH:mm"
/// - Instant (DateTime)   → TEXT ISO-8601 UTC
/// - FrequencyPattern     → TEXT JSON（与备份文件同一编码，frequency_pattern.dart）
/// - 枚举                  → TEXT 枚举名（.name）
library;

import 'package:drift/drift.dart';

import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';

// ---------------------------------------------------------------------------
// 值转换器（均 const，供列定义 .map() 使用）
// ---------------------------------------------------------------------------

class _EnumText<T extends Enum> extends TypeConverter<T, String> {
  const _EnumText(this.values);

  final List<T> values;

  @override
  T fromSql(String fromDb) =>
      values.firstWhere((v) => v.name == fromDb,
          orElse: () => throw FormatException('未知枚举值 "$fromDb"'));

  @override
  String toSql(T value) => value.name;
}

const goalKindConverter = _EnumText<GoalKind>(GoalKind.values);

/// 003 v3：三类型 + 提醒频率档（值域见 entities.dart；v2 列随 T011 退役）。
const goalTypeConverter = _EnumText<GoalType>(GoalType.values);
const cadenceConverter = _EnumText<Cadence>(Cadence.values);
const goalStatusConverter = _EnumText<GoalStatus>(GoalStatus.values);
const frequencySourceConverter =
    _EnumText<FrequencySource>(FrequencySource.values);
const checkInStatusConverter = _EnumText<CheckInStatus>(CheckInStatus.values);

class LocalDateText extends TypeConverter<LocalDate, String> {
  const LocalDateText();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.isoString;
}

class WeekStartText extends TypeConverter<WeekStart, String> {
  const WeekStartText();

  @override
  WeekStart fromSql(String fromDb) => WeekStart.parse(fromDb);

  @override
  String toSql(WeekStart value) => value.isoString;
}

class LocalTimeText extends TypeConverter<LocalTime, String> {
  const LocalTimeText();

  @override
  LocalTime fromSql(String fromDb) => LocalTime.parse(fromDb);

  @override
  String toSql(LocalTime value) => value.isoString;
}

/// Instant：统一存 UTC ISO-8601。
class IsoDateTimeText extends TypeConverter<DateTime, String> {
  const IsoDateTimeText();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toUtc();

  @override
  String toSql(DateTime value) => value.toUtc().toIso8601String();
}

class FrequencyPatternJson extends TypeConverter<FrequencyPattern, String> {
  const FrequencyPatternJson();

  @override
  FrequencyPattern fromSql(String fromDb) =>
      FrequencyPattern.fromJsonString(fromDb);

  @override
  String toSql(FrequencyPattern value) => value.toJsonString();
}

// ---------------------------------------------------------------------------
// 表
// ---------------------------------------------------------------------------

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  // 003 v3：kind 重映射为三类型域（v2→v3 迁移见 app_database.dart）。
  TextColumn get goalType => text().map(goalTypeConverter)();
  TextColumn get iconKey => text()();
  // 003 v3 退役：可空化 + 存量置 NULL（零丢失惯例：只藏不删，不上界面）。
  TextColumn get colorKey => text().nullable()();
  TextColumn get status => text().map(goalStatusConverter)();
  TextColumn get createdAt => text().map(const LocalDateText())();
  TextColumn get deadline => text().nullable().map(const LocalDateText())();
  // 003 v3 新增：手动「标记达成」时间戳（research D4；NULL=未达成，
  // 与 GoalStatus.achieved 归档语义职责分离）。
  TextColumn get achievedAt => text().nullable().map(const IsoDateTimeText())();

  /// US3 定义模型（002 B 案 envelope，schema v2 可空列，T014 定稿）：
  /// motivation 动机 ≤60 字 / success_criterion 成功标准 ≤60 字 /
  /// cue_scene 提醒场景 ≤40 字（空 = 回落默认时段）。旧目标全 NULL。
  TextColumn get motivation => text().nullable()();
  TextColumn get successCriterion => text().nullable()();
  TextColumn get cueScene => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class FrequencyVersions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get effectiveFromWeek => text().map(const WeekStartText())();
  TextColumn get pattern => text().map(const FrequencyPatternJson())();
  TextColumn get source => text().map(frequencySourceConverter)();

  @override
  Set<Column> get primaryKey => {id};
}

class BusyModeSessions extends Table {
  TextColumn get id => text()();
  TextColumn get weekStart => text().map(const WeekStartText())();
  TextColumn get startedAt => text().map(const IsoDateTimeText())();
  TextColumn get endedAt =>
      text().nullable().map(const IsoDateTimeText())();

  @override
  Set<Column> get primaryKey => {id};
}

/// BusyModeSession.entries 的子行（sessionId, goalId, 降档频率）。
class BusyModeEntries extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(BusyModeSessions, #id)();
  TextColumn get goalId => text()();
  TextColumn get downgraded => text().map(const FrequencyPatternJson())();

  @override
  Set<Column> get primaryKey => {id};
}

class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get day => text().map(const LocalDateText())();
  TextColumn get createdAt => text().map(const IsoDateTimeText())();
  BoolColumn get isBackfill => boolean()();
  TextColumn get status => text().map(checkInStatusConverter)();

  @override
  Set<Column> get primaryKey => {id};
}

class MilestoneSteps extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean()();
  TextColumn get doneAt => text().nullable().map(const IsoDateTimeText())();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  TextColumn get time => text().map(const LocalTimeText())();
  BoolColumn get isEnabled => boolean()();
  // 003 v3 新增：提醒频率档（一天/三天/一周一次）；NULL 视为 daily。
  TextColumn get cadence => text().nullable().map(cadenceConverter)();

  @override
  Set<Column> get primaryKey => {id};
}

class WeeklyReviews extends Table {
  TextColumn get id => text()();
  TextColumn get weekStart => text().map(const WeekStartText())();
  TextColumn get settledAt => text().map(const IsoDateTimeText())();

  /// GoalWeekStat 列表 JSON + decision JSON（编码见 repositories.dart）。
  TextColumn get snapshotJson => text()();
  TextColumn get decisionJson => text()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Settings 单例：固定 id = 1 一行。
class SettingsRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get dailyBriefTime => text().map(const LocalTimeText())();
  // 003 v3 新增（research D7）：账号资料；NULL = 默认「我」+ 默认枚。
  TextColumn get nickname => text().nullable()();
  TextColumn get avatarKey => text().nullable()();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get notificationDeniedAcknowledged =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
