// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
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
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
    'why',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalCategory?, String>
  categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<GoalCategory?>($GoalsTable.$convertercategoryKeyn);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedOrderMeta = const VerificationMeta(
    'pinnedOrder',
  );
  @override
  late final GeneratedColumn<int> pinnedOrder = GeneratedColumn<int>(
    'pinned_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> targetDate =
      GeneratedColumn<String>(
        'target_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($GoalsTable.$convertertargetDaten);
  @override
  late final GeneratedColumnWithTypeConverter<FrequencyPattern?, String>
  frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<FrequencyPattern?>($GoalsTable.$converterfrequencyn);
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
  late final GeneratedColumnWithTypeConverter<DateTime?, String> achievedAt =
      GeneratedColumn<String>(
        'achieved_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GoalsTable.$converterachievedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> archivedAt =
      GeneratedColumn<String>(
        'archived_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GoalsTable.$converterarchivedAtn);
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
  List<GeneratedColumn> get $columns => [
    id,
    name,
    why,
    categoryKey,
    iconKey,
    colorKey,
    pinned,
    pinnedOrder,
    targetDate,
    frequency,
    status,
    achievedAt,
    archivedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
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
    if (data.containsKey('why')) {
      context.handle(
        _whyMeta,
        why.isAcceptableOrUnknown(data['why']!, _whyMeta),
      );
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
    } else if (isInserting) {
      context.missing(_colorKeyMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('pinned_order')) {
      context.handle(
        _pinnedOrderMeta,
        pinnedOrder.isAcceptableOrUnknown(
          data['pinned_order']!,
          _pinnedOrderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      why: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why'],
      ),
      categoryKey: $GoalsTable.$convertercategoryKeyn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category_key'],
        ),
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_key'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      pinnedOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pinned_order'],
      ),
      targetDate: $GoalsTable.$convertertargetDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_date'],
        ),
      ),
      frequency: $GoalsTable.$converterfrequencyn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}frequency'],
        ),
      ),
      status: $GoalsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      achievedAt: $GoalsTable.$converterachievedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}achieved_at'],
        ),
      ),
      archivedAt: $GoalsTable.$converterarchivedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}archived_at'],
        ),
      ),
      createdAt: $GoalsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static TypeConverter<GoalCategory, String> $convertercategoryKey =
      categoryConverter;
  static TypeConverter<GoalCategory?, String?> $convertercategoryKeyn =
      NullAwareTypeConverter.wrap($convertercategoryKey);
  static TypeConverter<LocalDate, String> $convertertargetDate =
      const LocalDateText();
  static TypeConverter<LocalDate?, String?> $convertertargetDaten =
      NullAwareTypeConverter.wrap($convertertargetDate);
  static TypeConverter<FrequencyPattern, String> $converterfrequency =
      const FrequencyPatternJson();
  static TypeConverter<FrequencyPattern?, String?> $converterfrequencyn =
      NullAwareTypeConverter.wrap($converterfrequency);
  static TypeConverter<GoalStatus, String> $converterstatus =
      goalStatusConverter;
  static TypeConverter<DateTime, String> $converterachievedAt =
      const IsoDateTimeText();
  static TypeConverter<DateTime?, String?> $converterachievedAtn =
      NullAwareTypeConverter.wrap($converterachievedAt);
  static TypeConverter<DateTime, String> $converterarchivedAt =
      const IsoDateTimeText();
  static TypeConverter<DateTime?, String?> $converterarchivedAtn =
      NullAwareTypeConverter.wrap($converterarchivedAt);
  static TypeConverter<LocalDate, String> $convertercreatedAt =
      const LocalDateText();
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final String id;
  final String name;
  final String? why;
  final GoalCategory? categoryKey;
  final String iconKey;
  final String colorKey;
  final bool pinned;
  final int? pinnedOrder;
  final LocalDate? targetDate;
  final FrequencyPattern? frequency;
  final GoalStatus status;
  final DateTime? achievedAt;
  final DateTime? archivedAt;
  final LocalDate createdAt;
  const GoalRow({
    required this.id,
    required this.name,
    this.why,
    this.categoryKey,
    required this.iconKey,
    required this.colorKey,
    required this.pinned,
    this.pinnedOrder,
    this.targetDate,
    this.frequency,
    required this.status,
    this.achievedAt,
    this.archivedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || why != null) {
      map['why'] = Variable<String>(why);
    }
    if (!nullToAbsent || categoryKey != null) {
      map['category_key'] = Variable<String>(
        $GoalsTable.$convertercategoryKeyn.toSql(categoryKey),
      );
    }
    map['icon_key'] = Variable<String>(iconKey);
    map['color_key'] = Variable<String>(colorKey);
    map['pinned'] = Variable<bool>(pinned);
    if (!nullToAbsent || pinnedOrder != null) {
      map['pinned_order'] = Variable<int>(pinnedOrder);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(
        $GoalsTable.$convertertargetDaten.toSql(targetDate),
      );
    }
    if (!nullToAbsent || frequency != null) {
      map['frequency'] = Variable<String>(
        $GoalsTable.$converterfrequencyn.toSql(frequency),
      );
    }
    {
      map['status'] = Variable<String>(
        $GoalsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<String>(
        $GoalsTable.$converterachievedAtn.toSql(achievedAt),
      );
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<String>(
        $GoalsTable.$converterarchivedAtn.toSql(archivedAt),
      );
    }
    {
      map['created_at'] = Variable<String>(
        $GoalsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      why: why == null && nullToAbsent ? const Value.absent() : Value(why),
      categoryKey: categoryKey == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryKey),
      iconKey: Value(iconKey),
      colorKey: Value(colorKey),
      pinned: Value(pinned),
      pinnedOrder: pinnedOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedOrder),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      frequency: frequency == null && nullToAbsent
          ? const Value.absent()
          : Value(frequency),
      status: Value(status),
      achievedAt: achievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(achievedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      why: serializer.fromJson<String?>(json['why']),
      categoryKey: serializer.fromJson<GoalCategory?>(json['categoryKey']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorKey: serializer.fromJson<String>(json['colorKey']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      pinnedOrder: serializer.fromJson<int?>(json['pinnedOrder']),
      targetDate: serializer.fromJson<LocalDate?>(json['targetDate']),
      frequency: serializer.fromJson<FrequencyPattern?>(json['frequency']),
      status: serializer.fromJson<GoalStatus>(json['status']),
      achievedAt: serializer.fromJson<DateTime?>(json['achievedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<LocalDate>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'why': serializer.toJson<String?>(why),
      'categoryKey': serializer.toJson<GoalCategory?>(categoryKey),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorKey': serializer.toJson<String>(colorKey),
      'pinned': serializer.toJson<bool>(pinned),
      'pinnedOrder': serializer.toJson<int?>(pinnedOrder),
      'targetDate': serializer.toJson<LocalDate?>(targetDate),
      'frequency': serializer.toJson<FrequencyPattern?>(frequency),
      'status': serializer.toJson<GoalStatus>(status),
      'achievedAt': serializer.toJson<DateTime?>(achievedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<LocalDate>(createdAt),
    };
  }

  GoalRow copyWith({
    String? id,
    String? name,
    Value<String?> why = const Value.absent(),
    Value<GoalCategory?> categoryKey = const Value.absent(),
    String? iconKey,
    String? colorKey,
    bool? pinned,
    Value<int?> pinnedOrder = const Value.absent(),
    Value<LocalDate?> targetDate = const Value.absent(),
    Value<FrequencyPattern?> frequency = const Value.absent(),
    GoalStatus? status,
    Value<DateTime?> achievedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    LocalDate? createdAt,
  }) => GoalRow(
    id: id ?? this.id,
    name: name ?? this.name,
    why: why.present ? why.value : this.why,
    categoryKey: categoryKey.present ? categoryKey.value : this.categoryKey,
    iconKey: iconKey ?? this.iconKey,
    colorKey: colorKey ?? this.colorKey,
    pinned: pinned ?? this.pinned,
    pinnedOrder: pinnedOrder.present ? pinnedOrder.value : this.pinnedOrder,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    frequency: frequency.present ? frequency.value : this.frequency,
    status: status ?? this.status,
    achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      why: data.why.present ? data.why.value : this.why,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      pinnedOrder: data.pinnedOrder.present
          ? data.pinnedOrder.value
          : this.pinnedOrder,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      status: data.status.present ? data.status.value : this.status,
      achievedAt: data.achievedAt.present
          ? data.achievedAt.value
          : this.achievedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('why: $why, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('pinned: $pinned, ')
          ..write('pinnedOrder: $pinnedOrder, ')
          ..write('targetDate: $targetDate, ')
          ..write('frequency: $frequency, ')
          ..write('status: $status, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    why,
    categoryKey,
    iconKey,
    colorKey,
    pinned,
    pinnedOrder,
    targetDate,
    frequency,
    status,
    achievedAt,
    archivedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.why == this.why &&
          other.categoryKey == this.categoryKey &&
          other.iconKey == this.iconKey &&
          other.colorKey == this.colorKey &&
          other.pinned == this.pinned &&
          other.pinnedOrder == this.pinnedOrder &&
          other.targetDate == this.targetDate &&
          other.frequency == this.frequency &&
          other.status == this.status &&
          other.achievedAt == this.achievedAt &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> why;
  final Value<GoalCategory?> categoryKey;
  final Value<String> iconKey;
  final Value<String> colorKey;
  final Value<bool> pinned;
  final Value<int?> pinnedOrder;
  final Value<LocalDate?> targetDate;
  final Value<FrequencyPattern?> frequency;
  final Value<GoalStatus> status;
  final Value<DateTime?> achievedAt;
  final Value<DateTime?> archivedAt;
  final Value<LocalDate> createdAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.why = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.pinned = const Value.absent(),
    this.pinnedOrder = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.frequency = const Value.absent(),
    this.status = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String name,
    this.why = const Value.absent(),
    this.categoryKey = const Value.absent(),
    required String iconKey,
    required String colorKey,
    this.pinned = const Value.absent(),
    this.pinnedOrder = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.frequency = const Value.absent(),
    required GoalStatus status,
    this.achievedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required LocalDate createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       iconKey = Value(iconKey),
       colorKey = Value(colorKey),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<GoalRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? why,
    Expression<String>? categoryKey,
    Expression<String>? iconKey,
    Expression<String>? colorKey,
    Expression<bool>? pinned,
    Expression<int>? pinnedOrder,
    Expression<String>? targetDate,
    Expression<String>? frequency,
    Expression<String>? status,
    Expression<String>? achievedAt,
    Expression<String>? archivedAt,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (why != null) 'why': why,
      if (categoryKey != null) 'category_key': categoryKey,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorKey != null) 'color_key': colorKey,
      if (pinned != null) 'pinned': pinned,
      if (pinnedOrder != null) 'pinned_order': pinnedOrder,
      if (targetDate != null) 'target_date': targetDate,
      if (frequency != null) 'frequency': frequency,
      if (status != null) 'status': status,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? why,
    Value<GoalCategory?>? categoryKey,
    Value<String>? iconKey,
    Value<String>? colorKey,
    Value<bool>? pinned,
    Value<int?>? pinnedOrder,
    Value<LocalDate?>? targetDate,
    Value<FrequencyPattern?>? frequency,
    Value<GoalStatus>? status,
    Value<DateTime?>? achievedAt,
    Value<DateTime?>? archivedAt,
    Value<LocalDate>? createdAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      why: why ?? this.why,
      categoryKey: categoryKey ?? this.categoryKey,
      iconKey: iconKey ?? this.iconKey,
      colorKey: colorKey ?? this.colorKey,
      pinned: pinned ?? this.pinned,
      pinnedOrder: pinnedOrder ?? this.pinnedOrder,
      targetDate: targetDate ?? this.targetDate,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      achievedAt: achievedAt ?? this.achievedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
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
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(
        $GoalsTable.$convertercategoryKeyn.toSql(categoryKey.value),
      );
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (pinnedOrder.present) {
      map['pinned_order'] = Variable<int>(pinnedOrder.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(
        $GoalsTable.$convertertargetDaten.toSql(targetDate.value),
      );
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(
        $GoalsTable.$converterfrequencyn.toSql(frequency.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $GoalsTable.$converterstatus.toSql(status.value),
      );
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<String>(
        $GoalsTable.$converterachievedAtn.toSql(achievedAt.value),
      );
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<String>(
        $GoalsTable.$converterarchivedAtn.toSql(archivedAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $GoalsTable.$convertercreatedAt.toSql(createdAt.value),
      );
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
          ..write('why: $why, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('pinned: $pinned, ')
          ..write('pinnedOrder: $pinnedOrder, ')
          ..write('targetDate: $targetDate, ')
          ..write('frequency: $frequency, ')
          ..write('status: $status, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressRecordsTable extends ProgressRecords
    with TableInfo<$ProgressRecordsTable, RecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> day =
      GeneratedColumn<String>(
        'day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($ProgressRecordsTable.$converterday);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ProgressRecordsTable.$convertercreatedAt);
  static const VerificationMeta _isBackfillMeta = const VerificationMeta(
    'isBackfill',
  );
  @override
  late final GeneratedColumn<bool> isBackfill = GeneratedColumn<bool>(
    'is_backfill',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_backfill" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecordKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecordKind>($ProgressRecordsTable.$converterkind);
  static const VerificationMeta _milestoneIdMeta = const VerificationMeta(
    'milestoneId',
  );
  @override
  late final GeneratedColumn<String> milestoneId = GeneratedColumn<String>(
    'milestone_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    title,
    body,
    durationMinutes,
    day,
    createdAt,
    isBackfill,
    kind,
    milestoneId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordRow> instance, {
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
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('is_backfill')) {
      context.handle(
        _isBackfillMeta,
        isBackfill.isAcceptableOrUnknown(data['is_backfill']!, _isBackfillMeta),
      );
    }
    if (data.containsKey('milestone_id')) {
      context.handle(
        _milestoneIdMeta,
        milestoneId.isAcceptableOrUnknown(
          data['milestone_id']!,
          _milestoneIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordRow(
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
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      day: $ProgressRecordsTable.$converterday.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}day'],
        )!,
      ),
      createdAt: $ProgressRecordsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      isBackfill: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_backfill'],
      )!,
      kind: $ProgressRecordsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      milestoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestone_id'],
      ),
    );
  }

  @override
  $ProgressRecordsTable createAlias(String alias) {
    return $ProgressRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterday = const LocalDateText();
  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeText();
  static TypeConverter<RecordKind, String> $converterkind = recordKindConverter;
}

class RecordRow extends DataClass implements Insertable<RecordRow> {
  final String id;
  final String goalId;
  final String title;
  final String? body;
  final int? durationMinutes;
  final LocalDate day;
  final DateTime createdAt;
  final bool isBackfill;
  final RecordKind kind;
  final String? milestoneId;
  const RecordRow({
    required this.id,
    required this.goalId,
    required this.title,
    this.body,
    this.durationMinutes,
    required this.day,
    required this.createdAt,
    required this.isBackfill,
    required this.kind,
    this.milestoneId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    {
      map['day'] = Variable<String>(
        $ProgressRecordsTable.$converterday.toSql(day),
      );
    }
    {
      map['created_at'] = Variable<String>(
        $ProgressRecordsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['is_backfill'] = Variable<bool>(isBackfill);
    {
      map['kind'] = Variable<String>(
        $ProgressRecordsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || milestoneId != null) {
      map['milestone_id'] = Variable<String>(milestoneId);
    }
    return map;
  }

  ProgressRecordsCompanion toCompanion(bool nullToAbsent) {
    return ProgressRecordsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      day: Value(day),
      createdAt: Value(createdAt),
      isBackfill: Value(isBackfill),
      kind: Value(kind),
      milestoneId: milestoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(milestoneId),
    );
  }

  factory RecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      day: serializer.fromJson<LocalDate>(json['day']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isBackfill: serializer.fromJson<bool>(json['isBackfill']),
      kind: serializer.fromJson<RecordKind>(json['kind']),
      milestoneId: serializer.fromJson<String?>(json['milestoneId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'day': serializer.toJson<LocalDate>(day),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isBackfill': serializer.toJson<bool>(isBackfill),
      'kind': serializer.toJson<RecordKind>(kind),
      'milestoneId': serializer.toJson<String?>(milestoneId),
    };
  }

  RecordRow copyWith({
    String? id,
    String? goalId,
    String? title,
    Value<String?> body = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    LocalDate? day,
    DateTime? createdAt,
    bool? isBackfill,
    RecordKind? kind,
    Value<String?> milestoneId = const Value.absent(),
  }) => RecordRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    day: day ?? this.day,
    createdAt: createdAt ?? this.createdAt,
    isBackfill: isBackfill ?? this.isBackfill,
    kind: kind ?? this.kind,
    milestoneId: milestoneId.present ? milestoneId.value : this.milestoneId,
  );
  RecordRow copyWithCompanion(ProgressRecordsCompanion data) {
    return RecordRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      day: data.day.present ? data.day.value : this.day,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isBackfill: data.isBackfill.present
          ? data.isBackfill.value
          : this.isBackfill,
      kind: data.kind.present ? data.kind.value : this.kind,
      milestoneId: data.milestoneId.present
          ? data.milestoneId.value
          : this.milestoneId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBackfill: $isBackfill, ')
          ..write('kind: $kind, ')
          ..write('milestoneId: $milestoneId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    title,
    body,
    durationMinutes,
    day,
    createdAt,
    isBackfill,
    kind,
    milestoneId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.title == this.title &&
          other.body == this.body &&
          other.durationMinutes == this.durationMinutes &&
          other.day == this.day &&
          other.createdAt == this.createdAt &&
          other.isBackfill == this.isBackfill &&
          other.kind == this.kind &&
          other.milestoneId == this.milestoneId);
}

class ProgressRecordsCompanion extends UpdateCompanion<RecordRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> title;
  final Value<String?> body;
  final Value<int?> durationMinutes;
  final Value<LocalDate> day;
  final Value<DateTime> createdAt;
  final Value<bool> isBackfill;
  final Value<RecordKind> kind;
  final Value<String?> milestoneId;
  final Value<int> rowid;
  const ProgressRecordsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.day = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isBackfill = const Value.absent(),
    this.kind = const Value.absent(),
    this.milestoneId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressRecordsCompanion.insert({
    required String id,
    required String goalId,
    required String title,
    this.body = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    required LocalDate day,
    required DateTime createdAt,
    this.isBackfill = const Value.absent(),
    required RecordKind kind,
    this.milestoneId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       title = Value(title),
       day = Value(day),
       createdAt = Value(createdAt),
       kind = Value(kind);
  static Insertable<RecordRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? durationMinutes,
    Expression<String>? day,
    Expression<String>? createdAt,
    Expression<bool>? isBackfill,
    Expression<String>? kind,
    Expression<String>? milestoneId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (day != null) 'day': day,
      if (createdAt != null) 'created_at': createdAt,
      if (isBackfill != null) 'is_backfill': isBackfill,
      if (kind != null) 'kind': kind,
      if (milestoneId != null) 'milestone_id': milestoneId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? title,
    Value<String?>? body,
    Value<int?>? durationMinutes,
    Value<LocalDate>? day,
    Value<DateTime>? createdAt,
    Value<bool>? isBackfill,
    Value<RecordKind>? kind,
    Value<String?>? milestoneId,
    Value<int>? rowid,
  }) {
    return ProgressRecordsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      body: body ?? this.body,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      isBackfill: isBackfill ?? this.isBackfill,
      kind: kind ?? this.kind,
      milestoneId: milestoneId ?? this.milestoneId,
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
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(
        $ProgressRecordsTable.$converterday.toSql(day.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $ProgressRecordsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (isBackfill.present) {
      map['is_backfill'] = Variable<bool>(isBackfill.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ProgressRecordsTable.$converterkind.toSql(kind.value),
      );
    }
    if (milestoneId.present) {
      map['milestone_id'] = Variable<String>(milestoneId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRecordsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBackfill: $isBackfill, ')
          ..write('kind: $kind, ')
          ..write('milestoneId: $milestoneId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MilestonesTable extends Milestones
    with TableInfo<$MilestonesTable, MilestoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MilestonesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> doneAt =
      GeneratedColumn<String>(
        'done_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($MilestonesTable.$converterdoneAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    title,
    description,
    position,
    isDone,
    doneAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<MilestoneRow> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MilestoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MilestoneRow(
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
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      doneAt: $MilestonesTable.$converterdoneAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}done_at'],
        ),
      ),
    );
  }

  @override
  $MilestonesTable createAlias(String alias) {
    return $MilestonesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterdoneAt =
      const IsoDateTimeText();
  static TypeConverter<DateTime?, String?> $converterdoneAtn =
      NullAwareTypeConverter.wrap($converterdoneAt);
}

class MilestoneRow extends DataClass implements Insertable<MilestoneRow> {
  final String id;
  final String goalId;
  final String title;
  final String? description;
  final int position;
  final bool isDone;
  final DateTime? doneAt;
  const MilestoneRow({
    required this.id,
    required this.goalId,
    required this.title,
    this.description,
    required this.position,
    required this.isDone,
    this.doneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['position'] = Variable<int>(position);
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<String>(
        $MilestonesTable.$converterdoneAtn.toSql(doneAt),
      );
    }
    return map;
  }

  MilestonesCompanion toCompanion(bool nullToAbsent) {
    return MilestonesCompanion(
      id: Value(id),
      goalId: Value(goalId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      position: Value(position),
      isDone: Value(isDone),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
    );
  }

  factory MilestoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MilestoneRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      position: serializer.fromJson<int>(json['position']),
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
      'description': serializer.toJson<String?>(description),
      'position': serializer.toJson<int>(position),
      'isDone': serializer.toJson<bool>(isDone),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
    };
  }

  MilestoneRow copyWith({
    String? id,
    String? goalId,
    String? title,
    Value<String?> description = const Value.absent(),
    int? position,
    bool? isDone,
    Value<DateTime?> doneAt = const Value.absent(),
  }) => MilestoneRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    position: position ?? this.position,
    isDone: isDone ?? this.isDone,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
  );
  MilestoneRow copyWithCompanion(MilestonesCompanion data) {
    return MilestoneRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      position: data.position.present ? data.position.value : this.position,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MilestoneRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('position: $position, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, goalId, title, description, position, isDone, doneAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MilestoneRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.title == this.title &&
          other.description == this.description &&
          other.position == this.position &&
          other.isDone == this.isDone &&
          other.doneAt == this.doneAt);
}

class MilestonesCompanion extends UpdateCompanion<MilestoneRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> position;
  final Value<bool> isDone;
  final Value<DateTime?> doneAt;
  final Value<int> rowid;
  const MilestonesCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.position = const Value.absent(),
    this.isDone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilestonesCompanion.insert({
    required String id,
    required String goalId,
    required String title,
    this.description = const Value.absent(),
    this.position = const Value.absent(),
    this.isDone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       title = Value(title);
  static Insertable<MilestoneRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? position,
    Expression<bool>? isDone,
    Expression<String>? doneAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (position != null) 'position': position,
      if (isDone != null) 'is_done': isDone,
      if (doneAt != null) 'done_at': doneAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilestonesCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? position,
    Value<bool>? isDone,
    Value<DateTime?>? doneAt,
    Value<int>? rowid,
  }) {
    return MilestonesCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<String>(
        $MilestonesTable.$converterdoneAtn.toSql(doneAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilestonesCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('position: $position, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Cadence, String> cadence =
      GeneratedColumn<String>(
        'cadence',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Cadence>($RemindersTable.$convertercadence);
  @override
  List<GeneratedColumn> get $columns => [id, goalId, time, isEnabled, cadence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
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
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
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
      cadence: $RemindersTable.$convertercadence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cadence'],
        )!,
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
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final String goalId;
  final LocalTime time;
  final bool isEnabled;
  final Cadence cadence;
  const ReminderRow({
    required this.id,
    required this.goalId,
    required this.time,
    required this.isEnabled,
    required this.cadence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    {
      map['time'] = Variable<String>(
        $RemindersTable.$convertertime.toSql(time),
      );
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    {
      map['cadence'] = Variable<String>(
        $RemindersTable.$convertercadence.toSql(cadence),
      );
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      goalId: Value(goalId),
      time: Value(time),
      isEnabled: Value(isEnabled),
      cadence: Value(cadence),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      time: serializer.fromJson<LocalTime>(json['time']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      cadence: serializer.fromJson<Cadence>(json['cadence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'time': serializer.toJson<LocalTime>(time),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'cadence': serializer.toJson<Cadence>(cadence),
    };
  }

  ReminderRow copyWith({
    String? id,
    String? goalId,
    LocalTime? time,
    bool? isEnabled,
    Cadence? cadence,
  }) => ReminderRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    time: time ?? this.time,
    isEnabled: isEnabled ?? this.isEnabled,
    cadence: cadence ?? this.cadence,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      time: data.time.present ? data.time.value : this.time,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
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
      (other is ReminderRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.time == this.time &&
          other.isEnabled == this.isEnabled &&
          other.cadence == this.cadence);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<LocalTime> time;
  final Value<bool> isEnabled;
  final Value<Cadence> cadence;
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
    required String goalId,
    required LocalTime time,
    this.isEnabled = const Value.absent(),
    required Cadence cadence,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       time = Value(time),
       cadence = Value(cadence);
  static Insertable<ReminderRow> custom({
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
    Value<String>? goalId,
    Value<LocalTime>? time,
    Value<bool>? isEnabled,
    Value<Cadence>? cadence,
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
        $RemindersTable.$convertercadence.toSql(cadence.value),
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
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindersEnabledMeta = const VerificationMeta(
    'remindersEnabled',
  );
  @override
  late final GeneratedColumn<bool> remindersEnabled = GeneratedColumn<bool>(
    'reminders_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nickname,
    avatarKey,
    themeMode,
    remindersEnabled,
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
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('reminders_enabled')) {
      context.handle(
        _remindersEnabledMeta,
        remindersEnabled.isAcceptableOrUnknown(
          data['reminders_enabled']!,
          _remindersEnabledMeta,
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
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      avatarKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_key'],
      ),
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      ),
      remindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_enabled'],
      )!,
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String? nickname;
  final String? avatarKey;
  final String? themeMode;
  final bool remindersEnabled;
  const SettingsRow({
    required this.id,
    this.nickname,
    this.avatarKey,
    this.themeMode,
    required this.remindersEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    if (!nullToAbsent || avatarKey != null) {
      map['avatar_key'] = Variable<String>(avatarKey);
    }
    if (!nullToAbsent || themeMode != null) {
      map['theme_mode'] = Variable<String>(themeMode);
    }
    map['reminders_enabled'] = Variable<bool>(remindersEnabled);
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      avatarKey: avatarKey == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarKey),
      themeMode: themeMode == null && nullToAbsent
          ? const Value.absent()
          : Value(themeMode),
      remindersEnabled: Value(remindersEnabled),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      avatarKey: serializer.fromJson<String?>(json['avatarKey']),
      themeMode: serializer.fromJson<String?>(json['themeMode']),
      remindersEnabled: serializer.fromJson<bool>(json['remindersEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nickname': serializer.toJson<String?>(nickname),
      'avatarKey': serializer.toJson<String?>(avatarKey),
      'themeMode': serializer.toJson<String?>(themeMode),
      'remindersEnabled': serializer.toJson<bool>(remindersEnabled),
    };
  }

  SettingsRow copyWith({
    int? id,
    Value<String?> nickname = const Value.absent(),
    Value<String?> avatarKey = const Value.absent(),
    Value<String?> themeMode = const Value.absent(),
    bool? remindersEnabled,
  }) => SettingsRow(
    id: id ?? this.id,
    nickname: nickname.present ? nickname.value : this.nickname,
    avatarKey: avatarKey.present ? avatarKey.value : this.avatarKey,
    themeMode: themeMode.present ? themeMode.value : this.themeMode,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
  );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatarKey: data.avatarKey.present ? data.avatarKey.value : this.avatarKey,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      remindersEnabled: data.remindersEnabled.present
          ? data.remindersEnabled.value
          : this.remindersEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatarKey: $avatarKey, ')
          ..write('themeMode: $themeMode, ')
          ..write('remindersEnabled: $remindersEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nickname, avatarKey, themeMode, remindersEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.avatarKey == this.avatarKey &&
          other.themeMode == this.themeMode &&
          other.remindersEnabled == this.remindersEnabled);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String?> nickname;
  final Value<String?> avatarKey;
  final Value<String?> themeMode;
  final Value<bool> remindersEnabled;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatarKey = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatarKey = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? nickname,
    Expression<String>? avatarKey,
    Expression<String>? themeMode,
    Expression<bool>? remindersEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (avatarKey != null) 'avatar_key': avatarKey,
      if (themeMode != null) 'theme_mode': themeMode,
      if (remindersEnabled != null) 'reminders_enabled': remindersEnabled,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<String?>? nickname,
    Value<String?>? avatarKey,
    Value<String?>? themeMode,
    Value<bool>? remindersEnabled,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarKey: avatarKey ?? this.avatarKey,
      themeMode: themeMode ?? this.themeMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatarKey.present) {
      map['avatar_key'] = Variable<String>(avatarKey.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (remindersEnabled.present) {
      map['reminders_enabled'] = Variable<bool>(remindersEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatarKey: $avatarKey, ')
          ..write('themeMode: $themeMode, ')
          ..write('remindersEnabled: $remindersEnabled')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $ProgressRecordsTable progressRecords = $ProgressRecordsTable(
    this,
  );
  late final $MilestonesTable milestones = $MilestonesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    goals,
    progressRecords,
    milestones,
    reminders,
    settingsRows,
  ];
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String name,
  Value<String?> why,
  Value<GoalCategory?> categoryKey,
  required String iconKey,
  required String colorKey,
  Value<bool> pinned,
  Value<int?> pinnedOrder,
  Value<LocalDate?> targetDate,
  Value<FrequencyPattern?> frequency,
  required GoalStatus status,
  Value<DateTime?> achievedAt,
  Value<DateTime?> archivedAt,
  required LocalDate createdAt,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> why,
  Value<GoalCategory?> categoryKey,
  Value<String> iconKey,
  Value<String> colorKey,
  Value<bool> pinned,
  Value<int?> pinnedOrder,
  Value<LocalDate?> targetDate,
  Value<FrequencyPattern?> frequency,
  Value<GoalStatus> status,
  Value<DateTime?> achievedAt,
  Value<DateTime?> archivedAt,
  Value<LocalDate> createdAt,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, GoalRow> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProgressRecordsTable, List<RecordRow>>
  _progressRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.progressRecords,
    aliasName: 'goals__id__progress_records__goal_id',
  );

  $$ProgressRecordsTableProcessedTableManager get progressRecordsRefs {
    final manager = $$ProgressRecordsTableTableManager(
      $_db,
      $_db.progressRecords,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _progressRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MilestonesTable, List<MilestoneRow>>
  _milestonesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.milestones,
    aliasName: 'goals__id__milestones__goal_id',
  );

  $$MilestonesTableProcessedTableManager get milestonesRefs {
    final manager = $$MilestonesTableTableManager(
      $_db,
      $_db.milestones,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_milestonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<ReminderRow>>
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

  ColumnFilters<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalCategory?, GoalCategory, String>
  get categoryKey => $composableBuilder(
    column: $table.categoryKey,
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

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pinnedOrder => $composableBuilder(
    column: $table.pinnedOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String>
  get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<FrequencyPattern?, FrequencyPattern, String>
  get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalStatus, GoalStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get achievedAt =>
      $composableBuilder(
        column: $table.achievedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get archivedAt =>
      $composableBuilder(
        column: $table.archivedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> progressRecordsRefs(
    Expression<bool> Function($$ProgressRecordsTableFilterComposer f) f,
  ) {
    final $$ProgressRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressRecords,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressRecordsTableFilterComposer(
            $db: $db,
            $table: $db.progressRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> milestonesRefs(
    Expression<bool> Function($$MilestonesTableFilterComposer f) f,
  ) {
    final $$MilestonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestones,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MilestonesTableFilterComposer(
            $db: $db,
            $table: $db.milestones,
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

  ColumnOrderings<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryKey => $composableBuilder(
    column: $table.categoryKey,
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

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pinnedOrder => $composableBuilder(
    column: $table.pinnedOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  GeneratedColumn<String> get why =>
      $composableBuilder(column: $table.why, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalCategory?, String> get categoryKey =>
      $composableBuilder(
        column: $table.categoryKey,
        builder: (column) => column,
      );

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<int> get pinnedOrder => $composableBuilder(
    column: $table.pinnedOrder,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate?, String> get targetDate =>
      $composableBuilder(
        column: $table.targetDate,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<FrequencyPattern?, String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get achievedAt =>
      $composableBuilder(
        column: $table.achievedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get archivedAt =>
      $composableBuilder(
        column: $table.archivedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<LocalDate, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> progressRecordsRefs<T extends Object>(
    Expression<T> Function($$ProgressRecordsTableAnnotationComposer a) f,
  ) {
    final $$ProgressRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressRecords,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.progressRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> milestonesRefs<T extends Object>(
    Expression<T> Function($$MilestonesTableAnnotationComposer a) f,
  ) {
    final $$MilestonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestones,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MilestonesTableAnnotationComposer(
            $db: $db,
            $table: $db.milestones,
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
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, $$GoalsTableReferences),
          GoalRow,
          PrefetchHooks Function({
            bool progressRecordsRefs,
            bool milestonesRefs,
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
                Value<String?> why = const Value.absent(),
                Value<GoalCategory?> categoryKey = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<String> colorKey = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int?> pinnedOrder = const Value.absent(),
                Value<LocalDate?> targetDate = const Value.absent(),
                Value<FrequencyPattern?> frequency = const Value.absent(),
                Value<GoalStatus> status = const Value.absent(),
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<LocalDate> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                why: why,
                categoryKey: categoryKey,
                iconKey: iconKey,
                colorKey: colorKey,
                pinned: pinned,
                pinnedOrder: pinnedOrder,
                targetDate: targetDate,
                frequency: frequency,
                status: status,
                achievedAt: achievedAt,
                archivedAt: archivedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> why = const Value.absent(),
                Value<GoalCategory?> categoryKey = const Value.absent(),
                required String iconKey,
                required String colorKey,
                Value<bool> pinned = const Value.absent(),
                Value<int?> pinnedOrder = const Value.absent(),
                Value<LocalDate?> targetDate = const Value.absent(),
                Value<FrequencyPattern?> frequency = const Value.absent(),
                required GoalStatus status,
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                required LocalDate createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                why: why,
                categoryKey: categoryKey,
                iconKey: iconKey,
                colorKey: colorKey,
                pinned: pinned,
                pinnedOrder: pinnedOrder,
                targetDate: targetDate,
                frequency: frequency,
                status: status,
                achievedAt: achievedAt,
                archivedAt: archivedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, GoalRow>(table),
                  $$GoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                progressRecordsRefs = false,
                milestonesRefs = false,
                remindersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (progressRecordsRefs) db.progressRecords,
                    if (milestonesRefs) db.milestones,
                    if (remindersRefs) db.reminders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (progressRecordsRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          RecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._progressRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).progressRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (milestonesRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          MilestoneRow
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._milestonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).milestonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          ReminderRow
                        >(
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
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, $$GoalsTableReferences),
      GoalRow,
      PrefetchHooks Function({
        bool progressRecordsRefs,
        bool milestonesRefs,
        bool remindersRefs,
      })
    >;
typedef $$ProgressRecordsTableCreateCompanionBuilder =
    ProgressRecordsCompanion Function({
      required String id,
      required String goalId,
      required String title,
      Value<String?> body,
      Value<int?> durationMinutes,
      required LocalDate day,
      required DateTime createdAt,
      Value<bool> isBackfill,
      required RecordKind kind,
      Value<String?> milestoneId,
      Value<int> rowid,
    });
typedef $$ProgressRecordsTableUpdateCompanionBuilder =
    ProgressRecordsCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> title,
      Value<String?> body,
      Value<int?> durationMinutes,
      Value<LocalDate> day,
      Value<DateTime> createdAt,
      Value<bool> isBackfill,
      Value<RecordKind> kind,
      Value<String?> milestoneId,
      Value<int> rowid,
    });

final class $$ProgressRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $ProgressRecordsTable, RecordRow> {
  $$ProgressRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('progress_records__goal_id__goals__id');

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

class $$ProgressRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressRecordsTable> {
  $$ProgressRecordsTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
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

  ColumnWithTypeConverterFilters<RecordKind, RecordKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => ColumnFilters(column),
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

class $$ProgressRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressRecordsTable> {
  $$ProgressRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
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

class $$ProgressRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressRecordsTable> {
  $$ProgressRecordsTableAnnotationComposer({
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

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate, String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecordKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => column,
  );

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

class $$ProgressRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressRecordsTable,
          RecordRow,
          $$ProgressRecordsTableFilterComposer,
          $$ProgressRecordsTableOrderingComposer,
          $$ProgressRecordsTableAnnotationComposer,
          $$ProgressRecordsTableCreateCompanionBuilder,
          $$ProgressRecordsTableUpdateCompanionBuilder,
          (RecordRow, $$ProgressRecordsTableReferences),
          RecordRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$ProgressRecordsTableTableManager(
    _$AppDatabase db,
    $ProgressRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<LocalDate> day = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isBackfill = const Value.absent(),
                Value<RecordKind> kind = const Value.absent(),
                Value<String?> milestoneId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressRecordsCompanion(
                id: id,
                goalId: goalId,
                title: title,
                body: body,
                durationMinutes: durationMinutes,
                day: day,
                createdAt: createdAt,
                isBackfill: isBackfill,
                kind: kind,
                milestoneId: milestoneId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String title,
                Value<String?> body = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                required LocalDate day,
                required DateTime createdAt,
                Value<bool> isBackfill = const Value.absent(),
                required RecordKind kind,
                Value<String?> milestoneId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressRecordsCompanion.insert(
                id: id,
                goalId: goalId,
                title: title,
                body: body,
                durationMinutes: durationMinutes,
                day: day,
                createdAt: createdAt,
                isBackfill: isBackfill,
                kind: kind,
                milestoneId: milestoneId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgressRecordsTable, RecordRow>(table),
                  $$ProgressRecordsTableReferences(db, table, e),
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
                        referencedTable: $$ProgressRecordsTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$ProgressRecordsTableReferences
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

typedef $$ProgressRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressRecordsTable,
      RecordRow,
      $$ProgressRecordsTableFilterComposer,
      $$ProgressRecordsTableOrderingComposer,
      $$ProgressRecordsTableAnnotationComposer,
      $$ProgressRecordsTableCreateCompanionBuilder,
      $$ProgressRecordsTableUpdateCompanionBuilder,
      (RecordRow, $$ProgressRecordsTableReferences),
      RecordRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$MilestonesTableCreateCompanionBuilder = MilestonesCompanion Function({
  required String id,
  required String goalId,
  required String title,
  Value<String?> description,
  Value<int> position,
  Value<bool> isDone,
  Value<DateTime?> doneAt,
  Value<int> rowid,
});
typedef $$MilestonesTableUpdateCompanionBuilder = MilestonesCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<String> title,
  Value<String?> description,
  Value<int> position,
  Value<bool> isDone,
  Value<DateTime?> doneAt,
  Value<int> rowid,
});

final class $$MilestonesTableReferences
    extends BaseReferences<_$AppDatabase, $MilestonesTable, MilestoneRow> {
  $$MilestonesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('milestones__goal_id__goals__id');

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

class $$MilestonesTableFilterComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
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

class $$MilestonesTableOrderingComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
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

class $$MilestonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

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

class $$MilestonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MilestonesTable,
          MilestoneRow,
          $$MilestonesTableFilterComposer,
          $$MilestonesTableOrderingComposer,
          $$MilestonesTableAnnotationComposer,
          $$MilestonesTableCreateCompanionBuilder,
          $$MilestonesTableUpdateCompanionBuilder,
          (MilestoneRow, $$MilestonesTableReferences),
          MilestoneRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$MilestonesTableTableManager(_$AppDatabase db, $MilestonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion(
                id: id,
                goalId: goalId,
                title: title,
                description: description,
                position: position,
                isDone: isDone,
                doneAt: doneAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion.insert(
                id: id,
                goalId: goalId,
                title: title,
                description: description,
                position: position,
                isDone: isDone,
                doneAt: doneAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MilestonesTable, MilestoneRow>(table),
                  $$MilestonesTableReferences(db, table, e),
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
                        referencedTable: $$MilestonesTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$MilestonesTableReferences
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

typedef $$MilestonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MilestonesTable,
      MilestoneRow,
      $$MilestonesTableFilterComposer,
      $$MilestonesTableOrderingComposer,
      $$MilestonesTableAnnotationComposer,
      $$MilestonesTableCreateCompanionBuilder,
      $$MilestonesTableUpdateCompanionBuilder,
      (MilestoneRow, $$MilestonesTableReferences),
      MilestoneRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String goalId,
  required LocalTime time,
  Value<bool> isEnabled,
  required Cadence cadence,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<LocalTime> time,
  Value<bool> isEnabled,
  Value<Cadence> cadence,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('reminders__goal_id__goals__id');

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

  ColumnWithTypeConverterFilters<Cadence, Cadence, String> get cadence =>
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

  GeneratedColumnWithTypeConverter<Cadence, String> get cadence =>
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
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (ReminderRow, $$RemindersTableReferences),
          ReminderRow,
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
                Value<String> goalId = const Value.absent(),
                Value<LocalTime> time = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<Cadence> cadence = const Value.absent(),
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
                required String goalId,
                required LocalTime time,
                Value<bool> isEnabled = const Value.absent(),
                required Cadence cadence,
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
                  e.readTable<$RemindersTable, ReminderRow>(table),
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
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (ReminderRow, $$RemindersTableReferences),
      ReminderRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<String?> nickname,
      Value<String?> avatarKey,
      Value<String?> themeMode,
      Value<bool> remindersEnabled,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<String?> nickname,
      Value<String?> avatarKey,
      Value<String?> themeMode,
      Value<bool> remindersEnabled,
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

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarKey => $composableBuilder(
    column: $table.avatarKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
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

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarKey => $composableBuilder(
    column: $table.avatarKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
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

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatarKey =>
      $composableBuilder(column: $table.avatarKey, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
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
                Value<String?> nickname = const Value.absent(),
                Value<String?> avatarKey = const Value.absent(),
                Value<String?> themeMode = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
              }) => SettingsRowsCompanion(
                id: id,
                nickname: nickname,
                avatarKey: avatarKey,
                themeMode: themeMode,
                remindersEnabled: remindersEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String?> avatarKey = const Value.absent(),
                Value<String?> themeMode = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                nickname: nickname,
                avatarKey: avatarKey,
                themeMode: themeMode,
                remindersEnabled: remindersEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsRowsTable, SettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsRowsTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
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
  $$ProgressRecordsTableTableManager get progressRecords =>
      $$ProgressRecordsTableTableManager(_db, _db.progressRecords);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db, _db.milestones);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
}
