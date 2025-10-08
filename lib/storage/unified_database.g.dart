// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_database.dart';

// ignore_for_file: type=lint
class $ServersTable extends Servers with TableInfo<$ServersTable, Server> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalIdMeta =
      const VerificationMeta('originalId');
  @override
  late final GeneratedColumn<String> originalId = GeneratedColumn<String>(
      'original_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teamColorMeta =
      const VerificationMeta('teamColor');
  @override
  late final GeneratedColumn<String> teamColor = GeneratedColumn<String>(
      'team_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stationTypeMeta =
      const VerificationMeta('stationType');
  @override
  late final GeneratedColumn<String> stationType = GeneratedColumn<String>(
      'station_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hireDateMeta =
      const VerificationMeta('hireDate');
  @override
  late final GeneratedColumn<String> hireDate = GeneratedColumn<String>(
      'hire_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        originalId,
        teamColor,
        stationType,
        hireDate,
        active,
        createdAt,
        updatedAt
      ];
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
    if (data.containsKey('team_color')) {
      context.handle(_teamColorMeta,
          teamColor.isAcceptableOrUnknown(data['team_color']!, _teamColorMeta));
    }
    if (data.containsKey('station_type')) {
      context.handle(
          _stationTypeMeta,
          stationType.isAcceptableOrUnknown(
              data['station_type']!, _stationTypeMeta));
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
      teamColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_color']),
      stationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}station_type']),
      hireDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hire_date'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ServersTable createAlias(String alias) {
    return $ServersTable(attachedDatabase, alias);
  }
}

class Server extends DataClass implements Insertable<Server> {
  final String id;
  final String name;
  final String? originalId;
  final String? teamColor;
  final String? stationType;
  final String hireDate;
  final bool active;
  final String createdAt;
  final String updatedAt;
  const Server(
      {required this.id,
      required this.name,
      this.originalId,
      this.teamColor,
      this.stationType,
      required this.hireDate,
      required this.active,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || originalId != null) {
      map['original_id'] = Variable<String>(originalId);
    }
    if (!nullToAbsent || teamColor != null) {
      map['team_color'] = Variable<String>(teamColor);
    }
    if (!nullToAbsent || stationType != null) {
      map['station_type'] = Variable<String>(stationType);
    }
    map['hire_date'] = Variable<String>(hireDate);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ServersCompanion toCompanion(bool nullToAbsent) {
    return ServersCompanion(
      id: Value(id),
      name: Value(name),
      originalId: originalId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalId),
      teamColor: teamColor == null && nullToAbsent
          ? const Value.absent()
          : Value(teamColor),
      stationType: stationType == null && nullToAbsent
          ? const Value.absent()
          : Value(stationType),
      hireDate: Value(hireDate),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Server.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Server(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      originalId: serializer.fromJson<String?>(json['originalId']),
      teamColor: serializer.fromJson<String?>(json['teamColor']),
      stationType: serializer.fromJson<String?>(json['stationType']),
      hireDate: serializer.fromJson<String>(json['hireDate']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'originalId': serializer.toJson<String?>(originalId),
      'teamColor': serializer.toJson<String?>(teamColor),
      'stationType': serializer.toJson<String?>(stationType),
      'hireDate': serializer.toJson<String>(hireDate),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Server copyWith(
          {String? id,
          String? name,
          Value<String?> originalId = const Value.absent(),
          Value<String?> teamColor = const Value.absent(),
          Value<String?> stationType = const Value.absent(),
          String? hireDate,
          bool? active,
          String? createdAt,
          String? updatedAt}) =>
      Server(
        id: id ?? this.id,
        name: name ?? this.name,
        originalId: originalId.present ? originalId.value : this.originalId,
        teamColor: teamColor.present ? teamColor.value : this.teamColor,
        stationType: stationType.present ? stationType.value : this.stationType,
        hireDate: hireDate ?? this.hireDate,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Server copyWithCompanion(ServersCompanion data) {
    return Server(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      originalId:
          data.originalId.present ? data.originalId.value : this.originalId,
      teamColor: data.teamColor.present ? data.teamColor.value : this.teamColor,
      stationType:
          data.stationType.present ? data.stationType.value : this.stationType,
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
          ..write('teamColor: $teamColor, ')
          ..write('stationType: $stationType, ')
          ..write('hireDate: $hireDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, originalId, teamColor, stationType,
      hireDate, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Server &&
          other.id == this.id &&
          other.name == this.name &&
          other.originalId == this.originalId &&
          other.teamColor == this.teamColor &&
          other.stationType == this.stationType &&
          other.hireDate == this.hireDate &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ServersCompanion extends UpdateCompanion<Server> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> originalId;
  final Value<String?> teamColor;
  final Value<String?> stationType;
  final Value<String> hireDate;
  final Value<bool> active;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.originalId = const Value.absent(),
    this.teamColor = const Value.absent(),
    this.stationType = const Value.absent(),
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
    this.teamColor = const Value.absent(),
    this.stationType = const Value.absent(),
    required String hireDate,
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
    Expression<String>? teamColor,
    Expression<String>? stationType,
    Expression<String>? hireDate,
    Expression<bool>? active,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (originalId != null) 'original_id': originalId,
      if (teamColor != null) 'team_color': teamColor,
      if (stationType != null) 'station_type': stationType,
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
      Value<String?>? teamColor,
      Value<String?>? stationType,
      Value<String>? hireDate,
      Value<bool>? active,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return ServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      originalId: originalId ?? this.originalId,
      teamColor: teamColor ?? this.teamColor,
      stationType: stationType ?? this.stationType,
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
    if (teamColor.present) {
      map['team_color'] = Variable<String>(teamColor.value);
    }
    if (stationType.present) {
      map['station_type'] = Variable<String>(stationType.value);
    }
    if (hireDate.present) {
      map['hire_date'] = Variable<String>(hireDate.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
          ..write('teamColor: $teamColor, ')
          ..write('stationType: $stationType, ')
          ..write('hireDate: $hireDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftRecordsTable extends ShiftRecords
    with TableInfo<$ShiftRecordsTable, ShiftRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shiftTypeMeta =
      const VerificationMeta('shiftType');
  @override
  late final GeneratedColumn<String> shiftType = GeneratedColumn<String>(
      'shift_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
      'start_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _countsMeta = const VerificationMeta('counts');
  @override
  late final GeneratedColumn<String> counts = GeneratedColumn<String>(
      'counts', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pizookieCountsMeta =
      const VerificationMeta('pizookieCounts');
  @override
  late final GeneratedColumn<String> pizookieCounts = GeneratedColumn<String>(
      'pizookie_counts', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stationAssignmentsMeta =
      const VerificationMeta('stationAssignments');
  @override
  late final GeneratedColumn<String> stationAssignments =
      GeneratedColumn<String>('station_assignments', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sectionAssignmentsMeta =
      const VerificationMeta('sectionAssignments');
  @override
  late final GeneratedColumn<String> sectionAssignments =
      GeneratedColumn<String>('section_assignments', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        label,
        shiftType,
        startDate,
        counts,
        pizookieCounts,
        stationAssignments,
        sectionAssignments,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_records';
  @override
  VerificationContext validateIntegrity(Insertable<ShiftRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('shift_type')) {
      context.handle(_shiftTypeMeta,
          shiftType.isAcceptableOrUnknown(data['shift_type']!, _shiftTypeMeta));
    } else if (isInserting) {
      context.missing(_shiftTypeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('counts')) {
      context.handle(_countsMeta,
          counts.isAcceptableOrUnknown(data['counts']!, _countsMeta));
    } else if (isInserting) {
      context.missing(_countsMeta);
    }
    if (data.containsKey('pizookie_counts')) {
      context.handle(
          _pizookieCountsMeta,
          pizookieCounts.isAcceptableOrUnknown(
              data['pizookie_counts']!, _pizookieCountsMeta));
    }
    if (data.containsKey('station_assignments')) {
      context.handle(
          _stationAssignmentsMeta,
          stationAssignments.isAcceptableOrUnknown(
              data['station_assignments']!, _stationAssignmentsMeta));
    }
    if (data.containsKey('section_assignments')) {
      context.handle(
          _sectionAssignmentsMeta,
          sectionAssignments.isAcceptableOrUnknown(
              data['section_assignments']!, _sectionAssignmentsMeta));
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
  ShiftRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      shiftType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift_type'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_date'])!,
      counts: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counts'])!,
      pizookieCounts: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pizookie_counts']),
      stationAssignments: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}station_assignments']),
      sectionAssignments: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}section_assignments']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ShiftRecordsTable createAlias(String alias) {
    return $ShiftRecordsTable(attachedDatabase, alias);
  }
}

class ShiftRecord extends DataClass implements Insertable<ShiftRecord> {
  final String id;
  final String label;
  final String shiftType;
  final String startDate;
  final String counts;
  final String? pizookieCounts;
  final String? stationAssignments;
  final String? sectionAssignments;
  final String createdAt;
  const ShiftRecord(
      {required this.id,
      required this.label,
      required this.shiftType,
      required this.startDate,
      required this.counts,
      this.pizookieCounts,
      this.stationAssignments,
      this.sectionAssignments,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['shift_type'] = Variable<String>(shiftType);
    map['start_date'] = Variable<String>(startDate);
    map['counts'] = Variable<String>(counts);
    if (!nullToAbsent || pizookieCounts != null) {
      map['pizookie_counts'] = Variable<String>(pizookieCounts);
    }
    if (!nullToAbsent || stationAssignments != null) {
      map['station_assignments'] = Variable<String>(stationAssignments);
    }
    if (!nullToAbsent || sectionAssignments != null) {
      map['section_assignments'] = Variable<String>(sectionAssignments);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ShiftRecordsCompanion toCompanion(bool nullToAbsent) {
    return ShiftRecordsCompanion(
      id: Value(id),
      label: Value(label),
      shiftType: Value(shiftType),
      startDate: Value(startDate),
      counts: Value(counts),
      pizookieCounts: pizookieCounts == null && nullToAbsent
          ? const Value.absent()
          : Value(pizookieCounts),
      stationAssignments: stationAssignments == null && nullToAbsent
          ? const Value.absent()
          : Value(stationAssignments),
      sectionAssignments: sectionAssignments == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionAssignments),
      createdAt: Value(createdAt),
    );
  }

  factory ShiftRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRecord(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      shiftType: serializer.fromJson<String>(json['shiftType']),
      startDate: serializer.fromJson<String>(json['startDate']),
      counts: serializer.fromJson<String>(json['counts']),
      pizookieCounts: serializer.fromJson<String?>(json['pizookieCounts']),
      stationAssignments:
          serializer.fromJson<String?>(json['stationAssignments']),
      sectionAssignments:
          serializer.fromJson<String?>(json['sectionAssignments']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'shiftType': serializer.toJson<String>(shiftType),
      'startDate': serializer.toJson<String>(startDate),
      'counts': serializer.toJson<String>(counts),
      'pizookieCounts': serializer.toJson<String?>(pizookieCounts),
      'stationAssignments': serializer.toJson<String?>(stationAssignments),
      'sectionAssignments': serializer.toJson<String?>(sectionAssignments),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ShiftRecord copyWith(
          {String? id,
          String? label,
          String? shiftType,
          String? startDate,
          String? counts,
          Value<String?> pizookieCounts = const Value.absent(),
          Value<String?> stationAssignments = const Value.absent(),
          Value<String?> sectionAssignments = const Value.absent(),
          String? createdAt}) =>
      ShiftRecord(
        id: id ?? this.id,
        label: label ?? this.label,
        shiftType: shiftType ?? this.shiftType,
        startDate: startDate ?? this.startDate,
        counts: counts ?? this.counts,
        pizookieCounts:
            pizookieCounts.present ? pizookieCounts.value : this.pizookieCounts,
        stationAssignments: stationAssignments.present
            ? stationAssignments.value
            : this.stationAssignments,
        sectionAssignments: sectionAssignments.present
            ? sectionAssignments.value
            : this.sectionAssignments,
        createdAt: createdAt ?? this.createdAt,
      );
  ShiftRecord copyWithCompanion(ShiftRecordsCompanion data) {
    return ShiftRecord(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      shiftType: data.shiftType.present ? data.shiftType.value : this.shiftType,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      counts: data.counts.present ? data.counts.value : this.counts,
      pizookieCounts: data.pizookieCounts.present
          ? data.pizookieCounts.value
          : this.pizookieCounts,
      stationAssignments: data.stationAssignments.present
          ? data.stationAssignments.value
          : this.stationAssignments,
      sectionAssignments: data.sectionAssignments.present
          ? data.sectionAssignments.value
          : this.sectionAssignments,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRecord(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('shiftType: $shiftType, ')
          ..write('startDate: $startDate, ')
          ..write('counts: $counts, ')
          ..write('pizookieCounts: $pizookieCounts, ')
          ..write('stationAssignments: $stationAssignments, ')
          ..write('sectionAssignments: $sectionAssignments, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, shiftType, startDate, counts,
      pizookieCounts, stationAssignments, sectionAssignments, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRecord &&
          other.id == this.id &&
          other.label == this.label &&
          other.shiftType == this.shiftType &&
          other.startDate == this.startDate &&
          other.counts == this.counts &&
          other.pizookieCounts == this.pizookieCounts &&
          other.stationAssignments == this.stationAssignments &&
          other.sectionAssignments == this.sectionAssignments &&
          other.createdAt == this.createdAt);
}

class ShiftRecordsCompanion extends UpdateCompanion<ShiftRecord> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> shiftType;
  final Value<String> startDate;
  final Value<String> counts;
  final Value<String?> pizookieCounts;
  final Value<String?> stationAssignments;
  final Value<String?> sectionAssignments;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ShiftRecordsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.shiftType = const Value.absent(),
    this.startDate = const Value.absent(),
    this.counts = const Value.absent(),
    this.pizookieCounts = const Value.absent(),
    this.stationAssignments = const Value.absent(),
    this.sectionAssignments = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftRecordsCompanion.insert({
    required String id,
    required String label,
    required String shiftType,
    required String startDate,
    required String counts,
    this.pizookieCounts = const Value.absent(),
    this.stationAssignments = const Value.absent(),
    this.sectionAssignments = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        label = Value(label),
        shiftType = Value(shiftType),
        startDate = Value(startDate),
        counts = Value(counts);
  static Insertable<ShiftRecord> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? shiftType,
    Expression<String>? startDate,
    Expression<String>? counts,
    Expression<String>? pizookieCounts,
    Expression<String>? stationAssignments,
    Expression<String>? sectionAssignments,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (shiftType != null) 'shift_type': shiftType,
      if (startDate != null) 'start_date': startDate,
      if (counts != null) 'counts': counts,
      if (pizookieCounts != null) 'pizookie_counts': pizookieCounts,
      if (stationAssignments != null) 'station_assignments': stationAssignments,
      if (sectionAssignments != null) 'section_assignments': sectionAssignments,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? label,
      Value<String>? shiftType,
      Value<String>? startDate,
      Value<String>? counts,
      Value<String?>? pizookieCounts,
      Value<String?>? stationAssignments,
      Value<String?>? sectionAssignments,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return ShiftRecordsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      shiftType: shiftType ?? this.shiftType,
      startDate: startDate ?? this.startDate,
      counts: counts ?? this.counts,
      pizookieCounts: pizookieCounts ?? this.pizookieCounts,
      stationAssignments: stationAssignments ?? this.stationAssignments,
      sectionAssignments: sectionAssignments ?? this.sectionAssignments,
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
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (shiftType.present) {
      map['shift_type'] = Variable<String>(shiftType.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (counts.present) {
      map['counts'] = Variable<String>(counts.value);
    }
    if (pizookieCounts.present) {
      map['pizookie_counts'] = Variable<String>(pizookieCounts.value);
    }
    if (stationAssignments.present) {
      map['station_assignments'] = Variable<String>(stationAssignments.value);
    }
    if (sectionAssignments.present) {
      map['section_assignments'] = Variable<String>(sectionAssignments.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRecordsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('shiftType: $shiftType, ')
          ..write('startDate: $startDate, ')
          ..write('counts: $counts, ')
          ..write('pizookieCounts: $pizookieCounts, ')
          ..write('stationAssignments: $stationAssignments, ')
          ..write('sectionAssignments: $sectionAssignments, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServerProfilesTable extends ServerProfiles
    with TableInfo<$ServerProfilesTable, ServerProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _birthdayMeta =
      const VerificationMeta('birthday');
  @override
  late final GeneratedColumn<String> birthday = GeneratedColumn<String>(
      'birthday', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hireDateMeta =
      const VerificationMeta('hireDate');
  @override
  late final GeneratedColumn<String> hireDate = GeneratedColumn<String>(
      'hire_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teamColorMeta =
      const VerificationMeta('teamColor');
  @override
  late final GeneratedColumn<String> teamColor = GeneratedColumn<String>(
      'team_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stationTypeMeta =
      const VerificationMeta('stationType');
  @override
  late final GeneratedColumn<String> stationType = GeneratedColumn<String>(
      'station_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _performanceDataMeta =
      const VerificationMeta('performanceData');
  @override
  late final GeneratedColumn<String> performanceData = GeneratedColumn<String>(
      'performance_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [
        serverId,
        avatarPath,
        birthday,
        hireDate,
        teamColor,
        stationType,
        performanceData,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<ServerProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('birthday')) {
      context.handle(_birthdayMeta,
          birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta));
    }
    if (data.containsKey('hire_date')) {
      context.handle(_hireDateMeta,
          hireDate.isAcceptableOrUnknown(data['hire_date']!, _hireDateMeta));
    }
    if (data.containsKey('team_color')) {
      context.handle(_teamColorMeta,
          teamColor.isAcceptableOrUnknown(data['team_color']!, _teamColorMeta));
    }
    if (data.containsKey('station_type')) {
      context.handle(
          _stationTypeMeta,
          stationType.isAcceptableOrUnknown(
              data['station_type']!, _stationTypeMeta));
    }
    if (data.containsKey('performance_data')) {
      context.handle(
          _performanceDataMeta,
          performanceData.isAcceptableOrUnknown(
              data['performance_data']!, _performanceDataMeta));
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
  Set<GeneratedColumn> get $primaryKey => {serverId};
  @override
  ServerProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerProfile(
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birthday']),
      hireDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hire_date']),
      teamColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_color']),
      stationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}station_type']),
      performanceData: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}performance_data']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ServerProfilesTable createAlias(String alias) {
    return $ServerProfilesTable(attachedDatabase, alias);
  }
}

class ServerProfile extends DataClass implements Insertable<ServerProfile> {
  final String serverId;
  final String? avatarPath;
  final String? birthday;
  final String? hireDate;
  final String? teamColor;
  final String? stationType;
  final String? performanceData;
  final String createdAt;
  final String updatedAt;
  const ServerProfile(
      {required this.serverId,
      this.avatarPath,
      this.birthday,
      this.hireDate,
      this.teamColor,
      this.stationType,
      this.performanceData,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<String>(birthday);
    }
    if (!nullToAbsent || hireDate != null) {
      map['hire_date'] = Variable<String>(hireDate);
    }
    if (!nullToAbsent || teamColor != null) {
      map['team_color'] = Variable<String>(teamColor);
    }
    if (!nullToAbsent || stationType != null) {
      map['station_type'] = Variable<String>(stationType);
    }
    if (!nullToAbsent || performanceData != null) {
      map['performance_data'] = Variable<String>(performanceData);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ServerProfilesCompanion toCompanion(bool nullToAbsent) {
    return ServerProfilesCompanion(
      serverId: Value(serverId),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      hireDate: hireDate == null && nullToAbsent
          ? const Value.absent()
          : Value(hireDate),
      teamColor: teamColor == null && nullToAbsent
          ? const Value.absent()
          : Value(teamColor),
      stationType: stationType == null && nullToAbsent
          ? const Value.absent()
          : Value(stationType),
      performanceData: performanceData == null && nullToAbsent
          ? const Value.absent()
          : Value(performanceData),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ServerProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerProfile(
      serverId: serializer.fromJson<String>(json['serverId']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      birthday: serializer.fromJson<String?>(json['birthday']),
      hireDate: serializer.fromJson<String?>(json['hireDate']),
      teamColor: serializer.fromJson<String?>(json['teamColor']),
      stationType: serializer.fromJson<String?>(json['stationType']),
      performanceData: serializer.fromJson<String?>(json['performanceData']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'birthday': serializer.toJson<String?>(birthday),
      'hireDate': serializer.toJson<String?>(hireDate),
      'teamColor': serializer.toJson<String?>(teamColor),
      'stationType': serializer.toJson<String?>(stationType),
      'performanceData': serializer.toJson<String?>(performanceData),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  ServerProfile copyWith(
          {String? serverId,
          Value<String?> avatarPath = const Value.absent(),
          Value<String?> birthday = const Value.absent(),
          Value<String?> hireDate = const Value.absent(),
          Value<String?> teamColor = const Value.absent(),
          Value<String?> stationType = const Value.absent(),
          Value<String?> performanceData = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      ServerProfile(
        serverId: serverId ?? this.serverId,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        birthday: birthday.present ? birthday.value : this.birthday,
        hireDate: hireDate.present ? hireDate.value : this.hireDate,
        teamColor: teamColor.present ? teamColor.value : this.teamColor,
        stationType: stationType.present ? stationType.value : this.stationType,
        performanceData: performanceData.present
            ? performanceData.value
            : this.performanceData,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ServerProfile copyWithCompanion(ServerProfilesCompanion data) {
    return ServerProfile(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      hireDate: data.hireDate.present ? data.hireDate.value : this.hireDate,
      teamColor: data.teamColor.present ? data.teamColor.value : this.teamColor,
      stationType:
          data.stationType.present ? data.stationType.value : this.stationType,
      performanceData: data.performanceData.present
          ? data.performanceData.value
          : this.performanceData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerProfile(')
          ..write('serverId: $serverId, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('birthday: $birthday, ')
          ..write('hireDate: $hireDate, ')
          ..write('teamColor: $teamColor, ')
          ..write('stationType: $stationType, ')
          ..write('performanceData: $performanceData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, avatarPath, birthday, hireDate,
      teamColor, stationType, performanceData, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerProfile &&
          other.serverId == this.serverId &&
          other.avatarPath == this.avatarPath &&
          other.birthday == this.birthday &&
          other.hireDate == this.hireDate &&
          other.teamColor == this.teamColor &&
          other.stationType == this.stationType &&
          other.performanceData == this.performanceData &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ServerProfilesCompanion extends UpdateCompanion<ServerProfile> {
  final Value<String> serverId;
  final Value<String?> avatarPath;
  final Value<String?> birthday;
  final Value<String?> hireDate;
  final Value<String?> teamColor;
  final Value<String?> stationType;
  final Value<String?> performanceData;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ServerProfilesCompanion({
    this.serverId = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.birthday = const Value.absent(),
    this.hireDate = const Value.absent(),
    this.teamColor = const Value.absent(),
    this.stationType = const Value.absent(),
    this.performanceData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerProfilesCompanion.insert({
    required String serverId,
    this.avatarPath = const Value.absent(),
    this.birthday = const Value.absent(),
    this.hireDate = const Value.absent(),
    this.teamColor = const Value.absent(),
    this.stationType = const Value.absent(),
    this.performanceData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId);
  static Insertable<ServerProfile> custom({
    Expression<String>? serverId,
    Expression<String>? avatarPath,
    Expression<String>? birthday,
    Expression<String>? hireDate,
    Expression<String>? teamColor,
    Expression<String>? stationType,
    Expression<String>? performanceData,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (birthday != null) 'birthday': birthday,
      if (hireDate != null) 'hire_date': hireDate,
      if (teamColor != null) 'team_color': teamColor,
      if (stationType != null) 'station_type': stationType,
      if (performanceData != null) 'performance_data': performanceData,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServerProfilesCompanion copyWith(
      {Value<String>? serverId,
      Value<String?>? avatarPath,
      Value<String?>? birthday,
      Value<String?>? hireDate,
      Value<String?>? teamColor,
      Value<String?>? stationType,
      Value<String?>? performanceData,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return ServerProfilesCompanion(
      serverId: serverId ?? this.serverId,
      avatarPath: avatarPath ?? this.avatarPath,
      birthday: birthday ?? this.birthday,
      hireDate: hireDate ?? this.hireDate,
      teamColor: teamColor ?? this.teamColor,
      stationType: stationType ?? this.stationType,
      performanceData: performanceData ?? this.performanceData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<String>(birthday.value);
    }
    if (hireDate.present) {
      map['hire_date'] = Variable<String>(hireDate.value);
    }
    if (teamColor.present) {
      map['team_color'] = Variable<String>(teamColor.value);
    }
    if (stationType.present) {
      map['station_type'] = Variable<String>(stationType.value);
    }
    if (performanceData.present) {
      map['performance_data'] = Variable<String>(performanceData.value);
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
    return (StringBuffer('ServerProfilesCompanion(')
          ..write('serverId: $serverId, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('birthday: $birthday, ')
          ..write('hireDate: $hireDate, ')
          ..write('teamColor: $teamColor, ')
          ..write('stationType: $stationType, ')
          ..write('performanceData: $performanceData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NPSFeedbackTable extends NPSFeedback
    with TableInfo<$NPSFeedbackTable, NPSFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NPSFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _feedbackTypeMeta =
      const VerificationMeta('feedbackType');
  @override
  late final GeneratedColumn<String> feedbackType = GeneratedColumn<String>(
      'feedback_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _feedbackDateMeta =
      const VerificationMeta('feedbackDate');
  @override
  late final GeneratedColumn<String> feedbackDate = GeneratedColumn<String>(
      'feedback_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _salesAmountMeta =
      const VerificationMeta('salesAmount');
  @override
  late final GeneratedColumn<double> salesAmount = GeneratedColumn<double>(
      'sales_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _tableNumberMeta =
      const VerificationMeta('tableNumber');
  @override
  late final GeneratedColumn<int> tableNumber = GeneratedColumn<int>(
      'table_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _shiftPeriodMeta =
      const VerificationMeta('shiftPeriod');
  @override
  late final GeneratedColumn<String> shiftPeriod = GeneratedColumn<String>(
      'shift_period', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _guestCountMeta =
      const VerificationMeta('guestCount');
  @override
  late final GeneratedColumn<int> guestCount = GeneratedColumn<int>(
      'guest_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
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
  static const String $name = 'n_p_s_feedback';
  @override
  VerificationContext validateIntegrity(Insertable<NPSFeedbackData> instance,
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
  NPSFeedbackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NPSFeedbackData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      feedbackType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feedback_type'])!,
      feedbackDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feedback_date'])!,
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
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NPSFeedbackTable createAlias(String alias) {
    return $NPSFeedbackTable(attachedDatabase, alias);
  }
}

class NPSFeedbackData extends DataClass implements Insertable<NPSFeedbackData> {
  final int id;
  final String serverId;
  final String feedbackType;
  final String feedbackDate;
  final double? salesAmount;
  final int? tableNumber;
  final String? shiftPeriod;
  final int? guestCount;
  final String? notes;
  final String createdAt;
  const NPSFeedbackData(
      {required this.id,
      required this.serverId,
      required this.feedbackType,
      required this.feedbackDate,
      this.salesAmount,
      this.tableNumber,
      this.shiftPeriod,
      this.guestCount,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['feedback_type'] = Variable<String>(feedbackType);
    map['feedback_date'] = Variable<String>(feedbackDate);
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
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  NPSFeedbackCompanion toCompanion(bool nullToAbsent) {
    return NPSFeedbackCompanion(
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
      createdAt: Value(createdAt),
    );
  }

  factory NPSFeedbackData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NPSFeedbackData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      feedbackType: serializer.fromJson<String>(json['feedbackType']),
      feedbackDate: serializer.fromJson<String>(json['feedbackDate']),
      salesAmount: serializer.fromJson<double?>(json['salesAmount']),
      tableNumber: serializer.fromJson<int?>(json['tableNumber']),
      shiftPeriod: serializer.fromJson<String?>(json['shiftPeriod']),
      guestCount: serializer.fromJson<int?>(json['guestCount']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'feedbackType': serializer.toJson<String>(feedbackType),
      'feedbackDate': serializer.toJson<String>(feedbackDate),
      'salesAmount': serializer.toJson<double?>(salesAmount),
      'tableNumber': serializer.toJson<int?>(tableNumber),
      'shiftPeriod': serializer.toJson<String?>(shiftPeriod),
      'guestCount': serializer.toJson<int?>(guestCount),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  NPSFeedbackData copyWith(
          {int? id,
          String? serverId,
          String? feedbackType,
          String? feedbackDate,
          Value<double?> salesAmount = const Value.absent(),
          Value<int?> tableNumber = const Value.absent(),
          Value<String?> shiftPeriod = const Value.absent(),
          Value<int?> guestCount = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? createdAt}) =>
      NPSFeedbackData(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        feedbackType: feedbackType ?? this.feedbackType,
        feedbackDate: feedbackDate ?? this.feedbackDate,
        salesAmount: salesAmount.present ? salesAmount.value : this.salesAmount,
        tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
        shiftPeriod: shiftPeriod.present ? shiftPeriod.value : this.shiftPeriod,
        guestCount: guestCount.present ? guestCount.value : this.guestCount,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  NPSFeedbackData copyWithCompanion(NPSFeedbackCompanion data) {
    return NPSFeedbackData(
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
    return (StringBuffer('NPSFeedbackData(')
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
      (other is NPSFeedbackData &&
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

class NPSFeedbackCompanion extends UpdateCompanion<NPSFeedbackData> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> feedbackType;
  final Value<String> feedbackDate;
  final Value<double?> salesAmount;
  final Value<int?> tableNumber;
  final Value<String?> shiftPeriod;
  final Value<int?> guestCount;
  final Value<String?> notes;
  final Value<String> createdAt;
  const NPSFeedbackCompanion({
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
  NPSFeedbackCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String feedbackType,
    required String feedbackDate,
    this.salesAmount = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.shiftPeriod = const Value.absent(),
    this.guestCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : serverId = Value(serverId),
        feedbackType = Value(feedbackType),
        feedbackDate = Value(feedbackDate);
  static Insertable<NPSFeedbackData> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? feedbackType,
    Expression<String>? feedbackDate,
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

  NPSFeedbackCompanion copyWith(
      {Value<int>? id,
      Value<String>? serverId,
      Value<String>? feedbackType,
      Value<String>? feedbackDate,
      Value<double?>? salesAmount,
      Value<int?>? tableNumber,
      Value<String?>? shiftPeriod,
      Value<int?>? guestCount,
      Value<String?>? notes,
      Value<String>? createdAt}) {
    return NPSFeedbackCompanion(
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
      map['feedback_date'] = Variable<String>(feedbackDate.value);
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
    return (StringBuffer('NPSFeedbackCompanion(')
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

class $NPSMonthlyReportsTable extends NPSMonthlyReports
    with TableInfo<$NPSMonthlyReportsTable, NPSMonthlyReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NPSMonthlyReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthYearMeta =
      const VerificationMeta('monthYear');
  @override
  late final GeneratedColumn<String> monthYear = GeneratedColumn<String>(
      'month_year', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _allTimeNpsPercentageMeta =
      const VerificationMeta('allTimeNpsPercentage');
  @override
  late final GeneratedColumn<double> allTimeNpsPercentage =
      GeneratedColumn<double>('all_time_nps_percentage', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _threeMonthNpsPercentageMeta =
      const VerificationMeta('threeMonthNpsPercentage');
  @override
  late final GeneratedColumn<double> threeMonthNpsPercentage =
      GeneratedColumn<double>('three_month_nps_percentage', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _oneMonthNpsPercentageMeta =
      const VerificationMeta('oneMonthNpsPercentage');
  @override
  late final GeneratedColumn<double> oneMonthNpsPercentage =
      GeneratedColumn<double>('one_month_nps_percentage', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _allTimeSalesMeta =
      const VerificationMeta('allTimeSales');
  @override
  late final GeneratedColumn<double> allTimeSales = GeneratedColumn<double>(
      'all_time_sales', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _allTimeTableCountMeta =
      const VerificationMeta('allTimeTableCount');
  @override
  late final GeneratedColumn<int> allTimeTableCount = GeneratedColumn<int>(
      'all_time_table_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _monthFeedbackYesMeta =
      const VerificationMeta('monthFeedbackYes');
  @override
  late final GeneratedColumn<int> monthFeedbackYes = GeneratedColumn<int>(
      'month_feedback_yes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _monthFeedbackMaybeMeta =
      const VerificationMeta('monthFeedbackMaybe');
  @override
  late final GeneratedColumn<int> monthFeedbackMaybe = GeneratedColumn<int>(
      'month_feedback_maybe', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _monthFeedbackNoMeta =
      const VerificationMeta('monthFeedbackNo');
  @override
  late final GeneratedColumn<int> monthFeedbackNo = GeneratedColumn<int>(
      'month_feedback_no', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _threeMonthFeedbackYesMeta =
      const VerificationMeta('threeMonthFeedbackYes');
  @override
  late final GeneratedColumn<int> threeMonthFeedbackYes = GeneratedColumn<int>(
      'three_month_feedback_yes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _threeMonthFeedbackMaybeMeta =
      const VerificationMeta('threeMonthFeedbackMaybe');
  @override
  late final GeneratedColumn<int> threeMonthFeedbackMaybe =
      GeneratedColumn<int>('three_month_feedback_maybe', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _threeMonthFeedbackNoMeta =
      const VerificationMeta('threeMonthFeedbackNo');
  @override
  late final GeneratedColumn<int> threeMonthFeedbackNo = GeneratedColumn<int>(
      'three_month_feedback_no', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _allTimeFeedbackYesMeta =
      const VerificationMeta('allTimeFeedbackYes');
  @override
  late final GeneratedColumn<int> allTimeFeedbackYes = GeneratedColumn<int>(
      'all_time_feedback_yes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _allTimeFeedbackMaybeMeta =
      const VerificationMeta('allTimeFeedbackMaybe');
  @override
  late final GeneratedColumn<int> allTimeFeedbackMaybe = GeneratedColumn<int>(
      'all_time_feedback_maybe', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _allTimeFeedbackNoMeta =
      const VerificationMeta('allTimeFeedbackNo');
  @override
  late final GeneratedColumn<int> allTimeFeedbackNo = GeneratedColumn<int>(
      'all_time_feedback_no', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<String> generatedAt = GeneratedColumn<String>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  static const VerificationMeta _dataAsOfDateMeta =
      const VerificationMeta('dataAsOfDate');
  @override
  late final GeneratedColumn<String> dataAsOfDate = GeneratedColumn<String>(
      'data_as_of_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        monthYear,
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
  static const String $name = 'n_p_s_monthly_reports';
  @override
  VerificationContext validateIntegrity(Insertable<NPSMonthlyReport> instance,
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
    if (data.containsKey('month_year')) {
      context.handle(_monthYearMeta,
          monthYear.isAcceptableOrUnknown(data['month_year']!, _monthYearMeta));
    } else if (isInserting) {
      context.missing(_monthYearMeta);
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
        {serverId, monthYear},
      ];
  @override
  NPSMonthlyReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NPSMonthlyReport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      monthYear: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_year'])!,
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
          .read(DriftSqlType.double, data['${effectivePrefix}all_time_sales'])!,
      allTimeTableCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_table_count'])!,
      monthFeedbackYes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}month_feedback_yes'])!,
      monthFeedbackMaybe: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}month_feedback_maybe'])!,
      monthFeedbackNo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month_feedback_no'])!,
      threeMonthFeedbackYes: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}three_month_feedback_yes'])!,
      threeMonthFeedbackMaybe: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}three_month_feedback_maybe'])!,
      threeMonthFeedbackNo: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}three_month_feedback_no'])!,
      allTimeFeedbackYes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_feedback_yes'])!,
      allTimeFeedbackMaybe: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_feedback_maybe'])!,
      allTimeFeedbackNo: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}all_time_feedback_no'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}generated_at'])!,
      dataAsOfDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_as_of_date'])!,
    );
  }

  @override
  $NPSMonthlyReportsTable createAlias(String alias) {
    return $NPSMonthlyReportsTable(attachedDatabase, alias);
  }
}

class NPSMonthlyReport extends DataClass
    implements Insertable<NPSMonthlyReport> {
  final int id;
  final String serverId;
  final String monthYear;
  final double? allTimeNpsPercentage;
  final double? threeMonthNpsPercentage;
  final double? oneMonthNpsPercentage;
  final double allTimeSales;
  final int allTimeTableCount;
  final int monthFeedbackYes;
  final int monthFeedbackMaybe;
  final int monthFeedbackNo;
  final int threeMonthFeedbackYes;
  final int threeMonthFeedbackMaybe;
  final int threeMonthFeedbackNo;
  final int allTimeFeedbackYes;
  final int allTimeFeedbackMaybe;
  final int allTimeFeedbackNo;
  final String generatedAt;
  final String dataAsOfDate;
  const NPSMonthlyReport(
      {required this.id,
      required this.serverId,
      required this.monthYear,
      this.allTimeNpsPercentage,
      this.threeMonthNpsPercentage,
      this.oneMonthNpsPercentage,
      required this.allTimeSales,
      required this.allTimeTableCount,
      required this.monthFeedbackYes,
      required this.monthFeedbackMaybe,
      required this.monthFeedbackNo,
      required this.threeMonthFeedbackYes,
      required this.threeMonthFeedbackMaybe,
      required this.threeMonthFeedbackNo,
      required this.allTimeFeedbackYes,
      required this.allTimeFeedbackMaybe,
      required this.allTimeFeedbackNo,
      required this.generatedAt,
      required this.dataAsOfDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['month_year'] = Variable<String>(monthYear);
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
    map['all_time_sales'] = Variable<double>(allTimeSales);
    map['all_time_table_count'] = Variable<int>(allTimeTableCount);
    map['month_feedback_yes'] = Variable<int>(monthFeedbackYes);
    map['month_feedback_maybe'] = Variable<int>(monthFeedbackMaybe);
    map['month_feedback_no'] = Variable<int>(monthFeedbackNo);
    map['three_month_feedback_yes'] = Variable<int>(threeMonthFeedbackYes);
    map['three_month_feedback_maybe'] = Variable<int>(threeMonthFeedbackMaybe);
    map['three_month_feedback_no'] = Variable<int>(threeMonthFeedbackNo);
    map['all_time_feedback_yes'] = Variable<int>(allTimeFeedbackYes);
    map['all_time_feedback_maybe'] = Variable<int>(allTimeFeedbackMaybe);
    map['all_time_feedback_no'] = Variable<int>(allTimeFeedbackNo);
    map['generated_at'] = Variable<String>(generatedAt);
    map['data_as_of_date'] = Variable<String>(dataAsOfDate);
    return map;
  }

  NPSMonthlyReportsCompanion toCompanion(bool nullToAbsent) {
    return NPSMonthlyReportsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      monthYear: Value(monthYear),
      allTimeNpsPercentage: allTimeNpsPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(allTimeNpsPercentage),
      threeMonthNpsPercentage: threeMonthNpsPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(threeMonthNpsPercentage),
      oneMonthNpsPercentage: oneMonthNpsPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(oneMonthNpsPercentage),
      allTimeSales: Value(allTimeSales),
      allTimeTableCount: Value(allTimeTableCount),
      monthFeedbackYes: Value(monthFeedbackYes),
      monthFeedbackMaybe: Value(monthFeedbackMaybe),
      monthFeedbackNo: Value(monthFeedbackNo),
      threeMonthFeedbackYes: Value(threeMonthFeedbackYes),
      threeMonthFeedbackMaybe: Value(threeMonthFeedbackMaybe),
      threeMonthFeedbackNo: Value(threeMonthFeedbackNo),
      allTimeFeedbackYes: Value(allTimeFeedbackYes),
      allTimeFeedbackMaybe: Value(allTimeFeedbackMaybe),
      allTimeFeedbackNo: Value(allTimeFeedbackNo),
      generatedAt: Value(generatedAt),
      dataAsOfDate: Value(dataAsOfDate),
    );
  }

  factory NPSMonthlyReport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NPSMonthlyReport(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      monthYear: serializer.fromJson<String>(json['monthYear']),
      allTimeNpsPercentage:
          serializer.fromJson<double?>(json['allTimeNpsPercentage']),
      threeMonthNpsPercentage:
          serializer.fromJson<double?>(json['threeMonthNpsPercentage']),
      oneMonthNpsPercentage:
          serializer.fromJson<double?>(json['oneMonthNpsPercentage']),
      allTimeSales: serializer.fromJson<double>(json['allTimeSales']),
      allTimeTableCount: serializer.fromJson<int>(json['allTimeTableCount']),
      monthFeedbackYes: serializer.fromJson<int>(json['monthFeedbackYes']),
      monthFeedbackMaybe: serializer.fromJson<int>(json['monthFeedbackMaybe']),
      monthFeedbackNo: serializer.fromJson<int>(json['monthFeedbackNo']),
      threeMonthFeedbackYes:
          serializer.fromJson<int>(json['threeMonthFeedbackYes']),
      threeMonthFeedbackMaybe:
          serializer.fromJson<int>(json['threeMonthFeedbackMaybe']),
      threeMonthFeedbackNo:
          serializer.fromJson<int>(json['threeMonthFeedbackNo']),
      allTimeFeedbackYes: serializer.fromJson<int>(json['allTimeFeedbackYes']),
      allTimeFeedbackMaybe:
          serializer.fromJson<int>(json['allTimeFeedbackMaybe']),
      allTimeFeedbackNo: serializer.fromJson<int>(json['allTimeFeedbackNo']),
      generatedAt: serializer.fromJson<String>(json['generatedAt']),
      dataAsOfDate: serializer.fromJson<String>(json['dataAsOfDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'monthYear': serializer.toJson<String>(monthYear),
      'allTimeNpsPercentage': serializer.toJson<double?>(allTimeNpsPercentage),
      'threeMonthNpsPercentage':
          serializer.toJson<double?>(threeMonthNpsPercentage),
      'oneMonthNpsPercentage':
          serializer.toJson<double?>(oneMonthNpsPercentage),
      'allTimeSales': serializer.toJson<double>(allTimeSales),
      'allTimeTableCount': serializer.toJson<int>(allTimeTableCount),
      'monthFeedbackYes': serializer.toJson<int>(monthFeedbackYes),
      'monthFeedbackMaybe': serializer.toJson<int>(monthFeedbackMaybe),
      'monthFeedbackNo': serializer.toJson<int>(monthFeedbackNo),
      'threeMonthFeedbackYes': serializer.toJson<int>(threeMonthFeedbackYes),
      'threeMonthFeedbackMaybe':
          serializer.toJson<int>(threeMonthFeedbackMaybe),
      'threeMonthFeedbackNo': serializer.toJson<int>(threeMonthFeedbackNo),
      'allTimeFeedbackYes': serializer.toJson<int>(allTimeFeedbackYes),
      'allTimeFeedbackMaybe': serializer.toJson<int>(allTimeFeedbackMaybe),
      'allTimeFeedbackNo': serializer.toJson<int>(allTimeFeedbackNo),
      'generatedAt': serializer.toJson<String>(generatedAt),
      'dataAsOfDate': serializer.toJson<String>(dataAsOfDate),
    };
  }

  NPSMonthlyReport copyWith(
          {int? id,
          String? serverId,
          String? monthYear,
          Value<double?> allTimeNpsPercentage = const Value.absent(),
          Value<double?> threeMonthNpsPercentage = const Value.absent(),
          Value<double?> oneMonthNpsPercentage = const Value.absent(),
          double? allTimeSales,
          int? allTimeTableCount,
          int? monthFeedbackYes,
          int? monthFeedbackMaybe,
          int? monthFeedbackNo,
          int? threeMonthFeedbackYes,
          int? threeMonthFeedbackMaybe,
          int? threeMonthFeedbackNo,
          int? allTimeFeedbackYes,
          int? allTimeFeedbackMaybe,
          int? allTimeFeedbackNo,
          String? generatedAt,
          String? dataAsOfDate}) =>
      NPSMonthlyReport(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        monthYear: monthYear ?? this.monthYear,
        allTimeNpsPercentage: allTimeNpsPercentage.present
            ? allTimeNpsPercentage.value
            : this.allTimeNpsPercentage,
        threeMonthNpsPercentage: threeMonthNpsPercentage.present
            ? threeMonthNpsPercentage.value
            : this.threeMonthNpsPercentage,
        oneMonthNpsPercentage: oneMonthNpsPercentage.present
            ? oneMonthNpsPercentage.value
            : this.oneMonthNpsPercentage,
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
  NPSMonthlyReport copyWithCompanion(NPSMonthlyReportsCompanion data) {
    return NPSMonthlyReport(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      monthYear: data.monthYear.present ? data.monthYear.value : this.monthYear,
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
    return (StringBuffer('NPSMonthlyReport(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('monthYear: $monthYear, ')
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
      monthYear,
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
      (other is NPSMonthlyReport &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.monthYear == this.monthYear &&
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

class NPSMonthlyReportsCompanion extends UpdateCompanion<NPSMonthlyReport> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> monthYear;
  final Value<double?> allTimeNpsPercentage;
  final Value<double?> threeMonthNpsPercentage;
  final Value<double?> oneMonthNpsPercentage;
  final Value<double> allTimeSales;
  final Value<int> allTimeTableCount;
  final Value<int> monthFeedbackYes;
  final Value<int> monthFeedbackMaybe;
  final Value<int> monthFeedbackNo;
  final Value<int> threeMonthFeedbackYes;
  final Value<int> threeMonthFeedbackMaybe;
  final Value<int> threeMonthFeedbackNo;
  final Value<int> allTimeFeedbackYes;
  final Value<int> allTimeFeedbackMaybe;
  final Value<int> allTimeFeedbackNo;
  final Value<String> generatedAt;
  final Value<String> dataAsOfDate;
  const NPSMonthlyReportsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.monthYear = const Value.absent(),
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
  NPSMonthlyReportsCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String monthYear,
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
    required String dataAsOfDate,
  })  : serverId = Value(serverId),
        monthYear = Value(monthYear),
        dataAsOfDate = Value(dataAsOfDate);
  static Insertable<NPSMonthlyReport> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? monthYear,
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
    Expression<String>? dataAsOfDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (monthYear != null) 'month_year': monthYear,
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

  NPSMonthlyReportsCompanion copyWith(
      {Value<int>? id,
      Value<String>? serverId,
      Value<String>? monthYear,
      Value<double?>? allTimeNpsPercentage,
      Value<double?>? threeMonthNpsPercentage,
      Value<double?>? oneMonthNpsPercentage,
      Value<double>? allTimeSales,
      Value<int>? allTimeTableCount,
      Value<int>? monthFeedbackYes,
      Value<int>? monthFeedbackMaybe,
      Value<int>? monthFeedbackNo,
      Value<int>? threeMonthFeedbackYes,
      Value<int>? threeMonthFeedbackMaybe,
      Value<int>? threeMonthFeedbackNo,
      Value<int>? allTimeFeedbackYes,
      Value<int>? allTimeFeedbackMaybe,
      Value<int>? allTimeFeedbackNo,
      Value<String>? generatedAt,
      Value<String>? dataAsOfDate}) {
    return NPSMonthlyReportsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      monthYear: monthYear ?? this.monthYear,
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
    if (monthYear.present) {
      map['month_year'] = Variable<String>(monthYear.value);
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
      map['data_as_of_date'] = Variable<String>(dataAsOfDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NPSMonthlyReportsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('monthYear: $monthYear, ')
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

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final String updatedAt;
  const AppSetting(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, String? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PerformanceDataTable extends PerformanceData
    with TableInfo<$PerformanceDataTable, PerformanceDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PerformanceDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataTypeMeta =
      const VerificationMeta('dataType');
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
      'data_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataContentMeta =
      const VerificationMeta('dataContent');
  @override
  late final GeneratedColumn<String> dataContent = GeneratedColumn<String>(
      'data_content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, serverId, dataType, dataContent, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'performance_data';
  @override
  VerificationContext validateIntegrity(
      Insertable<PerformanceDataData> instance,
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
    if (data.containsKey('data_type')) {
      context.handle(_dataTypeMeta,
          dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta));
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('data_content')) {
      context.handle(
          _dataContentMeta,
          dataContent.isAcceptableOrUnknown(
              data['data_content']!, _dataContentMeta));
    } else if (isInserting) {
      context.missing(_dataContentMeta);
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
  PerformanceDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PerformanceDataData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      dataType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_type'])!,
      dataContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PerformanceDataTable createAlias(String alias) {
    return $PerformanceDataTable(attachedDatabase, alias);
  }
}

class PerformanceDataData extends DataClass
    implements Insertable<PerformanceDataData> {
  final int id;
  final String serverId;
  final String dataType;
  final String dataContent;
  final String createdAt;
  const PerformanceDataData(
      {required this.id,
      required this.serverId,
      required this.dataType,
      required this.dataContent,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['data_type'] = Variable<String>(dataType);
    map['data_content'] = Variable<String>(dataContent);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PerformanceDataCompanion toCompanion(bool nullToAbsent) {
    return PerformanceDataCompanion(
      id: Value(id),
      serverId: Value(serverId),
      dataType: Value(dataType),
      dataContent: Value(dataContent),
      createdAt: Value(createdAt),
    );
  }

  factory PerformanceDataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PerformanceDataData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      dataType: serializer.fromJson<String>(json['dataType']),
      dataContent: serializer.fromJson<String>(json['dataContent']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'dataType': serializer.toJson<String>(dataType),
      'dataContent': serializer.toJson<String>(dataContent),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PerformanceDataData copyWith(
          {int? id,
          String? serverId,
          String? dataType,
          String? dataContent,
          String? createdAt}) =>
      PerformanceDataData(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        dataType: dataType ?? this.dataType,
        dataContent: dataContent ?? this.dataContent,
        createdAt: createdAt ?? this.createdAt,
      );
  PerformanceDataData copyWithCompanion(PerformanceDataCompanion data) {
    return PerformanceDataData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      dataContent:
          data.dataContent.present ? data.dataContent.value : this.dataContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PerformanceDataData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('dataType: $dataType, ')
          ..write('dataContent: $dataContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, serverId, dataType, dataContent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PerformanceDataData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.dataType == this.dataType &&
          other.dataContent == this.dataContent &&
          other.createdAt == this.createdAt);
}

class PerformanceDataCompanion extends UpdateCompanion<PerformanceDataData> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> dataType;
  final Value<String> dataContent;
  final Value<String> createdAt;
  const PerformanceDataCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.dataType = const Value.absent(),
    this.dataContent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PerformanceDataCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String dataType,
    required String dataContent,
    this.createdAt = const Value.absent(),
  })  : serverId = Value(serverId),
        dataType = Value(dataType),
        dataContent = Value(dataContent);
  static Insertable<PerformanceDataData> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? dataType,
    Expression<String>? dataContent,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (dataType != null) 'data_type': dataType,
      if (dataContent != null) 'data_content': dataContent,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PerformanceDataCompanion copyWith(
      {Value<int>? id,
      Value<String>? serverId,
      Value<String>? dataType,
      Value<String>? dataContent,
      Value<String>? createdAt}) {
    return PerformanceDataCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      dataType: dataType ?? this.dataType,
      dataContent: dataContent ?? this.dataContent,
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
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (dataContent.present) {
      map['data_content'] = Variable<String>(dataContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PerformanceDataCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('dataType: $dataType, ')
          ..write('dataContent: $dataContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BusinessDataTable extends BusinessData
    with TableInfo<$BusinessDataTable, BusinessDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monthYearMeta =
      const VerificationMeta('monthYear');
  @override
  late final GeneratedColumn<String> monthYear = GeneratedColumn<String>(
      'month_year', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataTypeMeta =
      const VerificationMeta('dataType');
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
      'data_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataContentMeta =
      const VerificationMeta('dataContent');
  @override
  late final GeneratedColumn<String> dataContent = GeneratedColumn<String>(
      'data_content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, monthYear, dataType, dataContent, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_data';
  @override
  VerificationContext validateIntegrity(Insertable<BusinessDataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_year')) {
      context.handle(_monthYearMeta,
          monthYear.isAcceptableOrUnknown(data['month_year']!, _monthYearMeta));
    } else if (isInserting) {
      context.missing(_monthYearMeta);
    }
    if (data.containsKey('data_type')) {
      context.handle(_dataTypeMeta,
          dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta));
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('data_content')) {
      context.handle(
          _dataContentMeta,
          dataContent.isAcceptableOrUnknown(
              data['data_content']!, _dataContentMeta));
    } else if (isInserting) {
      context.missing(_dataContentMeta);
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
  BusinessDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessDataData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      monthYear: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_year'])!,
      dataType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_type'])!,
      dataContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BusinessDataTable createAlias(String alias) {
    return $BusinessDataTable(attachedDatabase, alias);
  }
}

class BusinessDataData extends DataClass
    implements Insertable<BusinessDataData> {
  final int id;
  final String monthYear;
  final String dataType;
  final String dataContent;
  final String createdAt;
  const BusinessDataData(
      {required this.id,
      required this.monthYear,
      required this.dataType,
      required this.dataContent,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_year'] = Variable<String>(monthYear);
    map['data_type'] = Variable<String>(dataType);
    map['data_content'] = Variable<String>(dataContent);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  BusinessDataCompanion toCompanion(bool nullToAbsent) {
    return BusinessDataCompanion(
      id: Value(id),
      monthYear: Value(monthYear),
      dataType: Value(dataType),
      dataContent: Value(dataContent),
      createdAt: Value(createdAt),
    );
  }

  factory BusinessDataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessDataData(
      id: serializer.fromJson<int>(json['id']),
      monthYear: serializer.fromJson<String>(json['monthYear']),
      dataType: serializer.fromJson<String>(json['dataType']),
      dataContent: serializer.fromJson<String>(json['dataContent']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthYear': serializer.toJson<String>(monthYear),
      'dataType': serializer.toJson<String>(dataType),
      'dataContent': serializer.toJson<String>(dataContent),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  BusinessDataData copyWith(
          {int? id,
          String? monthYear,
          String? dataType,
          String? dataContent,
          String? createdAt}) =>
      BusinessDataData(
        id: id ?? this.id,
        monthYear: monthYear ?? this.monthYear,
        dataType: dataType ?? this.dataType,
        dataContent: dataContent ?? this.dataContent,
        createdAt: createdAt ?? this.createdAt,
      );
  BusinessDataData copyWithCompanion(BusinessDataCompanion data) {
    return BusinessDataData(
      id: data.id.present ? data.id.value : this.id,
      monthYear: data.monthYear.present ? data.monthYear.value : this.monthYear,
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      dataContent:
          data.dataContent.present ? data.dataContent.value : this.dataContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessDataData(')
          ..write('id: $id, ')
          ..write('monthYear: $monthYear, ')
          ..write('dataType: $dataType, ')
          ..write('dataContent: $dataContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, monthYear, dataType, dataContent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessDataData &&
          other.id == this.id &&
          other.monthYear == this.monthYear &&
          other.dataType == this.dataType &&
          other.dataContent == this.dataContent &&
          other.createdAt == this.createdAt);
}

class BusinessDataCompanion extends UpdateCompanion<BusinessDataData> {
  final Value<int> id;
  final Value<String> monthYear;
  final Value<String> dataType;
  final Value<String> dataContent;
  final Value<String> createdAt;
  const BusinessDataCompanion({
    this.id = const Value.absent(),
    this.monthYear = const Value.absent(),
    this.dataType = const Value.absent(),
    this.dataContent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BusinessDataCompanion.insert({
    this.id = const Value.absent(),
    required String monthYear,
    required String dataType,
    required String dataContent,
    this.createdAt = const Value.absent(),
  })  : monthYear = Value(monthYear),
        dataType = Value(dataType),
        dataContent = Value(dataContent);
  static Insertable<BusinessDataData> custom({
    Expression<int>? id,
    Expression<String>? monthYear,
    Expression<String>? dataType,
    Expression<String>? dataContent,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthYear != null) 'month_year': monthYear,
      if (dataType != null) 'data_type': dataType,
      if (dataContent != null) 'data_content': dataContent,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BusinessDataCompanion copyWith(
      {Value<int>? id,
      Value<String>? monthYear,
      Value<String>? dataType,
      Value<String>? dataContent,
      Value<String>? createdAt}) {
    return BusinessDataCompanion(
      id: id ?? this.id,
      monthYear: monthYear ?? this.monthYear,
      dataType: dataType ?? this.dataType,
      dataContent: dataContent ?? this.dataContent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthYear.present) {
      map['month_year'] = Variable<String>(monthYear.value);
    }
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (dataContent.present) {
      map['data_content'] = Variable<String>(dataContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessDataCompanion(')
          ..write('id: $id, ')
          ..write('monthYear: $monthYear, ')
          ..write('dataType: $dataType, ')
          ..write('dataContent: $dataContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StationAssignmentsTable extends StationAssignments
    with TableInfo<$StationAssignmentsTable, StationAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StationAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shiftDateMeta =
      const VerificationMeta('shiftDate');
  @override
  late final GeneratedColumn<String> shiftDate = GeneratedColumn<String>(
      'shift_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shiftTypeMeta =
      const VerificationMeta('shiftType');
  @override
  late final GeneratedColumn<String> shiftType = GeneratedColumn<String>(
      'shift_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stationTypeMeta =
      const VerificationMeta('stationType');
  @override
  late final GeneratedColumn<String> stationType = GeneratedColumn<String>(
      'station_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sectionAssignmentMeta =
      const VerificationMeta('sectionAssignment');
  @override
  late final GeneratedColumn<String> sectionAssignment =
      GeneratedColumn<String>('section_assignment', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        shiftDate,
        shiftType,
        stationType,
        sectionAssignment,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'station_assignments';
  @override
  VerificationContext validateIntegrity(Insertable<StationAssignment> instance,
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
    if (data.containsKey('shift_date')) {
      context.handle(_shiftDateMeta,
          shiftDate.isAcceptableOrUnknown(data['shift_date']!, _shiftDateMeta));
    } else if (isInserting) {
      context.missing(_shiftDateMeta);
    }
    if (data.containsKey('shift_type')) {
      context.handle(_shiftTypeMeta,
          shiftType.isAcceptableOrUnknown(data['shift_type']!, _shiftTypeMeta));
    } else if (isInserting) {
      context.missing(_shiftTypeMeta);
    }
    if (data.containsKey('station_type')) {
      context.handle(
          _stationTypeMeta,
          stationType.isAcceptableOrUnknown(
              data['station_type']!, _stationTypeMeta));
    }
    if (data.containsKey('section_assignment')) {
      context.handle(
          _sectionAssignmentMeta,
          sectionAssignment.isAcceptableOrUnknown(
              data['section_assignment']!, _sectionAssignmentMeta));
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
  StationAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StationAssignment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      shiftDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift_date'])!,
      shiftType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift_type'])!,
      stationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}station_type']),
      sectionAssignment: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}section_assignment']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StationAssignmentsTable createAlias(String alias) {
    return $StationAssignmentsTable(attachedDatabase, alias);
  }
}

class StationAssignment extends DataClass
    implements Insertable<StationAssignment> {
  final int id;
  final String serverId;
  final String shiftDate;
  final String shiftType;
  final String? stationType;
  final String? sectionAssignment;
  final String createdAt;
  const StationAssignment(
      {required this.id,
      required this.serverId,
      required this.shiftDate,
      required this.shiftType,
      this.stationType,
      this.sectionAssignment,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['shift_date'] = Variable<String>(shiftDate);
    map['shift_type'] = Variable<String>(shiftType);
    if (!nullToAbsent || stationType != null) {
      map['station_type'] = Variable<String>(stationType);
    }
    if (!nullToAbsent || sectionAssignment != null) {
      map['section_assignment'] = Variable<String>(sectionAssignment);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  StationAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return StationAssignmentsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      shiftDate: Value(shiftDate),
      shiftType: Value(shiftType),
      stationType: stationType == null && nullToAbsent
          ? const Value.absent()
          : Value(stationType),
      sectionAssignment: sectionAssignment == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionAssignment),
      createdAt: Value(createdAt),
    );
  }

  factory StationAssignment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StationAssignment(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      shiftDate: serializer.fromJson<String>(json['shiftDate']),
      shiftType: serializer.fromJson<String>(json['shiftType']),
      stationType: serializer.fromJson<String?>(json['stationType']),
      sectionAssignment:
          serializer.fromJson<String?>(json['sectionAssignment']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'shiftDate': serializer.toJson<String>(shiftDate),
      'shiftType': serializer.toJson<String>(shiftType),
      'stationType': serializer.toJson<String?>(stationType),
      'sectionAssignment': serializer.toJson<String?>(sectionAssignment),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  StationAssignment copyWith(
          {int? id,
          String? serverId,
          String? shiftDate,
          String? shiftType,
          Value<String?> stationType = const Value.absent(),
          Value<String?> sectionAssignment = const Value.absent(),
          String? createdAt}) =>
      StationAssignment(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        shiftDate: shiftDate ?? this.shiftDate,
        shiftType: shiftType ?? this.shiftType,
        stationType: stationType.present ? stationType.value : this.stationType,
        sectionAssignment: sectionAssignment.present
            ? sectionAssignment.value
            : this.sectionAssignment,
        createdAt: createdAt ?? this.createdAt,
      );
  StationAssignment copyWithCompanion(StationAssignmentsCompanion data) {
    return StationAssignment(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      shiftDate: data.shiftDate.present ? data.shiftDate.value : this.shiftDate,
      shiftType: data.shiftType.present ? data.shiftType.value : this.shiftType,
      stationType:
          data.stationType.present ? data.stationType.value : this.stationType,
      sectionAssignment: data.sectionAssignment.present
          ? data.sectionAssignment.value
          : this.sectionAssignment,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StationAssignment(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('shiftDate: $shiftDate, ')
          ..write('shiftType: $shiftType, ')
          ..write('stationType: $stationType, ')
          ..write('sectionAssignment: $sectionAssignment, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, shiftDate, shiftType,
      stationType, sectionAssignment, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StationAssignment &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.shiftDate == this.shiftDate &&
          other.shiftType == this.shiftType &&
          other.stationType == this.stationType &&
          other.sectionAssignment == this.sectionAssignment &&
          other.createdAt == this.createdAt);
}

class StationAssignmentsCompanion extends UpdateCompanion<StationAssignment> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> shiftDate;
  final Value<String> shiftType;
  final Value<String?> stationType;
  final Value<String?> sectionAssignment;
  final Value<String> createdAt;
  const StationAssignmentsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.shiftDate = const Value.absent(),
    this.shiftType = const Value.absent(),
    this.stationType = const Value.absent(),
    this.sectionAssignment = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StationAssignmentsCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String shiftDate,
    required String shiftType,
    this.stationType = const Value.absent(),
    this.sectionAssignment = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : serverId = Value(serverId),
        shiftDate = Value(shiftDate),
        shiftType = Value(shiftType);
  static Insertable<StationAssignment> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? shiftDate,
    Expression<String>? shiftType,
    Expression<String>? stationType,
    Expression<String>? sectionAssignment,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (shiftDate != null) 'shift_date': shiftDate,
      if (shiftType != null) 'shift_type': shiftType,
      if (stationType != null) 'station_type': stationType,
      if (sectionAssignment != null) 'section_assignment': sectionAssignment,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StationAssignmentsCompanion copyWith(
      {Value<int>? id,
      Value<String>? serverId,
      Value<String>? shiftDate,
      Value<String>? shiftType,
      Value<String?>? stationType,
      Value<String?>? sectionAssignment,
      Value<String>? createdAt}) {
    return StationAssignmentsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      shiftDate: shiftDate ?? this.shiftDate,
      shiftType: shiftType ?? this.shiftType,
      stationType: stationType ?? this.stationType,
      sectionAssignment: sectionAssignment ?? this.sectionAssignment,
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
    if (shiftDate.present) {
      map['shift_date'] = Variable<String>(shiftDate.value);
    }
    if (shiftType.present) {
      map['shift_type'] = Variable<String>(shiftType.value);
    }
    if (stationType.present) {
      map['station_type'] = Variable<String>(stationType.value);
    }
    if (sectionAssignment.present) {
      map['section_assignment'] = Variable<String>(sectionAssignment.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StationAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('shiftDate: $shiftDate, ')
          ..write('shiftType: $shiftType, ')
          ..write('stationType: $stationType, ')
          ..write('sectionAssignment: $sectionAssignment, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TapLogsTable extends TapLogs with TableInfo<$TapLogsTable, TapLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TapLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [key, data, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tap_logs';
  @override
  VerificationContext validateIntegrity(Insertable<TapLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  TapLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TapLog(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TapLogsTable createAlias(String alias) {
    return $TapLogsTable(attachedDatabase, alias);
  }
}

class TapLog extends DataClass implements Insertable<TapLog> {
  final String key;
  final String data;
  final String updatedAt;
  const TapLog(
      {required this.key, required this.data, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['data'] = Variable<String>(data);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TapLogsCompanion toCompanion(bool nullToAbsent) {
    return TapLogsCompanion(
      key: Value(key),
      data: Value(data),
      updatedAt: Value(updatedAt),
    );
  }

  factory TapLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TapLog(
      key: serializer.fromJson<String>(json['key']),
      data: serializer.fromJson<String>(json['data']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'data': serializer.toJson<String>(data),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TapLog copyWith({String? key, String? data, String? updatedAt}) => TapLog(
        key: key ?? this.key,
        data: data ?? this.data,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TapLog copyWithCompanion(TapLogsCompanion data) {
    return TapLog(
      key: data.key.present ? data.key.value : this.key,
      data: data.data.present ? data.data.value : this.data,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TapLog(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, data, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TapLog &&
          other.key == this.key &&
          other.data == this.data &&
          other.updatedAt == this.updatedAt);
}

class TapLogsCompanion extends UpdateCompanion<TapLog> {
  final Value<String> key;
  final Value<String> data;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TapLogsCompanion({
    this.key = const Value.absent(),
    this.data = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TapLogsCompanion.insert({
    required String key,
    required String data,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        data = Value(data);
  static Insertable<TapLog> custom({
    Expression<String>? key,
    Expression<String>? data,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (data != null) 'data': data,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TapLogsCompanion copyWith(
      {Value<String>? key,
      Value<String>? data,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return TapLogsCompanion(
      key: key ?? this.key,
      data: data ?? this.data,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
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
    return (StringBuffer('TapLogsCompanion(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayPlansTable extends DayPlans with TableInfo<$DayPlansTable, DayPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [date, data, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_plans';
  @override
  VerificationContext validateIntegrity(Insertable<DayPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayPlan(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DayPlansTable createAlias(String alias) {
    return $DayPlansTable(attachedDatabase, alias);
  }
}

class DayPlan extends DataClass implements Insertable<DayPlan> {
  final String date;
  final String data;
  final String updatedAt;
  const DayPlan(
      {required this.date, required this.data, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['data'] = Variable<String>(data);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  DayPlansCompanion toCompanion(bool nullToAbsent) {
    return DayPlansCompanion(
      date: Value(date),
      data: Value(data),
      updatedAt: Value(updatedAt),
    );
  }

  factory DayPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayPlan(
      date: serializer.fromJson<String>(json['date']),
      data: serializer.fromJson<String>(json['data']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'data': serializer.toJson<String>(data),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  DayPlan copyWith({String? date, String? data, String? updatedAt}) => DayPlan(
        date: date ?? this.date,
        data: data ?? this.data,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DayPlan copyWithCompanion(DayPlansCompanion data) {
    return DayPlan(
      date: data.date.present ? data.date.value : this.date,
      data: data.data.present ? data.data.value : this.data,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayPlan(')
          ..write('date: $date, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, data, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayPlan &&
          other.date == this.date &&
          other.data == this.data &&
          other.updatedAt == this.updatedAt);
}

class DayPlansCompanion extends UpdateCompanion<DayPlan> {
  final Value<String> date;
  final Value<String> data;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const DayPlansCompanion({
    this.date = const Value.absent(),
    this.data = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayPlansCompanion.insert({
    required String date,
    required String data,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        data = Value(data);
  static Insertable<DayPlan> custom({
    Expression<String>? date,
    Expression<String>? data,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (data != null) 'data': data,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayPlansCompanion copyWith(
      {Value<String>? date,
      Value<String>? data,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return DayPlansCompanion(
      date: date ?? this.date,
      data: data ?? this.data,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
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
    return (StringBuffer('DayPlansCompanion(')
          ..write('date: $date, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('CURRENT_TIMESTAMP'));
  @override
  List<GeneratedColumn> get $columns => [key, data, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(Insertable<Asset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class Asset extends DataClass implements Insertable<Asset> {
  final String key;
  final String data;
  final String updatedAt;
  const Asset({required this.key, required this.data, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['data'] = Variable<String>(data);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      key: Value(key),
      data: Value(data),
      updatedAt: Value(updatedAt),
    );
  }

  factory Asset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      key: serializer.fromJson<String>(json['key']),
      data: serializer.fromJson<String>(json['data']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'data': serializer.toJson<String>(data),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Asset copyWith({String? key, String? data, String? updatedAt}) => Asset(
        key: key ?? this.key,
        data: data ?? this.data,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      key: data.key.present ? data.key.value : this.key,
      data: data.data.present ? data.data.value : this.data,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, data, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.key == this.key &&
          other.data == this.data &&
          other.updatedAt == this.updatedAt);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> key;
  final Value<String> data;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AssetsCompanion({
    this.key = const Value.absent(),
    this.data = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String key,
    required String data,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        data = Value(data);
  static Insertable<Asset> custom({
    Expression<String>? key,
    Expression<String>? data,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (data != null) 'data': data,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith(
      {Value<String>? key,
      Value<String>? data,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return AssetsCompanion(
      key: key ?? this.key,
      data: data ?? this.data,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
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
    return (StringBuffer('AssetsCompanion(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UnifiedDatabase extends GeneratedDatabase {
  _$UnifiedDatabase(QueryExecutor e) : super(e);
  $UnifiedDatabaseManager get managers => $UnifiedDatabaseManager(this);
  late final $ServersTable servers = $ServersTable(this);
  late final $ShiftRecordsTable shiftRecords = $ShiftRecordsTable(this);
  late final $ServerProfilesTable serverProfiles = $ServerProfilesTable(this);
  late final $NPSFeedbackTable nPSFeedback = $NPSFeedbackTable(this);
  late final $NPSMonthlyReportsTable nPSMonthlyReports =
      $NPSMonthlyReportsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $PerformanceDataTable performanceData =
      $PerformanceDataTable(this);
  late final $BusinessDataTable businessData = $BusinessDataTable(this);
  late final $StationAssignmentsTable stationAssignments =
      $StationAssignmentsTable(this);
  late final $TapLogsTable tapLogs = $TapLogsTable(this);
  late final $DayPlansTable dayPlans = $DayPlansTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        servers,
        shiftRecords,
        serverProfiles,
        nPSFeedback,
        nPSMonthlyReports,
        appSettings,
        performanceData,
        businessData,
        stationAssignments,
        tapLogs,
        dayPlans,
        assets
      ];
}

typedef $$ServersTableCreateCompanionBuilder = ServersCompanion Function({
  required String id,
  required String name,
  Value<String?> originalId,
  Value<String?> teamColor,
  Value<String?> stationType,
  required String hireDate,
  Value<bool> active,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});
typedef $$ServersTableUpdateCompanionBuilder = ServersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> originalId,
  Value<String?> teamColor,
  Value<String?> stationType,
  Value<String> hireDate,
  Value<bool> active,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$ServersTableFilterComposer
    extends Composer<_$UnifiedDatabase, $ServersTable> {
  $$ServersTableFilterComposer({
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

  ColumnFilters<String> get teamColor => $composableBuilder(
      column: $table.teamColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ServersTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $ServersTable> {
  $$ServersTableOrderingComposer({
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

  ColumnOrderings<String> get teamColor => $composableBuilder(
      column: $table.teamColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ServersTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $ServersTable> {
  $$ServersTableAnnotationComposer({
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

  GeneratedColumn<String> get teamColor =>
      $composableBuilder(column: $table.teamColor, builder: (column) => column);

  GeneratedColumn<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => column);

  GeneratedColumn<String> get hireDate =>
      $composableBuilder(column: $table.hireDate, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ServersTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $ServersTable,
    Server,
    $$ServersTableFilterComposer,
    $$ServersTableOrderingComposer,
    $$ServersTableAnnotationComposer,
    $$ServersTableCreateCompanionBuilder,
    $$ServersTableUpdateCompanionBuilder,
    (Server, BaseReferences<_$UnifiedDatabase, $ServersTable, Server>),
    Server,
    PrefetchHooks Function()> {
  $$ServersTableTableManager(_$UnifiedDatabase db, $ServersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> originalId = const Value.absent(),
            Value<String?> teamColor = const Value.absent(),
            Value<String?> stationType = const Value.absent(),
            Value<String> hireDate = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServersCompanion(
            id: id,
            name: name,
            originalId: originalId,
            teamColor: teamColor,
            stationType: stationType,
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
            Value<String?> teamColor = const Value.absent(),
            Value<String?> stationType = const Value.absent(),
            required String hireDate,
            Value<bool> active = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServersCompanion.insert(
            id: id,
            name: name,
            originalId: originalId,
            teamColor: teamColor,
            stationType: stationType,
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

typedef $$ServersTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $ServersTable,
    Server,
    $$ServersTableFilterComposer,
    $$ServersTableOrderingComposer,
    $$ServersTableAnnotationComposer,
    $$ServersTableCreateCompanionBuilder,
    $$ServersTableUpdateCompanionBuilder,
    (Server, BaseReferences<_$UnifiedDatabase, $ServersTable, Server>),
    Server,
    PrefetchHooks Function()>;
typedef $$ShiftRecordsTableCreateCompanionBuilder = ShiftRecordsCompanion
    Function({
  required String id,
  required String label,
  required String shiftType,
  required String startDate,
  required String counts,
  Value<String?> pizookieCounts,
  Value<String?> stationAssignments,
  Value<String?> sectionAssignments,
  Value<String> createdAt,
  Value<int> rowid,
});
typedef $$ShiftRecordsTableUpdateCompanionBuilder = ShiftRecordsCompanion
    Function({
  Value<String> id,
  Value<String> label,
  Value<String> shiftType,
  Value<String> startDate,
  Value<String> counts,
  Value<String?> pizookieCounts,
  Value<String?> stationAssignments,
  Value<String?> sectionAssignments,
  Value<String> createdAt,
  Value<int> rowid,
});

class $$ShiftRecordsTableFilterComposer
    extends Composer<_$UnifiedDatabase, $ShiftRecordsTable> {
  $$ShiftRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shiftType => $composableBuilder(
      column: $table.shiftType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counts => $composableBuilder(
      column: $table.counts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pizookieCounts => $composableBuilder(
      column: $table.pizookieCounts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stationAssignments => $composableBuilder(
      column: $table.stationAssignments,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionAssignments => $composableBuilder(
      column: $table.sectionAssignments,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ShiftRecordsTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $ShiftRecordsTable> {
  $$ShiftRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shiftType => $composableBuilder(
      column: $table.shiftType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counts => $composableBuilder(
      column: $table.counts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pizookieCounts => $composableBuilder(
      column: $table.pizookieCounts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stationAssignments => $composableBuilder(
      column: $table.stationAssignments,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionAssignments => $composableBuilder(
      column: $table.sectionAssignments,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ShiftRecordsTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $ShiftRecordsTable> {
  $$ShiftRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get shiftType =>
      $composableBuilder(column: $table.shiftType, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get counts =>
      $composableBuilder(column: $table.counts, builder: (column) => column);

  GeneratedColumn<String> get pizookieCounts => $composableBuilder(
      column: $table.pizookieCounts, builder: (column) => column);

  GeneratedColumn<String> get stationAssignments => $composableBuilder(
      column: $table.stationAssignments, builder: (column) => column);

  GeneratedColumn<String> get sectionAssignments => $composableBuilder(
      column: $table.sectionAssignments, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ShiftRecordsTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $ShiftRecordsTable,
    ShiftRecord,
    $$ShiftRecordsTableFilterComposer,
    $$ShiftRecordsTableOrderingComposer,
    $$ShiftRecordsTableAnnotationComposer,
    $$ShiftRecordsTableCreateCompanionBuilder,
    $$ShiftRecordsTableUpdateCompanionBuilder,
    (
      ShiftRecord,
      BaseReferences<_$UnifiedDatabase, $ShiftRecordsTable, ShiftRecord>
    ),
    ShiftRecord,
    PrefetchHooks Function()> {
  $$ShiftRecordsTableTableManager(
      _$UnifiedDatabase db, $ShiftRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> shiftType = const Value.absent(),
            Value<String> startDate = const Value.absent(),
            Value<String> counts = const Value.absent(),
            Value<String?> pizookieCounts = const Value.absent(),
            Value<String?> stationAssignments = const Value.absent(),
            Value<String?> sectionAssignments = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftRecordsCompanion(
            id: id,
            label: label,
            shiftType: shiftType,
            startDate: startDate,
            counts: counts,
            pizookieCounts: pizookieCounts,
            stationAssignments: stationAssignments,
            sectionAssignments: sectionAssignments,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String label,
            required String shiftType,
            required String startDate,
            required String counts,
            Value<String?> pizookieCounts = const Value.absent(),
            Value<String?> stationAssignments = const Value.absent(),
            Value<String?> sectionAssignments = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftRecordsCompanion.insert(
            id: id,
            label: label,
            shiftType: shiftType,
            startDate: startDate,
            counts: counts,
            pizookieCounts: pizookieCounts,
            stationAssignments: stationAssignments,
            sectionAssignments: sectionAssignments,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShiftRecordsTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $ShiftRecordsTable,
    ShiftRecord,
    $$ShiftRecordsTableFilterComposer,
    $$ShiftRecordsTableOrderingComposer,
    $$ShiftRecordsTableAnnotationComposer,
    $$ShiftRecordsTableCreateCompanionBuilder,
    $$ShiftRecordsTableUpdateCompanionBuilder,
    (
      ShiftRecord,
      BaseReferences<_$UnifiedDatabase, $ShiftRecordsTable, ShiftRecord>
    ),
    ShiftRecord,
    PrefetchHooks Function()>;
typedef $$ServerProfilesTableCreateCompanionBuilder = ServerProfilesCompanion
    Function({
  required String serverId,
  Value<String?> avatarPath,
  Value<String?> birthday,
  Value<String?> hireDate,
  Value<String?> teamColor,
  Value<String?> stationType,
  Value<String?> performanceData,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});
typedef $$ServerProfilesTableUpdateCompanionBuilder = ServerProfilesCompanion
    Function({
  Value<String> serverId,
  Value<String?> avatarPath,
  Value<String?> birthday,
  Value<String?> hireDate,
  Value<String?> teamColor,
  Value<String?> stationType,
  Value<String?> performanceData,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$ServerProfilesTableFilterComposer
    extends Composer<_$UnifiedDatabase, $ServerProfilesTable> {
  $$ServerProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamColor => $composableBuilder(
      column: $table.teamColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get performanceData => $composableBuilder(
      column: $table.performanceData,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ServerProfilesTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $ServerProfilesTable> {
  $$ServerProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamColor => $composableBuilder(
      column: $table.teamColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get performanceData => $composableBuilder(
      column: $table.performanceData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ServerProfilesTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $ServerProfilesTable> {
  $$ServerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => column);

  GeneratedColumn<String> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<String> get hireDate =>
      $composableBuilder(column: $table.hireDate, builder: (column) => column);

  GeneratedColumn<String> get teamColor =>
      $composableBuilder(column: $table.teamColor, builder: (column) => column);

  GeneratedColumn<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => column);

  GeneratedColumn<String> get performanceData => $composableBuilder(
      column: $table.performanceData, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ServerProfilesTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $ServerProfilesTable,
    ServerProfile,
    $$ServerProfilesTableFilterComposer,
    $$ServerProfilesTableOrderingComposer,
    $$ServerProfilesTableAnnotationComposer,
    $$ServerProfilesTableCreateCompanionBuilder,
    $$ServerProfilesTableUpdateCompanionBuilder,
    (
      ServerProfile,
      BaseReferences<_$UnifiedDatabase, $ServerProfilesTable, ServerProfile>
    ),
    ServerProfile,
    PrefetchHooks Function()> {
  $$ServerProfilesTableTableManager(
      _$UnifiedDatabase db, $ServerProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> serverId = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<String?> birthday = const Value.absent(),
            Value<String?> hireDate = const Value.absent(),
            Value<String?> teamColor = const Value.absent(),
            Value<String?> stationType = const Value.absent(),
            Value<String?> performanceData = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServerProfilesCompanion(
            serverId: serverId,
            avatarPath: avatarPath,
            birthday: birthday,
            hireDate: hireDate,
            teamColor: teamColor,
            stationType: stationType,
            performanceData: performanceData,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String serverId,
            Value<String?> avatarPath = const Value.absent(),
            Value<String?> birthday = const Value.absent(),
            Value<String?> hireDate = const Value.absent(),
            Value<String?> teamColor = const Value.absent(),
            Value<String?> stationType = const Value.absent(),
            Value<String?> performanceData = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServerProfilesCompanion.insert(
            serverId: serverId,
            avatarPath: avatarPath,
            birthday: birthday,
            hireDate: hireDate,
            teamColor: teamColor,
            stationType: stationType,
            performanceData: performanceData,
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

typedef $$ServerProfilesTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $ServerProfilesTable,
    ServerProfile,
    $$ServerProfilesTableFilterComposer,
    $$ServerProfilesTableOrderingComposer,
    $$ServerProfilesTableAnnotationComposer,
    $$ServerProfilesTableCreateCompanionBuilder,
    $$ServerProfilesTableUpdateCompanionBuilder,
    (
      ServerProfile,
      BaseReferences<_$UnifiedDatabase, $ServerProfilesTable, ServerProfile>
    ),
    ServerProfile,
    PrefetchHooks Function()>;
typedef $$NPSFeedbackTableCreateCompanionBuilder = NPSFeedbackCompanion
    Function({
  Value<int> id,
  required String serverId,
  required String feedbackType,
  required String feedbackDate,
  Value<double?> salesAmount,
  Value<int?> tableNumber,
  Value<String?> shiftPeriod,
  Value<int?> guestCount,
  Value<String?> notes,
  Value<String> createdAt,
});
typedef $$NPSFeedbackTableUpdateCompanionBuilder = NPSFeedbackCompanion
    Function({
  Value<int> id,
  Value<String> serverId,
  Value<String> feedbackType,
  Value<String> feedbackDate,
  Value<double?> salesAmount,
  Value<int?> tableNumber,
  Value<String?> shiftPeriod,
  Value<int?> guestCount,
  Value<String?> notes,
  Value<String> createdAt,
});

class $$NPSFeedbackTableFilterComposer
    extends Composer<_$UnifiedDatabase, $NPSFeedbackTable> {
  $$NPSFeedbackTableFilterComposer({
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

  ColumnFilters<String> get feedbackDate => $composableBuilder(
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

class $$NPSFeedbackTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $NPSFeedbackTable> {
  $$NPSFeedbackTableOrderingComposer({
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

  ColumnOrderings<String> get feedbackDate => $composableBuilder(
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

class $$NPSFeedbackTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $NPSFeedbackTable> {
  $$NPSFeedbackTableAnnotationComposer({
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

  GeneratedColumn<String> get feedbackDate => $composableBuilder(
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

class $$NPSFeedbackTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $NPSFeedbackTable,
    NPSFeedbackData,
    $$NPSFeedbackTableFilterComposer,
    $$NPSFeedbackTableOrderingComposer,
    $$NPSFeedbackTableAnnotationComposer,
    $$NPSFeedbackTableCreateCompanionBuilder,
    $$NPSFeedbackTableUpdateCompanionBuilder,
    (
      NPSFeedbackData,
      BaseReferences<_$UnifiedDatabase, $NPSFeedbackTable, NPSFeedbackData>
    ),
    NPSFeedbackData,
    PrefetchHooks Function()> {
  $$NPSFeedbackTableTableManager(_$UnifiedDatabase db, $NPSFeedbackTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NPSFeedbackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NPSFeedbackTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NPSFeedbackTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<String> feedbackType = const Value.absent(),
            Value<String> feedbackDate = const Value.absent(),
            Value<double?> salesAmount = const Value.absent(),
            Value<int?> tableNumber = const Value.absent(),
            Value<String?> shiftPeriod = const Value.absent(),
            Value<int?> guestCount = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              NPSFeedbackCompanion(
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
            required String feedbackDate,
            Value<double?> salesAmount = const Value.absent(),
            Value<int?> tableNumber = const Value.absent(),
            Value<String?> shiftPeriod = const Value.absent(),
            Value<int?> guestCount = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              NPSFeedbackCompanion.insert(
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

typedef $$NPSFeedbackTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $NPSFeedbackTable,
    NPSFeedbackData,
    $$NPSFeedbackTableFilterComposer,
    $$NPSFeedbackTableOrderingComposer,
    $$NPSFeedbackTableAnnotationComposer,
    $$NPSFeedbackTableCreateCompanionBuilder,
    $$NPSFeedbackTableUpdateCompanionBuilder,
    (
      NPSFeedbackData,
      BaseReferences<_$UnifiedDatabase, $NPSFeedbackTable, NPSFeedbackData>
    ),
    NPSFeedbackData,
    PrefetchHooks Function()>;
typedef $$NPSMonthlyReportsTableCreateCompanionBuilder
    = NPSMonthlyReportsCompanion Function({
  Value<int> id,
  required String serverId,
  required String monthYear,
  Value<double?> allTimeNpsPercentage,
  Value<double?> threeMonthNpsPercentage,
  Value<double?> oneMonthNpsPercentage,
  Value<double> allTimeSales,
  Value<int> allTimeTableCount,
  Value<int> monthFeedbackYes,
  Value<int> monthFeedbackMaybe,
  Value<int> monthFeedbackNo,
  Value<int> threeMonthFeedbackYes,
  Value<int> threeMonthFeedbackMaybe,
  Value<int> threeMonthFeedbackNo,
  Value<int> allTimeFeedbackYes,
  Value<int> allTimeFeedbackMaybe,
  Value<int> allTimeFeedbackNo,
  Value<String> generatedAt,
  required String dataAsOfDate,
});
typedef $$NPSMonthlyReportsTableUpdateCompanionBuilder
    = NPSMonthlyReportsCompanion Function({
  Value<int> id,
  Value<String> serverId,
  Value<String> monthYear,
  Value<double?> allTimeNpsPercentage,
  Value<double?> threeMonthNpsPercentage,
  Value<double?> oneMonthNpsPercentage,
  Value<double> allTimeSales,
  Value<int> allTimeTableCount,
  Value<int> monthFeedbackYes,
  Value<int> monthFeedbackMaybe,
  Value<int> monthFeedbackNo,
  Value<int> threeMonthFeedbackYes,
  Value<int> threeMonthFeedbackMaybe,
  Value<int> threeMonthFeedbackNo,
  Value<int> allTimeFeedbackYes,
  Value<int> allTimeFeedbackMaybe,
  Value<int> allTimeFeedbackNo,
  Value<String> generatedAt,
  Value<String> dataAsOfDate,
});

class $$NPSMonthlyReportsTableFilterComposer
    extends Composer<_$UnifiedDatabase, $NPSMonthlyReportsTable> {
  $$NPSMonthlyReportsTableFilterComposer({
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

  ColumnFilters<String> get monthYear => $composableBuilder(
      column: $table.monthYear, builder: (column) => ColumnFilters(column));

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

  ColumnFilters<String> get dataAsOfDate => $composableBuilder(
      column: $table.dataAsOfDate, builder: (column) => ColumnFilters(column));
}

class $$NPSMonthlyReportsTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $NPSMonthlyReportsTable> {
  $$NPSMonthlyReportsTableOrderingComposer({
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

  ColumnOrderings<String> get monthYear => $composableBuilder(
      column: $table.monthYear, builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<String> get dataAsOfDate => $composableBuilder(
      column: $table.dataAsOfDate,
      builder: (column) => ColumnOrderings(column));
}

class $$NPSMonthlyReportsTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $NPSMonthlyReportsTable> {
  $$NPSMonthlyReportsTableAnnotationComposer({
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

  GeneratedColumn<String> get monthYear =>
      $composableBuilder(column: $table.monthYear, builder: (column) => column);

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

  GeneratedColumn<String> get dataAsOfDate => $composableBuilder(
      column: $table.dataAsOfDate, builder: (column) => column);
}

class $$NPSMonthlyReportsTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $NPSMonthlyReportsTable,
    NPSMonthlyReport,
    $$NPSMonthlyReportsTableFilterComposer,
    $$NPSMonthlyReportsTableOrderingComposer,
    $$NPSMonthlyReportsTableAnnotationComposer,
    $$NPSMonthlyReportsTableCreateCompanionBuilder,
    $$NPSMonthlyReportsTableUpdateCompanionBuilder,
    (
      NPSMonthlyReport,
      BaseReferences<_$UnifiedDatabase, $NPSMonthlyReportsTable,
          NPSMonthlyReport>
    ),
    NPSMonthlyReport,
    PrefetchHooks Function()> {
  $$NPSMonthlyReportsTableTableManager(
      _$UnifiedDatabase db, $NPSMonthlyReportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NPSMonthlyReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NPSMonthlyReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NPSMonthlyReportsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<String> monthYear = const Value.absent(),
            Value<double?> allTimeNpsPercentage = const Value.absent(),
            Value<double?> threeMonthNpsPercentage = const Value.absent(),
            Value<double?> oneMonthNpsPercentage = const Value.absent(),
            Value<double> allTimeSales = const Value.absent(),
            Value<int> allTimeTableCount = const Value.absent(),
            Value<int> monthFeedbackYes = const Value.absent(),
            Value<int> monthFeedbackMaybe = const Value.absent(),
            Value<int> monthFeedbackNo = const Value.absent(),
            Value<int> threeMonthFeedbackYes = const Value.absent(),
            Value<int> threeMonthFeedbackMaybe = const Value.absent(),
            Value<int> threeMonthFeedbackNo = const Value.absent(),
            Value<int> allTimeFeedbackYes = const Value.absent(),
            Value<int> allTimeFeedbackMaybe = const Value.absent(),
            Value<int> allTimeFeedbackNo = const Value.absent(),
            Value<String> generatedAt = const Value.absent(),
            Value<String> dataAsOfDate = const Value.absent(),
          }) =>
              NPSMonthlyReportsCompanion(
            id: id,
            serverId: serverId,
            monthYear: monthYear,
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
            required String monthYear,
            Value<double?> allTimeNpsPercentage = const Value.absent(),
            Value<double?> threeMonthNpsPercentage = const Value.absent(),
            Value<double?> oneMonthNpsPercentage = const Value.absent(),
            Value<double> allTimeSales = const Value.absent(),
            Value<int> allTimeTableCount = const Value.absent(),
            Value<int> monthFeedbackYes = const Value.absent(),
            Value<int> monthFeedbackMaybe = const Value.absent(),
            Value<int> monthFeedbackNo = const Value.absent(),
            Value<int> threeMonthFeedbackYes = const Value.absent(),
            Value<int> threeMonthFeedbackMaybe = const Value.absent(),
            Value<int> threeMonthFeedbackNo = const Value.absent(),
            Value<int> allTimeFeedbackYes = const Value.absent(),
            Value<int> allTimeFeedbackMaybe = const Value.absent(),
            Value<int> allTimeFeedbackNo = const Value.absent(),
            Value<String> generatedAt = const Value.absent(),
            required String dataAsOfDate,
          }) =>
              NPSMonthlyReportsCompanion.insert(
            id: id,
            serverId: serverId,
            monthYear: monthYear,
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

typedef $$NPSMonthlyReportsTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $NPSMonthlyReportsTable,
    NPSMonthlyReport,
    $$NPSMonthlyReportsTableFilterComposer,
    $$NPSMonthlyReportsTableOrderingComposer,
    $$NPSMonthlyReportsTableAnnotationComposer,
    $$NPSMonthlyReportsTableCreateCompanionBuilder,
    $$NPSMonthlyReportsTableUpdateCompanionBuilder,
    (
      NPSMonthlyReport,
      BaseReferences<_$UnifiedDatabase, $NPSMonthlyReportsTable,
          NPSMonthlyReport>
    ),
    NPSMonthlyReport,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<String> updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$UnifiedDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSetting,
      BaseReferences<_$UnifiedDatabase, $AppSettingsTable, AppSetting>
    ),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$UnifiedDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSetting,
      BaseReferences<_$UnifiedDatabase, $AppSettingsTable, AppSetting>
    ),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$PerformanceDataTableCreateCompanionBuilder = PerformanceDataCompanion
    Function({
  Value<int> id,
  required String serverId,
  required String dataType,
  required String dataContent,
  Value<String> createdAt,
});
typedef $$PerformanceDataTableUpdateCompanionBuilder = PerformanceDataCompanion
    Function({
  Value<int> id,
  Value<String> serverId,
  Value<String> dataType,
  Value<String> dataContent,
  Value<String> createdAt,
});

class $$PerformanceDataTableFilterComposer
    extends Composer<_$UnifiedDatabase, $PerformanceDataTable> {
  $$PerformanceDataTableFilterComposer({
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

  ColumnFilters<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataContent => $composableBuilder(
      column: $table.dataContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PerformanceDataTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $PerformanceDataTable> {
  $$PerformanceDataTableOrderingComposer({
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

  ColumnOrderings<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataContent => $composableBuilder(
      column: $table.dataContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PerformanceDataTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $PerformanceDataTable> {
  $$PerformanceDataTableAnnotationComposer({
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

  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<String> get dataContent => $composableBuilder(
      column: $table.dataContent, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PerformanceDataTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $PerformanceDataTable,
    PerformanceDataData,
    $$PerformanceDataTableFilterComposer,
    $$PerformanceDataTableOrderingComposer,
    $$PerformanceDataTableAnnotationComposer,
    $$PerformanceDataTableCreateCompanionBuilder,
    $$PerformanceDataTableUpdateCompanionBuilder,
    (
      PerformanceDataData,
      BaseReferences<_$UnifiedDatabase, $PerformanceDataTable,
          PerformanceDataData>
    ),
    PerformanceDataData,
    PrefetchHooks Function()> {
  $$PerformanceDataTableTableManager(
      _$UnifiedDatabase db, $PerformanceDataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PerformanceDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PerformanceDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PerformanceDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<String> dataType = const Value.absent(),
            Value<String> dataContent = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              PerformanceDataCompanion(
            id: id,
            serverId: serverId,
            dataType: dataType,
            dataContent: dataContent,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String serverId,
            required String dataType,
            required String dataContent,
            Value<String> createdAt = const Value.absent(),
          }) =>
              PerformanceDataCompanion.insert(
            id: id,
            serverId: serverId,
            dataType: dataType,
            dataContent: dataContent,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PerformanceDataTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $PerformanceDataTable,
    PerformanceDataData,
    $$PerformanceDataTableFilterComposer,
    $$PerformanceDataTableOrderingComposer,
    $$PerformanceDataTableAnnotationComposer,
    $$PerformanceDataTableCreateCompanionBuilder,
    $$PerformanceDataTableUpdateCompanionBuilder,
    (
      PerformanceDataData,
      BaseReferences<_$UnifiedDatabase, $PerformanceDataTable,
          PerformanceDataData>
    ),
    PerformanceDataData,
    PrefetchHooks Function()>;
typedef $$BusinessDataTableCreateCompanionBuilder = BusinessDataCompanion
    Function({
  Value<int> id,
  required String monthYear,
  required String dataType,
  required String dataContent,
  Value<String> createdAt,
});
typedef $$BusinessDataTableUpdateCompanionBuilder = BusinessDataCompanion
    Function({
  Value<int> id,
  Value<String> monthYear,
  Value<String> dataType,
  Value<String> dataContent,
  Value<String> createdAt,
});

class $$BusinessDataTableFilterComposer
    extends Composer<_$UnifiedDatabase, $BusinessDataTable> {
  $$BusinessDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get monthYear => $composableBuilder(
      column: $table.monthYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataContent => $composableBuilder(
      column: $table.dataContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BusinessDataTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $BusinessDataTable> {
  $$BusinessDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get monthYear => $composableBuilder(
      column: $table.monthYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataContent => $composableBuilder(
      column: $table.dataContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BusinessDataTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $BusinessDataTable> {
  $$BusinessDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get monthYear =>
      $composableBuilder(column: $table.monthYear, builder: (column) => column);

  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<String> get dataContent => $composableBuilder(
      column: $table.dataContent, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BusinessDataTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $BusinessDataTable,
    BusinessDataData,
    $$BusinessDataTableFilterComposer,
    $$BusinessDataTableOrderingComposer,
    $$BusinessDataTableAnnotationComposer,
    $$BusinessDataTableCreateCompanionBuilder,
    $$BusinessDataTableUpdateCompanionBuilder,
    (
      BusinessDataData,
      BaseReferences<_$UnifiedDatabase, $BusinessDataTable, BusinessDataData>
    ),
    BusinessDataData,
    PrefetchHooks Function()> {
  $$BusinessDataTableTableManager(
      _$UnifiedDatabase db, $BusinessDataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> monthYear = const Value.absent(),
            Value<String> dataType = const Value.absent(),
            Value<String> dataContent = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              BusinessDataCompanion(
            id: id,
            monthYear: monthYear,
            dataType: dataType,
            dataContent: dataContent,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String monthYear,
            required String dataType,
            required String dataContent,
            Value<String> createdAt = const Value.absent(),
          }) =>
              BusinessDataCompanion.insert(
            id: id,
            monthYear: monthYear,
            dataType: dataType,
            dataContent: dataContent,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BusinessDataTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $BusinessDataTable,
    BusinessDataData,
    $$BusinessDataTableFilterComposer,
    $$BusinessDataTableOrderingComposer,
    $$BusinessDataTableAnnotationComposer,
    $$BusinessDataTableCreateCompanionBuilder,
    $$BusinessDataTableUpdateCompanionBuilder,
    (
      BusinessDataData,
      BaseReferences<_$UnifiedDatabase, $BusinessDataTable, BusinessDataData>
    ),
    BusinessDataData,
    PrefetchHooks Function()>;
typedef $$StationAssignmentsTableCreateCompanionBuilder
    = StationAssignmentsCompanion Function({
  Value<int> id,
  required String serverId,
  required String shiftDate,
  required String shiftType,
  Value<String?> stationType,
  Value<String?> sectionAssignment,
  Value<String> createdAt,
});
typedef $$StationAssignmentsTableUpdateCompanionBuilder
    = StationAssignmentsCompanion Function({
  Value<int> id,
  Value<String> serverId,
  Value<String> shiftDate,
  Value<String> shiftType,
  Value<String?> stationType,
  Value<String?> sectionAssignment,
  Value<String> createdAt,
});

class $$StationAssignmentsTableFilterComposer
    extends Composer<_$UnifiedDatabase, $StationAssignmentsTable> {
  $$StationAssignmentsTableFilterComposer({
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

  ColumnFilters<String> get shiftDate => $composableBuilder(
      column: $table.shiftDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shiftType => $composableBuilder(
      column: $table.shiftType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionAssignment => $composableBuilder(
      column: $table.sectionAssignment,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$StationAssignmentsTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $StationAssignmentsTable> {
  $$StationAssignmentsTableOrderingComposer({
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

  ColumnOrderings<String> get shiftDate => $composableBuilder(
      column: $table.shiftDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shiftType => $composableBuilder(
      column: $table.shiftType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionAssignment => $composableBuilder(
      column: $table.sectionAssignment,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$StationAssignmentsTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $StationAssignmentsTable> {
  $$StationAssignmentsTableAnnotationComposer({
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

  GeneratedColumn<String> get shiftDate =>
      $composableBuilder(column: $table.shiftDate, builder: (column) => column);

  GeneratedColumn<String> get shiftType =>
      $composableBuilder(column: $table.shiftType, builder: (column) => column);

  GeneratedColumn<String> get stationType => $composableBuilder(
      column: $table.stationType, builder: (column) => column);

  GeneratedColumn<String> get sectionAssignment => $composableBuilder(
      column: $table.sectionAssignment, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StationAssignmentsTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $StationAssignmentsTable,
    StationAssignment,
    $$StationAssignmentsTableFilterComposer,
    $$StationAssignmentsTableOrderingComposer,
    $$StationAssignmentsTableAnnotationComposer,
    $$StationAssignmentsTableCreateCompanionBuilder,
    $$StationAssignmentsTableUpdateCompanionBuilder,
    (
      StationAssignment,
      BaseReferences<_$UnifiedDatabase, $StationAssignmentsTable,
          StationAssignment>
    ),
    StationAssignment,
    PrefetchHooks Function()> {
  $$StationAssignmentsTableTableManager(
      _$UnifiedDatabase db, $StationAssignmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StationAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StationAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StationAssignmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<String> shiftDate = const Value.absent(),
            Value<String> shiftType = const Value.absent(),
            Value<String?> stationType = const Value.absent(),
            Value<String?> sectionAssignment = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              StationAssignmentsCompanion(
            id: id,
            serverId: serverId,
            shiftDate: shiftDate,
            shiftType: shiftType,
            stationType: stationType,
            sectionAssignment: sectionAssignment,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String serverId,
            required String shiftDate,
            required String shiftType,
            Value<String?> stationType = const Value.absent(),
            Value<String?> sectionAssignment = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              StationAssignmentsCompanion.insert(
            id: id,
            serverId: serverId,
            shiftDate: shiftDate,
            shiftType: shiftType,
            stationType: stationType,
            sectionAssignment: sectionAssignment,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StationAssignmentsTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $StationAssignmentsTable,
    StationAssignment,
    $$StationAssignmentsTableFilterComposer,
    $$StationAssignmentsTableOrderingComposer,
    $$StationAssignmentsTableAnnotationComposer,
    $$StationAssignmentsTableCreateCompanionBuilder,
    $$StationAssignmentsTableUpdateCompanionBuilder,
    (
      StationAssignment,
      BaseReferences<_$UnifiedDatabase, $StationAssignmentsTable,
          StationAssignment>
    ),
    StationAssignment,
    PrefetchHooks Function()>;
typedef $$TapLogsTableCreateCompanionBuilder = TapLogsCompanion Function({
  required String key,
  required String data,
  Value<String> updatedAt,
  Value<int> rowid,
});
typedef $$TapLogsTableUpdateCompanionBuilder = TapLogsCompanion Function({
  Value<String> key,
  Value<String> data,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$TapLogsTableFilterComposer
    extends Composer<_$UnifiedDatabase, $TapLogsTable> {
  $$TapLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TapLogsTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $TapLogsTable> {
  $$TapLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TapLogsTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $TapLogsTable> {
  $$TapLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TapLogsTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $TapLogsTable,
    TapLog,
    $$TapLogsTableFilterComposer,
    $$TapLogsTableOrderingComposer,
    $$TapLogsTableAnnotationComposer,
    $$TapLogsTableCreateCompanionBuilder,
    $$TapLogsTableUpdateCompanionBuilder,
    (TapLog, BaseReferences<_$UnifiedDatabase, $TapLogsTable, TapLog>),
    TapLog,
    PrefetchHooks Function()> {
  $$TapLogsTableTableManager(_$UnifiedDatabase db, $TapLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TapLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TapLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TapLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TapLogsCompanion(
            key: key,
            data: data,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String data,
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TapLogsCompanion.insert(
            key: key,
            data: data,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TapLogsTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $TapLogsTable,
    TapLog,
    $$TapLogsTableFilterComposer,
    $$TapLogsTableOrderingComposer,
    $$TapLogsTableAnnotationComposer,
    $$TapLogsTableCreateCompanionBuilder,
    $$TapLogsTableUpdateCompanionBuilder,
    (TapLog, BaseReferences<_$UnifiedDatabase, $TapLogsTable, TapLog>),
    TapLog,
    PrefetchHooks Function()>;
typedef $$DayPlansTableCreateCompanionBuilder = DayPlansCompanion Function({
  required String date,
  required String data,
  Value<String> updatedAt,
  Value<int> rowid,
});
typedef $$DayPlansTableUpdateCompanionBuilder = DayPlansCompanion Function({
  Value<String> date,
  Value<String> data,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$DayPlansTableFilterComposer
    extends Composer<_$UnifiedDatabase, $DayPlansTable> {
  $$DayPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DayPlansTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $DayPlansTable> {
  $$DayPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DayPlansTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $DayPlansTable> {
  $$DayPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DayPlansTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $DayPlansTable,
    DayPlan,
    $$DayPlansTableFilterComposer,
    $$DayPlansTableOrderingComposer,
    $$DayPlansTableAnnotationComposer,
    $$DayPlansTableCreateCompanionBuilder,
    $$DayPlansTableUpdateCompanionBuilder,
    (DayPlan, BaseReferences<_$UnifiedDatabase, $DayPlansTable, DayPlan>),
    DayPlan,
    PrefetchHooks Function()> {
  $$DayPlansTableTableManager(_$UnifiedDatabase db, $DayPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DayPlansCompanion(
            date: date,
            data: data,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            required String data,
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DayPlansCompanion.insert(
            date: date,
            data: data,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DayPlansTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $DayPlansTable,
    DayPlan,
    $$DayPlansTableFilterComposer,
    $$DayPlansTableOrderingComposer,
    $$DayPlansTableAnnotationComposer,
    $$DayPlansTableCreateCompanionBuilder,
    $$DayPlansTableUpdateCompanionBuilder,
    (DayPlan, BaseReferences<_$UnifiedDatabase, $DayPlansTable, DayPlan>),
    DayPlan,
    PrefetchHooks Function()>;
typedef $$AssetsTableCreateCompanionBuilder = AssetsCompanion Function({
  required String key,
  required String data,
  Value<String> updatedAt,
  Value<int> rowid,
});
typedef $$AssetsTableUpdateCompanionBuilder = AssetsCompanion Function({
  Value<String> key,
  Value<String> data,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$AssetsTableFilterComposer
    extends Composer<_$UnifiedDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AssetsTableOrderingComposer
    extends Composer<_$UnifiedDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$UnifiedDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AssetsTableTableManager extends RootTableManager<
    _$UnifiedDatabase,
    $AssetsTable,
    Asset,
    $$AssetsTableFilterComposer,
    $$AssetsTableOrderingComposer,
    $$AssetsTableAnnotationComposer,
    $$AssetsTableCreateCompanionBuilder,
    $$AssetsTableUpdateCompanionBuilder,
    (Asset, BaseReferences<_$UnifiedDatabase, $AssetsTable, Asset>),
    Asset,
    PrefetchHooks Function()> {
  $$AssetsTableTableManager(_$UnifiedDatabase db, $AssetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetsCompanion(
            key: key,
            data: data,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String data,
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetsCompanion.insert(
            key: key,
            data: data,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AssetsTableProcessedTableManager = ProcessedTableManager<
    _$UnifiedDatabase,
    $AssetsTable,
    Asset,
    $$AssetsTableFilterComposer,
    $$AssetsTableOrderingComposer,
    $$AssetsTableAnnotationComposer,
    $$AssetsTableCreateCompanionBuilder,
    $$AssetsTableUpdateCompanionBuilder,
    (Asset, BaseReferences<_$UnifiedDatabase, $AssetsTable, Asset>),
    Asset,
    PrefetchHooks Function()>;

class $UnifiedDatabaseManager {
  final _$UnifiedDatabase _db;
  $UnifiedDatabaseManager(this._db);
  $$ServersTableTableManager get servers =>
      $$ServersTableTableManager(_db, _db.servers);
  $$ShiftRecordsTableTableManager get shiftRecords =>
      $$ShiftRecordsTableTableManager(_db, _db.shiftRecords);
  $$ServerProfilesTableTableManager get serverProfiles =>
      $$ServerProfilesTableTableManager(_db, _db.serverProfiles);
  $$NPSFeedbackTableTableManager get nPSFeedback =>
      $$NPSFeedbackTableTableManager(_db, _db.nPSFeedback);
  $$NPSMonthlyReportsTableTableManager get nPSMonthlyReports =>
      $$NPSMonthlyReportsTableTableManager(_db, _db.nPSMonthlyReports);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$PerformanceDataTableTableManager get performanceData =>
      $$PerformanceDataTableTableManager(_db, _db.performanceData);
  $$BusinessDataTableTableManager get businessData =>
      $$BusinessDataTableTableManager(_db, _db.businessData);
  $$StationAssignmentsTableTableManager get stationAssignments =>
      $$StationAssignmentsTableTableManager(_db, _db.stationAssignments);
  $$TapLogsTableTableManager get tapLogs =>
      $$TapLogsTableTableManager(_db, _db.tapLogs);
  $$DayPlansTableTableManager get dayPlans =>
      $$DayPlansTableTableManager(_db, _db.dayPlans);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
}
