// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RideSummariesTable extends RideSummaries
    with TableInfo<$RideSummariesTable, RideSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RideSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _shortcutIdMeta =
      const VerificationMeta('shortcutId');
  @override
  late final GeneratedColumn<String> shortcutId = GeneratedColumn<String>(
      'shortcut_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _distanceMetresMeta =
      const VerificationMeta('distanceMetres');
  @override
  late final GeneratedColumn<double> distanceMetres = GeneratedColumn<double>(
      'distance_metres', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _elevationGainMetresMeta =
      const VerificationMeta('elevationGainMetres');
  @override
  late final GeneratedColumn<double> elevationGainMetres =
      GeneratedColumn<double>('elevation_gain_metres', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _elevationLossMetresMeta =
      const VerificationMeta('elevationLossMetres');
  @override
  late final GeneratedColumn<double> elevationLossMetres =
      GeneratedColumn<double>('elevation_loss_metres', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _averageSpeedKmhMeta =
      const VerificationMeta('averageSpeedKmh');
  @override
  late final GeneratedColumn<double> averageSpeedKmh = GeneratedColumn<double>(
      'average_speed_kmh', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        shortcutId,
        distanceMetres,
        durationSeconds,
        elevationGainMetres,
        elevationLossMetres,
        averageSpeedKmh,
        startTime
      ];
  @override
  String get aliasedName => _alias ?? 'ride_summaries';
  @override
  String get actualTableName => 'ride_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<RideSummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shortcut_id')) {
      context.handle(
          _shortcutIdMeta,
          shortcutId.isAcceptableOrUnknown(
              data['shortcut_id']!, _shortcutIdMeta));
    }
    if (data.containsKey('distance_metres')) {
      context.handle(
          _distanceMetresMeta,
          distanceMetres.isAcceptableOrUnknown(
              data['distance_metres']!, _distanceMetresMeta));
    } else if (isInserting) {
      context.missing(_distanceMetresMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('elevation_gain_metres')) {
      context.handle(
          _elevationGainMetresMeta,
          elevationGainMetres.isAcceptableOrUnknown(
              data['elevation_gain_metres']!, _elevationGainMetresMeta));
    } else if (isInserting) {
      context.missing(_elevationGainMetresMeta);
    }
    if (data.containsKey('elevation_loss_metres')) {
      context.handle(
          _elevationLossMetresMeta,
          elevationLossMetres.isAcceptableOrUnknown(
              data['elevation_loss_metres']!, _elevationLossMetresMeta));
    } else if (isInserting) {
      context.missing(_elevationLossMetresMeta);
    }
    if (data.containsKey('average_speed_kmh')) {
      context.handle(
          _averageSpeedKmhMeta,
          averageSpeedKmh.isAcceptableOrUnknown(
              data['average_speed_kmh']!, _averageSpeedKmhMeta));
    } else if (isInserting) {
      context.missing(_averageSpeedKmhMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RideSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RideSummary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      shortcutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shortcut_id']),
      distanceMetres: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_metres'])!,
      durationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}duration_seconds'])!,
      elevationGainMetres: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}elevation_gain_metres'])!,
      elevationLossMetres: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}elevation_loss_metres'])!,
      averageSpeedKmh: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}average_speed_kmh'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
    );
  }

  @override
  $RideSummariesTable createAlias(String alias) {
    return $RideSummariesTable(attachedDatabase, alias);
  }
}

