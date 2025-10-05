// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class Servers extends Table with TableInfo<Servers, Server> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Servers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _originalIdMeta =
      const VerificationMeta('originalId');
  late final GeneratedColumn<String> originalId = GeneratedColumn<String>(
      'original_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _hireDateMeta =
      const VerificationMeta('hireDate');
  late final GeneratedColumn<DateTime> hireDate = GeneratedColumn<DateTime>(
      'hire_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  late final GeneratedColumn<int> active = GeneratedColumn<int>(
      'active', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1',
      defaultValue: const CustomExpression('1'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT CURRENT_TIMESTAMP',
      defaultValue: const CustomExpression('CURRENT_TIMESTAMP'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT CURRENT_TIMESTAMP',
      defaultValue: const CustomExpression('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, originalId, hireDate, active, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servers';
  @override
  VerificationContext validateIntegrity(Insertable<Server> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('original_id')) {
      context.handle(
          _originalIdMeta,
          originalId.isAcceptableOrUnknown(
              data['original_id']!, _originalIdMeta));
    }
    if (data.containsKey('hire_date')) {
      context.handle(_hireDateMeta,
          hireDate.isAcceptableOrUnknown(data['hire_date']!, _hireDateMeta));
    } else if (isInserting) {
      context.missing(_hireDateMeta);
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Server map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Server(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      originalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_id']),
      hireDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}hire_date'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  Servers createAlias(String alias) {
    return Servers(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Server extends DataClass implements Insertable<Server> {
  final String id;
  final String name;
  final String? originalId;
  final DateTime hireDate;
  final int active;
  final String? createdAt;
  final String? updatedAt;
  const Server(
      {required this.id,
      required this.name,
      this.originalId,
      required this.hireDate,
      required this.active,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || originalId != null) {
      map['original_id'] = Variable<String>(originalId);
    }
    map['hire_date'] = Variable<DateTime>(hireDate);
    map['active'] = Variable<int>(active);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  ServersCompanion toCompanion(bool nullToAbsent) {
    return ServersCompanion(
      id: Value(id),
      name: Value(name),
      originalId: originalId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalId),
      hireDate: Value(hireDate),
      active: Value(active),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Server.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Server(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      originalId: serializer.fromJson<String?>(json['original_id']),
      hireDate: serializer.fromJson<DateTime>(json['hire_date']),
      active: serializer.fromJson<int>(json['active']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'original_id': serializer.toJson<String?>(originalId),
      'hire_date': serializer.toJson<DateTime>(hireDate),
      'active': serializer.toJson<int>(active),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
    };
  }

  Server copyWith(
          {String? id,
          String? name,
          Value<String?> originalId = const Value.absent(),
          DateTime? hireDate,
          int? active,
          Value<String?> createdAt = const Value.absent(),
          Value<String?> updatedAt = const Value.absent()}) =>
      Server(
        id: id ?? this.id,
        name: name ?? this.name,
        originalId: originalId.present ? originalId.value : this.originalId,
        hireDate: hireDate ?? this.hireDate,
        active: active ?? this.active,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Server copyWithCompanion(ServersCompanion data) {
    return Server(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      originalId:
          data.originalId.present ? data.originalId.value : this.originalId,
      hireDate: data.hireDate.present ? data.hireDate.value : this.hireDate,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Server(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('originalId: $originalId, ')
          ..write('hireDate: $hireDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, originalId, hireDate, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Server &&
          other.id == this.id &&
          other.name == this.name &&
          other.originalId == this.originalId &&
          other.hireDate == this.hireDate &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ServersCompanion extends UpdateCompanion<Server> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> originalId;
  final Value<DateTime> hireDate;
  final Value<int> active;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const ServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.originalId = const Value.absent(),
    this.hireDate = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServersCompanion.insert({
    required String id,
    required String name,
    this.originalId = const Value.absent(),
    required DateTime hireDate,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        hireDate = Value(hireDate);
  static Insertable<Server> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? originalId,
    Expression<DateTime>? hireDate,
    Expression<int>? active,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (originalId != null) 'original_id': originalId,
      if (hireDate != null) 'hire_date': hireDate,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? originalId,
      Value<DateTime>? hireDate,
      Value<int>? active,
      Value<String?>? createdAt,
      Value<String?>? updatedAt,
      Value<int>? rowid}) {
    return ServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      originalId: originalId ?? this.originalId,
      hireDate: hireDate ?? this.hireDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (originalId.present) {
      map['original_id'] = Variable<String>(originalId.value);
    }
    if (hireDate.present) {
      map['hire_date'] = Variable<DateTime>(hireDate.value);
    }
    if (active.present) {
      map['active'] = Variable<int>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('originalId: $originalId, ')
          ..write('hireDate: $hireDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NpsFeedback extends Table with TableInfo<NpsFeedback, NpsFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NpsFeedback(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _feedbackTypeMeta =
      const VerificationMeta('feedbackType');
  late final GeneratedColumn<String> feedbackType = GeneratedColumn<String>(
      'feedback_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL CHECK (feedback_type IN (\'yes\', \'maybe\', \'no\'))');
  static const VerificationMeta _feedbackDateMeta =
      const VerificationMeta('feedbackDate');
  late final GeneratedColumn<DateTime> feedbackDate = GeneratedColumn<DateTime>(
      'feedback_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _salesAmountMeta =
      const VerificationMeta('salesAmount');
  late final GeneratedColumn<double> salesAmount = GeneratedColumn<double>(
      'sales_amount', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _tableNumberMeta =
      const VerificationMeta('tableNumber');
  late final GeneratedColumn<int> tableNumber = GeneratedColumn<int>(
      'table_number', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _shiftPeriodMeta =
      const VerificationMeta('shiftPeriod');
  late final GeneratedColumn<String> shiftPeriod = GeneratedColumn<String>(
      'shift_period', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints:
          'CHECK (shift_period IN (\'breakfast\', \'lunch\', \'dinner\', \'late_night\'))');
  static const VerificationMeta _guestCountMeta =
      const VerificationMeta('guestCount');
  late final GeneratedColumn<int> guestCount = GeneratedColumn<int>(
      'guest_count', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT CURRENT_TIMESTAMP',
      defaultValue: const CustomExpression('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        feedbackType,
        feedbackDate,
        salesAmount,
        tableNumber,
        shiftPeriod,
        guestCount,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nps_feedback';
  @override
  VerificationContext validateIntegrity(Insertable<NpsFeedbackData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('feedback_type')) {
      context.handle(
          _feedbackTypeMeta,
          feedbackType.isAcceptableOrUnknown(
              data['feedback_type']!, _feedbackTypeMeta));
    } else if (isInserting) {
      context.missing(_feedbackTypeMeta);
    }
    if (data.containsKey('feedback_date')) {
      context.handle(
          _feedbackDateMeta,
          feedbackDate.isAcceptableOrUnknown(
              data['feedback_date']!, _feedbackDateMeta));
    } else if (isInserting) {
      context.missing(_feedbackDateMeta);
    }
    if (data.containsKey('sales_amount')) {
      context.handle(
          _salesAmountMeta,
          salesAmount.isAcceptableOrUnknown(
              data['sales_amount']!, _salesAmountMeta));
    }
    if (data.containsKey('table_number')) {
      context.handle(
          _tableNumberMeta,
          tableNumber.isAcceptableOrUnknown(
              data['table_number']!, _tableNumberMeta));
    }
    if (data.containsKey('shift_period')) {
      context.handle(
          _shiftPeriodMeta,
          shiftPeriod.isAcceptableOrUnknown(
              data['shift_period']!, _shiftPeriodMeta));
    }
    if (data.containsKey('guest_count')) {
      context.handle(
          _guestCountMeta,
          guestCount.isAcceptableOrUnknown(
              data['guest_count']!, _guestCountMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NpsFeedbackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NpsFeedbackData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      feedbackType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feedback_type'])!,
      feedbackDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}feedback_date'])!,
      salesAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sales_amount']),
      tableNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}table_number']),
      shiftPeriod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift_period']),
      guestCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}guest_count']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
    );
  }

  @override
  NpsFeedback createAlias(String alias) {
    return NpsFeedback(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['FOREIGN KEY(server_id)REFERENCES servers(id)ON DELETE RESTRICT'];
  @override
  bool get dontWriteConstraints => true;
}

class NpsFeedbackData extends DataClass implements Insertable<NpsFeedbackData> {
  final int id;
  final String serverId;
  final String feedbackType;
  final DateTime feedbackDate;
  final double? salesAmount;
  final int? tableNumber;
  final String? shiftPeriod;
  final int? guestCount;
  final String? notes;
  final String? createdAt;
  const NpsFeedbackData(
      {required this.id,
      required this.serverId,
      required this.feedbackType,
      required this.feedbackDate,
      this.salesAmount,
      this.tableNumber,
      this.shiftPeriod,
      this.guestCount,
      this.notes,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['feedback_type'] = Variable<String>(feedbackType);
    map['feedback_date'] = Variable<DateTime>(feedbackDate);
    if (!nullToAbsent || salesAmount != null) {
      map['sales_amount'] = Variable<double>(salesAmount);
    }
    if (!nullToAbsent || tableNumber != null) {
      map['table_number'] = Variable<int>(tableNumber);
    }
    if (!nullToAbsent || shiftPeriod != null) {
      map['shift_period'] = Variable<String>(shiftPeriod);
    }
    if (!nullToAbsent || guestCount != null) {
      map['guest_count'] = Variable<int>(guestCount);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  NpsFeedbackCompanion toCompanion(bool nullToAbsent) {
    return NpsFeedbackCompanion(
      id: Value(id),
      serverId: Value(serverId),
      feedbackType: Value(feedbackType),
      feedbackDate: Value(feedbackDate),
      salesAmount: salesAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(salesAmount),
      tableNumber: tableNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNumber),
      shiftPeriod: shiftPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftPeriod),
      guestCount: guestCount == null && nullToAbsent
          ? const Value.absent()
          : Value(guestCount),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory NpsFeedbackData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NpsFeedbackData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['server_id']),
      feedbackType: serializer.fromJson<String>(json['feedback_type']),
      feedbackDate: serializer.fromJson<DateTime>(json['feedback_date']),
      salesAmount: serializer.fromJson<double?>(json['sales_amount']),
      tableNumber: serializer.fromJson<int?>(json['table_number']),
      shiftPeriod: serializer.fromJson<String?>(json['shift_period']),
      guestCount: serializer.fromJson<int?>(json['guest_count']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'server_id': serializer.toJson<String>(serverId),
      'feedback_type': serializer.toJson<String>(feedbackType),
      'feedback_date': serializer.toJson<DateTime>(feedbackDate),
      'sales_amount': serializer.toJson<double?>(salesAmount),
      'table_number': serializer.toJson<int?>(tableNumber),
      'shift_period': serializer.toJson<String?>(shiftPeriod),
      'guest_count': serializer.toJson<int?>(guestCount),
      'notes': serializer.toJson<String?>(notes),
      'created_at': serializer.toJson<String?>(createdAt),
    };
  }

  NpsFeedbackData copyWith(
          {int? id,
          String? serverId,
          String? feedbackType,
          DateTime? feedbackDate,
          Value<double?> salesAmount = const Value.absent(),
          Value<int?> tableNumber = const Value.absent(),
          Value<String?> shiftPeriod = const Value.absent(),
          Value<int?> guestCount = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> createdAt = const Value.absent()}) =>
      NpsFeedbackData(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        feedbackType: feedbackType ?? this.feedbackType,
        feedbackDate: feedbackDate ?? this.feedbackDate,
        salesAmount: salesAmount.present ? salesAmount.value : this.salesAmount,
        tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
        shiftPeriod: shiftPeriod.present ? shiftPeriod.value : this.shiftPeriod,
        guestCount: guestCount.present ? guestCount.value : this.guestCount,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  NpsFeedbackData copyWithCompanion(NpsFeedbackCompanion data) {
    return NpsFeedbackData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      feedbackType: data.feedbackType.present
          ? data.feedbackType.value
          : this.feedbackType,
      feedbackDate: data.feedbackDate.present
          ? data.feedbackDate.value
          : this.feedbackDate,
      salesAmount:
          data.salesAmount.present ? data.salesAmount.value : this.salesAmount,
      tableNumber:
          data.tableNumber.present ? data.tableNumber.value : this.tableNumber,
      shiftPeriod:
          data.shiftPeriod.present ? data.shiftPeriod.value : this.shiftPeriod,
      guestCount:
          data.guestCount.present ? data.guestCount.value : this.guestCount,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NpsFeedbackData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('feedbackType: $feedbackType, ')
          ..write('feedbackDate: $feedbackDate, ')
          ..write('salesAmount: $salesAmount, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('shiftPeriod: $shiftPeriod, ')
          ..write('guestCount: $guestCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, feedbackType, feedbackDate,
      salesAmount, tableNumber, shiftPeriod, guestCount, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NpsFeedbackData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.feedbackType == this.feedbackType &&
          other.feedbackDate == this.feedbackDate &&
          other.salesAmount == this.salesAmount &&
          other.tableNumber == this.tableNumber &&
          other.shiftPeriod == this.shiftPeriod &&
          other.guestCount == this.guestCount &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class NpsFeedbackCompanion extends UpdateCompanion<NpsFeedbackData> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> feedbackType;
  final Value<DateTime> feedbackDate;
  final Value<double?> salesAmount;
  final Value<int?> tableNumber;
  final Value<String?> shiftPeriod;
  final Value<int?> guestCount;
  final Value<String?> notes;
  final Value<String?> createdAt;
  const NpsFeedbackCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.feedbackType = const Value.absent(),
    this.feedbackDate = const Value.absent(),
    this.salesAmount = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.shiftPeriod = const Value.absent(),
    this.guestCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NpsFeedbackCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String feedbackType,
    required DateTime feedbackDate,
    this.salesAmount = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.shiftPeriod = const Value.absent(),
    this.guestCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : serverId = Value(serverId),
        feedbackType = Value(feedbackType),
        feedbackDate = Value(feedbackDate);
  static Insertable<NpsFeedbackData> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? feedbackType,
    Expression<DateTime>? feedbackDate,
    Expression<double>? salesAmount,
    Expression<int>? tableNumber,
    Expression<String>? shiftPeriod,
    Expression<int>? guestCount,
    Expression<String>? notes,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (feedbackType != null) 'feedback_type': feedbackType,
      if (feedbackDate != null) 'feedback_date': feedbackDate,
      if (salesAmount != null) 'sales_amount': salesAmount,
      if (tableNumber != null) 'table_number': tableNumber,
      if (shiftPeriod != null) 'shift_period': shiftPeriod,
      if (guestCount != null) 'guest_count': guestCount,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NpsFeedbackCompanion copyWith(
      {Value<int>? id,
      Value<String>? serverId,
      Value<String>? feedbackType,
      Value<DateTime>? feedbackDate,
      Value<double?>? salesAmount,
      Value<int?>? tableNumber,
      Value<String?>? shiftPeriod,
      Value<int?>? guestCount,
      Value<String?>? notes,
      Value<String?>? createdAt}) {
    return NpsFeedbackCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      feedbackType: feedbackType ?? this.feedbackType,
      feedbackDate: feedbackDate ?? this.feedbackDate,
      salesAmount: salesAmount ?? this.salesAmount,
      tableNumber: tableNumber ?? this.tableNumber,
      shiftPeriod: shiftPeriod ?? this.shiftPeriod,
      guestCount: guestCount ?? this.guestCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (feedbackType.present) {
      map['feedback_type'] = Variable<String>(feedbackType.value);
    }
    if (feedbackDate.present) {
      map['feedback_date'] = Variable<DateTime>(feedbackDate.value);
    }
    if (salesAmount.present) {
      map['sales_amount'] = Variable<double>(salesAmount.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<int>(tableNumber.value);
    }
    if (shiftPeriod.present) {
      map['shift_period'] = Variable<String>(shiftPeriod.value);
    }
    if (guestCount.present) {
      map['guest_count'] = Variable<int>(guestCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NpsFeedbackCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('feedbackType: $feedbackType, ')
          ..write('feedbackDate: $feedbackDate, ')
          ..write('salesAmount: $salesAmount, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('shiftPeriod: $shiftPeriod, ')
          ..write('guestCount: $guestCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class NpsMonthlyReports extends Table
    with TableInfo<NpsMonthlyReports, NpsMonthlyReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NpsMonthlyReports(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _reportMonthMeta =
      const VerificationMeta('reportMonth');
  late final GeneratedColumn<int> reportMonth = GeneratedColumn<int>(
      'report_month', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _reportYearMeta =
      const VerificationMeta('reportYear');
  late final GeneratedColumn<int> reportYear = GeneratedColumn<int>(
      'report_year', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _allTimeNpsPercentageMeta =
      const VerificationMeta('allTimeNpsPercentage');
  late final GeneratedColumn<double> allTimeNpsPercentage =
      GeneratedColumn<double>('all_time_nps_percentage', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          $customConstraints: '');
  static const VerificationMeta _threeMonthNpsPercentageMeta =
      const VerificationMeta('threeMonthNpsPercentage');
  late final GeneratedColumn<double> threeMonthNpsPercentage =
      GeneratedColumn<double>('three_month_nps_percentage', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          $customConstraints: '');
  static const VerificationMeta _oneMonthNpsPercentageMeta =
      const VerificationMeta('oneMonthNpsPercentage');
  late final GeneratedColumn<double> oneMonthNpsPercentage =
      GeneratedColumn<double>('one_month_nps_percentage', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          $customConstraints: '');
  static const VerificationMeta _allTimeSalesMeta =
      const VerificationMeta('allTimeSales');
  late final GeneratedColumn<double> allTimeSales = GeneratedColumn<double>(
      'all_time_sales', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0.0',
      defaultValue: const CustomExpression('0.0'));
  static const VerificationMeta _allTimeTableCountMeta =
      const VerificationMeta('allTimeTableCount');
  late final GeneratedColumn<int> allTimeTableCount = GeneratedColumn<int>(
      'all_time_table_count', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _monthFeedbackYesMeta =
      const VerificationMeta('monthFeedbackYes');
  late final GeneratedColumn<int> monthFeedbackYes = GeneratedColumn<int>(
      'month_feedback_yes', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _monthFeedbackMaybeMeta =
      const VerificationMeta('monthFeedbackMaybe');
  late final GeneratedColumn<int> monthFeedbackMaybe = GeneratedColumn<int>(
      'month_feedback_maybe', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _monthFeedbackNoMeta =
      const VerificationMeta('monthFeedbackNo');
  late final GeneratedColumn<int> monthFeedbackNo = GeneratedColumn<int>(
      'month_feedback_no', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _threeMonthFeedbackYesMeta =
      const VerificationMeta('threeMonthFeedbackYes');
  late final GeneratedColumn<int> threeMonthFeedbackYes = GeneratedColumn<int>(
      'three_month_feedback_yes', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _threeMonthFeedbackMaybeMeta =
      const VerificationMeta('threeMonthFeedbackMaybe');
  late final GeneratedColumn<int> threeMonthFeedbackMaybe =
      GeneratedColumn<int>('three_month_feedback_maybe', aliasedName, true,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          $customConstraints: 'DEFAULT 0',
          defaultValue: const CustomExpression('0'));
  static const VerificationMeta _threeMonthFeedbackNoMeta =
      const VerificationMeta('threeMonthFeedbackNo');
  late final GeneratedColumn<int> threeMonthFeedbackNo = GeneratedColumn<int>(
      'three_month_feedback_no', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _allTimeFeedbackYesMeta =
      const VerificationMeta('allTimeFeedbackYes');
  late final GeneratedColumn<int> allTimeFeedbackYes = GeneratedColumn<int>(
      'all_time_feedback_yes', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _allTimeFeedbackMaybeMeta =
      const VerificationMeta('allTimeFeedbackMaybe');
  late final GeneratedColumn<int> allTimeFeedbackMaybe = GeneratedColumn<int>(
      'all_time_feedback_maybe', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _allTimeFeedbackNoMeta =
      const VerificationMeta('allTimeFeedbackNo');
  late final GeneratedColumn<int> allTimeFeedbackNo = GeneratedColumn<int>(
      'all_time_feedback_no', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  late final GeneratedColumn<String> generatedAt = GeneratedColumn<String>(
      'generated_at', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT CURRENT_TIMESTAMP',
      defaultValue: const CustomExpression('CURRENT_TIMESTAMP'));
  static const VerificationMeta _dataAsOfDateMeta =
      const VerificationMeta('dataAsOfDate');
  late final GeneratedColumn<DateTime> dataAsOfDate = GeneratedColumn<DateTime>(
      'data_as_of_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        reportMonth,
        reportYear,
        allTimeNpsPercentage,
        threeMonthNpsPercentage,
        oneMonthNpsPercentage,
        allTimeSales,
        allTimeTableCount,
        monthFeedbackYes,
        monthFeedbackMaybe,
        monthFeedbackNo,
        threeMonthFeedbackYes,
        threeMonthFeedbackMaybe,
        threeMonthFeedbackNo,
        allTimeFeedbackYes,
        allTimeFeedbackMaybe,
        allTimeFeedbackNo,
        generatedAt,
        dataAsOfDate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nps_monthly_reports';
  @override
  VerificationContext validateIntegrity(Insertable<NpsMonthlyReport> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('report_month')) {
      context.handle(
          _reportMonthMeta,
          reportMonth.isAcceptableOrUnknown(
              data['report_month']!, _reportMonthMeta));
    } else if (isInserting) {
      context.missing(_reportMonthMeta);
    }
    if (data.containsKey('report_year')) {
      context.handle(
          _reportYearMeta,
          reportYear.isAcceptableOrUnknown(
              data['report_year']!, _reportYearMeta));
    } else if (isInserting) {
      context.missing(_reportYearMeta);
    }
    if (data.containsKey('all_time_nps_percentage')) {
      context.handle(
          _allTimeNpsPercentageMeta,
          allTimeNpsPercentage.isAcceptableOrUnknown(
              data['all_time_nps_percentage']!, _allTimeNpsPercentageMeta));
    }
    if (data.containsKey('three_month_nps_percentage')) {
      context.handle(
          _threeMonthNpsPercentageMeta,
          threeMonthNpsPercentage.isAcceptableOrUnknown(
              data['three_month_nps_percentage']!,
              _threeMonthNpsPercentageMeta));
    }
    if (data.containsKey('one_month_nps_percentage')) {
      context.handle(
          _oneMonthNpsPercentageMeta,
          oneMonthNpsPercentage.isAcceptableOrUnknown(
              data['one_month_nps_percentage']!, _oneMonthNpsPercentageMeta));
    }
    if (data.containsKey('all_time_sales')) {
      context.handle(
          _allTimeSalesMeta,
          allTimeSales.isAcceptableOrUnknown(
              data['all_time_sales']!, _allTimeSalesMeta));
    }
    if (data.containsKey('all_time_table_count')) {
      context.handle(
          _allTimeTableCountMeta,
          allTimeTableCount.isAcceptableOrUnknown(
              data['all_time_table_count']!, _allTimeTableCountMeta));
    }
    if (data.containsKey('month_feedback_yes')) {
      context.handle(
          _monthFeedbackYesMeta,
          monthFeedbackYes.isAcceptableOrUnknown(
              data['month_feedback_yes']!, _monthFeedbackYesMeta));
    }
    if (data.containsKey('month_feedback_maybe')) {
      context.handle(
          _monthFeedbackMaybeMeta,
          monthFeedbackMaybe.isAcceptableOrUnknown(
              data['month_feedback_maybe']!, _monthFeedbackMaybeMeta));
    }
    if (data.containsKey('month_feedback_no')) {
      context.handle(
          _monthFeedbackNoMeta,
          monthFeedbackNo.isAcceptableOrUnknown(
              data['month_feedback_no']!, _monthFeedbackNoMeta));
    }
    if (data.containsKey('three_month_feedback_yes')) {
      context.handle(
          _threeMonthFeedbackYesMeta,
          threeMonthFeedbackYes.isAcceptableOrUnknown(
              data['three_month_feedback_yes']!, _threeMonthFeedbackYesMeta));
    }
    if (data.containsKey('three_month_feedback_maybe')) {
      context.handle(
          _threeMonthFeedbackMaybeMeta,
          threeMonthFeedbackMaybe.isAcceptableOrUnknown(
              data['three_month_feedback_maybe']!,
              _threeMonthFeedbackMaybeMeta));
    }
    if (data.containsKey('three_month_feedback_no')) {
      context.handle(
          _threeMonthFeedbackNoMeta,
          threeMonthFeedbackNo.isAcceptableOrUnknown(
              data['three_month_feedback_no']!, _threeMonthFeedbackNoMeta));
    }
    if (data.containsKey('all_time_feedback_yes')) {
      context.handle(
          _allTimeFeedbackYesMeta,
          allTimeFeedbackYes.isAcceptableOrUnknown(
              data['all_time_feedback_yes']!, _allTimeFeedbackYesMeta));
    }
    if (data.containsKey('all_time_feedback_maybe')) {
      context.handle(
          _allTimeFeedbackMaybeMeta,
          allTimeFeedbackMaybe.isAcceptableOrUnknown(
              data['all_time_feedback_maybe']!, _allTimeFeedbackMaybeMeta));
    }
    if (data.containsKey('all_time_feedback_no')) {
      context.handle(
          _allTimeFeedbackNoMeta,
          allTimeFeedbackNo.isAcceptableOrUnknown(
              data['all_time_feedback_no']!, _allTimeFeedbackNoMeta));
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    }
    if (data.containsKey('data_as_of_date')) {
      context.handle(
          _dataAsOfDateMeta,
          dataAsOfDate.isAcceptableOrUnknown(
              data['data_as_of_date']!, _dataAsOfDateMeta));
    } else if (isInserting) {
      context.missing(_dataAsOfDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {serverId, reportMonth},
      ];
  @override
  NpsMonthlyReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NpsMonthlyReport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      reportMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}report_month'])!,
      reportYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}report_year'])!,
      allTimeNpsPercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}all_time_nps_percentage']),
      threeMonthNpsPercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}three_month_nps_percentage']),
      oneMonthNpsPercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}one_month_nps_percentage']),
      allTimeSales: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}all_time_sales']),
      allTimeTableCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_table_count']),
      monthFeedbackYes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month_feedback_yes']),
      monthFeedbackMaybe: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}month_feedback_maybe']),
      monthFeedbackNo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month_feedback_no']),
      threeMonthFeedbackYes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}three_month_feedback_yes']),
      threeMonthFeedbackMaybe: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}three_month_feedback_maybe']),
      threeMonthFeedbackNo: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}three_month_feedback_no']),
      allTimeFeedbackYes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_feedback_yes']),
      allTimeFeedbackMaybe: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_feedback_maybe']),
      allTimeFeedbackNo: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_feedback_no']),
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}generated_at']),
      dataAsOfDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}data_as_of_date'])!,
    );
  }

  @override
  NpsMonthlyReports createAlias(String alias) {
    return NpsMonthlyReports(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
        'FOREIGN KEY(server_id)REFERENCES servers(id)ON DELETE RESTRICT',
        'UNIQUE(server_id, report_month)'
      ];
  @override
  bool get dontWriteConstraints => true;
}

class NpsMonthlyReport extends DataClass
    implements Insertable<NpsMonthlyReport> {
  final int id;
  final String serverId;
  final int reportMonth;
  final int reportYear;
  final double? allTimeNpsPercentage;
  final double? threeMonthNpsPercentage;
  final double? oneMonthNpsPercentage;
  final double? allTimeSales;
  final int? allTimeTableCount;
  final int? monthFeedbackYes;
  final int? monthFeedbackMaybe;
  final int? monthFeedbackNo;
  final int? threeMonthFeedbackYes;
  final int? threeMonthFeedbackMaybe;
  final int? threeMonthFeedbackNo;
  final int? allTimeFeedbackYes;
  final int? allTimeFeedbackMaybe;
  final int? allTimeFeedbackNo;
  final String? generatedAt;
  final DateTime dataAsOfDate;
  const NpsMonthlyReport(
      {required this.id,
      required this.serverId,
      required this.reportMonth,
      required this.reportYear,
      this.allTimeNpsPercentage,
      this.threeMonthNpsPercentage,
      this.oneMonthNpsPercentage,
      this.allTimeSales,
      this.allTimeTableCount,
      this.monthFeedbackYes,
      this.monthFeedbackMaybe,
      this.monthFeedbackNo,
      this.threeMonthFeedbackYes,
      this.threeMonthFeedbackMaybe,
      this.threeMonthFeedbackNo,
      this.allTimeFeedbackYes,
      this.allTimeFeedbackMaybe,
      this.allTimeFeedbackNo,
      this.generatedAt,
      required this.dataAsOfDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['report_month'] = Variable<int>(reportMonth);
    map['report_year'] = Variable<int>(reportYear);
    if (!nullToAbsent || allTimeNpsPercentage != null) {
      map['all_time_nps_percentage'] = Variable<double>(allTimeNpsPercentage);
    }
    if (!nullToAbsent || threeMonthNpsPercentage != null) {
      map['three_month_nps_percentage'] =
          Variable<double>(threeMonthNpsPercentage);
    }
    if (!nullToAbsent || oneMonthNpsPercentage != null) {
      map['one_month_nps_percentage'] = Variable<double>(oneMonthNpsPercentage);
    }
    if (!nullToAbsent || allTimeSales != null) {
      map['all_time_sales'] = Variable<double>(allTimeSales);
    }
    if (!nullToAbsent || allTimeTableCount != null) {
      map['all_time_table_count'] = Variable<int>(allTimeTableCount);
    }
    if (!nullToAbsent || monthFeedbackYes != null) {
      map['month_feedback_yes'] = Variable<int>(monthFeedbackYes);
    }
    if (!nullToAbsent || monthFeedbackMaybe != null) {
      map['month_feedback_maybe'] = Variable<int>(monthFeedbackMaybe);
    }
    if (!nullToAbsent || monthFeedbackNo != null) {
      map['month_feedback_no'] = Variable<int>(monthFeedbackNo);
    }
    if (!nullToAbsent || threeMonthFeedbackYes != null) {
      map['three_month_feedback_yes'] = Variable<int>(threeMonthFeedbackYes);
    }
    if (!nullToAbsent || threeMonthFeedbackMaybe != null) {
      map['three_month_feedback_maybe'] =
          Variable<int>(threeMonthFeedbackMaybe);
    }
    if (!nullToAbsent || threeMonthFeedbackNo != null) {
      map['three_month_feedback_no'] = Variable<int>(threeMonthFeedbackNo);
    }
    if (!nullToAbsent || allTimeFeedbackYes != null) {
      map['all_time_feedback_yes'] = Variable<int>(allTimeFeedbackYes);
    }
    if (!nullToAbsent || allTimeFeedbackMaybe != null) {
      map['all_time_feedback_maybe'] = Variable<int>(allTimeFeedbackMaybe);
    }
    if (!nullToAbsent || allTimeFeedbackNo != null) {
      map['all_time_feedback_no'] = Variable<int>(allTimeFeedbackNo);
    }
    if (!nullToAbsent || generatedAt != null) {
      map['generated_at'] = Variable<String>(generatedAt);
    }
    map['data_as_of_date'] = Variable<DateTime>(dataAsOfDate);
    return map;
  }

  NpsMonthlyReportsCompanion toCompanion(bool nullToAbsent) {
    return NpsMonthlyReportsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      reportMonth: Value(reportMonth),
      reportYear: Value(reportYear),
      allTimeNpsPercentage: allTimeNpsPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(allTimeNpsPercentage),
      threeMonthNpsPercentage: threeMonthNpsPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(threeMonthNpsPercentage),
      oneMonthNpsPercentage: oneMonthNpsPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(oneMonthNpsPercentage),
      allTimeSales: allTimeSales == null && nullToAbsent
          ? const Value.absent()
          : Value(allTimeSales),
      allTimeTableCount: allTimeTableCount == null && nullToAbsent
          ? const Value.absent()
          : Value(allTimeTableCount),
      monthFeedbackYes: monthFeedbackYes == null && nullToAbsent
          ? const Value.absent()
          : Value(monthFeedbackYes),
      monthFeedbackMaybe: monthFeedbackMaybe == null && nullToAbsent
          ? const Value.absent()
          : Value(monthFeedbackMaybe),
      monthFeedbackNo: monthFeedbackNo == null && nullToAbsent
          ? const Value.absent()
          : Value(monthFeedbackNo),
      threeMonthFeedbackYes: threeMonthFeedbackYes == null && nullToAbsent
          ? const Value.absent()
          : Value(threeMonthFeedbackYes),
      threeMonthFeedbackMaybe: threeMonthFeedbackMaybe == null && nullToAbsent
          ? const Value.absent()
          : Value(threeMonthFeedbackMaybe),
      threeMonthFeedbackNo: threeMonthFeedbackNo == null && nullToAbsent
          ? const Value.absent()
          : Value(threeMonthFeedbackNo),
      allTimeFeedbackYes: allTimeFeedbackYes == null && nullToAbsent
          ? const Value.absent()
          : Value(allTimeFeedbackYes),
      allTimeFeedbackMaybe: allTimeFeedbackMaybe == null && nullToAbsent
          ? const Value.absent()
          : Value(allTimeFeedbackMaybe),
      allTimeFeedbackNo: allTimeFeedbackNo == null && nullToAbsent
          ? const Value.absent()
          : Value(allTimeFeedbackNo),
      generatedAt: generatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(generatedAt),
      dataAsOfDate: Value(dataAsOfDate),
    );
  }

  factory NpsMonthlyReport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NpsMonthlyReport(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['server_id']),
      reportMonth: serializer.fromJson<int>(json['report_month']),
      reportYear: serializer.fromJson<int>(json['report_year']),
      allTimeNpsPercentage:
          serializer.fromJson<double?>(json['all_time_nps_percentage']),
      threeMonthNpsPercentage:
          serializer.fromJson<double?>(json['three_month_nps_percentage']),
      oneMonthNpsPercentage:
          serializer.fromJson<double?>(json['one_month_nps_percentage']),
      allTimeSales: serializer.fromJson<double?>(json['all_time_sales']),
      allTimeTableCount:
          serializer.fromJson<int?>(json['all_time_table_count']),
      monthFeedbackYes: serializer.fromJson<int?>(json['month_feedback_yes']),
      monthFeedbackMaybe:
          serializer.fromJson<int?>(json['month_feedback_maybe']),
      monthFeedbackNo: serializer.fromJson<int?>(json['month_feedback_no']),
      threeMonthFeedbackYes:
          serializer.fromJson<int?>(json['three_month_feedback_yes']),
      threeMonthFeedbackMaybe:
          serializer.fromJson<int?>(json['three_month_feedback_maybe']),
      threeMonthFeedbackNo:
          serializer.fromJson<int?>(json['three_month_feedback_no']),
      allTimeFeedbackYes:
          serializer.fromJson<int?>(json['all_time_feedback_yes']),
      allTimeFeedbackMaybe:
          serializer.fromJson<int?>(json['all_time_feedback_maybe']),
      allTimeFeedbackNo:
          serializer.fromJson<int?>(json['all_time_feedback_no']),
      generatedAt: serializer.fromJson<String?>(json['generated_at']),
      dataAsOfDate: serializer.fromJson<DateTime>(json['data_as_of_date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'server_id': serializer.toJson<String>(serverId),
      'report_month': serializer.toJson<int>(reportMonth),
      'report_year': serializer.toJson<int>(reportYear),
      'all_time_nps_percentage':
          serializer.toJson<double?>(allTimeNpsPercentage),
      'three_month_nps_percentage':
          serializer.toJson<double?>(threeMonthNpsPercentage),
      'one_month_nps_percentage':
          serializer.toJson<double?>(oneMonthNpsPercentage),
      'all_time_sales': serializer.toJson<double?>(allTimeSales),
      'all_time_table_count': serializer.toJson<int?>(allTimeTableCount),
      'month_feedback_yes': serializer.toJson<int?>(monthFeedbackYes),
      'month_feedback_maybe': serializer.toJson<int?>(monthFeedbackMaybe),
      'month_feedback_no': serializer.toJson<int?>(monthFeedbackNo),
      'three_month_feedback_yes':
          serializer.toJson<int?>(threeMonthFeedbackYes),
      'three_month_feedback_maybe':
          serializer.toJson<int?>(threeMonthFeedbackMaybe),
      'three_month_feedback_no': serializer.toJson<int?>(threeMonthFeedbackNo),
      'all_time_feedback_yes': serializer.toJson<int?>(allTimeFeedbackYes),
      'all_time_feedback_maybe': serializer.toJson<int?>(allTimeFeedbackMaybe),
      'all_time_feedback_no': serializer.toJson<int?>(allTimeFeedbackNo),
      'generated_at': serializer.toJson<String?>(generatedAt),
      'data_as_of_date': serializer.toJson<DateTime>(dataAsOfDate),
    };
  }

  NpsMonthlyReport copyWith(
          {int? id,
          String? serverId,
          int? reportMonth,
          int? reportYear,
          Value<double?> allTimeNpsPercentage = const Value.absent(),
          Value<double?> threeMonthNpsPercentage = const Value.absent(),
          Value<double?> oneMonthNpsPercentage = const Value.absent(),
          Value<double?> allTimeSales = const Value.absent(),
          Value<int?> allTimeTableCount = const Value.absent(),
          Value<int?> monthFeedbackYes = const Value.absent(),
          Value<int?> monthFeedbackMaybe = const Value.absent(),
          Value<int?> monthFeedbackNo = const Value.absent(),
          Value<int?> threeMonthFeedbackYes = const Value.absent(),
          Value<int?> threeMonthFeedbackMaybe = const Value.absent(),
          Value<int?> threeMonthFeedbackNo = const Value.absent(),
          Value<int?> allTimeFeedbackYes = const Value.absent(),
          Value<int?> allTimeFeedbackMaybe = const Value.absent(),
          Value<int?> allTimeFeedbackNo = const Value.absent(),
          Value<String?> generatedAt = const Value.absent(),
          DateTime? dataAsOfDate}) =>
      NpsMonthlyReport(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        reportMonth: reportMonth ?? this.reportMonth,
        reportYear: reportYear ?? this.reportYear,
        allTimeNpsPercentage: allTimeNpsPercentage.present
            ? allTimeNpsPercentage.value
            : this.allTimeNpsPercentage,
        threeMonthNpsPercentage: threeMonthNpsPercentage.present
            ? threeMonthNpsPercentage.value
            : this.threeMonthNpsPercentage,
        oneMonthNpsPercentage: oneMonthNpsPercentage.present
            ? oneMonthNpsPercentage.value
            : this.oneMonthNpsPercentage,
        allTimeSales:
            allTimeSales.present ? allTimeSales.value : this.allTimeSales,
        allTimeTableCount: allTimeTableCount.present
            ? allTimeTableCount.value
            : this.allTimeTableCount,
        monthFeedbackYes: monthFeedbackYes.present
            ? monthFeedbackYes.value
            : this.monthFeedbackYes,
        monthFeedbackMaybe: monthFeedbackMaybe.present
            ? monthFeedbackMaybe.value
            : this.monthFeedbackMaybe,
        monthFeedbackNo: monthFeedbackNo.present
            ? monthFeedbackNo.value
            : this.monthFeedbackNo,
        threeMonthFeedbackYes: threeMonthFeedbackYes.present
            ? threeMonthFeedbackYes.value
            : this.threeMonthFeedbackYes,
        threeMonthFeedbackMaybe: threeMonthFeedbackMaybe.present
            ? threeMonthFeedbackMaybe.value
            : this.threeMonthFeedbackMaybe,
        threeMonthFeedbackNo: threeMonthFeedbackNo.present
            ? threeMonthFeedbackNo.value
            : this.threeMonthFeedbackNo,
        allTimeFeedbackYes: allTimeFeedbackYes.present
            ? allTimeFeedbackYes.value
            : this.allTimeFeedbackYes,
        allTimeFeedbackMaybe: allTimeFeedbackMaybe.present
            ? allTimeFeedbackMaybe.value
            : this.allTimeFeedbackMaybe,
        allTimeFeedbackNo: allTimeFeedbackNo.present
            ? allTimeFeedbackNo.value
            : this.allTimeFeedbackNo,
        generatedAt: generatedAt.present ? generatedAt.value : this.generatedAt,
        dataAsOfDate: dataAsOfDate ?? this.dataAsOfDate,
      );
  NpsMonthlyReport copyWithCompanion(NpsMonthlyReportsCompanion data) {
    return NpsMonthlyReport(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      reportMonth:
          data.reportMonth.present ? data.reportMonth.value : this.reportMonth,
      reportYear:
          data.reportYear.present ? data.reportYear.value : this.reportYear,
      allTimeNpsPercentage: data.allTimeNpsPercentage.present
          ? data.allTimeNpsPercentage.value
          : this.allTimeNpsPercentage,
      threeMonthNpsPercentage: data.threeMonthNpsPercentage.present
          ? data.threeMonthNpsPercentage.value
          : this.threeMonthNpsPercentage,
      oneMonthNpsPercentage: data.oneMonthNpsPercentage.present
          ? data.oneMonthNpsPercentage.value
          : this.oneMonthNpsPercentage,
      allTimeSales: data.allTimeSales.present
          ? data.allTimeSales.value
          : this.allTimeSales,
      allTimeTableCount: data.allTimeTableCount.present
          ? data.allTimeTableCount.value
          : this.allTimeTableCount,
      monthFeedbackYes: data.monthFeedbackYes.present
          ? data.monthFeedbackYes.value
          : this.monthFeedbackYes,
      monthFeedbackMaybe: data.monthFeedbackMaybe.present
          ? data.monthFeedbackMaybe.value
          : this.monthFeedbackMaybe,
      monthFeedbackNo: data.monthFeedbackNo.present
          ? data.monthFeedbackNo.value
          : this.monthFeedbackNo,
      threeMonthFeedbackYes: data.threeMonthFeedbackYes.present
          ? data.threeMonthFeedbackYes.value
          : this.threeMonthFeedbackYes,
      threeMonthFeedbackMaybe: data.threeMonthFeedbackMaybe.present
          ? data.threeMonthFeedbackMaybe.value
          : this.threeMonthFeedbackMaybe,
      threeMonthFeedbackNo: data.threeMonthFeedbackNo.present
          ? data.threeMonthFeedbackNo.value
          : this.threeMonthFeedbackNo,
      allTimeFeedbackYes: data.allTimeFeedbackYes.present
          ? data.allTimeFeedbackYes.value
          : this.allTimeFeedbackYes,
      allTimeFeedbackMaybe: data.allTimeFeedbackMaybe.present
          ? data.allTimeFeedbackMaybe.value
          : this.allTimeFeedbackMaybe,
      allTimeFeedbackNo: data.allTimeFeedbackNo.present
          ? data.allTimeFeedbackNo.value
          : this.allTimeFeedbackNo,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      dataAsOfDate: data.dataAsOfDate.present
          ? data.dataAsOfDate.value
          : this.dataAsOfDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NpsMonthlyReport(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('reportMonth: $reportMonth, ')
          ..write('reportYear: $reportYear, ')
          ..write('allTimeNpsPercentage: $allTimeNpsPercentage, ')
          ..write('threeMonthNpsPercentage: $threeMonthNpsPercentage, ')
          ..write('oneMonthNpsPercentage: $oneMonthNpsPercentage, ')
          ..write('allTimeSales: $allTimeSales, ')
          ..write('allTimeTableCount: $allTimeTableCount, ')
          ..write('monthFeedbackYes: $monthFeedbackYes, ')
          ..write('monthFeedbackMaybe: $monthFeedbackMaybe, ')
          ..write('monthFeedbackNo: $monthFeedbackNo, ')
          ..write('threeMonthFeedbackYes: $threeMonthFeedbackYes, ')
          ..write('threeMonthFeedbackMaybe: $threeMonthFeedbackMaybe, ')
          ..write('threeMonthFeedbackNo: $threeMonthFeedbackNo, ')
          ..write('allTimeFeedbackYes: $allTimeFeedbackYes, ')
          ..write('allTimeFeedbackMaybe: $allTimeFeedbackMaybe, ')
          ..write('allTimeFeedbackNo: $allTimeFeedbackNo, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('dataAsOfDate: $dataAsOfDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      reportMonth,
      reportYear,
      allTimeNpsPercentage,
      threeMonthNpsPercentage,
      oneMonthNpsPercentage,
      allTimeSales,
      allTimeTableCount,
      monthFeedbackYes,
      monthFeedbackMaybe,
      monthFeedbackNo,
      threeMonthFeedbackYes,
      threeMonthFeedbackMaybe,
      threeMonthFeedbackNo,
      allTimeFeedbackYes,
      allTimeFeedbackMaybe,
      allTimeFeedbackNo,
      generatedAt,
      dataAsOfDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NpsMonthlyReport &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.reportMonth == this.reportMonth &&
          other.reportYear == this.reportYear &&
          other.allTimeNpsPercentage == this.allTimeNpsPercentage &&
          other.threeMonthNpsPercentage == this.threeMonthNpsPercentage &&
          other.oneMonthNpsPercentage == this.oneMonthNpsPercentage &&
          other.allTimeSales == this.allTimeSales &&
          other.allTimeTableCount == this.allTimeTableCount &&
          other.monthFeedbackYes == this.monthFeedbackYes &&
          other.monthFeedbackMaybe == this.monthFeedbackMaybe &&
          other.monthFeedbackNo == this.monthFeedbackNo &&
          other.threeMonthFeedbackYes == this.threeMonthFeedbackYes &&
          other.threeMonthFeedbackMaybe == this.threeMonthFeedbackMaybe &&
          other.threeMonthFeedbackNo == this.threeMonthFeedbackNo &&
          other.allTimeFeedbackYes == this.allTimeFeedbackYes &&
          other.allTimeFeedbackMaybe == this.allTimeFeedbackMaybe &&
          other.allTimeFeedbackNo == this.allTimeFeedbackNo &&
          other.generatedAt == this.generatedAt &&
          other.dataAsOfDate == this.dataAsOfDate);
}

class NpsMonthlyReportsCompanion extends UpdateCompanion<NpsMonthlyReport> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<int> reportMonth;
  final Value<int> reportYear;
  final Value<double?> allTimeNpsPercentage;
  final Value<double?> threeMonthNpsPercentage;
  final Value<double?> oneMonthNpsPercentage;
  final Value<double?> allTimeSales;
  final Value<int?> allTimeTableCount;
  final Value<int?> monthFeedbackYes;
  final Value<int?> monthFeedbackMaybe;
  final Value<int?> monthFeedbackNo;
  final Value<int?> threeMonthFeedbackYes;
  final Value<int?> threeMonthFeedbackMaybe;
  final Value<int?> threeMonthFeedbackNo;
  final Value<int?> allTimeFeedbackYes;
  final Value<int?> allTimeFeedbackMaybe;
  final Value<int?> allTimeFeedbackNo;
  final Value<String?> generatedAt;
  final Value<DateTime> dataAsOfDate;
  const NpsMonthlyReportsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.reportMonth = const Value.absent(),
    this.reportYear = const Value.absent(),
    this.allTimeNpsPercentage = const Value.absent(),
    this.threeMonthNpsPercentage = const Value.absent(),
    this.oneMonthNpsPercentage = const Value.absent(),
    this.allTimeSales = const Value.absent(),
    this.allTimeTableCount = const Value.absent(),
    this.monthFeedbackYes = const Value.absent(),
    this.monthFeedbackMaybe = const Value.absent(),
    this.monthFeedbackNo = const Value.absent(),
    this.threeMonthFeedbackYes = const Value.absent(),
    this.threeMonthFeedbackMaybe = const Value.absent(),
    this.threeMonthFeedbackNo = const Value.absent(),
    this.allTimeFeedbackYes = const Value.absent(),
    this.allTimeFeedbackMaybe = const Value.absent(),
    this.allTimeFeedbackNo = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.dataAsOfDate = const Value.absent(),
  });
  NpsMonthlyReportsCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required int reportMonth,
    required int reportYear,
    this.allTimeNpsPercentage = const Value.absent(),
    this.threeMonthNpsPercentage = const Value.absent(),
    this.oneMonthNpsPercentage = const Value.absent(),
    this.allTimeSales = const Value.absent(),
    this.allTimeTableCount = const Value.absent(),
    this.monthFeedbackYes = const Value.absent(),
    this.monthFeedbackMaybe = const Value.absent(),
    this.monthFeedbackNo = const Value.absent(),
    this.threeMonthFeedbackYes = const Value.absent(),
    this.threeMonthFeedbackMaybe = const Value.absent(),
    this.threeMonthFeedbackNo = const Value.absent(),
    this.allTimeFeedbackYes = const Value.absent(),
    this.allTimeFeedbackMaybe = const Value.absent(),
    this.allTimeFeedbackNo = const Value.absent(),
    this.generatedAt = const Value.absent(),
    required DateTime dataAsOfDate,
  })  : serverId = Value(serverId),
        reportMonth = Value(reportMonth),
        reportYear = Value(reportYear),
        dataAsOfDate = Value(dataAsOfDate);
  static Insertable<NpsMonthlyReport> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<int>? reportMonth,
    Expression<int>? reportYear,
    Expression<double>? allTimeNpsPercentage,
    Expression<double>? threeMonthNpsPercentage,
    Expression<double>? oneMonthNpsPercentage,
    Expression<double>? allTimeSales,
    Expression<int>? allTimeTableCount,
    Expression<int>? monthFeedbackYes,
    Expression<int>? monthFeedbackMaybe,
    Expression<int>? monthFeedbackNo,
    Expression<int>? threeMonthFeedbackYes,
    Expression<int>? threeMonthFeedbackMaybe,
    Expression<int>? threeMonthFeedbackNo,
    Expression<int>? allTimeFeedbackYes,
    Expression<int>? allTimeFeedbackMaybe,
    Expression<int>? allTimeFeedbackNo,
    Expression<String>? generatedAt,
    Expression<DateTime>? dataAsOfDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (reportMonth != null) 'report_month': reportMonth,
      if (reportYear != null) 'report_year': reportYear,
      if (allTimeNpsPercentage != null)
        'all_time_nps_percentage': allTimeNpsPercentage,
      if (threeMonthNpsPercentage != null)
        'three_month_nps_percentage': threeMonthNpsPercentage,
      if (oneMonthNpsPercentage != null)
        'one_month_nps_percentage': oneMonthNpsPercentage,
      if (allTimeSales != null) 'all_time_sales': allTimeSales,
      if (allTimeTableCount != null) 'all_time_table_count': allTimeTableCount,
      if (monthFeedbackYes != null) 'month_feedback_yes': monthFeedbackYes,
      if (monthFeedbackMaybe != null)
        'month_feedback_maybe': monthFeedbackMaybe,
      if (monthFeedbackNo != null) 'month_feedback_no': monthFeedbackNo,
      if (threeMonthFeedbackYes != null)
        'three_month_feedback_yes': threeMonthFeedbackYes,
      if (threeMonthFeedbackMaybe != null)
        'three_month_feedback_maybe': threeMonthFeedbackMaybe,
      if (threeMonthFeedbackNo != null)
        'three_month_feedback_no': threeMonthFeedbackNo,
      if (allTimeFeedbackYes != null)
        'all_time_feedback_yes': allTimeFeedbackYes,
      if (allTimeFeedbackMaybe != null)
        'all_time_feedback_maybe': allTimeFeedbackMaybe,
      if (allTimeFeedbackNo != null) 'all_time_feedback_no': allTimeFeedbackNo,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (dataAsOfDate != null) 'data_as_of_date': dataAsOfDate,
    });
  }

  NpsMonthlyReportsCompanion copyWith(
      {Value<int>? id,
      Value<String>? serverId,
      Value<int>? reportMonth,
      Value<int>? reportYear,
      Value<double?>? allTimeNpsPercentage,
      Value<double?>? threeMonthNpsPercentage,
      Value<double?>? oneMonthNpsPercentage,
      Value<double?>? allTimeSales,
      Value<int?>? allTimeTableCount,
      Value<int?>? monthFeedbackYes,
      Value<int?>? monthFeedbackMaybe,
      Value<int?>? monthFeedbackNo,
      Value<int?>? threeMonthFeedbackYes,
      Value<int?>? threeMonthFeedbackMaybe,
      Value<int?>? threeMonthFeedbackNo,
      Value<int?>? allTimeFeedbackYes,
      Value<int?>? allTimeFeedbackMaybe,
      Value<int?>? allTimeFeedbackNo,
      Value<String?>? generatedAt,
      Value<DateTime>? dataAsOfDate}) {
    return NpsMonthlyReportsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      reportMonth: reportMonth ?? this.reportMonth,
      reportYear: reportYear ?? this.reportYear,
      allTimeNpsPercentage: allTimeNpsPercentage ?? this.allTimeNpsPercentage,
      threeMonthNpsPercentage:
          threeMonthNpsPercentage ?? this.threeMonthNpsPercentage,
      oneMonthNpsPercentage:
          oneMonthNpsPercentage ?? this.oneMonthNpsPercentage,
      allTimeSales: allTimeSales ?? this.allTimeSales,
      allTimeTableCount: allTimeTableCount ?? this.allTimeTableCount,
      monthFeedbackYes: monthFeedbackYes ?? this.monthFeedbackYes,
      monthFeedbackMaybe: monthFeedbackMaybe ?? this.monthFeedbackMaybe,
      monthFeedbackNo: monthFeedbackNo ?? this.monthFeedbackNo,
      threeMonthFeedbackYes:
          threeMonthFeedbackYes ?? this.threeMonthFeedbackYes,
      threeMonthFeedbackMaybe:
          threeMonthFeedbackMaybe ?? this.threeMonthFeedbackMaybe,
      threeMonthFeedbackNo: threeMonthFeedbackNo ?? this.threeMonthFeedbackNo,
      allTimeFeedbackYes: allTimeFeedbackYes ?? this.allTimeFeedbackYes,
      allTimeFeedbackMaybe: allTimeFeedbackMaybe ?? this.allTimeFeedbackMaybe,
      allTimeFeedbackNo: allTimeFeedbackNo ?? this.allTimeFeedbackNo,
      generatedAt: generatedAt ?? this.generatedAt,
      dataAsOfDate: dataAsOfDate ?? this.dataAsOfDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (reportMonth.present) {
      map['report_month'] = Variable<int>(reportMonth.value);
    }
    if (reportYear.present) {
      map['report_year'] = Variable<int>(reportYear.value);
    }
    if (allTimeNpsPercentage.present) {
      map['all_time_nps_percentage'] =
          Variable<double>(allTimeNpsPercentage.value);
    }
    if (threeMonthNpsPercentage.present) {
      map['three_month_nps_percentage'] =
          Variable<double>(threeMonthNpsPercentage.value);
    }
    if (oneMonthNpsPercentage.present) {
      map['one_month_nps_percentage'] =
          Variable<double>(oneMonthNpsPercentage.value);
    }
    if (allTimeSales.present) {
      map['all_time_sales'] = Variable<double>(allTimeSales.value);
    }
    if (allTimeTableCount.present) {
      map['all_time_table_count'] = Variable<int>(allTimeTableCount.value);
    }
    if (monthFeedbackYes.present) {
      map['month_feedback_yes'] = Variable<int>(monthFeedbackYes.value);
    }
    if (monthFeedbackMaybe.present) {
      map['month_feedback_maybe'] = Variable<int>(monthFeedbackMaybe.value);
    }
    if (monthFeedbackNo.present) {
      map['month_feedback_no'] = Variable<int>(monthFeedbackNo.value);
    }
    if (threeMonthFeedbackYes.present) {
      map['three_month_feedback_yes'] =
          Variable<int>(threeMonthFeedbackYes.value);
    }
    if (threeMonthFeedbackMaybe.present) {
      map['three_month_feedback_maybe'] =
          Variable<int>(threeMonthFeedbackMaybe.value);
    }
    if (threeMonthFeedbackNo.present) {
      map['three_month_feedback_no'] =
          Variable<int>(threeMonthFeedbackNo.value);
    }
    if (allTimeFeedbackYes.present) {
      map['all_time_feedback_yes'] = Variable<int>(allTimeFeedbackYes.value);
    }
    if (allTimeFeedbackMaybe.present) {
      map['all_time_feedback_maybe'] =
          Variable<int>(allTimeFeedbackMaybe.value);
    }
    if (allTimeFeedbackNo.present) {
      map['all_time_feedback_no'] = Variable<int>(allTimeFeedbackNo.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<String>(generatedAt.value);
    }
    if (dataAsOfDate.present) {
      map['data_as_of_date'] = Variable<DateTime>(dataAsOfDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NpsMonthlyReportsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('reportMonth: $reportMonth, ')
          ..write('reportYear: $reportYear, ')
          ..write('allTimeNpsPercentage: $allTimeNpsPercentage, ')
          ..write('threeMonthNpsPercentage: $threeMonthNpsPercentage, ')
          ..write('oneMonthNpsPercentage: $oneMonthNpsPercentage, ')
          ..write('allTimeSales: $allTimeSales, ')
          ..write('allTimeTableCount: $allTimeTableCount, ')
          ..write('monthFeedbackYes: $monthFeedbackYes, ')
          ..write('monthFeedbackMaybe: $monthFeedbackMaybe, ')
          ..write('monthFeedbackNo: $monthFeedbackNo, ')
          ..write('threeMonthFeedbackYes: $threeMonthFeedbackYes, ')
          ..write('threeMonthFeedbackMaybe: $threeMonthFeedbackMaybe, ')
          ..write('threeMonthFeedbackNo: $threeMonthFeedbackNo, ')
          ..write('allTimeFeedbackYes: $allTimeFeedbackYes, ')
          ..write('allTimeFeedbackMaybe: $allTimeFeedbackMaybe, ')
          ..write('allTimeFeedbackNo: $allTimeFeedbackNo, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('dataAsOfDate: $dataAsOfDate')
          ..write(')'))
        .toString();
  }
}

class NpsCalculationLog extends Table
    with TableInfo<NpsCalculationLog, NpsCalculationLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NpsCalculationLog(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const VerificationMeta _calculationTypeMeta =
      const VerificationMeta('calculationType');
  late final GeneratedColumn<String> calculationType = GeneratedColumn<String>(
      'calculation_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _reportMonthMeta =
      const VerificationMeta('reportMonth');
  late final GeneratedColumn<int> reportMonth = GeneratedColumn<int>(
      'report_month', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _calculationStartMeta =
      const VerificationMeta('calculationStart');
  late final GeneratedColumn<String> calculationStart = GeneratedColumn<String>(
      'calculation_start', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _calculationEndMeta =
      const VerificationMeta('calculationEnd');
  late final GeneratedColumn<String> calculationEnd = GeneratedColumn<String>(
      'calculation_end', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _recordsProcessedMeta =
      const VerificationMeta('recordsProcessed');
  late final GeneratedColumn<int> recordsProcessed = GeneratedColumn<int>(
      'records_processed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _successMeta =
      const VerificationMeta('success');
  late final GeneratedColumn<int> success = GeneratedColumn<int>(
      'success', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        calculationType,
        serverId,
        reportMonth,
        calculationStart,
        calculationEnd,
        recordsProcessed,
        success,
        errorMessage,
        createdBy
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nps_calculation_log';
  @override
  VerificationContext validateIntegrity(
      Insertable<NpsCalculationLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('calculation_type')) {
      context.handle(
          _calculationTypeMeta,
          calculationType.isAcceptableOrUnknown(
              data['calculation_type']!, _calculationTypeMeta));
    } else if (isInserting) {
      context.missing(_calculationTypeMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('report_month')) {
      context.handle(
          _reportMonthMeta,
          reportMonth.isAcceptableOrUnknown(
              data['report_month']!, _reportMonthMeta));
    }
    if (data.containsKey('calculation_start')) {
      context.handle(
          _calculationStartMeta,
          calculationStart.isAcceptableOrUnknown(
              data['calculation_start']!, _calculationStartMeta));
    } else if (isInserting) {
      context.missing(_calculationStartMeta);
    }
    if (data.containsKey('calculation_end')) {
      context.handle(
          _calculationEndMeta,
          calculationEnd.isAcceptableOrUnknown(
              data['calculation_end']!, _calculationEndMeta));
    } else if (isInserting) {
      context.missing(_calculationEndMeta);
    }
    if (data.containsKey('records_processed')) {
      context.handle(
          _recordsProcessedMeta,
          recordsProcessed.isAcceptableOrUnknown(
              data['records_processed']!, _recordsProcessedMeta));
    } else if (isInserting) {
      context.missing(_recordsProcessedMeta);
    }
    if (data.containsKey('success')) {
      context.handle(_successMeta,
          success.isAcceptableOrUnknown(data['success']!, _successMeta));
    } else if (isInserting) {
      context.missing(_successMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NpsCalculationLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NpsCalculationLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      calculationType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calculation_type'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      reportMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}report_month']),
      calculationStart: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calculation_start'])!,
      calculationEnd: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calculation_end'])!,
      recordsProcessed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}records_processed'])!,
      success: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}success'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
    );
  }

  @override
  NpsCalculationLog createAlias(String alias) {
    return NpsCalculationLog(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['FOREIGN KEY(server_id)REFERENCES servers(id)ON DELETE SET NULL'];
  @override
  bool get dontWriteConstraints => true;
}

class NpsCalculationLogData extends DataClass
    implements Insertable<NpsCalculationLogData> {
  final int id;
  final String calculationType;
  final String? serverId;
  final int? reportMonth;
  final String calculationStart;
  final String calculationEnd;
  final int recordsProcessed;
  final int success;
  final String? errorMessage;
  final String? createdBy;
  const NpsCalculationLogData(
      {required this.id,
      required this.calculationType,
      this.serverId,
      this.reportMonth,
      required this.calculationStart,
      required this.calculationEnd,
      required this.recordsProcessed,
      required this.success,
      this.errorMessage,
      this.createdBy});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['calculation_type'] = Variable<String>(calculationType);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || reportMonth != null) {
      map['report_month'] = Variable<int>(reportMonth);
    }
    map['calculation_start'] = Variable<String>(calculationStart);
    map['calculation_end'] = Variable<String>(calculationEnd);
    map['records_processed'] = Variable<int>(recordsProcessed);
    map['success'] = Variable<int>(success);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    return map;
  }

  NpsCalculationLogCompanion toCompanion(bool nullToAbsent) {
    return NpsCalculationLogCompanion(
      id: Value(id),
      calculationType: Value(calculationType),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      reportMonth: reportMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(reportMonth),
      calculationStart: Value(calculationStart),
      calculationEnd: Value(calculationEnd),
      recordsProcessed: Value(recordsProcessed),
      success: Value(success),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
    );
  }

  factory NpsCalculationLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NpsCalculationLogData(
      id: serializer.fromJson<int>(json['id']),
      calculationType: serializer.fromJson<String>(json['calculation_type']),
      serverId: serializer.fromJson<String?>(json['server_id']),
      reportMonth: serializer.fromJson<int?>(json['report_month']),
      calculationStart: serializer.fromJson<String>(json['calculation_start']),
      calculationEnd: serializer.fromJson<String>(json['calculation_end']),
      recordsProcessed: serializer.fromJson<int>(json['records_processed']),
      success: serializer.fromJson<int>(json['success']),
      errorMessage: serializer.fromJson<String?>(json['error_message']),
      createdBy: serializer.fromJson<String?>(json['created_by']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'calculation_type': serializer.toJson<String>(calculationType),
      'server_id': serializer.toJson<String?>(serverId),
      'report_month': serializer.toJson<int?>(reportMonth),
      'calculation_start': serializer.toJson<String>(calculationStart),
      'calculation_end': serializer.toJson<String>(calculationEnd),
      'records_processed': serializer.toJson<int>(recordsProcessed),
      'success': serializer.toJson<int>(success),
      'error_message': serializer.toJson<String?>(errorMessage),
      'created_by': serializer.toJson<String?>(createdBy),
    };
  }

  NpsCalculationLogData copyWith(
          {int? id,
          String? calculationType,
          Value<String?> serverId = const Value.absent(),
          Value<int?> reportMonth = const Value.absent(),
          String? calculationStart,
          String? calculationEnd,
          int? recordsProcessed,
          int? success,
          Value<String?> errorMessage = const Value.absent(),
          Value<String?> createdBy = const Value.absent()}) =>
      NpsCalculationLogData(
        id: id ?? this.id,
        calculationType: calculationType ?? this.calculationType,
        serverId: serverId.present ? serverId.value : this.serverId,
        reportMonth: reportMonth.present ? reportMonth.value : this.reportMonth,
        calculationStart: calculationStart ?? this.calculationStart,
        calculationEnd: calculationEnd ?? this.calculationEnd,
        recordsProcessed: recordsProcessed ?? this.recordsProcessed,
        success: success ?? this.success,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
      );
  NpsCalculationLogData copyWithCompanion(NpsCalculationLogCompanion data) {
    return NpsCalculationLogData(
      id: data.id.present ? data.id.value : this.id,
      calculationType: data.calculationType.present
          ? data.calculationType.value
          : this.calculationType,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      reportMonth:
          data.reportMonth.present ? data.reportMonth.value : this.reportMonth,
      calculationStart: data.calculationStart.present
          ? data.calculationStart.value
          : this.calculationStart,
      calculationEnd: data.calculationEnd.present
          ? data.calculationEnd.value
          : this.calculationEnd,
      recordsProcessed: data.recordsProcessed.present
          ? data.recordsProcessed.value
          : this.recordsProcessed,
      success: data.success.present ? data.success.value : this.success,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NpsCalculationLogData(')
          ..write('id: $id, ')
          ..write('calculationType: $calculationType, ')
          ..write('serverId: $serverId, ')
          ..write('reportMonth: $reportMonth, ')
          ..write('calculationStart: $calculationStart, ')
          ..write('calculationEnd: $calculationEnd, ')
          ..write('recordsProcessed: $recordsProcessed, ')
          ..write('success: $success, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdBy: $createdBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      calculationType,
      serverId,
      reportMonth,
      calculationStart,
      calculationEnd,
      recordsProcessed,
      success,
      errorMessage,
      createdBy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NpsCalculationLogData &&
          other.id == this.id &&
          other.calculationType == this.calculationType &&
          other.serverId == this.serverId &&
          other.reportMonth == this.reportMonth &&
          other.calculationStart == this.calculationStart &&
          other.calculationEnd == this.calculationEnd &&
          other.recordsProcessed == this.recordsProcessed &&
          other.success == this.success &&
          other.errorMessage == this.errorMessage &&
          other.createdBy == this.createdBy);
}

class NpsCalculationLogCompanion
    extends UpdateCompanion<NpsCalculationLogData> {
  final Value<int> id;
  final Value<String> calculationType;
  final Value<String?> serverId;
  final Value<int?> reportMonth;
  final Value<String> calculationStart;
  final Value<String> calculationEnd;
  final Value<int> recordsProcessed;
  final Value<int> success;
  final Value<String?> errorMessage;
  final Value<String?> createdBy;
  const NpsCalculationLogCompanion({
    this.id = const Value.absent(),
    this.calculationType = const Value.absent(),
    this.serverId = const Value.absent(),
    this.reportMonth = const Value.absent(),
    this.calculationStart = const Value.absent(),
    this.calculationEnd = const Value.absent(),
    this.recordsProcessed = const Value.absent(),
    this.success = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdBy = const Value.absent(),
  });
  NpsCalculationLogCompanion.insert({
    this.id = const Value.absent(),
    required String calculationType,
    this.serverId = const Value.absent(),
    this.reportMonth = const Value.absent(),
    required String calculationStart,
    required String calculationEnd,
    required int recordsProcessed,
    required int success,
    this.errorMessage = const Value.absent(),
    this.createdBy = const Value.absent(),
  })  : calculationType = Value(calculationType),
        calculationStart = Value(calculationStart),
        calculationEnd = Value(calculationEnd),
        recordsProcessed = Value(recordsProcessed),
        success = Value(success);
  static Insertable<NpsCalculationLogData> custom({
    Expression<int>? id,
    Expression<String>? calculationType,
    Expression<String>? serverId,
    Expression<int>? reportMonth,
    Expression<String>? calculationStart,
    Expression<String>? calculationEnd,
    Expression<int>? recordsProcessed,
    Expression<int>? success,
    Expression<String>? errorMessage,
    Expression<String>? createdBy,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calculationType != null) 'calculation_type': calculationType,
      if (serverId != null) 'server_id': serverId,
      if (reportMonth != null) 'report_month': reportMonth,
      if (calculationStart != null) 'calculation_start': calculationStart,
      if (calculationEnd != null) 'calculation_end': calculationEnd,
      if (recordsProcessed != null) 'records_processed': recordsProcessed,
      if (success != null) 'success': success,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdBy != null) 'created_by': createdBy,
    });
  }

  NpsCalculationLogCompanion copyWith(
      {Value<int>? id,
      Value<String>? calculationType,
      Value<String?>? serverId,
      Value<int?>? reportMonth,
      Value<String>? calculationStart,
      Value<String>? calculationEnd,
      Value<int>? recordsProcessed,
      Value<int>? success,
      Value<String?>? errorMessage,
      Value<String?>? createdBy}) {
    return NpsCalculationLogCompanion(
      id: id ?? this.id,
      calculationType: calculationType ?? this.calculationType,
      serverId: serverId ?? this.serverId,
      reportMonth: reportMonth ?? this.reportMonth,
      calculationStart: calculationStart ?? this.calculationStart,
      calculationEnd: calculationEnd ?? this.calculationEnd,
      recordsProcessed: recordsProcessed ?? this.recordsProcessed,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (calculationType.present) {
      map['calculation_type'] = Variable<String>(calculationType.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (reportMonth.present) {
      map['report_month'] = Variable<int>(reportMonth.value);
    }
    if (calculationStart.present) {
      map['calculation_start'] = Variable<String>(calculationStart.value);
    }
    if (calculationEnd.present) {
      map['calculation_end'] = Variable<String>(calculationEnd.value);
    }
    if (recordsProcessed.present) {
      map['records_processed'] = Variable<int>(recordsProcessed.value);
    }
    if (success.present) {
      map['success'] = Variable<int>(success.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NpsCalculationLogCompanion(')
          ..write('id: $id, ')
          ..write('calculationType: $calculationType, ')
          ..write('serverId: $serverId, ')
          ..write('reportMonth: $reportMonth, ')
          ..write('calculationStart: $calculationStart, ')
          ..write('calculationEnd: $calculationEnd, ')
          ..write('recordsProcessed: $recordsProcessed, ')
          ..write('success: $success, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdBy: $createdBy')
          ..write(')'))
        .toString();
  }
}

abstract class _$DriftNPSDatabase extends GeneratedDatabase {
  _$DriftNPSDatabase(QueryExecutor e) : super(e);
  $DriftNPSDatabaseManager get managers => $DriftNPSDatabaseManager(this);
  late final Servers servers = Servers(this);
  late final Index idxServersActive = Index('idx_servers_active',
      'CREATE INDEX idx_servers_active ON servers (active)');
  late final Index idxServersHireDate = Index('idx_servers_hire_date',
      'CREATE INDEX idx_servers_hire_date ON servers (hire_date)');
  late final NpsFeedback npsFeedback = NpsFeedback(this);
  late final Index idxFeedbackServerId = Index('idx_feedback_server_id',
      'CREATE INDEX idx_feedback_server_id ON nps_feedback (server_id)');
  late final Index idxFeedbackDate = Index('idx_feedback_date',
      'CREATE INDEX idx_feedback_date ON nps_feedback (feedback_date)');
  late final Index idxFeedbackServerDate = Index('idx_feedback_server_date',
      'CREATE INDEX idx_feedback_server_date ON nps_feedback (server_id, feedback_date)');
  late final Index idxFeedbackType = Index('idx_feedback_type',
      'CREATE INDEX idx_feedback_type ON nps_feedback (feedback_type)');
  late final NpsMonthlyReports npsMonthlyReports = NpsMonthlyReports(this);
  late final Index idxMonthlyReportsServerId = Index(
      'idx_monthly_reports_server_id',
      'CREATE INDEX idx_monthly_reports_server_id ON nps_monthly_reports (server_id)');
  late final Index idxMonthlyReportsMonth = Index('idx_monthly_reports_month',
      'CREATE INDEX idx_monthly_reports_month ON nps_monthly_reports (report_month)');
  late final Index idxMonthlyReportsYear = Index('idx_monthly_reports_year',
      'CREATE INDEX idx_monthly_reports_year ON nps_monthly_reports (report_year)');
  late final Index idxMonthlyReportsServerMonth = Index(
      'idx_monthly_reports_server_month',
      'CREATE INDEX idx_monthly_reports_server_month ON nps_monthly_reports (server_id, report_month)');
  late final NpsCalculationLog npsCalculationLog = NpsCalculationLog(this);
  late final Index idxCalcLogType = Index('idx_calc_log_type',
      'CREATE INDEX idx_calc_log_type ON nps_calculation_log (calculation_type)');
  late final Index idxCalcLogDate = Index('idx_calc_log_date',
      'CREATE INDEX idx_calc_log_date ON nps_calculation_log (calculation_start)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        servers,
        idxServersActive,
        idxServersHireDate,
        npsFeedback,
        idxFeedbackServerId,
        idxFeedbackDate,
        idxFeedbackServerDate,
        idxFeedbackType,
        npsMonthlyReports,
        idxMonthlyReportsServerId,
        idxMonthlyReportsMonth,
        idxMonthlyReportsYear,
        idxMonthlyReportsServerMonth,
        npsCalculationLog,
        idxCalcLogType,
        idxCalcLogDate
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('servers',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('nps_calculation_log', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}

typedef $ServersCreateCompanionBuilder = ServersCompanion Function({
  required String id,
  required String name,
  Value<String?> originalId,
  required DateTime hireDate,
  Value<int> active,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $ServersUpdateCompanionBuilder = ServersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> originalId,
  Value<DateTime> hireDate,
  Value<int> active,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});

class $ServersFilterComposer extends Composer<_$DriftNPSDatabase, Servers> {
  $ServersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $ServersOrderingComposer extends Composer<_$DriftNPSDatabase, Servers> {
  $ServersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $ServersAnnotationComposer extends Composer<_$DriftNPSDatabase, Servers> {
  $ServersAnnotationComposer({
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

  GeneratedColumn<String> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => column);

  GeneratedColumn<DateTime> get hireDate =>
      $composableBuilder(column: $table.hireDate, builder: (column) => column);

  GeneratedColumn<int> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $ServersTableManager extends RootTableManager<
    _$DriftNPSDatabase,
    Servers,
    Server,
    $ServersFilterComposer,
    $ServersOrderingComposer,
    $ServersAnnotationComposer,
    $ServersCreateCompanionBuilder,
    $ServersUpdateCompanionBuilder,
    (Server, BaseReferences<_$DriftNPSDatabase, Servers, Server>),
    Server,
    PrefetchHooks Function()> {
  $ServersTableManager(_$DriftNPSDatabase db, Servers table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ServersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ServersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ServersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> originalId = const Value.absent(),
            Value<DateTime> hireDate = const Value.absent(),
            Value<int> active = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServersCompanion(
            id: id,
            name: name,
            originalId: originalId,
            hireDate: hireDate,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> originalId = const Value.absent(),
            required DateTime hireDate,
            Value<int> active = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServersCompanion.insert(
            id: id,
            name: name,
            originalId: originalId,
            hireDate: hireDate,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $ServersProcessedTableManager = ProcessedTableManager<
    _$DriftNPSDatabase,
    Servers,
    Server,
    $ServersFilterComposer,
    $ServersOrderingComposer,
    $ServersAnnotationComposer,
    $ServersCreateCompanionBuilder,
    $ServersUpdateCompanionBuilder,
    (Server, BaseReferences<_$DriftNPSDatabase, Servers, Server>),
    Server,
    PrefetchHooks Function()>;
typedef $NpsFeedbackCreateCompanionBuilder = NpsFeedbackCompanion Function({
  Value<int> id,
  required String serverId,
  required String feedbackType,
  required DateTime feedbackDate,
  Value<double?> salesAmount,
  Value<int?> tableNumber,
  Value<String?> shiftPeriod,
  Value<int?> guestCount,
  Value<String?> notes,
  Value<String?> createdAt,
});
typedef $NpsFeedbackUpdateCompanionBuilder = NpsFeedbackCompanion Function({
  Value<int> id,
  Value<String> serverId,
  Value<String> feedbackType,
  Value<DateTime> feedbackDate,
  Value<double?> salesAmount,
  Value<int?> tableNumber,
  Value<String?> shiftPeriod,
  Value<int?> guestCount,
  Value<String?> notes,
  Value<String?> createdAt,
});

class $NpsFeedbackFilterComposer
    extends Composer<_$DriftNPSDatabase, NpsFeedback> {
  $NpsFeedbackFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedbackType => $composableBuilder(
      column: $table.feedbackType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get feedbackDate => $composableBuilder(
      column: $table.feedbackDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get salesAmount => $composableBuilder(
      column: $table.salesAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tableNumber => $composableBuilder(
      column: $table.tableNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shiftPeriod => $composableBuilder(
      column: $table.shiftPeriod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get guestCount => $composableBuilder(
      column: $table.guestCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $NpsFeedbackOrderingComposer
    extends Composer<_$DriftNPSDatabase, NpsFeedback> {
  $NpsFeedbackOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedbackType => $composableBuilder(
      column: $table.feedbackType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get feedbackDate => $composableBuilder(
      column: $table.feedbackDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get salesAmount => $composableBuilder(
      column: $table.salesAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tableNumber => $composableBuilder(
      column: $table.tableNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shiftPeriod => $composableBuilder(
      column: $table.shiftPeriod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get guestCount => $composableBuilder(
      column: $table.guestCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $NpsFeedbackAnnotationComposer
    extends Composer<_$DriftNPSDatabase, NpsFeedback> {
  $NpsFeedbackAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get feedbackType => $composableBuilder(
      column: $table.feedbackType, builder: (column) => column);

  GeneratedColumn<DateTime> get feedbackDate => $composableBuilder(
      column: $table.feedbackDate, builder: (column) => column);

  GeneratedColumn<double> get salesAmount => $composableBuilder(
      column: $table.salesAmount, builder: (column) => column);

  GeneratedColumn<int> get tableNumber => $composableBuilder(
      column: $table.tableNumber, builder: (column) => column);

  GeneratedColumn<String> get shiftPeriod => $composableBuilder(
      column: $table.shiftPeriod, builder: (column) => column);

  GeneratedColumn<int> get guestCount => $composableBuilder(
      column: $table.guestCount, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $NpsFeedbackTableManager extends RootTableManager<
    _$DriftNPSDatabase,
    NpsFeedback,
    NpsFeedbackData,
    $NpsFeedbackFilterComposer,
    $NpsFeedbackOrderingComposer,
    $NpsFeedbackAnnotationComposer,
    $NpsFeedbackCreateCompanionBuilder,
    $NpsFeedbackUpdateCompanionBuilder,
    (
      NpsFeedbackData,
      BaseReferences<_$DriftNPSDatabase, NpsFeedback, NpsFeedbackData>
    ),
    NpsFeedbackData,
    PrefetchHooks Function()> {
  $NpsFeedbackTableManager(_$DriftNPSDatabase db, NpsFeedback table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $NpsFeedbackFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $NpsFeedbackOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $NpsFeedbackAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<String> feedbackType = const Value.absent(),
            Value<DateTime> feedbackDate = const Value.absent(),
            Value<double?> salesAmount = const Value.absent(),
            Value<int?> tableNumber = const Value.absent(),
            Value<String?> shiftPeriod = const Value.absent(),
            Value<int?> guestCount = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              NpsFeedbackCompanion(
            id: id,
            serverId: serverId,
            feedbackType: feedbackType,
            feedbackDate: feedbackDate,
            salesAmount: salesAmount,
            tableNumber: tableNumber,
            shiftPeriod: shiftPeriod,
            guestCount: guestCount,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String serverId,
            required String feedbackType,
            required DateTime feedbackDate,
            Value<double?> salesAmount = const Value.absent(),
            Value<int?> tableNumber = const Value.absent(),
            Value<String?> shiftPeriod = const Value.absent(),
            Value<int?> guestCount = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              NpsFeedbackCompanion.insert(
            id: id,
            serverId: serverId,
            feedbackType: feedbackType,
            feedbackDate: feedbackDate,
            salesAmount: salesAmount,
            tableNumber: tableNumber,
            shiftPeriod: shiftPeriod,
            guestCount: guestCount,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $NpsFeedbackProcessedTableManager = ProcessedTableManager<
    _$DriftNPSDatabase,
    NpsFeedback,
    NpsFeedbackData,
    $NpsFeedbackFilterComposer,
    $NpsFeedbackOrderingComposer,
    $NpsFeedbackAnnotationComposer,
    $NpsFeedbackCreateCompanionBuilder,
    $NpsFeedbackUpdateCompanionBuilder,
    (
      NpsFeedbackData,
      BaseReferences<_$DriftNPSDatabase, NpsFeedback, NpsFeedbackData>
    ),
    NpsFeedbackData,
    PrefetchHooks Function()>;
typedef $NpsMonthlyReportsCreateCompanionBuilder = NpsMonthlyReportsCompanion
    Function({
  Value<int> id,
  required String serverId,
  required int reportMonth,
  required int reportYear,
  Value<double?> allTimeNpsPercentage,
  Value<double?> threeMonthNpsPercentage,
  Value<double?> oneMonthNpsPercentage,
  Value<double?> allTimeSales,
  Value<int?> allTimeTableCount,
  Value<int?> monthFeedbackYes,
  Value<int?> monthFeedbackMaybe,
  Value<int?> monthFeedbackNo,
  Value<int?> threeMonthFeedbackYes,
  Value<int?> threeMonthFeedbackMaybe,
  Value<int?> threeMonthFeedbackNo,
  Value<int?> allTimeFeedbackYes,
  Value<int?> allTimeFeedbackMaybe,
  Value<int?> allTimeFeedbackNo,
  Value<String?> generatedAt,
  required DateTime dataAsOfDate,
});
typedef $NpsMonthlyReportsUpdateCompanionBuilder = NpsMonthlyReportsCompanion
    Function({
  Value<int> id,
  Value<String> serverId,
  Value<int> reportMonth,
  Value<int> reportYear,
  Value<double?> allTimeNpsPercentage,
  Value<double?> threeMonthNpsPercentage,
  Value<double?> oneMonthNpsPercentage,
  Value<double?> allTimeSales,
  Value<int?> allTimeTableCount,
  Value<int?> monthFeedbackYes,
  Value<int?> monthFeedbackMaybe,
  Value<int?> monthFeedbackNo,
  Value<int?> threeMonthFeedbackYes,
  Value<int?> threeMonthFeedbackMaybe,
  Value<int?> threeMonthFeedbackNo,
  Value<int?> allTimeFeedbackYes,
  Value<int?> allTimeFeedbackMaybe,
  Value<int?> allTimeFeedbackNo,
  Value<String?> generatedAt,
  Value<DateTime> dataAsOfDate,
});

class $NpsMonthlyReportsFilterComposer
    extends Composer<_$DriftNPSDatabase, NpsMonthlyReports> {
  $NpsMonthlyReportsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reportMonth => $composableBuilder(
      column: $table.reportMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reportYear => $composableBuilder(
      column: $table.reportYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get allTimeNpsPercentage => $composableBuilder(
      column: $table.allTimeNpsPercentage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get threeMonthNpsPercentage => $composableBuilder(
      column: $table.threeMonthNpsPercentage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get oneMonthNpsPercentage => $composableBuilder(
      column: $table.oneMonthNpsPercentage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get allTimeSales => $composableBuilder(
      column: $table.allTimeSales, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get allTimeTableCount => $composableBuilder(
      column: $table.allTimeTableCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get monthFeedbackYes => $composableBuilder(
      column: $table.monthFeedbackYes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get monthFeedbackMaybe => $composableBuilder(
      column: $table.monthFeedbackMaybe,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get monthFeedbackNo => $composableBuilder(
      column: $table.monthFeedbackNo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get threeMonthFeedbackYes => $composableBuilder(
      column: $table.threeMonthFeedbackYes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get threeMonthFeedbackMaybe => $composableBuilder(
      column: $table.threeMonthFeedbackMaybe,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get threeMonthFeedbackNo => $composableBuilder(
      column: $table.threeMonthFeedbackNo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get allTimeFeedbackYes => $composableBuilder(
      column: $table.allTimeFeedbackYes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get allTimeFeedbackMaybe => $composableBuilder(
      column: $table.allTimeFeedbackMaybe,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get allTimeFeedbackNo => $composableBuilder(
      column: $table.allTimeFeedbackNo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataAsOfDate => $composableBuilder(
      column: $table.dataAsOfDate, builder: (column) => ColumnFilters(column));
}

class $NpsMonthlyReportsOrderingComposer
    extends Composer<_$DriftNPSDatabase, NpsMonthlyReports> {
  $NpsMonthlyReportsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reportMonth => $composableBuilder(
      column: $table.reportMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reportYear => $composableBuilder(
      column: $table.reportYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get allTimeNpsPercentage => $composableBuilder(
      column: $table.allTimeNpsPercentage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get threeMonthNpsPercentage => $composableBuilder(
      column: $table.threeMonthNpsPercentage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get oneMonthNpsPercentage => $composableBuilder(
      column: $table.oneMonthNpsPercentage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get allTimeSales => $composableBuilder(
      column: $table.allTimeSales,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get allTimeTableCount => $composableBuilder(
      column: $table.allTimeTableCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get monthFeedbackYes => $composableBuilder(
      column: $table.monthFeedbackYes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get monthFeedbackMaybe => $composableBuilder(
      column: $table.monthFeedbackMaybe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get monthFeedbackNo => $composableBuilder(
      column: $table.monthFeedbackNo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get threeMonthFeedbackYes => $composableBuilder(
      column: $table.threeMonthFeedbackYes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get threeMonthFeedbackMaybe => $composableBuilder(
      column: $table.threeMonthFeedbackMaybe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get threeMonthFeedbackNo => $composableBuilder(
      column: $table.threeMonthFeedbackNo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get allTimeFeedbackYes => $composableBuilder(
      column: $table.allTimeFeedbackYes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get allTimeFeedbackMaybe => $composableBuilder(
      column: $table.allTimeFeedbackMaybe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get allTimeFeedbackNo => $composableBuilder(
      column: $table.allTimeFeedbackNo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataAsOfDate => $composableBuilder(
      column: $table.dataAsOfDate,
      builder: (column) => ColumnOrderings(column));
}

class $NpsMonthlyReportsAnnotationComposer
    extends Composer<_$DriftNPSDatabase, NpsMonthlyReports> {
  $NpsMonthlyReportsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get reportMonth => $composableBuilder(
      column: $table.reportMonth, builder: (column) => column);

  GeneratedColumn<int> get reportYear => $composableBuilder(
      column: $table.reportYear, builder: (column) => column);

  GeneratedColumn<double> get allTimeNpsPercentage => $composableBuilder(
      column: $table.allTimeNpsPercentage, builder: (column) => column);

  GeneratedColumn<double> get threeMonthNpsPercentage => $composableBuilder(
      column: $table.threeMonthNpsPercentage, builder: (column) => column);

  GeneratedColumn<double> get oneMonthNpsPercentage => $composableBuilder(
      column: $table.oneMonthNpsPercentage, builder: (column) => column);

  GeneratedColumn<double> get allTimeSales => $composableBuilder(
      column: $table.allTimeSales, builder: (column) => column);

  GeneratedColumn<int> get allTimeTableCount => $composableBuilder(
      column: $table.allTimeTableCount, builder: (column) => column);

  GeneratedColumn<int> get monthFeedbackYes => $composableBuilder(
      column: $table.monthFeedbackYes, builder: (column) => column);

  GeneratedColumn<int> get monthFeedbackMaybe => $composableBuilder(
      column: $table.monthFeedbackMaybe, builder: (column) => column);

  GeneratedColumn<int> get monthFeedbackNo => $composableBuilder(
      column: $table.monthFeedbackNo, builder: (column) => column);

  GeneratedColumn<int> get threeMonthFeedbackYes => $composableBuilder(
      column: $table.threeMonthFeedbackYes, builder: (column) => column);

  GeneratedColumn<int> get threeMonthFeedbackMaybe => $composableBuilder(
      column: $table.threeMonthFeedbackMaybe, builder: (column) => column);

  GeneratedColumn<int> get threeMonthFeedbackNo => $composableBuilder(
      column: $table.threeMonthFeedbackNo, builder: (column) => column);

  GeneratedColumn<int> get allTimeFeedbackYes => $composableBuilder(
      column: $table.allTimeFeedbackYes, builder: (column) => column);

  GeneratedColumn<int> get allTimeFeedbackMaybe => $composableBuilder(
      column: $table.allTimeFeedbackMaybe, builder: (column) => column);

  GeneratedColumn<int> get allTimeFeedbackNo => $composableBuilder(
      column: $table.allTimeFeedbackNo, builder: (column) => column);

  GeneratedColumn<String> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dataAsOfDate => $composableBuilder(
      column: $table.dataAsOfDate, builder: (column) => column);
}

class $NpsMonthlyReportsTableManager extends RootTableManager<
    _$DriftNPSDatabase,
    NpsMonthlyReports,
    NpsMonthlyReport,
    $NpsMonthlyReportsFilterComposer,
    $NpsMonthlyReportsOrderingComposer,
    $NpsMonthlyReportsAnnotationComposer,
    $NpsMonthlyReportsCreateCompanionBuilder,
    $NpsMonthlyReportsUpdateCompanionBuilder,
    (
      NpsMonthlyReport,
      BaseReferences<_$DriftNPSDatabase, NpsMonthlyReports, NpsMonthlyReport>
    ),
    NpsMonthlyReport,
    PrefetchHooks Function()> {
  $NpsMonthlyReportsTableManager(_$DriftNPSDatabase db, NpsMonthlyReports table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $NpsMonthlyReportsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $NpsMonthlyReportsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $NpsMonthlyReportsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<int> reportMonth = const Value.absent(),
            Value<int> reportYear = const Value.absent(),
            Value<double?> allTimeNpsPercentage = const Value.absent(),
            Value<double?> threeMonthNpsPercentage = const Value.absent(),
            Value<double?> oneMonthNpsPercentage = const Value.absent(),
            Value<double?> allTimeSales = const Value.absent(),
            Value<int?> allTimeTableCount = const Value.absent(),
            Value<int?> monthFeedbackYes = const Value.absent(),
            Value<int?> monthFeedbackMaybe = const Value.absent(),
            Value<int?> monthFeedbackNo = const Value.absent(),
            Value<int?> threeMonthFeedbackYes = const Value.absent(),
            Value<int?> threeMonthFeedbackMaybe = const Value.absent(),
            Value<int?> threeMonthFeedbackNo = const Value.absent(),
            Value<int?> allTimeFeedbackYes = const Value.absent(),
            Value<int?> allTimeFeedbackMaybe = const Value.absent(),
            Value<int?> allTimeFeedbackNo = const Value.absent(),
            Value<String?> generatedAt = const Value.absent(),
            Value<DateTime> dataAsOfDate = const Value.absent(),
          }) =>
              NpsMonthlyReportsCompanion(
            id: id,
            serverId: serverId,
            reportMonth: reportMonth,
            reportYear: reportYear,
            allTimeNpsPercentage: allTimeNpsPercentage,
            threeMonthNpsPercentage: threeMonthNpsPercentage,
            oneMonthNpsPercentage: oneMonthNpsPercentage,
            allTimeSales: allTimeSales,
            allTimeTableCount: allTimeTableCount,
            monthFeedbackYes: monthFeedbackYes,
            monthFeedbackMaybe: monthFeedbackMaybe,
            monthFeedbackNo: monthFeedbackNo,
            threeMonthFeedbackYes: threeMonthFeedbackYes,
            threeMonthFeedbackMaybe: threeMonthFeedbackMaybe,
            threeMonthFeedbackNo: threeMonthFeedbackNo,
            allTimeFeedbackYes: allTimeFeedbackYes,
            allTimeFeedbackMaybe: allTimeFeedbackMaybe,
            allTimeFeedbackNo: allTimeFeedbackNo,
            generatedAt: generatedAt,
            dataAsOfDate: dataAsOfDate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String serverId,
            required int reportMonth,
            required int reportYear,
            Value<double?> allTimeNpsPercentage = const Value.absent(),
            Value<double?> threeMonthNpsPercentage = const Value.absent(),
            Value<double?> oneMonthNpsPercentage = const Value.absent(),
            Value<double?> allTimeSales = const Value.absent(),
            Value<int?> allTimeTableCount = const Value.absent(),
            Value<int?> monthFeedbackYes = const Value.absent(),
            Value<int?> monthFeedbackMaybe = const Value.absent(),
            Value<int?> monthFeedbackNo = const Value.absent(),
            Value<int?> threeMonthFeedbackYes = const Value.absent(),
            Value<int?> threeMonthFeedbackMaybe = const Value.absent(),
            Value<int?> threeMonthFeedbackNo = const Value.absent(),
            Value<int?> allTimeFeedbackYes = const Value.absent(),
            Value<int?> allTimeFeedbackMaybe = const Value.absent(),
            Value<int?> allTimeFeedbackNo = const Value.absent(),
            Value<String?> generatedAt = const Value.absent(),
            required DateTime dataAsOfDate,
          }) =>
              NpsMonthlyReportsCompanion.insert(
            id: id,
            serverId: serverId,
            reportMonth: reportMonth,
            reportYear: reportYear,
            allTimeNpsPercentage: allTimeNpsPercentage,
            threeMonthNpsPercentage: threeMonthNpsPercentage,
            oneMonthNpsPercentage: oneMonthNpsPercentage,
            allTimeSales: allTimeSales,
            allTimeTableCount: allTimeTableCount,
            monthFeedbackYes: monthFeedbackYes,
            monthFeedbackMaybe: monthFeedbackMaybe,
            monthFeedbackNo: monthFeedbackNo,
            threeMonthFeedbackYes: threeMonthFeedbackYes,
            threeMonthFeedbackMaybe: threeMonthFeedbackMaybe,
            threeMonthFeedbackNo: threeMonthFeedbackNo,
            allTimeFeedbackYes: allTimeFeedbackYes,
            allTimeFeedbackMaybe: allTimeFeedbackMaybe,
            allTimeFeedbackNo: allTimeFeedbackNo,
            generatedAt: generatedAt,
            dataAsOfDate: dataAsOfDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $NpsMonthlyReportsProcessedTableManager = ProcessedTableManager<
    _$DriftNPSDatabase,
    NpsMonthlyReports,
    NpsMonthlyReport,
    $NpsMonthlyReportsFilterComposer,
    $NpsMonthlyReportsOrderingComposer,
    $NpsMonthlyReportsAnnotationComposer,
    $NpsMonthlyReportsCreateCompanionBuilder,
    $NpsMonthlyReportsUpdateCompanionBuilder,
    (
      NpsMonthlyReport,
      BaseReferences<_$DriftNPSDatabase, NpsMonthlyReports, NpsMonthlyReport>
    ),
    NpsMonthlyReport,
    PrefetchHooks Function()>;
typedef $NpsCalculationLogCreateCompanionBuilder = NpsCalculationLogCompanion
    Function({
  Value<int> id,
  required String calculationType,
  Value<String?> serverId,
  Value<int?> reportMonth,
  required String calculationStart,
  required String calculationEnd,
  required int recordsProcessed,
  required int success,
  Value<String?> errorMessage,
  Value<String?> createdBy,
});
typedef $NpsCalculationLogUpdateCompanionBuilder = NpsCalculationLogCompanion
    Function({
  Value<int> id,
  Value<String> calculationType,
  Value<String?> serverId,
  Value<int?> reportMonth,
  Value<String> calculationStart,
  Value<String> calculationEnd,
  Value<int> recordsProcessed,
  Value<int> success,
  Value<String?> errorMessage,
  Value<String?> createdBy,
});

class $NpsCalculationLogFilterComposer
    extends Composer<_$DriftNPSDatabase, NpsCalculationLog> {
  $NpsCalculationLogFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calculationType => $composableBuilder(
      column: $table.calculationType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reportMonth => $composableBuilder(
      column: $table.reportMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calculationStart => $composableBuilder(
      column: $table.calculationStart,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calculationEnd => $composableBuilder(
      column: $table.calculationEnd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordsProcessed => $composableBuilder(
      column: $table.recordsProcessed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));
}

class $NpsCalculationLogOrderingComposer
    extends Composer<_$DriftNPSDatabase, NpsCalculationLog> {
  $NpsCalculationLogOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calculationType => $composableBuilder(
      column: $table.calculationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reportMonth => $composableBuilder(
      column: $table.reportMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calculationStart => $composableBuilder(
      column: $table.calculationStart,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calculationEnd => $composableBuilder(
      column: $table.calculationEnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordsProcessed => $composableBuilder(
      column: $table.recordsProcessed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));
}

class $NpsCalculationLogAnnotationComposer
    extends Composer<_$DriftNPSDatabase, NpsCalculationLog> {
  $NpsCalculationLogAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get calculationType => $composableBuilder(
      column: $table.calculationType, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get reportMonth => $composableBuilder(
      column: $table.reportMonth, builder: (column) => column);

  GeneratedColumn<String> get calculationStart => $composableBuilder(
      column: $table.calculationStart, builder: (column) => column);

  GeneratedColumn<String> get calculationEnd => $composableBuilder(
      column: $table.calculationEnd, builder: (column) => column);

  GeneratedColumn<int> get recordsProcessed => $composableBuilder(
      column: $table.recordsProcessed, builder: (column) => column);

  GeneratedColumn<int> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);
}

class $NpsCalculationLogTableManager extends RootTableManager<
    _$DriftNPSDatabase,
    NpsCalculationLog,
    NpsCalculationLogData,
    $NpsCalculationLogFilterComposer,
    $NpsCalculationLogOrderingComposer,
    $NpsCalculationLogAnnotationComposer,
    $NpsCalculationLogCreateCompanionBuilder,
    $NpsCalculationLogUpdateCompanionBuilder,
    (
      NpsCalculationLogData,
      BaseReferences<_$DriftNPSDatabase, NpsCalculationLog,
          NpsCalculationLogData>
    ),
    NpsCalculationLogData,
    PrefetchHooks Function()> {
  $NpsCalculationLogTableManager(_$DriftNPSDatabase db, NpsCalculationLog table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $NpsCalculationLogFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $NpsCalculationLogOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $NpsCalculationLogAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> calculationType = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<int?> reportMonth = const Value.absent(),
            Value<String> calculationStart = const Value.absent(),
            Value<String> calculationEnd = const Value.absent(),
            Value<int> recordsProcessed = const Value.absent(),
            Value<int> success = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
          }) =>
              NpsCalculationLogCompanion(
            id: id,
            calculationType: calculationType,
            serverId: serverId,
            reportMonth: reportMonth,
            calculationStart: calculationStart,
            calculationEnd: calculationEnd,
            recordsProcessed: recordsProcessed,
            success: success,
            errorMessage: errorMessage,
            createdBy: createdBy,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String calculationType,
            Value<String?> serverId = const Value.absent(),
            Value<int?> reportMonth = const Value.absent(),
            required String calculationStart,
            required String calculationEnd,
            required int recordsProcessed,
            required int success,
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
          }) =>
              NpsCalculationLogCompanion.insert(
            id: id,
            calculationType: calculationType,
            serverId: serverId,
            reportMonth: reportMonth,
            calculationStart: calculationStart,
            calculationEnd: calculationEnd,
            recordsProcessed: recordsProcessed,
            success: success,
            errorMessage: errorMessage,
            createdBy: createdBy,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $NpsCalculationLogProcessedTableManager = ProcessedTableManager<
    _$DriftNPSDatabase,
    NpsCalculationLog,
    NpsCalculationLogData,
    $NpsCalculationLogFilterComposer,
    $NpsCalculationLogOrderingComposer,
    $NpsCalculationLogAnnotationComposer,
    $NpsCalculationLogCreateCompanionBuilder,
    $NpsCalculationLogUpdateCompanionBuilder,
    (
      NpsCalculationLogData,
      BaseReferences<_$DriftNPSDatabase, NpsCalculationLog,
          NpsCalculationLogData>
    ),
    NpsCalculationLogData,
    PrefetchHooks Function()>;

class $DriftNPSDatabaseManager {
  final _$DriftNPSDatabase _db;
  $DriftNPSDatabaseManager(this._db);
  $ServersTableManager get servers => $ServersTableManager(_db, _db.servers);
  $NpsFeedbackTableManager get npsFeedback =>
      $NpsFeedbackTableManager(_db, _db.npsFeedback);
  $NpsMonthlyReportsTableManager get npsMonthlyReports =>
      $NpsMonthlyReportsTableManager(_db, _db.npsMonthlyReports);
  $NpsCalculationLogTableManager get npsCalculationLog =>
      $NpsCalculationLogTableManager(_db, _db.npsCalculationLog);
}
