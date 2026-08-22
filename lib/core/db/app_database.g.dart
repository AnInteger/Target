// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalType, String> goalType =
      GeneratedColumn<String>(
        'goal_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GoalType>($GoalsTable.$convertergoalType);
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<String> colorKey = GeneratedColumn<String>(
    'color_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GoalStatus>($GoalsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($GoalsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> deadline =
      GeneratedColumn<String>(
        'deadline',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($GoalsTable.$converterdeadlinen);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> achievedAt =
      GeneratedColumn<String>(
        'achieved_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GoalsTable.$converterachievedAtn);
  static const VerificationMeta _motivationMeta = const VerificationMeta(
    'motivation',
  );
  @override
  late final GeneratedColumn<String> motivation = GeneratedColumn<String>(
    'motivation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _successCriterionMeta = const VerificationMeta(
    'successCriterion',
  );
  @override
  late final GeneratedColumn<String> successCriterion = GeneratedColumn<String>(
    'success_criterion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cueSceneMeta = const VerificationMeta(
    'cueScene',
  );
  @override
  late final GeneratedColumn<String> cueScene = GeneratedColumn<String>(
    'cue_scene',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    goalType,
    iconKey,
    colorKey,
    status,
    createdAt,
    deadline,
    achievedAt,
    motivation,
    successCriterion,
    cueScene,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    }
    if (data.containsKey('motivation')) {
      context.handle(
        _motivationMeta,
        motivation.isAcceptableOrUnknown(data['motivation']!, _motivationMeta),
      );
    }
    if (data.containsKey('success_criterion')) {
      context.handle(
        _successCriterionMeta,
        successCriterion.isAcceptableOrUnknown(
          data['success_criterion']!,
          _successCriterionMeta,
        ),
      );
    }
    if (data.containsKey('cue_scene')) {
      context.handle(
        _cueSceneMeta,
        cueScene.isAcceptableOrUnknown(data['cue_scene']!, _cueSceneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      goalType: $GoalsTable.$convertergoalType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}goal_type'],
        )!,
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_key'],
      ),
      status: $GoalsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: $GoalsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      deadline: $GoalsTable.$converterdeadlinen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deadline'],
        ),
      ),
      achievedAt: $GoalsTable.$converterachievedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}achieved_at'],
        ),
      ),
      motivation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivation'],
      ),
      successCriterion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}success_criterion'],
      ),
      cueScene: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cue_scene'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static TypeConverter<GoalType, String> $convertergoalType = goalTypeConverter;
  static TypeConverter<GoalStatus, String> $converterstatus =
      goalStatusConverter;
  static TypeConverter<LocalDate, String> $convertercreatedAt =
      const LocalDateText();
  static TypeConverter<LocalDate, String> $converterdeadline =
      const LocalDateText();
  static TypeConverter<LocalDate?, String?> $converterdeadlinen =
      NullAwareTypeConverter.wrap($converterdeadline);
  static TypeConverter<DateTime, String> $converterachievedAt =
      const IsoDateTimeText();
  static TypeConverter<DateTime?, String?> $converterachievedAtn =
      NullAwareTypeConverter.wrap($converterachievedAt);
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String name;
  final GoalType goalType;
  final String iconKey;
  final String? colorKey;
  final GoalStatus status;
  final LocalDate createdAt;
  final LocalDate? deadline;
  final DateTime? achievedAt;

  /// US3 定义模型（002 B 案 envelope，schema v2 可空列，T014 定稿）：
  /// motivation 动机 ≤60 字 / success_criterion 成功标准 ≤60 字 /
  /// cue_scene 提醒场景 ≤40 字（空 = 回落默认时段）。旧目标全 NULL。
  final String? motivation;
  final String? successCriterion;
  final String? cueScene;
  const Goal({
    required this.id,
    required this.name,
    required this.goalType,
    required this.iconKey,
    this.colorKey,
    required this.status,
    required this.createdAt,
    this.deadline,
    this.achievedAt,
    this.motivation,
    this.successCriterion,
    this.cueScene,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['goal_type'] = Variable<String>(
        $GoalsTable.$convertergoalType.toSql(goalType),
      );
    }
    map['icon_key'] = Variable<String>(iconKey);
    if (!nullToAbsent || colorKey != null) {
      map['color_key'] = Variable<String>(colorKey);
    }
    {
      map['status'] = Variable<String>(
        $GoalsTable.$converterstatus.toSql(status),
      );
    }
    {
      map['created_at'] = Variable<String>(
        $GoalsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<String>(
        $GoalsTable.$converterdeadlinen.toSql(deadline),
      );
    }
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<String>(
        $GoalsTable.$converterachievedAtn.toSql(achievedAt),
      );
    }
    if (!nullToAbsent || motivation != null) {
      map['motivation'] = Variable<String>(motivation);
    }
    if (!nullToAbsent || successCriterion != null) {
      map['success_criterion'] = Variable<String>(successCriterion);
    }
    if (!nullToAbsent || cueScene != null) {
      map['cue_scene'] = Variable<String>(cueScene);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      goalType: Value(goalType),
      iconKey: Value(iconKey),
      colorKey: colorKey == null && nullToAbsent
          ? const Value.absent()
          : Value(colorKey),
      status: Value(status),
      createdAt: Value(createdAt),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      achievedAt: achievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(achievedAt),
      motivation: motivation == null && nullToAbsent
          ? const Value.absent()
          : Value(motivation),
      successCriterion: successCriterion == null && nullToAbsent
          ? const Value.absent()
          : Value(successCriterion),
      cueScene: cueScene == null && nullToAbsent
          ? const Value.absent()
          : Value(cueScene),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      goalType: serializer.fromJson<GoalType>(json['goalType']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorKey: serializer.fromJson<String?>(json['colorKey']),
      status: serializer.fromJson<GoalStatus>(json['status']),
      createdAt: serializer.fromJson<LocalDate>(json['createdAt']),
      deadline: serializer.fromJson<LocalDate?>(json['deadline']),
      achievedAt: serializer.fromJson<DateTime?>(json['achievedAt']),
      motivation: serializer.fromJson<String?>(json['motivation']),
      successCriterion: serializer.fromJson<String?>(json['successCriterion']),
      cueScene: serializer.fromJson<String?>(json['cueScene']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'goalType': serializer.toJson<GoalType>(goalType),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorKey': serializer.toJson<String?>(colorKey),
      'status': serializer.toJson<GoalStatus>(status),
      'createdAt': serializer.toJson<LocalDate>(createdAt),
      'deadline': serializer.toJson<LocalDate?>(deadline),
      'achievedAt': serializer.toJson<DateTime?>(achievedAt),
      'motivation': serializer.toJson<String?>(motivation),
      'successCriterion': serializer.toJson<String?>(successCriterion),
      'cueScene': serializer.toJson<String?>(cueScene),
    };
  }

  Goal copyWith({
    String? id,
    String? name,
    GoalType? goalType,
    String? iconKey,
    Value<String?> colorKey = const Value.absent(),
    GoalStatus? status,
    LocalDate? createdAt,
    Value<LocalDate?> deadline = const Value.absent(),
    Value<DateTime?> achievedAt = const Value.absent(),
    Value<String?> motivation = const Value.absent(),
    Value<String?> successCriterion = const Value.absent(),
    Value<String?> cueScene = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    goalType: goalType ?? this.goalType,
    iconKey: iconKey ?? this.iconKey,
    colorKey: colorKey.present ? colorKey.value : this.colorKey,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    deadline: deadline.present ? deadline.value : this.deadline,
    achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
    motivation: motivation.present ? motivation.value : this.motivation,
    successCriterion: successCriterion.present
        ? successCriterion.value
        : this.successCriterion,
    cueScene: cueScene.present ? cueScene.value : this.cueScene,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      achievedAt: data.achievedAt.present
          ? data.achievedAt.value
          : this.achievedAt,
      motivation: data.motivation.present
          ? data.motivation.value
          : this.motivation,
      successCriterion: data.successCriterion.present
          ? data.successCriterion.value
          : this.successCriterion,
      cueScene: data.cueScene.present ? data.cueScene.value : this.cueScene,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('goalType: $goalType, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('deadline: $deadline, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('motivation: $motivation, ')
          ..write('successCriterion: $successCriterion, ')
          ..write('cueScene: $cueScene')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    goalType,
    iconKey,
    colorKey,
    status,
    createdAt,
    deadline,
    achievedAt,
    motivation,
    successCriterion,
    cueScene,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.name == this.name &&
          other.goalType == this.goalType &&
          other.iconKey == this.iconKey &&
          other.colorKey == this.colorKey &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.deadline == this.deadline &&
          other.achievedAt == this.achievedAt &&
          other.motivation == this.motivation &&
          other.successCriterion == this.successCriterion &&
          other.cueScene == this.cueScene);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> name;
  final Value<GoalType> goalType;
  final Value<String> iconKey;
  final Value<String?> colorKey;
  final Value<GoalStatus> status;
  final Value<LocalDate> createdAt;
  final Value<LocalDate?> deadline;
  final Value<DateTime?> achievedAt;
  final Value<String?> motivation;
  final Value<String?> successCriterion;
  final Value<String?> cueScene;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.goalType = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deadline = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.motivation = const Value.absent(),
    this.successCriterion = const Value.absent(),
    this.cueScene = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String name,
    required GoalType goalType,
    required String iconKey,
    this.colorKey = const Value.absent(),
    required GoalStatus status,
    required LocalDate createdAt,
    this.deadline = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.motivation = const Value.absent(),
    this.successCriterion = const Value.absent(),
    this.cueScene = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       goalType = Value(goalType),
       iconKey = Value(iconKey),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? goalType,
    Expression<String>? iconKey,
    Expression<String>? colorKey,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? deadline,
    Expression<String>? achievedAt,
    Expression<String>? motivation,
    Expression<String>? successCriterion,
    Expression<String>? cueScene,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (goalType != null) 'goal_type': goalType,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorKey != null) 'color_key': colorKey,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (deadline != null) 'deadline': deadline,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (motivation != null) 'motivation': motivation,
      if (successCriterion != null) 'success_criterion': successCriterion,
      if (cueScene != null) 'cue_scene': cueScene,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<GoalType>? goalType,
    Value<String>? iconKey,
    Value<String?>? colorKey,
    Value<GoalStatus>? status,
    Value<LocalDate>? createdAt,
    Value<LocalDate?>? deadline,
    Value<DateTime?>? achievedAt,
    Value<String?>? motivation,
    Value<String?>? successCriterion,
    Value<String?>? cueScene,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      goalType: goalType ?? this.goalType,
      iconKey: iconKey ?? this.iconKey,
      colorKey: colorKey ?? this.colorKey,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      achievedAt: achievedAt ?? this.achievedAt,
      motivation: motivation ?? this.motivation,
      successCriterion: successCriterion ?? this.successCriterion,
      cueScene: cueScene ?? this.cueScene,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(
        $GoalsTable.$convertergoalType.toSql(goalType.value),
      );
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $GoalsTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $GoalsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (deadline.present) {
      map['deadline'] = Variable<String>(
        $GoalsTable.$converterdeadlinen.toSql(deadline.value),
      );
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<String>(
        $GoalsTable.$converterachievedAtn.toSql(achievedAt.value),
      );
    }
    if (motivation.present) {
      map['motivation'] = Variable<String>(motivation.value);
    }
    if (successCriterion.present) {
      map['success_criterion'] = Variable<String>(successCriterion.value);
    }
    if (cueScene.present) {
      map['cue_scene'] = Variable<String>(cueScene.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('goalType: $goalType, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('deadline: $deadline, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('motivation: $motivation, ')
          ..write('successCriterion: $successCriterion, ')
          ..write('cueScene: $cueScene, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FrequencyVersionsTable extends FrequencyVersions
    with TableInfo<$FrequencyVersionsTable, FrequencyVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrequencyVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<WeekStart, String>
  effectiveFromWeek =
      GeneratedColumn<String>(
        'effective_from_week',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WeekStart>(
        $FrequencyVersionsTable.$convertereffectiveFromWeek,
      );
  @override
  late final GeneratedColumnWithTypeConverter<FrequencyPattern, String>
  pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FrequencyPattern>($FrequencyVersionsTable.$converterpattern);
  @override
  late final GeneratedColumnWithTypeConverter<FrequencySource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FrequencySource>(
        $FrequencyVersionsTable.$convertersource,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    effectiveFromWeek,
    pattern,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frequency_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrequencyVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FrequencyVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrequencyVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      effectiveFromWeek: $FrequencyVersionsTable.$convertereffectiveFromWeek
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}effective_from_week'],
            )!,
          ),
      pattern: $FrequencyVersionsTable.$converterpattern.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pattern'],
        )!,
      ),
      source: $FrequencyVersionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
    );
  }

  @override
  $FrequencyVersionsTable createAlias(String alias) {
    return $FrequencyVersionsTable(attachedDatabase, alias);
  }

  static TypeConverter<WeekStart, String> $convertereffectiveFromWeek =
      const WeekStartText();
  static TypeConverter<FrequencyPattern, String> $converterpattern =
      const FrequencyPatternJson();
  static TypeConverter<FrequencySource, String> $convertersource =
      frequencySourceConverter;
}

class FrequencyVersion extends DataClass
    implements Insertable<FrequencyVersion> {
  final String id;
  final String goalId;
  final WeekStart effectiveFromWeek;
  final FrequencyPattern pattern;
  final FrequencySource source;
  const FrequencyVersion({
    required this.id,
    required this.goalId,
    required this.effectiveFromWeek,
    required this.pattern,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    {
      map['effective_from_week'] = Variable<String>(
        $FrequencyVersionsTable.$convertereffectiveFromWeek.toSql(
          effectiveFromWeek,
        ),
      );
    }
    {
      map['pattern'] = Variable<String>(
        $FrequencyVersionsTable.$converterpattern.toSql(pattern),
      );
    }
    {
      map['source'] = Variable<String>(
        $FrequencyVersionsTable.$convertersource.toSql(source),
      );
    }
    return map;
  }

  FrequencyVersionsCompanion toCompanion(bool nullToAbsent) {
    return FrequencyVersionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      effectiveFromWeek: Value(effectiveFromWeek),
      pattern: Value(pattern),
      source: Value(source),
    );
  }

  factory FrequencyVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrequencyVersion(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      effectiveFromWeek: serializer.fromJson<WeekStart>(
        json['effectiveFromWeek'],
      ),
      pattern: serializer.fromJson<FrequencyPattern>(json['pattern']),
      source: serializer.fromJson<FrequencySource>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'effectiveFromWeek': serializer.toJson<WeekStart>(effectiveFromWeek),
      'pattern': serializer.toJson<FrequencyPattern>(pattern),
      'source': serializer.toJson<FrequencySource>(source),
    };
  }

  FrequencyVersion copyWith({
    String? id,
    String? goalId,
    WeekStart? effectiveFromWeek,
    FrequencyPattern? pattern,
    FrequencySource? source,
  }) => FrequencyVersion(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    effectiveFromWeek: effectiveFromWeek ?? this.effectiveFromWeek,
    pattern: pattern ?? this.pattern,
    source: source ?? this.source,
  );
  FrequencyVersion copyWithCompanion(FrequencyVersionsCompanion data) {
    return FrequencyVersion(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      effectiveFromWeek: data.effectiveFromWeek.present
          ? data.effectiveFromWeek.value
          : this.effectiveFromWeek,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrequencyVersion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('effectiveFromWeek: $effectiveFromWeek, ')
          ..write('pattern: $pattern, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, goalId, effectiveFromWeek, pattern, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrequencyVersion &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.effectiveFromWeek == this.effectiveFromWeek &&
          other.pattern == this.pattern &&
          other.source == this.source);
}

class FrequencyVersionsCompanion extends UpdateCompanion<FrequencyVersion> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<WeekStart> effectiveFromWeek;
  final Value<FrequencyPattern> pattern;
  final Value<FrequencySource> source;
  final Value<int> rowid;
  const FrequencyVersionsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.effectiveFromWeek = const Value.absent(),
    this.pattern = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FrequencyVersionsCompanion.insert({
    required String id,
    required String goalId,
    required WeekStart effectiveFromWeek,
    required FrequencyPattern pattern,
    required FrequencySource source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       effectiveFromWeek = Value(effectiveFromWeek),
       pattern = Value(pattern),
       source = Value(source);
  static Insertable<FrequencyVersion> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? effectiveFromWeek,
    Expression<String>? pattern,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (effectiveFromWeek != null) 'effective_from_week': effectiveFromWeek,
      if (pattern != null) 'pattern': pattern,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FrequencyVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<WeekStart>? effectiveFromWeek,
    Value<FrequencyPattern>? pattern,
    Value<FrequencySource>? source,
    Value<int>? rowid,
  }) {
    return FrequencyVersionsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      effectiveFromWeek: effectiveFromWeek ?? this.effectiveFromWeek,
      pattern: pattern ?? this.pattern,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (effectiveFromWeek.present) {
      map['effective_from_week'] = Variable<String>(
        $FrequencyVersionsTable.$convertereffectiveFromWeek.toSql(
          effectiveFromWeek.value,
        ),
      );
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(
        $FrequencyVersionsTable.$converterpattern.toSql(pattern.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $FrequencyVersionsTable.$convertersource.toSql(source.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrequencyVersionsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('effectiveFromWeek: $effectiveFromWeek, ')
          ..write('pattern: $pattern, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusyModeSessionsTable extends BusyModeSessions
    with TableInfo<$BusyModeSessionsTable, BusyModeSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusyModeSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WeekStart, String> weekStart =
      GeneratedColumn<String>(
        'week_start',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WeekStart>($BusyModeSessionsTable.$converterweekStart);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> startedAt =
      GeneratedColumn<String>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BusyModeSessionsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> endedAt =
      GeneratedColumn<String>(
        'ended_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($BusyModeSessionsTable.$converterendedAtn);
  @override
  List<GeneratedColumn> get $columns => [id, weekStart, startedAt, endedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'busy_mode_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusyModeSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusyModeSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusyModeSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weekStart: $BusyModeSessionsTable.$converterweekStart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}week_start'],
        )!,
      ),
      startedAt: $BusyModeSessionsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      endedAt: $BusyModeSessionsTable.$converterendedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ended_at'],
        ),
      ),
    );
  }

  @override
  $BusyModeSessionsTable createAlias(String alias) {
    return $BusyModeSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<WeekStart, String> $converterweekStart =
      const WeekStartText();
  static TypeConverter<DateTime, String> $converterstartedAt =
      const IsoDateTimeText();
  static TypeConverter<DateTime, String> $converterendedAt =
      const IsoDateTimeText();
  static TypeConverter<DateTime?, String?> $converterendedAtn =
      NullAwareTypeConverter.wrap($converterendedAt);
}

class BusyModeSession extends DataClass implements Insertable<BusyModeSession> {
  final String id;
  final WeekStart weekStart;
  final DateTime startedAt;
  final DateTime? endedAt;
  const BusyModeSession({
    required this.id,
    required this.weekStart,
    required this.startedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['week_start'] = Variable<String>(
        $BusyModeSessionsTable.$converterweekStart.toSql(weekStart),
      );
    }
    {
      map['started_at'] = Variable<String>(
        $BusyModeSessionsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<String>(
        $BusyModeSessionsTable.$converterendedAtn.toSql(endedAt),
      );
    }
    return map;
  }

  BusyModeSessionsCompanion toCompanion(bool nullToAbsent) {
    return BusyModeSessionsCompanion(
      id: Value(id),
      weekStart: Value(weekStart),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory BusyModeSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusyModeSession(
      id: serializer.fromJson<String>(json['id']),
      weekStart: serializer.fromJson<WeekStart>(json['weekStart']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weekStart': serializer.toJson<WeekStart>(weekStart),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  BusyModeSession copyWith({
    String? id,
    WeekStart? weekStart,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => BusyModeSession(
    id: id ?? this.id,
    weekStart: weekStart ?? this.weekStart,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  BusyModeSession copyWithCompanion(BusyModeSessionsCompanion data) {
    return BusyModeSession(
      id: data.id.present ? data.id.value : this.id,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusyModeSession(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weekStart, startedAt, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusyModeSession &&
          other.id == this.id &&
          other.weekStart == this.weekStart &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class BusyModeSessionsCompanion extends UpdateCompanion<BusyModeSession> {
  final Value<String> id;
  final Value<WeekStart> weekStart;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> rowid;
  const BusyModeSessionsCompanion({
    this.id = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusyModeSessionsCompanion.insert({
    required String id,
    required WeekStart weekStart,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weekStart = Value(weekStart),
       startedAt = Value(startedAt);
  static Insertable<BusyModeSession> custom({
    Expression<String>? id,
    Expression<String>? weekStart,
    Expression<String>? startedAt,
    Expression<String>? endedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStart != null) 'week_start': weekStart,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusyModeSessionsCompanion copyWith({
    Value<String>? id,
    Value<WeekStart>? weekStart,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? rowid,
  }) {
    return BusyModeSessionsCompanion(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(
        $BusyModeSessionsTable.$converterweekStart.toSql(weekStart.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(
        $BusyModeSessionsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<String>(
        $BusyModeSessionsTable.$converterendedAtn.toSql(endedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusyModeSessionsCompanion(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusyModeEntriesTable extends BusyModeEntries
    with TableInfo<$BusyModeEntriesTable, BusyModeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusyModeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES busy_mode_sessions (id)',
    ),
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FrequencyPattern, String>
  downgraded = GeneratedColumn<String>(
    'downgraded',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FrequencyPattern>($BusyModeEntriesTable.$converterdowngraded);
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, goalId, downgraded];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'busy_mode_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusyModeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusyModeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusyModeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      downgraded: $BusyModeEntriesTable.$converterdowngraded.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}downgraded'],
        )!,
      ),
    );
  }

  @override
  $BusyModeEntriesTable createAlias(String alias) {
    return $BusyModeEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<FrequencyPattern, String> $converterdowngraded =
      const FrequencyPatternJson();
}

class BusyModeEntry extends DataClass implements Insertable<BusyModeEntry> {
  final String id;
  final String sessionId;
  final String goalId;
  final FrequencyPattern downgraded;
  const BusyModeEntry({
    required this.id,
    required this.sessionId,
    required this.goalId,
    required this.downgraded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['goal_id'] = Variable<String>(goalId);
    {
      map['downgraded'] = Variable<String>(
        $BusyModeEntriesTable.$converterdowngraded.toSql(downgraded),
      );
    }
    return map;
  }

  BusyModeEntriesCompanion toCompanion(bool nullToAbsent) {
    return BusyModeEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      goalId: Value(goalId),
      downgraded: Value(downgraded),
    );
  }

  factory BusyModeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusyModeEntry(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      goalId: serializer.fromJson<String>(json['goalId']),
      downgraded: serializer.fromJson<FrequencyPattern>(json['downgraded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'goalId': serializer.toJson<String>(goalId),
      'downgraded': serializer.toJson<FrequencyPattern>(downgraded),
    };
  }

  BusyModeEntry copyWith({
    String? id,
    String? sessionId,
    String? goalId,
    FrequencyPattern? downgraded,
  }) => BusyModeEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    goalId: goalId ?? this.goalId,
    downgraded: downgraded ?? this.downgraded,
  );
  BusyModeEntry copyWithCompanion(BusyModeEntriesCompanion data) {
    return BusyModeEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      downgraded: data.downgraded.present
          ? data.downgraded.value
          : this.downgraded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusyModeEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('goalId: $goalId, ')
          ..write('downgraded: $downgraded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, goalId, downgraded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusyModeEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.goalId == this.goalId &&
          other.downgraded == this.downgraded);
}

class BusyModeEntriesCompanion extends UpdateCompanion<BusyModeEntry> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> goalId;
  final Value<FrequencyPattern> downgraded;
  final Value<int> rowid;
  const BusyModeEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.goalId = const Value.absent(),
    this.downgraded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusyModeEntriesCompanion.insert({
    required String id,
    required String sessionId,
    required String goalId,
    required FrequencyPattern downgraded,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       goalId = Value(goalId),
       downgraded = Value(downgraded);
  static Insertable<BusyModeEntry> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? goalId,
    Expression<String>? downgraded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (goalId != null) 'goal_id': goalId,
      if (downgraded != null) 'downgraded': downgraded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusyModeEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? goalId,
    Value<FrequencyPattern>? downgraded,
    Value<int>? rowid,
  }) {
    return BusyModeEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      goalId: goalId ?? this.goalId,
      downgraded: downgraded ?? this.downgraded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (downgraded.present) {
      map['downgraded'] = Variable<String>(
        $BusyModeEntriesTable.$converterdowngraded.toSql(downgraded.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusyModeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('goalId: $goalId, ')
          ..write('downgraded: $downgraded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns with TableInfo<$CheckInsTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> day =
      GeneratedColumn<String>(
        'day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($CheckInsTable.$converterday);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CheckInsTable.$convertercreatedAt);
  static const VerificationMeta _isBackfillMeta = const VerificationMeta(
    'isBackfill',
  );
  @override
  late final GeneratedColumn<bool> isBackfill = GeneratedColumn<bool>(
    'is_backfill',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_backfill" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CheckInStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CheckInStatus>($CheckInsTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    day,
    createdAt,
    isBackfill,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('is_backfill')) {
      context.handle(
        _isBackfillMeta,
        isBackfill.isAcceptableOrUnknown(data['is_backfill']!, _isBackfillMeta),
      );
    } else if (isInserting) {
      context.missing(_isBackfillMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      day: $CheckInsTable.$converterday.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}day'],
        )!,
      ),
      createdAt: $CheckInsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      isBackfill: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_backfill'],
      )!,
      status: $CheckInsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterday = const LocalDateText();
  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeText();
  static TypeConverter<CheckInStatus, String> $converterstatus =
      checkInStatusConverter;
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  final String id;
  final String goalId;
  final LocalDate day;
  final DateTime createdAt;
  final bool isBackfill;
  final CheckInStatus status;
  const CheckIn({
    required this.id,
    required this.goalId,
    required this.day,
    required this.createdAt,
    required this.isBackfill,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    {
      map['day'] = Variable<String>($CheckInsTable.$converterday.toSql(day));
    }
    {
      map['created_at'] = Variable<String>(
        $CheckInsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['is_backfill'] = Variable<bool>(isBackfill);
    {
      map['status'] = Variable<String>(
        $CheckInsTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      day: Value(day),
      createdAt: Value(createdAt),
      isBackfill: Value(isBackfill),
      status: Value(status),
    );
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      day: serializer.fromJson<LocalDate>(json['day']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isBackfill: serializer.fromJson<bool>(json['isBackfill']),
      status: serializer.fromJson<CheckInStatus>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'day': serializer.toJson<LocalDate>(day),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isBackfill': serializer.toJson<bool>(isBackfill),
      'status': serializer.toJson<CheckInStatus>(status),
    };
  }

  CheckIn copyWith({
    String? id,
    String? goalId,
    LocalDate? day,
    DateTime? createdAt,
    bool? isBackfill,
    CheckInStatus? status,
  }) => CheckIn(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    day: day ?? this.day,
    createdAt: createdAt ?? this.createdAt,
    isBackfill: isBackfill ?? this.isBackfill,
    status: status ?? this.status,
  );
  CheckIn copyWithCompanion(CheckInsCompanion data) {
    return CheckIn(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      day: data.day.present ? data.day.value : this.day,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isBackfill: data.isBackfill.present
          ? data.isBackfill.value
          : this.isBackfill,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBackfill: $isBackfill, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, goalId, day, createdAt, isBackfill, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckIn &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.day == this.day &&
          other.createdAt == this.createdAt &&
          other.isBackfill == this.isBackfill &&
          other.status == this.status);
}

class CheckInsCompanion extends UpdateCompanion<CheckIn> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<LocalDate> day;
  final Value<DateTime> createdAt;
  final Value<bool> isBackfill;
  final Value<CheckInStatus> status;
  final Value<int> rowid;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.day = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isBackfill = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckInsCompanion.insert({
    required String id,
    required String goalId,
    required LocalDate day,
    required DateTime createdAt,
    required bool isBackfill,
    required CheckInStatus status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       day = Value(day),
       createdAt = Value(createdAt),
       isBackfill = Value(isBackfill),
       status = Value(status);
  static Insertable<CheckIn> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? day,
    Expression<String>? createdAt,
    Expression<bool>? isBackfill,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (day != null) 'day': day,
      if (createdAt != null) 'created_at': createdAt,
      if (isBackfill != null) 'is_backfill': isBackfill,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckInsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<LocalDate>? day,
    Value<DateTime>? createdAt,
    Value<bool>? isBackfill,
    Value<CheckInStatus>? status,
    Value<int>? rowid,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      isBackfill: isBackfill ?? this.isBackfill,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(
        $CheckInsTable.$converterday.toSql(day.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $CheckInsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (isBackfill.present) {
      map['is_backfill'] = Variable<bool>(isBackfill.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $CheckInsTable.$converterstatus.toSql(status.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBackfill: $isBackfill, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MilestoneStepsTable extends MilestoneSteps
    with TableInfo<$MilestoneStepsTable, MilestoneStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MilestoneStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> doneAt =
      GeneratedColumn<String>(
        'done_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($MilestoneStepsTable.$converterdoneAtn);
  @override
  List<GeneratedColumn> get $columns => [id, goalId, title, isDone, doneAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'milestone_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<MilestoneStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    } else if (isInserting) {
      context.missing(_isDoneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MilestoneStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MilestoneStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      doneAt: $MilestoneStepsTable.$converterdoneAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}done_at'],
        ),
      ),
    );
  }

  @override
  $MilestoneStepsTable createAlias(String alias) {
    return $MilestoneStepsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterdoneAt =
      const IsoDateTimeText();
  static TypeConverter<DateTime?, String?> $converterdoneAtn =
      NullAwareTypeConverter.wrap($converterdoneAt);
}

class MilestoneStep extends DataClass implements Insertable<MilestoneStep> {
  final String id;
  final String goalId;
  final String title;
  final bool isDone;
  final DateTime? doneAt;
  const MilestoneStep({
    required this.id,
    required this.goalId,
    required this.title,
    required this.isDone,
    this.doneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['title'] = Variable<String>(title);
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<String>(
        $MilestoneStepsTable.$converterdoneAtn.toSql(doneAt),
      );
    }
    return map;
  }

  MilestoneStepsCompanion toCompanion(bool nullToAbsent) {
    return MilestoneStepsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      title: Value(title),
      isDone: Value(isDone),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
    );
  }

  factory MilestoneStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MilestoneStep(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      title: serializer.fromJson<String>(json['title']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'title': serializer.toJson<String>(title),
      'isDone': serializer.toJson<bool>(isDone),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
    };
  }

  MilestoneStep copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? isDone,
    Value<DateTime?> doneAt = const Value.absent(),
  }) => MilestoneStep(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
  );
  MilestoneStep copyWithCompanion(MilestoneStepsCompanion data) {
    return MilestoneStep(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      title: data.title.present ? data.title.value : this.title,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MilestoneStep(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, title, isDone, doneAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MilestoneStep &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.title == this.title &&
          other.isDone == this.isDone &&
          other.doneAt == this.doneAt);
}

class MilestoneStepsCompanion extends UpdateCompanion<MilestoneStep> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> title;
  final Value<bool> isDone;
  final Value<DateTime?> doneAt;
  final Value<int> rowid;
  const MilestoneStepsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.title = const Value.absent(),
    this.isDone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilestoneStepsCompanion.insert({
    required String id,
    required String goalId,
    required String title,
    required bool isDone,
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       title = Value(title),
       isDone = Value(isDone);
  static Insertable<MilestoneStep> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? title,
    Expression<bool>? isDone,
    Expression<String>? doneAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (title != null) 'title': title,
      if (isDone != null) 'is_done': isDone,
      if (doneAt != null) 'done_at': doneAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilestoneStepsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? title,
    Value<bool>? isDone,
    Value<DateTime?>? doneAt,
    Value<int>? rowid,
  }) {
    return MilestoneStepsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      doneAt: doneAt ?? this.doneAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<String>(
        $MilestoneStepsTable.$converterdoneAtn.toSql(doneAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilestoneStepsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalTime, String> time =
      GeneratedColumn<String>(
        'time',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalTime>($RemindersTable.$convertertime);
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Cadence?, String> cadence =
      GeneratedColumn<String>(
        'cadence',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Cadence?>($RemindersTable.$convertercadencen);
  @override
  List<GeneratedColumn> get $columns => [id, goalId, time, isEnabled, cadence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    } else if (isInserting) {
      context.missing(_isEnabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
      time: $RemindersTable.$convertertime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}time'],
        )!,
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      cadence: $RemindersTable.$convertercadencen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cadence'],
        ),
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalTime, String> $convertertime =
      const LocalTimeText();
  static TypeConverter<Cadence, String> $convertercadence = cadenceConverter;
  static TypeConverter<Cadence?, String?> $convertercadencen =
      NullAwareTypeConverter.wrap($convertercadence);
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String? goalId;
  final LocalTime time;
  final bool isEnabled;
  final Cadence? cadence;
  const Reminder({
    required this.id,
    this.goalId,
    required this.time,
    required this.isEnabled,
    this.cadence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    {
      map['time'] = Variable<String>(
        $RemindersTable.$convertertime.toSql(time),
      );
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || cadence != null) {
      map['cadence'] = Variable<String>(
        $RemindersTable.$convertercadencen.toSql(cadence),
      );
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
      time: Value(time),
      isEnabled: Value(isEnabled),
      cadence: cadence == null && nullToAbsent
          ? const Value.absent()
          : Value(cadence),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String?>(json['goalId']),
      time: serializer.fromJson<LocalTime>(json['time']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      cadence: serializer.fromJson<Cadence?>(json['cadence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String?>(goalId),
      'time': serializer.toJson<LocalTime>(time),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'cadence': serializer.toJson<Cadence?>(cadence),
    };
  }

  Reminder copyWith({
    String? id,
    Value<String?> goalId = const Value.absent(),
    LocalTime? time,
    bool? isEnabled,
    Value<Cadence?> cadence = const Value.absent(),
  }) => Reminder(
    id: id ?? this.id,
    goalId: goalId.present ? goalId.value : this.goalId,
    time: time ?? this.time,
    isEnabled: isEnabled ?? this.isEnabled,
    cadence: cadence.present ? cadence.value : this.cadence,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      time: data.time.present ? data.time.value : this.time,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('time: $time, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('cadence: $cadence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, time, isEnabled, cadence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.time == this.time &&
          other.isEnabled == this.isEnabled &&
          other.cadence == this.cadence);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String?> goalId;
  final Value<LocalTime> time;
  final Value<bool> isEnabled;
  final Value<Cadence?> cadence;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.time = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.cadence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    this.goalId = const Value.absent(),
    required LocalTime time,
    required bool isEnabled,
    this.cadence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       time = Value(time),
       isEnabled = Value(isEnabled);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? time,
    Expression<bool>? isEnabled,
    Expression<String>? cadence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (time != null) 'time': time,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (cadence != null) 'cadence': cadence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String?>? goalId,
    Value<LocalTime>? time,
    Value<bool>? isEnabled,
    Value<Cadence?>? cadence,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      cadence: cadence ?? this.cadence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(
        $RemindersTable.$convertertime.toSql(time.value),
      );
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(
        $RemindersTable.$convertercadencen.toSql(cadence.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('time: $time, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('cadence: $cadence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeeklyReviewsTable extends WeeklyReviews
    with TableInfo<$WeeklyReviewsTable, WeeklyReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WeekStart, String> weekStart =
      GeneratedColumn<String>(
        'week_start',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WeekStart>($WeeklyReviewsTable.$converterweekStart);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> settledAt =
      GeneratedColumn<String>(
        'settled_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($WeeklyReviewsTable.$convertersettledAt);
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decisionJsonMeta = const VerificationMeta(
    'decisionJson',
  );
  @override
  late final GeneratedColumn<String> decisionJson = GeneratedColumn<String>(
    'decision_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weekStart,
    settledAt,
    snapshotJson,
    decisionJson,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('decision_json')) {
      context.handle(
        _decisionJsonMeta,
        decisionJson.isAcceptableOrUnknown(
          data['decision_json']!,
          _decisionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_decisionJsonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weekStart: $WeeklyReviewsTable.$converterweekStart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}week_start'],
        )!,
      ),
      settledAt: $WeeklyReviewsTable.$convertersettledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}settled_at'],
        )!,
      ),
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
      decisionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision_json'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $WeeklyReviewsTable createAlias(String alias) {
    return $WeeklyReviewsTable(attachedDatabase, alias);
  }

  static TypeConverter<WeekStart, String> $converterweekStart =
      const WeekStartText();
  static TypeConverter<DateTime, String> $convertersettledAt =
      const IsoDateTimeText();
}

class WeeklyReview extends DataClass implements Insertable<WeeklyReview> {
  final String id;
  final WeekStart weekStart;
  final DateTime settledAt;

  /// GoalWeekStat 列表 JSON + decision JSON（编码见 repositories.dart）。
  final String snapshotJson;
  final String decisionJson;
  final String? note;
  const WeeklyReview({
    required this.id,
    required this.weekStart,
    required this.settledAt,
    required this.snapshotJson,
    required this.decisionJson,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['week_start'] = Variable<String>(
        $WeeklyReviewsTable.$converterweekStart.toSql(weekStart),
      );
    }
    {
      map['settled_at'] = Variable<String>(
        $WeeklyReviewsTable.$convertersettledAt.toSql(settledAt),
      );
    }
    map['snapshot_json'] = Variable<String>(snapshotJson);
    map['decision_json'] = Variable<String>(decisionJson);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  WeeklyReviewsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyReviewsCompanion(
      id: Value(id),
      weekStart: Value(weekStart),
      settledAt: Value(settledAt),
      snapshotJson: Value(snapshotJson),
      decisionJson: Value(decisionJson),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory WeeklyReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyReview(
      id: serializer.fromJson<String>(json['id']),
      weekStart: serializer.fromJson<WeekStart>(json['weekStart']),
      settledAt: serializer.fromJson<DateTime>(json['settledAt']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      decisionJson: serializer.fromJson<String>(json['decisionJson']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weekStart': serializer.toJson<WeekStart>(weekStart),
      'settledAt': serializer.toJson<DateTime>(settledAt),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'decisionJson': serializer.toJson<String>(decisionJson),
      'note': serializer.toJson<String?>(note),
    };
  }

  WeeklyReview copyWith({
    String? id,
    WeekStart? weekStart,
    DateTime? settledAt,
    String? snapshotJson,
    String? decisionJson,
    Value<String?> note = const Value.absent(),
  }) => WeeklyReview(
    id: id ?? this.id,
    weekStart: weekStart ?? this.weekStart,
    settledAt: settledAt ?? this.settledAt,
    snapshotJson: snapshotJson ?? this.snapshotJson,
    decisionJson: decisionJson ?? this.decisionJson,
    note: note.present ? note.value : this.note,
  );
  WeeklyReview copyWithCompanion(WeeklyReviewsCompanion data) {
    return WeeklyReview(
      id: data.id.present ? data.id.value : this.id,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      decisionJson: data.decisionJson.present
          ? data.decisionJson.value
          : this.decisionJson,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReview(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('settledAt: $settledAt, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('decisionJson: $decisionJson, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, weekStart, settledAt, snapshotJson, decisionJson, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyReview &&
          other.id == this.id &&
          other.weekStart == this.weekStart &&
          other.settledAt == this.settledAt &&
          other.snapshotJson == this.snapshotJson &&
          other.decisionJson == this.decisionJson &&
          other.note == this.note);
}

class WeeklyReviewsCompanion extends UpdateCompanion<WeeklyReview> {
  final Value<String> id;
  final Value<WeekStart> weekStart;
  final Value<DateTime> settledAt;
  final Value<String> snapshotJson;
  final Value<String> decisionJson;
  final Value<String?> note;
  final Value<int> rowid;
  const WeeklyReviewsCompanion({
    this.id = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.decisionJson = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeeklyReviewsCompanion.insert({
    required String id,
    required WeekStart weekStart,
    required DateTime settledAt,
    required String snapshotJson,
    required String decisionJson,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weekStart = Value(weekStart),
       settledAt = Value(settledAt),
       snapshotJson = Value(snapshotJson),
       decisionJson = Value(decisionJson);
  static Insertable<WeeklyReview> custom({
    Expression<String>? id,
    Expression<String>? weekStart,
    Expression<String>? settledAt,
    Expression<String>? snapshotJson,
    Expression<String>? decisionJson,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStart != null) 'week_start': weekStart,
      if (settledAt != null) 'settled_at': settledAt,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (decisionJson != null) 'decision_json': decisionJson,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeeklyReviewsCompanion copyWith({
    Value<String>? id,
    Value<WeekStart>? weekStart,
    Value<DateTime>? settledAt,
    Value<String>? snapshotJson,
    Value<String>? decisionJson,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return WeeklyReviewsCompanion(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      settledAt: settledAt ?? this.settledAt,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      decisionJson: decisionJson ?? this.decisionJson,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(
        $WeeklyReviewsTable.$converterweekStart.toSql(weekStart.value),
      );
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<String>(
        $WeeklyReviewsTable.$convertersettledAt.toSql(settledAt.value),
      );
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (decisionJson.present) {
      map['decision_json'] = Variable<String>(decisionJson.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReviewsCompanion(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('settledAt: $settledAt, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('decisionJson: $decisionJson, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalTime, String>
  dailyBriefTime = GeneratedColumn<String>(
    'daily_brief_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<LocalTime>($SettingsRowsTable.$converterdailyBriefTime);
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarKeyMeta = const VerificationMeta(
    'avatarKey',
  );
  @override
  late final GeneratedColumn<String> avatarKey = GeneratedColumn<String>(
    'avatar_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notificationDeniedAcknowledgedMeta =
      const VerificationMeta('notificationDeniedAcknowledged');
  @override
  late final GeneratedColumn<bool> notificationDeniedAcknowledged =
      GeneratedColumn<bool>(
        'notification_denied_acknowledged',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notification_denied_acknowledged" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyBriefTime,
    nickname,
    avatarKey,
    onboardingCompleted,
    notificationDeniedAcknowledged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('avatar_key')) {
      context.handle(
        _avatarKeyMeta,
        avatarKey.isAcceptableOrUnknown(data['avatar_key']!, _avatarKeyMeta),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('notification_denied_acknowledged')) {
      context.handle(
        _notificationDeniedAcknowledgedMeta,
        notificationDeniedAcknowledged.isAcceptableOrUnknown(
          data['notification_denied_acknowledged']!,
          _notificationDeniedAcknowledgedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dailyBriefTime: $SettingsRowsTable.$converterdailyBriefTime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}daily_brief_time'],
        )!,
      ),
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      avatarKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_key'],
      ),
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      notificationDeniedAcknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notification_denied_acknowledged'],
      )!,
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalTime, String> $converterdailyBriefTime =
      const LocalTimeText();
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final LocalTime dailyBriefTime;
  final String? nickname;
  final String? avatarKey;
  final bool onboardingCompleted;
  final bool notificationDeniedAcknowledged;
  const SettingsRow({
    required this.id,
    required this.dailyBriefTime,
    this.nickname,
    this.avatarKey,
    required this.onboardingCompleted,
    required this.notificationDeniedAcknowledged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['daily_brief_time'] = Variable<String>(
        $SettingsRowsTable.$converterdailyBriefTime.toSql(dailyBriefTime),
      );
    }
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    if (!nullToAbsent || avatarKey != null) {
      map['avatar_key'] = Variable<String>(avatarKey);
    }
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['notification_denied_acknowledged'] = Variable<bool>(
      notificationDeniedAcknowledged,
    );
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      dailyBriefTime: Value(dailyBriefTime),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      avatarKey: avatarKey == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarKey),
      onboardingCompleted: Value(onboardingCompleted),
      notificationDeniedAcknowledged: Value(notificationDeniedAcknowledged),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      dailyBriefTime: serializer.fromJson<LocalTime>(json['dailyBriefTime']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      avatarKey: serializer.fromJson<String?>(json['avatarKey']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      notificationDeniedAcknowledged: serializer.fromJson<bool>(
        json['notificationDeniedAcknowledged'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dailyBriefTime': serializer.toJson<LocalTime>(dailyBriefTime),
      'nickname': serializer.toJson<String?>(nickname),
      'avatarKey': serializer.toJson<String?>(avatarKey),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'notificationDeniedAcknowledged': serializer.toJson<bool>(
        notificationDeniedAcknowledged,
      ),
    };
  }

  SettingsRow copyWith({
    int? id,
    LocalTime? dailyBriefTime,
    Value<String?> nickname = const Value.absent(),
    Value<String?> avatarKey = const Value.absent(),
    bool? onboardingCompleted,
    bool? notificationDeniedAcknowledged,
  }) => SettingsRow(
    id: id ?? this.id,
    dailyBriefTime: dailyBriefTime ?? this.dailyBriefTime,
    nickname: nickname.present ? nickname.value : this.nickname,
    avatarKey: avatarKey.present ? avatarKey.value : this.avatarKey,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    notificationDeniedAcknowledged:
        notificationDeniedAcknowledged ?? this.notificationDeniedAcknowledged,
  );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      dailyBriefTime: data.dailyBriefTime.present
          ? data.dailyBriefTime.value
          : this.dailyBriefTime,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatarKey: data.avatarKey.present ? data.avatarKey.value : this.avatarKey,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      notificationDeniedAcknowledged:
          data.notificationDeniedAcknowledged.present
          ? data.notificationDeniedAcknowledged.value
          : this.notificationDeniedAcknowledged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('dailyBriefTime: $dailyBriefTime, ')
          ..write('nickname: $nickname, ')
          ..write('avatarKey: $avatarKey, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write(
            'notificationDeniedAcknowledged: $notificationDeniedAcknowledged',
          )
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyBriefTime,
    nickname,
    avatarKey,
    onboardingCompleted,
    notificationDeniedAcknowledged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.dailyBriefTime == this.dailyBriefTime &&
          other.nickname == this.nickname &&
          other.avatarKey == this.avatarKey &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.notificationDeniedAcknowledged ==
              this.notificationDeniedAcknowledged);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<LocalTime> dailyBriefTime;
  final Value<String?> nickname;
  final Value<String?> avatarKey;
  final Value<bool> onboardingCompleted;
  final Value<bool> notificationDeniedAcknowledged;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.dailyBriefTime = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatarKey = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.notificationDeniedAcknowledged = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    required LocalTime dailyBriefTime,
    this.nickname = const Value.absent(),
    this.avatarKey = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.notificationDeniedAcknowledged = const Value.absent(),
  }) : dailyBriefTime = Value(dailyBriefTime);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? dailyBriefTime,
    Expression<String>? nickname,
    Expression<String>? avatarKey,
    Expression<bool>? onboardingCompleted,
    Expression<bool>? notificationDeniedAcknowledged,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyBriefTime != null) 'daily_brief_time': dailyBriefTime,
      if (nickname != null) 'nickname': nickname,
      if (avatarKey != null) 'avatar_key': avatarKey,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (notificationDeniedAcknowledged != null)
        'notification_denied_acknowledged': notificationDeniedAcknowledged,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<LocalTime>? dailyBriefTime,
    Value<String?>? nickname,
    Value<String?>? avatarKey,
    Value<bool>? onboardingCompleted,
    Value<bool>? notificationDeniedAcknowledged,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      dailyBriefTime: dailyBriefTime ?? this.dailyBriefTime,
      nickname: nickname ?? this.nickname,
      avatarKey: avatarKey ?? this.avatarKey,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationDeniedAcknowledged:
          notificationDeniedAcknowledged ?? this.notificationDeniedAcknowledged,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dailyBriefTime.present) {
      map['daily_brief_time'] = Variable<String>(
        $SettingsRowsTable.$converterdailyBriefTime.toSql(dailyBriefTime.value),
      );
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatarKey.present) {
      map['avatar_key'] = Variable<String>(avatarKey.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (notificationDeniedAcknowledged.present) {
      map['notification_denied_acknowledged'] = Variable<bool>(
        notificationDeniedAcknowledged.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('dailyBriefTime: $dailyBriefTime, ')
          ..write('nickname: $nickname, ')
          ..write('avatarKey: $avatarKey, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write(
            'notificationDeniedAcknowledged: $notificationDeniedAcknowledged',
          )
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $FrequencyVersionsTable frequencyVersions =
      $FrequencyVersionsTable(this);
  late final $BusyModeSessionsTable busyModeSessions = $BusyModeSessionsTable(
    this,
  );
  late final $BusyModeEntriesTable busyModeEntries = $BusyModeEntriesTable(
    this,
  );
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $MilestoneStepsTable milestoneSteps = $MilestoneStepsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $WeeklyReviewsTable weeklyReviews = $WeeklyReviewsTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    goals,
    frequencyVersions,
    busyModeSessions,
    busyModeEntries,
    checkIns,
    milestoneSteps,
    reminders,
    weeklyReviews,
    settingsRows,
  ];
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String name,
  required GoalType goalType,
  required String iconKey,
  Value<String?> colorKey,
  required GoalStatus status,
  required LocalDate createdAt,
  Value<LocalDate?> deadline,
  Value<DateTime?> achievedAt,
  Value<String?> motivation,
  Value<String?> successCriterion,
  Value<String?> cueScene,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<GoalType> goalType,
  Value<String> iconKey,
  Value<String?> colorKey,
  Value<GoalStatus> status,
  Value<LocalDate> createdAt,
  Value<LocalDate?> deadline,
  Value<DateTime?> achievedAt,
  Value<String?> motivation,
  Value<String?> successCriterion,
  Value<String?> cueScene,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FrequencyVersionsTable, List<FrequencyVersion>>
  _frequencyVersionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.frequencyVersions,
        aliasName: 'goals__id__frequency_versions__goal_id',
      );

  $$FrequencyVersionsTableProcessedTableManager get frequencyVersionsRefs {
    final manager = $$FrequencyVersionsTableTableManager(
      $_db,
      $_db.frequencyVersions,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _frequencyVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CheckInsTable, List<CheckIn>> _checkInsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.checkIns,
    aliasName: 'goals__id__check_ins__goal_id',
  );

  $$CheckInsTableProcessedTableManager get checkInsRefs {
    final manager = $$CheckInsTableTableManager(
      $_db,
      $_db.checkIns,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkInsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MilestoneStepsTable, List<MilestoneStep>>
  _milestoneStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.milestoneSteps,
    aliasName: 'goals__id__milestone_steps__goal_id',
  );

  $$MilestoneStepsTableProcessedTableManager get milestoneStepsRefs {
    final manager = $$MilestoneStepsTableTableManager(
      $_db,
      $_db.milestoneSteps,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_milestoneStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'goals__id__reminders__goal_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalType, GoalType, String> get goalType =>
      $composableBuilder(
        column: $table.goalType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalStatus, GoalStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String> get deadline =>
      $composableBuilder(
        column: $table.deadline,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get achievedAt =>
      $composableBuilder(
        column: $table.achievedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get successCriterion => $composableBuilder(
    column: $table.successCriterion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cueScene => $composableBuilder(
    column: $table.cueScene,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> frequencyVersionsRefs(
    Expression<bool> Function($$FrequencyVersionsTableFilterComposer f) f,
  ) {
    final $$FrequencyVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frequencyVersions,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequencyVersionsTableFilterComposer(
            $db: $db,
            $table: $db.frequencyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> checkInsRefs(
    Expression<bool> Function($$CheckInsTableFilterComposer f) f,
  ) {
    final $$CheckInsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableFilterComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> milestoneStepsRefs(
    Expression<bool> Function($$MilestoneStepsTableFilterComposer f) f,
  ) {
    final $$MilestoneStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestoneSteps,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MilestoneStepsTableFilterComposer(
            $db: $db,
            $table: $db.milestoneSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get successCriterion => $composableBuilder(
    column: $table.successCriterion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cueScene => $composableBuilder(
    column: $table.cueScene,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalType, String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate?, String> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get achievedAt =>
      $composableBuilder(
        column: $table.achievedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get successCriterion => $composableBuilder(
    column: $table.successCriterion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cueScene =>
      $composableBuilder(column: $table.cueScene, builder: (column) => column);

  Expression<T> frequencyVersionsRefs<T extends Object>(
    Expression<T> Function($$FrequencyVersionsTableAnnotationComposer a) f,
  ) {
    final $$FrequencyVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.frequencyVersions,
          getReferencedColumn: (t) => t.goalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FrequencyVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.frequencyVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> checkInsRefs<T extends Object>(
    Expression<T> Function($$CheckInsTableAnnotationComposer a) f,
  ) {
    final $$CheckInsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> milestoneStepsRefs<T extends Object>(
    Expression<T> Function($$MilestoneStepsTableAnnotationComposer a) f,
  ) {
    final $$MilestoneStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestoneSteps,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MilestoneStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.milestoneSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, $$GoalsTableReferences),
          Goal,
          PrefetchHooks Function({
            bool frequencyVersionsRefs,
            bool checkInsRefs,
            bool milestoneStepsRefs,
            bool remindersRefs,
          })
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<GoalType> goalType = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<String?> colorKey = const Value.absent(),
                Value<GoalStatus> status = const Value.absent(),
                Value<LocalDate> createdAt = const Value.absent(),
                Value<LocalDate?> deadline = const Value.absent(),
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<String?> motivation = const Value.absent(),
                Value<String?> successCriterion = const Value.absent(),
                Value<String?> cueScene = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                goalType: goalType,
                iconKey: iconKey,
                colorKey: colorKey,
                status: status,
                createdAt: createdAt,
                deadline: deadline,
                achievedAt: achievedAt,
                motivation: motivation,
                successCriterion: successCriterion,
                cueScene: cueScene,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required GoalType goalType,
                required String iconKey,
                Value<String?> colorKey = const Value.absent(),
                required GoalStatus status,
                required LocalDate createdAt,
                Value<LocalDate?> deadline = const Value.absent(),
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<String?> motivation = const Value.absent(),
                Value<String?> successCriterion = const Value.absent(),
                Value<String?> cueScene = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                goalType: goalType,
                iconKey: iconKey,
                colorKey: colorKey,
                status: status,
                createdAt: createdAt,
                deadline: deadline,
                achievedAt: achievedAt,
                motivation: motivation,
                successCriterion: successCriterion,
                cueScene: cueScene,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GoalsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                frequencyVersionsRefs = false,
                checkInsRefs = false,
                milestoneStepsRefs = false,
                remindersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (frequencyVersionsRefs) db.frequencyVersions,
                    if (checkInsRefs) db.checkIns,
                    if (milestoneStepsRefs) db.milestoneSteps,
                    if (remindersRefs) db.reminders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (frequencyVersionsRefs)
                        await $_getPrefetchedData<
                          Goal,
                          $GoalsTable,
                          FrequencyVersion
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._frequencyVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).frequencyVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (checkInsRefs)
                        await $_getPrefetchedData<Goal, $GoalsTable, CheckIn>(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._checkInsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).checkInsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (milestoneStepsRefs)
                        await $_getPrefetchedData<
                          Goal,
                          $GoalsTable,
                          MilestoneStep
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._milestoneStepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).milestoneStepsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<Goal, $GoalsTable, Reminder>(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, $$GoalsTableReferences),
      Goal,
      PrefetchHooks Function({
        bool frequencyVersionsRefs,
        bool checkInsRefs,
        bool milestoneStepsRefs,
        bool remindersRefs,
      })
    >;
typedef $$FrequencyVersionsTableCreateCompanionBuilder =
    FrequencyVersionsCompanion Function({
      required String id,
      required String goalId,
      required WeekStart effectiveFromWeek,
      required FrequencyPattern pattern,
      required FrequencySource source,
      Value<int> rowid,
    });
typedef $$FrequencyVersionsTableUpdateCompanionBuilder =
    FrequencyVersionsCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<WeekStart> effectiveFromWeek,
      Value<FrequencyPattern> pattern,
      Value<FrequencySource> source,
      Value<int> rowid,
    });

final class $$FrequencyVersionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FrequencyVersionsTable,
          FrequencyVersion
        > {
  $$FrequencyVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('frequency_versions__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FrequencyVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $FrequencyVersionsTable> {
  $$FrequencyVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WeekStart, WeekStart, String>
  get effectiveFromWeek => $composableBuilder(
    column: $table.effectiveFromWeek,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<FrequencyPattern, FrequencyPattern, String>
  get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<FrequencySource, FrequencySource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequencyVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FrequencyVersionsTable> {
  $$FrequencyVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveFromWeek => $composableBuilder(
    column: $table.effectiveFromWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequencyVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FrequencyVersionsTable> {
  $$FrequencyVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WeekStart, String> get effectiveFromWeek =>
      $composableBuilder(
        column: $table.effectiveFromWeek,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<FrequencyPattern, String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FrequencySource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequencyVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FrequencyVersionsTable,
          FrequencyVersion,
          $$FrequencyVersionsTableFilterComposer,
          $$FrequencyVersionsTableOrderingComposer,
          $$FrequencyVersionsTableAnnotationComposer,
          $$FrequencyVersionsTableCreateCompanionBuilder,
          $$FrequencyVersionsTableUpdateCompanionBuilder,
          (FrequencyVersion, $$FrequencyVersionsTableReferences),
          FrequencyVersion,
          PrefetchHooks Function({bool goalId})
        > {
  $$FrequencyVersionsTableTableManager(
    _$AppDatabase db,
    $FrequencyVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrequencyVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrequencyVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrequencyVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<WeekStart> effectiveFromWeek = const Value.absent(),
                Value<FrequencyPattern> pattern = const Value.absent(),
                Value<FrequencySource> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrequencyVersionsCompanion(
                id: id,
                goalId: goalId,
                effectiveFromWeek: effectiveFromWeek,
                pattern: pattern,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required WeekStart effectiveFromWeek,
                required FrequencyPattern pattern,
                required FrequencySource source,
                Value<int> rowid = const Value.absent(),
              }) => FrequencyVersionsCompanion.insert(
                id: id,
                goalId: goalId,
                effectiveFromWeek: effectiveFromWeek,
                pattern: pattern,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FrequencyVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$FrequencyVersionsTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$FrequencyVersionsTableReferences
                            ._goalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FrequencyVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FrequencyVersionsTable,
      FrequencyVersion,
      $$FrequencyVersionsTableFilterComposer,
      $$FrequencyVersionsTableOrderingComposer,
      $$FrequencyVersionsTableAnnotationComposer,
      $$FrequencyVersionsTableCreateCompanionBuilder,
      $$FrequencyVersionsTableUpdateCompanionBuilder,
      (FrequencyVersion, $$FrequencyVersionsTableReferences),
      FrequencyVersion,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$BusyModeSessionsTableCreateCompanionBuilder =
    BusyModeSessionsCompanion Function({
      required String id,
      required WeekStart weekStart,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });
typedef $$BusyModeSessionsTableUpdateCompanionBuilder =
    BusyModeSessionsCompanion Function({
      Value<String> id,
      Value<WeekStart> weekStart,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });

final class $$BusyModeSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $BusyModeSessionsTable, BusyModeSession> {
  $$BusyModeSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$BusyModeEntriesTable, List<BusyModeEntry>>
  _busyModeEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.busyModeEntries,
    aliasName: 'busy_mode_sessions__id__busy_mode_entries__session_id',
  );

  $$BusyModeEntriesTableProcessedTableManager get busyModeEntriesRefs {
    final manager = $$BusyModeEntriesTableTableManager(
      $_db,
      $_db.busyModeEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _busyModeEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BusyModeSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $BusyModeSessionsTable> {
  $$BusyModeSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WeekStart, WeekStart, String> get weekStart =>
      $composableBuilder(
        column: $table.weekStart,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get endedAt =>
      $composableBuilder(
        column: $table.endedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> busyModeEntriesRefs(
    Expression<bool> Function($$BusyModeEntriesTableFilterComposer f) f,
  ) {
    final $$BusyModeEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.busyModeEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusyModeEntriesTableFilterComposer(
            $db: $db,
            $table: $db.busyModeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BusyModeSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $BusyModeSessionsTable> {
  $$BusyModeSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusyModeSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusyModeSessionsTable> {
  $$BusyModeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WeekStart, String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  Expression<T> busyModeEntriesRefs<T extends Object>(
    Expression<T> Function($$BusyModeEntriesTableAnnotationComposer a) f,
  ) {
    final $$BusyModeEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.busyModeEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusyModeEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.busyModeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BusyModeSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusyModeSessionsTable,
          BusyModeSession,
          $$BusyModeSessionsTableFilterComposer,
          $$BusyModeSessionsTableOrderingComposer,
          $$BusyModeSessionsTableAnnotationComposer,
          $$BusyModeSessionsTableCreateCompanionBuilder,
          $$BusyModeSessionsTableUpdateCompanionBuilder,
          (BusyModeSession, $$BusyModeSessionsTableReferences),
          BusyModeSession,
          PrefetchHooks Function({bool busyModeEntriesRefs})
        > {
  $$BusyModeSessionsTableTableManager(
    _$AppDatabase db,
    $BusyModeSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusyModeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusyModeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusyModeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<WeekStart> weekStart = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusyModeSessionsCompanion(
                id: id,
                weekStart: weekStart,
                startedAt: startedAt,
                endedAt: endedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required WeekStart weekStart,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusyModeSessionsCompanion.insert(
                id: id,
                weekStart: weekStart,
                startedAt: startedAt,
                endedAt: endedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BusyModeSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({busyModeEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (busyModeEntriesRefs) db.busyModeEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (busyModeEntriesRefs)
                    await $_getPrefetchedData<
                      BusyModeSession,
                      $BusyModeSessionsTable,
                      BusyModeEntry
                    >(
                      currentTable: table,
                      referencedTable: $$BusyModeSessionsTableReferences
                          ._busyModeEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BusyModeSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).busyModeEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BusyModeSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusyModeSessionsTable,
      BusyModeSession,
      $$BusyModeSessionsTableFilterComposer,
      $$BusyModeSessionsTableOrderingComposer,
      $$BusyModeSessionsTableAnnotationComposer,
      $$BusyModeSessionsTableCreateCompanionBuilder,
      $$BusyModeSessionsTableUpdateCompanionBuilder,
      (BusyModeSession, $$BusyModeSessionsTableReferences),
      BusyModeSession,
      PrefetchHooks Function({bool busyModeEntriesRefs})
    >;
typedef $$BusyModeEntriesTableCreateCompanionBuilder =
    BusyModeEntriesCompanion Function({
      required String id,
      required String sessionId,
      required String goalId,
      required FrequencyPattern downgraded,
      Value<int> rowid,
    });
typedef $$BusyModeEntriesTableUpdateCompanionBuilder =
    BusyModeEntriesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> goalId,
      Value<FrequencyPattern> downgraded,
      Value<int> rowid,
    });

final class $$BusyModeEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $BusyModeEntriesTable, BusyModeEntry> {
  $$BusyModeEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusyModeSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .busyModeSessions
      .createAlias('busy_mode_entries__session_id__busy_mode_sessions__id');

  $$BusyModeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$BusyModeSessionsTableTableManager(
      $_db,
      $_db.busyModeSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BusyModeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BusyModeEntriesTable> {
  $$BusyModeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FrequencyPattern, FrequencyPattern, String>
  get downgraded => $composableBuilder(
    column: $table.downgraded,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$BusyModeSessionsTableFilterComposer get sessionId {
    final $$BusyModeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.busyModeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusyModeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.busyModeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BusyModeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BusyModeEntriesTable> {
  $$BusyModeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downgraded => $composableBuilder(
    column: $table.downgraded,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusyModeSessionsTableOrderingComposer get sessionId {
    final $$BusyModeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.busyModeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusyModeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.busyModeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BusyModeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusyModeEntriesTable> {
  $$BusyModeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FrequencyPattern, String> get downgraded =>
      $composableBuilder(
        column: $table.downgraded,
        builder: (column) => column,
      );

  $$BusyModeSessionsTableAnnotationComposer get sessionId {
    final $$BusyModeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.busyModeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusyModeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.busyModeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BusyModeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusyModeEntriesTable,
          BusyModeEntry,
          $$BusyModeEntriesTableFilterComposer,
          $$BusyModeEntriesTableOrderingComposer,
          $$BusyModeEntriesTableAnnotationComposer,
          $$BusyModeEntriesTableCreateCompanionBuilder,
          $$BusyModeEntriesTableUpdateCompanionBuilder,
          (BusyModeEntry, $$BusyModeEntriesTableReferences),
          BusyModeEntry,
          PrefetchHooks Function({bool sessionId})
        > {
  $$BusyModeEntriesTableTableManager(
    _$AppDatabase db,
    $BusyModeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusyModeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusyModeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusyModeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<FrequencyPattern> downgraded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusyModeEntriesCompanion(
                id: id,
                sessionId: sessionId,
                goalId: goalId,
                downgraded: downgraded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String goalId,
                required FrequencyPattern downgraded,
                Value<int> rowid = const Value.absent(),
              }) => BusyModeEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                goalId: goalId,
                downgraded: downgraded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BusyModeEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$BusyModeEntriesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$BusyModeEntriesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BusyModeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusyModeEntriesTable,
      BusyModeEntry,
      $$BusyModeEntriesTableFilterComposer,
      $$BusyModeEntriesTableOrderingComposer,
      $$BusyModeEntriesTableAnnotationComposer,
      $$BusyModeEntriesTableCreateCompanionBuilder,
      $$BusyModeEntriesTableUpdateCompanionBuilder,
      (BusyModeEntry, $$BusyModeEntriesTableReferences),
      BusyModeEntry,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$CheckInsTableCreateCompanionBuilder = CheckInsCompanion Function({
  required String id,
  required String goalId,
  required LocalDate day,
  required DateTime createdAt,
  required bool isBackfill,
  required CheckInStatus status,
  Value<int> rowid,
});
typedef $$CheckInsTableUpdateCompanionBuilder = CheckInsCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<LocalDate> day,
  Value<DateTime> createdAt,
  Value<bool> isBackfill,
  Value<CheckInStatus> status,
  Value<int> rowid,
});

final class $$CheckInsTableReferences
    extends BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn> {
  $$CheckInsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('check_ins__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get day =>
      $composableBuilder(
        column: $table.day,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CheckInStatus, CheckInStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CheckInStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckInsTable,
          CheckIn,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckIn, $$CheckInsTableReferences),
          CheckIn,
          PrefetchHooks Function({bool goalId})
        > {
  $$CheckInsTableTableManager(_$AppDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<LocalDate> day = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isBackfill = const Value.absent(),
                Value<CheckInStatus> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                goalId: goalId,
                day: day,
                createdAt: createdAt,
                isBackfill: isBackfill,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required LocalDate day,
                required DateTime createdAt,
                required bool isBackfill,
                required CheckInStatus status,
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion.insert(
                id: id,
                goalId: goalId,
                day: day,
                createdAt: createdAt,
                isBackfill: isBackfill,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CheckInsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$CheckInsTableReferences._goalIdTable(
                          db,
                        ),
                        referencedColumn: $$CheckInsTableReferences
                            ._goalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckInsTable,
      CheckIn,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckIn, $$CheckInsTableReferences),
      CheckIn,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$MilestoneStepsTableCreateCompanionBuilder =
    MilestoneStepsCompanion Function({
      required String id,
      required String goalId,
      required String title,
      required bool isDone,
      Value<DateTime?> doneAt,
      Value<int> rowid,
    });
typedef $$MilestoneStepsTableUpdateCompanionBuilder =
    MilestoneStepsCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> title,
      Value<bool> isDone,
      Value<DateTime?> doneAt,
      Value<int> rowid,
    });

final class $$MilestoneStepsTableReferences
    extends BaseReferences<_$AppDatabase, $MilestoneStepsTable, MilestoneStep> {
  $$MilestoneStepsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('milestone_steps__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MilestoneStepsTableFilterComposer
    extends Composer<_$AppDatabase, $MilestoneStepsTable> {
  $$MilestoneStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get doneAt =>
      $composableBuilder(
        column: $table.doneAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MilestoneStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $MilestoneStepsTable> {
  $$MilestoneStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MilestoneStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MilestoneStepsTable> {
  $$MilestoneStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MilestoneStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MilestoneStepsTable,
          MilestoneStep,
          $$MilestoneStepsTableFilterComposer,
          $$MilestoneStepsTableOrderingComposer,
          $$MilestoneStepsTableAnnotationComposer,
          $$MilestoneStepsTableCreateCompanionBuilder,
          $$MilestoneStepsTableUpdateCompanionBuilder,
          (MilestoneStep, $$MilestoneStepsTableReferences),
          MilestoneStep,
          PrefetchHooks Function({bool goalId})
        > {
  $$MilestoneStepsTableTableManager(
    _$AppDatabase db,
    $MilestoneStepsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MilestoneStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MilestoneStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MilestoneStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestoneStepsCompanion(
                id: id,
                goalId: goalId,
                title: title,
                isDone: isDone,
                doneAt: doneAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String title,
                required bool isDone,
                Value<DateTime?> doneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestoneStepsCompanion.insert(
                id: id,
                goalId: goalId,
                title: title,
                isDone: isDone,
                doneAt: doneAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MilestoneStepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$MilestoneStepsTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$MilestoneStepsTableReferences
                            ._goalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MilestoneStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MilestoneStepsTable,
      MilestoneStep,
      $$MilestoneStepsTableFilterComposer,
      $$MilestoneStepsTableOrderingComposer,
      $$MilestoneStepsTableAnnotationComposer,
      $$MilestoneStepsTableCreateCompanionBuilder,
      $$MilestoneStepsTableUpdateCompanionBuilder,
      (MilestoneStep, $$MilestoneStepsTableReferences),
      MilestoneStep,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  Value<String?> goalId,
  required LocalTime time,
  required bool isEnabled,
  Value<Cadence?> cadence,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String?> goalId,
  Value<LocalTime> time,
  Value<bool> isEnabled,
  Value<Cadence?> cadence,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('reminders__goal_id__goals__id');

  $$GoalsTableProcessedTableManager? get goalId {
    final $_column = $_itemColumn<String>('goal_id');
    if ($_column == null) return null;
    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalTime, LocalTime, String> get time =>
      $composableBuilder(
        column: $table.time,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Cadence?, Cadence, String> get cadence =>
      $composableBuilder(
        column: $table.cadence,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalTime, String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Cadence?, String> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool goalId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<LocalTime> time = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<Cadence?> cadence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                goalId: goalId,
                time: time,
                isEnabled: isEnabled,
                cadence: cadence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> goalId = const Value.absent(),
                required LocalTime time,
                required bool isEnabled,
                Value<Cadence?> cadence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                goalId: goalId,
                time: time,
                isEnabled: isEnabled,
                cadence: cadence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$RemindersTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._goalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$WeeklyReviewsTableCreateCompanionBuilder =
    WeeklyReviewsCompanion Function({
      required String id,
      required WeekStart weekStart,
      required DateTime settledAt,
      required String snapshotJson,
      required String decisionJson,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$WeeklyReviewsTableUpdateCompanionBuilder =
    WeeklyReviewsCompanion Function({
      Value<String> id,
      Value<WeekStart> weekStart,
      Value<DateTime> settledAt,
      Value<String> snapshotJson,
      Value<String> decisionJson,
      Value<String?> note,
      Value<int> rowid,
    });

class $$WeeklyReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyReviewsTable> {
  $$WeeklyReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WeekStart, WeekStart, String> get weekStart =>
      $composableBuilder(
        column: $table.weekStart,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get settledAt =>
      $composableBuilder(
        column: $table.settledAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decisionJson => $composableBuilder(
    column: $table.decisionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyReviewsTable> {
  $$WeeklyReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decisionJson => $composableBuilder(
    column: $table.decisionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyReviewsTable> {
  $$WeeklyReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WeekStart, String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decisionJson => $composableBuilder(
    column: $table.decisionJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$WeeklyReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeklyReviewsTable,
          WeeklyReview,
          $$WeeklyReviewsTableFilterComposer,
          $$WeeklyReviewsTableOrderingComposer,
          $$WeeklyReviewsTableAnnotationComposer,
          $$WeeklyReviewsTableCreateCompanionBuilder,
          $$WeeklyReviewsTableUpdateCompanionBuilder,
          (
            WeeklyReview,
            BaseReferences<_$AppDatabase, $WeeklyReviewsTable, WeeklyReview>,
          ),
          WeeklyReview,
          PrefetchHooks Function()
        > {
  $$WeeklyReviewsTableTableManager(_$AppDatabase db, $WeeklyReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<WeekStart> weekStart = const Value.absent(),
                Value<DateTime> settledAt = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
                Value<String> decisionJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeeklyReviewsCompanion(
                id: id,
                weekStart: weekStart,
                settledAt: settledAt,
                snapshotJson: snapshotJson,
                decisionJson: decisionJson,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required WeekStart weekStart,
                required DateTime settledAt,
                required String snapshotJson,
                required String decisionJson,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeeklyReviewsCompanion.insert(
                id: id,
                weekStart: weekStart,
                settledAt: settledAt,
                snapshotJson: snapshotJson,
                decisionJson: decisionJson,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeklyReviewsTable,
      WeeklyReview,
      $$WeeklyReviewsTableFilterComposer,
      $$WeeklyReviewsTableOrderingComposer,
      $$WeeklyReviewsTableAnnotationComposer,
      $$WeeklyReviewsTableCreateCompanionBuilder,
      $$WeeklyReviewsTableUpdateCompanionBuilder,
      (
        WeeklyReview,
        BaseReferences<_$AppDatabase, $WeeklyReviewsTable, WeeklyReview>,
      ),
      WeeklyReview,
      PrefetchHooks Function()
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      required LocalTime dailyBriefTime,
      Value<String?> nickname,
      Value<String?> avatarKey,
      Value<bool> onboardingCompleted,
      Value<bool> notificationDeniedAcknowledged,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<LocalTime> dailyBriefTime,
      Value<String?> nickname,
      Value<String?> avatarKey,
      Value<bool> onboardingCompleted,
      Value<bool> notificationDeniedAcknowledged,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalTime, LocalTime, String>
  get dailyBriefTime => $composableBuilder(
    column: $table.dailyBriefTime,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarKey => $composableBuilder(
    column: $table.avatarKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationDeniedAcknowledged => $composableBuilder(
    column: $table.notificationDeniedAcknowledged,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyBriefTime => $composableBuilder(
    column: $table.dailyBriefTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarKey => $composableBuilder(
    column: $table.avatarKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationDeniedAcknowledged =>
      $composableBuilder(
        column: $table.notificationDeniedAcknowledged,
        builder: (column) => ColumnOrderings(column),
      );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalTime, String> get dailyBriefTime =>
      $composableBuilder(
        column: $table.dailyBriefTime,
        builder: (column) => column,
      );

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatarKey =>
      $composableBuilder(column: $table.avatarKey, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationDeniedAcknowledged =>
      $composableBuilder(
        column: $table.notificationDeniedAcknowledged,
        builder: (column) => column,
      );
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(_$AppDatabase db, $SettingsRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<LocalTime> dailyBriefTime = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String?> avatarKey = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<bool> notificationDeniedAcknowledged =
                    const Value.absent(),
              }) => SettingsRowsCompanion(
                id: id,
                dailyBriefTime: dailyBriefTime,
                nickname: nickname,
                avatarKey: avatarKey,
                onboardingCompleted: onboardingCompleted,
                notificationDeniedAcknowledged: notificationDeniedAcknowledged,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required LocalTime dailyBriefTime,
                Value<String?> nickname = const Value.absent(),
                Value<String?> avatarKey = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<bool> notificationDeniedAcknowledged =
                    const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                dailyBriefTime: dailyBriefTime,
                nickname: nickname,
                avatarKey: avatarKey,
                onboardingCompleted: onboardingCompleted,
                notificationDeniedAcknowledged: notificationDeniedAcknowledged,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$FrequencyVersionsTableTableManager get frequencyVersions =>
      $$FrequencyVersionsTableTableManager(_db, _db.frequencyVersions);
  $$BusyModeSessionsTableTableManager get busyModeSessions =>
      $$BusyModeSessionsTableTableManager(_db, _db.busyModeSessions);
  $$BusyModeEntriesTableTableManager get busyModeEntries =>
      $$BusyModeEntriesTableTableManager(_db, _db.busyModeEntries);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$MilestoneStepsTableTableManager get milestoneSteps =>
      $$MilestoneStepsTableTableManager(_db, _db.milestoneSteps);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$WeeklyReviewsTableTableManager get weeklyReviews =>
      $$WeeklyReviewsTableTableManager(_db, _db.weeklyReviews);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
}