class RideSummary extends DataClass implements Insertable<RideSummary> {
  final int id;
  final String? shortcutId;
  final double distanceMetres;
  final double durationSeconds;
  final double elevationGainMetres;
  final double elevationLossMetres;
  final double averageSpeedKmh;
  final DateTime startTime;
  const RideSummary(
      {required this.id,
      this.shortcutId,
      required this.distanceMetres,
      required this.durationSeconds,
      required this.elevationGainMetres,
      required this.elevationLossMetres,
      required this.averageSpeedKmh,
      required this.startTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || shortcutId != null) {
      map['shortcut_id'] = Variable<String>(shortcutId);
    }
    map['distance_metres'] = Variable<double>(distanceMetres);
    map['duration_seconds'] = Variable<double>(durationSeconds);
    map['elevation_gain_metres'] = Variable<double>(elevationGainMetres);
    map['elevation_loss_metres'] = Variable<double>(elevationLossMetres);
    map['average_speed_kmh'] = Variable<double>(averageSpeedKmh);
    map['start_time'] = Variable<DateTime>(startTime);
    return map;
  }

  RideSummariesCompanion toCompanion(bool nullToAbsent) {
    return RideSummariesCompanion(
      id: Value(id),
      shortcutId: shortcutId == null && nullToAbsent
          ? const Value.absent()
          : Value(shortcutId),
      distanceMetres: Value(distanceMetres),
      durationSeconds: Value(durationSeconds),
      elevationGainMetres: Value(elevationGainMetres),
      elevationLossMetres: Value(elevationLossMetres),
      averageSpeedKmh: Value(averageSpeedKmh),
      startTime: Value(startTime),
    );
  }

  factory RideSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideSummary(
      id: serializer.fromJson<int>(json['id']),
      shortcutId: serializer.fromJson<String?>(json['shortcutId']),
      distanceMetres: serializer.fromJson<double>(json['distanceMetres']),
      durationSeconds: serializer.fromJson<double>(json['durationSeconds']),
      elevationGainMetres:
          serializer.fromJson<double>(json['elevationGainMetres']),
      elevationLossMetres:
          serializer.fromJson<double>(json['elevationLossMetres']),
      averageSpeedKmh: serializer.fromJson<double>(json['averageSpeedKmh']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shortcutId': serializer.toJson<String?>(shortcutId),
      'distanceMetres': serializer.toJson<double>(distanceMetres),
      'durationSeconds': serializer.toJson<double>(durationSeconds),
      'elevationGainMetres': serializer.toJson<double>(elevationGainMetres),
      'elevationLossMetres': serializer.toJson<double>(elevationLossMetres),
      'averageSpeedKmh': serializer.toJson<double>(averageSpeedKmh),
      'startTime': serializer.toJson<DateTime>(startTime),
    };
  }

