/// drift 持久化 schema v8（006 · 清库重建，无迁移链）。
///
/// 存储约定（specs/006-app-v3-redesign/data-model.md）：
/// - LocalDate → TEXT "YYYY-MM-DD"（严格解析）
/// - LocalTime → TEXT "HH:mm"
/// - Instant (DateTime) → TEXT ISO-8601 UTC
/// - FrequencyPattern → TEXT JSON（frequency_pattern.dart 同编码）
/// - 枚举 → TEXT 枚举名（.name）
/// 不建表：WeeklyReviews / FrequencyVersions / BusyMode* / CheckIns（退役）。
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
  T fromSql(String fromDb) => values.firstWhere(
    (v) => v.name == fromDb,
    orElse: () => throw FormatException('未知枚举值 "$fromDb"'),
  );

  @override
  String toSql(T value) => value.name;
}

const goalStatusConverter = _EnumText<GoalStatus>(GoalStatus.values);
const cadenceConverter = _EnumText<Cadence>(Cadence.values);
const recordKindConverter = _EnumText<RecordKind>(RecordKind.values);
const categoryConverter = _EnumText<GoalCategory>(GoalCategory.values);

class LocalDateText extends TypeConverter<LocalDate, String> {
  const LocalDateText();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.isoString;
}

class LocalTimeText extends TypeConverter<LocalTime, String> {
  const LocalTimeText();

  @override
  LocalTime fromSql(String fromDb) => LocalTime.parse(fromDb);

  @override
  String toSql(LocalTime value) => value.isoString;
}

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

@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get why => text().nullable()();
  TextColumn get categoryKey => text().nullable().map(categoryConverter)();
  TextColumn get iconKey => text()();
  TextColumn get colorKey => text()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  IntColumn get pinnedOrder => integer().nullable()();
  TextColumn get targetDate => text().nullable().map(const LocalDateText())();
  TextColumn get frequency =>
      text().nullable().map(const FrequencyPatternJson())();
  TextColumn get status => text().map(goalStatusConverter)();
  TextColumn get achievedAt => text().nullable().map(const IsoDateTimeText())();
  TextColumn get archivedAt => text().nullable().map(const IsoDateTimeText())();
  TextColumn get createdAt => text().map(const LocalDateText())();

  @override
  Set<Column> get primaryKey => {id};
}

/// 富进展记录（替代 CheckIns；FR-002）。
@DataClassName('RecordRow')
class ProgressRecords extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get day => text().map(const LocalDateText())();
  TextColumn get createdAt => text().map(const IsoDateTimeText())();
  BoolColumn get isBackfill => boolean().withDefault(const Constant(false))();
  TextColumn get kind => text().map(recordKindConverter)();
  TextColumn get milestoneId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MilestoneRow')
class Milestones extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  TextColumn get doneAt => text().nullable().map(const IsoDateTimeText())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get time => text().map(const LocalTimeText())();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get cadence => text().map(cadenceConverter)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Settings 单例：固定 id = 1 一行。
@DataClassName('SettingsRow')
class SettingsRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get nickname => text().nullable()();
  TextColumn get avatarKey => text().nullable()();
  TextColumn get themeMode => text().nullable()();
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