  RideSummary copyWith(
          {int? id,
          Value<String?> shortcutId = const Value.absent(),
          double? distanceMetres,
          double? durationSeconds,
          double? elevationGainMetres,
          double? elevationLossMetres,
          double? averageSpeedKmh,
          DateTime? startTime}) =>
      RideSummary(
        id: id ?? this.id,
        shortcutId: shortcutId.present ? shortcutId.value : this.shortcutId,
        distanceMetres: distanceMetres ?? this.distanceMetres,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        elevationGainMetres: elevationGainMetres ?? this.elevationGainMetres,
        elevationLossMetres: elevationLossMetres ?? this.elevationLossMetres,
        averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
        startTime: startTime ?? this.startTime,
      );
  @override
  String toString() {
    return (StringBuffer('RideSummary(')
          ..write('id: $id, ')
          ..write('shortcutId: $shortcutId, ')
          ..write('distanceMetres: $distanceMetres, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('elevationGainMetres: $elevationGainMetres, ')
          ..write('elevationLossMetres: $elevationLossMetres, ')
          ..write('averageSpeedKmh: $averageSpeedKmh, ')
          ..write('startTime: $startTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      shortcutId,
      distanceMetres,
      durationSeconds,
      elevationGainMetres,
      elevationLossMetres,
      averageSpeedKmh,
      startTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideSummary &&
          other.id == this.id &&
          other.shortcutId == this.shortcutId &&
          other.distanceMetres == this.distanceMetres &&
          other.durationSeconds == this.durationSeconds &&
          other.elevationGainMetres == this.elevationGainMetres &&
          other.elevationLossMetres == this.elevationLossMetres &&
          other.averageSpeedKmh == this.averageSpeedKmh &&
          other.startTime == this.startTime);
}

class RideSummariesCompanion extends UpdateCompanion<RideSummary> {
  final Value<int> id;
  final Value<String?> shortcutId;
  final Value<double> distanceMetres;
  final Value<double> durationSeconds;
  final Value<double> elevationGainMetres;
  final Value<double> elevationLossMetres;
  final Value<double> averageSpeedKmh;
  final Value<DateTime> startTime;
  const RideSummariesCompanion({
    this.id = const Value.absent(),
    this.shortcutId = const Value.absent(),
    this.distanceMetres = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.elevationGainMetres = const Value.absent(),
    this.elevationLossMetres = const Value.absent(),
    this.averageSpeedKmh = const Value.absent(),
    this.startTime = const Value.absent(),
  });
  RideSummariesCompanion.insert({
    this.id = const Value.absent(),
    this.shortcutId = const Value.absent(),
    required double distanceMetres,
    required double durationSeconds,
    required double elevationGainMetres,
    required double elevationLossMetres,
    required double averageSpeedKmh,
    required DateTime startTime,
  })  : distanceMetres = Value(distanceMetres),
        durationSeconds = Value(durationSeconds),
        elevationGainMetres = Value(elevationGainMetres),
        elevationLossMetres = Value(elevationLossMetres),
        averageSpeedKmh = Value(averageSpeedKmh),
        startTime = Value(startTime);
  static Insertable<RideSummary> custom({
    Expression<int>? id,
    Expression<String>? shortcutId,
    Expression<double>? distanceMetres,
    Expression<double>? durationSeconds,
    Expression<double>? elevationGainMetres,
    Expression<double>? elevationLossMetres,
    Expression<double>? averageSpeedKmh,
    Expression<DateTime>? startTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shortcutId != null) 'shortcut_id': shortcutId,
      if (distanceMetres != null) 'distance_metres': distanceMetres,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (elevationGainMetres != null)
        'elevation_gain_metres': elevationGainMetres,
      if (elevationLossMetres != null)
        'elevation_loss_metres': elevationLossMetres,
      if (averageSpeedKmh != null) 'average_speed_kmh': averageSpeedKmh,
      if (startTime != null) 'start_time': startTime,
    });
  }

  RideSummariesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? shortcutId,
      Value<double>? distanceMetres,
      Value<double>? durationSeconds,
      Value<double>? elevationGainMetres,
      Value<double>? elevationLossMetres,
      Value<double>? averageSpeedKmh,
      Value<DateTime>? startTime}) {
    return RideSummariesCompanion(
      id: id ?? this.id,
      shortcutId: shortcutId ?? this.shortcutId,
      distanceMetres: distanceMetres ?? this.distanceMetres,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      elevationGainMetres: elevationGainMetres ?? this.elevationGainMetres,
      elevationLossMetres: elevationLossMetres ?? this.elevationLossMetres,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shortcutId.present) {
      map['shortcut_id'] = Variable<String>(shortcutId.value);
    }
    if (distanceMetres.present) {
      map['distance_metres'] = Variable<double>(distanceMetres.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (elevationGainMetres.present) {
      map['elevation_gain_metres'] =
          Variable<double>(elevationGainMetres.value);
    }
    if (elevationLossMetres.present) {
      map['elevation_loss_metres'] =
          Variable<double>(elevationLossMetres.value);
    }
    if (averageSpeedKmh.present) {
      map['average_speed_kmh'] = Variable<double>(averageSpeedKmh.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RideSummariesCompanion(')
          ..write('id: $id, ')
          ..write('shortcutId: $shortcutId, ')
          ..write('distanceMetres: $distanceMetres, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('elevationGainMetres: $elevationGainMetres, ')
          ..write('elevationLossMetres: $elevationLossMetres, ')
          ..write('averageSpeedKmh: $averageSpeedKmh, ')
          ..write('startTime: $startTime')
          ..write(')'))
        .toString();
  }
}

class $ChallengesTable extends Challenges
    with TableInfo<$ChallengesTable, Challenge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChallengesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
      'xp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _closingTimeMeta =
      const VerificationMeta('closingTime');
  @override
  late final GeneratedColumn<DateTime> closingTime = GeneratedColumn<DateTime>(
      'closing_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
      'target', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isWeeklyMeta =
      const VerificationMeta('isWeekly');
  @override
  late final GeneratedColumn<bool> isWeekly =
      GeneratedColumn<bool>('is_weekly', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("is_weekly" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  static const VerificationMeta _isOpenMeta = const VerificationMeta('isOpen');
  @override
  late final GeneratedColumn<bool> isOpen =
      GeneratedColumn<bool>('is_open', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("is_open" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  static const VerificationMeta _shortcutIdMeta =
      const VerificationMeta('shortcutId');
  @override
  late final GeneratedColumn<String> shortcutId = GeneratedColumn<String>(
      'shortcut_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
      'type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        xp,
        startTime,
        closingTime,
        description,
        target,
        progress,
        isWeekly,
        isOpen,
        shortcutId,
        type
      ];
  @override
  String get aliasedName => _alias ?? 'challenges';
  @override
  String get actualTableName => 'challenges';
  @override
  VerificationContext validateIntegrity(Insertable<Challenge> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    } else if (isInserting) {
      context.missing(_xpMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('closing_time')) {
      context.handle(
          _closingTimeMeta,
          closingTime.isAcceptableOrUnknown(
              data['closing_time']!, _closingTimeMeta));
    } else if (isInserting) {
      context.missing(_closingTimeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta,
          target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('is_weekly')) {
      context.handle(_isWeeklyMeta,
          isWeekly.isAcceptableOrUnknown(data['is_weekly']!, _isWeeklyMeta));
    } else if (isInserting) {
      context.missing(_isWeeklyMeta);
    }
    if (data.containsKey('is_open')) {
      context.handle(_isOpenMeta,
          isOpen.isAcceptableOrUnknown(data['is_open']!, _isOpenMeta));
    } else if (isInserting) {
      context.missing(_isOpenMeta);
    }
    if (data.containsKey('shortcut_id')) {
      context.handle(
          _shortcutIdMeta,
          shortcutId.isAcceptableOrUnknown(
              data['shortcut_id']!, _shortcutIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Challenge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Challenge(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      xp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      closingTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closing_time'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      target: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      isWeekly: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_weekly'])!,
      isOpen: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_open'])!,
      shortcutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shortcut_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $ChallengesTable createAlias(String alias) {
    return $ChallengesTable(attachedDatabase, alias);
  }
}

class Challenge extends DataClass implements Insertable<Challenge> {
  final int id;
  final int xp;
  final DateTime startTime;
  final DateTime closingTime;
  final String description;
  final int target;
  final int progress;
  final bool isWeekly;
  final bool isOpen;
  final String? shortcutId;
  final int type;
  const Challenge(
      {required this.id,
      required this.xp,
      required this.startTime,
      required this.closingTime,
      required this.description,
      required this.target,
      required this.progress,
      required this.isWeekly,
      required this.isOpen,
      this.shortcutId,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['xp'] = Variable<int>(xp);
    map['start_time'] = Variable<DateTime>(startTime);
    map['closing_time'] = Variable<DateTime>(closingTime);
    map['description'] = Variable<String>(description);
    map['target'] = Variable<int>(target);
    map['progress'] = Variable<int>(progress);
    map['is_weekly'] = Variable<bool>(isWeekly);
    map['is_open'] = Variable<bool>(isOpen);
    if (!nullToAbsent || shortcutId != null) {
      map['shortcut_id'] = Variable<String>(shortcutId);
    }
    map['type'] = Variable<int>(type);
    return map;
  }

  ChallengesCompanion toCompanion(bool nullToAbsent) {
    return ChallengesCompanion(
      id: Value(id),
      xp: Value(xp),
      startTime: Value(startTime),
      closingTime: Value(closingTime),
      description: Value(description),
      target: Value(target),
      progress: Value(progress),
      isWeekly: Value(isWeekly),
      isOpen: Value(isOpen),
      shortcutId: shortcutId == null && nullToAbsent
          ? const Value.absent()
          : Value(shortcutId),
      type: Value(type),
    );
  }

  factory Challenge.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Challenge(
      id: serializer.fromJson<int>(json['id']),
      xp: serializer.fromJson<int>(json['xp']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      closingTime: serializer.fromJson<DateTime>(json['closingTime']),
      description: serializer.fromJson<String>(json['description']),
      target: serializer.fromJson<int>(json['target']),
      progress: serializer.fromJson<int>(json['progress']),
      isWeekly: serializer.fromJson<bool>(json['isWeekly']),
      isOpen: serializer.fromJson<bool>(json['isOpen']),
      shortcutId: serializer.fromJson<String?>(json['shortcutId']),
      type: serializer.fromJson<int>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'xp': serializer.toJson<int>(xp),
      'startTime': serializer.toJson<DateTime>(startTime),
      'closingTime': serializer.toJson<DateTime>(closingTime),
      'description': serializer.toJson<String>(description),
      'target': serializer.toJson<int>(target),
      'progress': serializer.toJson<int>(progress),
      'isWeekly': serializer.toJson<bool>(isWeekly),
      'isOpen': serializer.toJson<bool>(isOpen),
      'shortcutId': serializer.toJson<String?>(shortcutId),
      'type': serializer.toJson<int>(type),
    };
  }

  Challenge copyWith(
          {int? id,
          int? xp,
          DateTime? startTime,
          DateTime? closingTime,
          String? description,
          int? target,
          int? progress,
          bool? isWeekly,
          bool? isOpen,
          Value<String?> shortcutId = const Value.absent(),
          int? type}) =>
      Challenge(
        id: id ?? this.id,
        xp: xp ?? this.xp,
        startTime: startTime ?? this.startTime,
        closingTime: closingTime ?? this.closingTime,
        description: description ?? this.description,
        target: target ?? this.target,
        progress: progress ?? this.progress,
        isWeekly: isWeekly ?? this.isWeekly,
        isOpen: isOpen ?? this.isOpen,
        shortcutId: shortcutId.present ? shortcutId.value : this.shortcutId,
        type: type ?? this.type,
      );
  @override
  String toString() {
    return (StringBuffer('Challenge(')
          ..write('id: $id, ')
          ..write('xp: $xp, ')
          ..write('startTime: $startTime, ')
          ..write('closingTime: $closingTime, ')
          ..write('description: $description, ')
          ..write('target: $target, ')
          ..write('progress: $progress, ')
          ..write('isWeekly: $isWeekly, ')
          ..write('isOpen: $isOpen, ')
          ..write('shortcutId: $shortcutId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, xp, startTime, closingTime, description,
      target, progress, isWeekly, isOpen, shortcutId, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Challenge &&
          other.id == this.id &&
          other.xp == this.xp &&
          other.startTime == this.startTime &&
          other.closingTime == this.closingTime &&
          other.description == this.description &&
          other.target == this.target &&
          other.progress == this.progress &&
          other.isWeekly == this.isWeekly &&
          other.isOpen == this.isOpen &&
          other.shortcutId == this.shortcutId &&
          other.type == this.type);
}

class ChallengesCompanion extends UpdateCompanion<Challenge> {
  final Value<int> id;
  final Value<int> xp;
  final Value<DateTime> startTime;
  final Value<DateTime> closingTime;
  final Value<String> description;
  final Value<int> target;
  final Value<int> progress;
  final Value<bool> isWeekly;
  final Value<bool> isOpen;
  final Value<String?> shortcutId;
  final Value<int> type;
  const ChallengesCompanion({
    this.id = const Value.absent(),
    this.xp = const Value.absent(),
    this.startTime = const Value.absent(),
    this.closingTime = const Value.absent(),
    this.description = const Value.absent(),
    this.target = const Value.absent(),
    this.progress = const Value.absent(),
    this.isWeekly = const Value.absent(),
    this.isOpen = const Value.absent(),
    this.shortcutId = const Value.absent(),
    this.type = const Value.absent(),
  });
  ChallengesCompanion.insert({
    this.id = const Value.absent(),
    required int xp,
    required DateTime startTime,
    required DateTime closingTime,
    required String description,
    required int target,
    required int progress,
    required bool isWeekly,
    required bool isOpen,
    this.shortcutId = const Value.absent(),
    required int type,
  })  : xp = Value(xp),
        startTime = Value(startTime),
        closingTime = Value(closingTime),
        description = Value(description),
        target = Value(target),
        progress = Value(progress),
        isWeekly = Value(isWeekly),
        isOpen = Value(isOpen),
        type = Value(type);
  static Insertable<Challenge> custom({
    Expression<int>? id,
    Expression<int>? xp,
    Expression<DateTime>? startTime,
    Expression<DateTime>? closingTime,
    Expression<String>? description,
    Expression<int>? target,
    Expression<int>? progress,
    Expression<bool>? isWeekly,
    Expression<bool>? isOpen,
    Expression<String>? shortcutId,
    Expression<int>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (xp != null) 'xp': xp,
      if (startTime != null) 'start_time': startTime,
      if (closingTime != null) 'closing_time': closingTime,
      if (description != null) 'description': description,
      if (target != null) 'target': target,
      if (progress != null) 'progress': progress,
      if (isWeekly != null) 'is_weekly': isWeekly,
      if (isOpen != null) 'is_open': isOpen,
      if (shortcutId != null) 'shortcut_id': shortcutId,
      if (type != null) 'type': type,
    });
  }

  ChallengesCompanion copyWith(
      {Value<int>? id,
      Value<int>? xp,
      Value<DateTime>? startTime,
      Value<DateTime>? closingTime,
      Value<String>? description,
      Value<int>? target,
      Value<int>? progress,
      Value<bool>? isWeekly,
      Value<bool>? isOpen,
      Value<String?>? shortcutId,
      Value<int>? type}) {
    return ChallengesCompanion(
      id: id ?? this.id,
      xp: xp ?? this.xp,
      startTime: startTime ?? this.startTime,
      closingTime: closingTime ?? this.closingTime,
      description: description ?? this.description,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      isWeekly: isWeekly ?? this.isWeekly,
      isOpen: isOpen ?? this.isOpen,
      shortcutId: shortcutId ?? this.shortcutId,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (closingTime.present) {
      map['closing_time'] = Variable<DateTime>(closingTime.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (isWeekly.present) {
      map['is_weekly'] = Variable<bool>(isWeekly.value);
    }
    if (isOpen.present) {
      map['is_open'] = Variable<bool>(isOpen.value);
    }
    if (shortcutId.present) {
      map['shortcut_id'] = Variable<String>(shortcutId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengesCompanion(')
          ..write('id: $id, ')
          ..write('xp: $xp, ')
          ..write('startTime: $startTime, ')
          ..write('closingTime: $closingTime, ')
          ..write('description: $description, ')
          ..write('target: $target, ')
          ..write('progress: $progress, ')
          ..write('isWeekly: $isWeekly, ')
          ..write('isOpen: $isOpen, ')
          ..write('shortcutId: $shortcutId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $RideSummariesTable rideSummaries = $RideSummariesTable(this);
  late final $ChallengesTable challenges = $ChallengesTable(this);
  late final RideSummaryDao rideSummaryDao =
      RideSummaryDao(this as AppDatabase);
  late final ChallengeDao challengeDao = ChallengeDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [rideSummaries, challenges];
}