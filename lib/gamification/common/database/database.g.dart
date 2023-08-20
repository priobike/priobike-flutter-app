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
  final double distanceMetres;
  final double durationSeconds;
  final double elevationGainMetres;
  final double elevationLossMetres;
  final double averageSpeedKmh;
  final DateTime startTime;
  const RideSummary(
      {required this.id,
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
          double? distanceMetres,
          double? durationSeconds,
          double? elevationGainMetres,
          double? elevationLossMetres,
          double? averageSpeedKmh,
          DateTime? startTime}) =>
      RideSummary(
        id: id ?? this.id,
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
  int get hashCode => Object.hash(id, distanceMetres, durationSeconds,
      elevationGainMetres, elevationLossMetres, averageSpeedKmh, startTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideSummary &&
          other.id == this.id &&
          other.distanceMetres == this.distanceMetres &&
          other.durationSeconds == this.durationSeconds &&
          other.elevationGainMetres == this.elevationGainMetres &&
          other.elevationLossMetres == this.elevationLossMetres &&
          other.averageSpeedKmh == this.averageSpeedKmh &&
          other.startTime == this.startTime);
}

class RideSummariesCompanion extends UpdateCompanion<RideSummary> {
  final Value<int> id;
  final Value<double> distanceMetres;
  final Value<double> durationSeconds;
  final Value<double> elevationGainMetres;
  final Value<double> elevationLossMetres;
  final Value<double> averageSpeedKmh;
  final Value<DateTime> startTime;
  const RideSummariesCompanion({
    this.id = const Value.absent(),
    this.distanceMetres = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.elevationGainMetres = const Value.absent(),
    this.elevationLossMetres = const Value.absent(),
    this.averageSpeedKmh = const Value.absent(),
    this.startTime = const Value.absent(),
  });
  RideSummariesCompanion.insert({
    this.id = const Value.absent(),
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
    Expression<double>? distanceMetres,
    Expression<double>? durationSeconds,
    Expression<double>? elevationGainMetres,
    Expression<double>? elevationLossMetres,
    Expression<double>? averageSpeedKmh,
    Expression<DateTime>? startTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
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
      Value<double>? distanceMetres,
      Value<double>? durationSeconds,
      Value<double>? elevationGainMetres,
      Value<double>? elevationLossMetres,
      Value<double>? averageSpeedKmh,
      Value<DateTime>? startTime}) {
    return RideSummariesCompanion(
      id: id ?? this.id,
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

class $DistanceChallengesTable extends DistanceChallenges
    with TableInfo<$DistanceChallengesTable, DistanceChallenge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistanceChallengesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _intervalStartMeta =
      const VerificationMeta('intervalStart');
  @override
  late final GeneratedColumn<DateTime> intervalStart =
      GeneratedColumn<DateTime>('interval_start', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _intervalEndMeta =
      const VerificationMeta('intervalEnd');
  @override
  late final GeneratedColumn<DateTime> intervalEnd = GeneratedColumn<DateTime>(
      'interval_end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _targetDistanceMeta =
      const VerificationMeta('targetDistance');
  @override
  late final GeneratedColumn<double> targetDistance = GeneratedColumn<double>(
      'target_distance', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, xp, intervalStart, intervalEnd, targetDistance];
  @override
  String get aliasedName => _alias ?? 'distance_challenges';
  @override
  String get actualTableName => 'distance_challenges';
  @override
  VerificationContext validateIntegrity(Insertable<DistanceChallenge> instance,
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
    if (data.containsKey('interval_start')) {
      context.handle(
          _intervalStartMeta,
          intervalStart.isAcceptableOrUnknown(
              data['interval_start']!, _intervalStartMeta));
    } else if (isInserting) {
      context.missing(_intervalStartMeta);
    }
    if (data.containsKey('interval_end')) {
      context.handle(
          _intervalEndMeta,
          intervalEnd.isAcceptableOrUnknown(
              data['interval_end']!, _intervalEndMeta));
    } else if (isInserting) {
      context.missing(_intervalEndMeta);
    }
    if (data.containsKey('target_distance')) {
      context.handle(
          _targetDistanceMeta,
          targetDistance.isAcceptableOrUnknown(
              data['target_distance']!, _targetDistanceMeta));
    } else if (isInserting) {
      context.missing(_targetDistanceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DistanceChallenge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DistanceChallenge(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      xp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp'])!,
      intervalStart: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}interval_start'])!,
      intervalEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}interval_end'])!,
      targetDistance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}target_distance'])!,
    );
  }

  @override
  $DistanceChallengesTable createAlias(String alias) {
    return $DistanceChallengesTable(attachedDatabase, alias);
  }
}

class DistanceChallenge extends DataClass
    implements Insertable<DistanceChallenge> {
  final int id;
  final int xp;
  final DateTime intervalStart;
  final DateTime intervalEnd;
  final double targetDistance;
  const DistanceChallenge(
      {required this.id,
      required this.xp,
      required this.intervalStart,
      required this.intervalEnd,
      required this.targetDistance});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['xp'] = Variable<int>(xp);
    map['interval_start'] = Variable<DateTime>(intervalStart);
    map['interval_end'] = Variable<DateTime>(intervalEnd);
    map['target_distance'] = Variable<double>(targetDistance);
    return map;
  }

  DistanceChallengesCompanion toCompanion(bool nullToAbsent) {
    return DistanceChallengesCompanion(
      id: Value(id),
      xp: Value(xp),
      intervalStart: Value(intervalStart),
      intervalEnd: Value(intervalEnd),
      targetDistance: Value(targetDistance),
    );
  }

  factory DistanceChallenge.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DistanceChallenge(
      id: serializer.fromJson<int>(json['id']),
      xp: serializer.fromJson<int>(json['xp']),
      intervalStart: serializer.fromJson<DateTime>(json['intervalStart']),
      intervalEnd: serializer.fromJson<DateTime>(json['intervalEnd']),
      targetDistance: serializer.fromJson<double>(json['targetDistance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'xp': serializer.toJson<int>(xp),
      'intervalStart': serializer.toJson<DateTime>(intervalStart),
      'intervalEnd': serializer.toJson<DateTime>(intervalEnd),
      'targetDistance': serializer.toJson<double>(targetDistance),
    };
  }

  DistanceChallenge copyWith(
          {int? id,
          int? xp,
          DateTime? intervalStart,
          DateTime? intervalEnd,
          double? targetDistance}) =>
      DistanceChallenge(
        id: id ?? this.id,
        xp: xp ?? this.xp,
        intervalStart: intervalStart ?? this.intervalStart,
        intervalEnd: intervalEnd ?? this.intervalEnd,
        targetDistance: targetDistance ?? this.targetDistance,
      );
  @override
  String toString() {
    return (StringBuffer('DistanceChallenge(')
          ..write('id: $id, ')
          ..write('xp: $xp, ')
          ..write('intervalStart: $intervalStart, ')
          ..write('intervalEnd: $intervalEnd, ')
          ..write('targetDistance: $targetDistance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, xp, intervalStart, intervalEnd, targetDistance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistanceChallenge &&
          other.id == this.id &&
          other.xp == this.xp &&
          other.intervalStart == this.intervalStart &&
          other.intervalEnd == this.intervalEnd &&
          other.targetDistance == this.targetDistance);
}

class DistanceChallengesCompanion extends UpdateCompanion<DistanceChallenge> {
  final Value<int> id;
  final Value<int> xp;
  final Value<DateTime> intervalStart;
  final Value<DateTime> intervalEnd;
  final Value<double> targetDistance;
  const DistanceChallengesCompanion({
    this.id = const Value.absent(),
    this.xp = const Value.absent(),
    this.intervalStart = const Value.absent(),
    this.intervalEnd = const Value.absent(),
    this.targetDistance = const Value.absent(),
  });
  DistanceChallengesCompanion.insert({
    this.id = const Value.absent(),
    required int xp,
    required DateTime intervalStart,
    required DateTime intervalEnd,
    required double targetDistance,
  })  : xp = Value(xp),
        intervalStart = Value(intervalStart),
        intervalEnd = Value(intervalEnd),
        targetDistance = Value(targetDistance);
  static Insertable<DistanceChallenge> custom({
    Expression<int>? id,
    Expression<int>? xp,
    Expression<DateTime>? intervalStart,
    Expression<DateTime>? intervalEnd,
    Expression<double>? targetDistance,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (xp != null) 'xp': xp,
      if (intervalStart != null) 'interval_start': intervalStart,
      if (intervalEnd != null) 'interval_end': intervalEnd,
      if (targetDistance != null) 'target_distance': targetDistance,
    });
  }

  DistanceChallengesCompanion copyWith(
      {Value<int>? id,
      Value<int>? xp,
      Value<DateTime>? intervalStart,
      Value<DateTime>? intervalEnd,
      Value<double>? targetDistance}) {
    return DistanceChallengesCompanion(
      id: id ?? this.id,
      xp: xp ?? this.xp,
      intervalStart: intervalStart ?? this.intervalStart,
      intervalEnd: intervalEnd ?? this.intervalEnd,
      targetDistance: targetDistance ?? this.targetDistance,
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
    if (intervalStart.present) {
      map['interval_start'] = Variable<DateTime>(intervalStart.value);
    }
    if (intervalEnd.present) {
      map['interval_end'] = Variable<DateTime>(intervalEnd.value);
    }
    if (targetDistance.present) {
      map['target_distance'] = Variable<double>(targetDistance.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistanceChallengesCompanion(')
          ..write('id: $id, ')
          ..write('xp: $xp, ')
          ..write('intervalStart: $intervalStart, ')
          ..write('intervalEnd: $intervalEnd, ')
          ..write('targetDistance: $targetDistance')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $RideSummariesTable rideSummaries = $RideSummariesTable(this);
  late final $DistanceChallengesTable distanceChallenges =
      $DistanceChallengesTable(this);
  late final RideSummaryDao rideSummaryDao =
      RideSummaryDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [rideSummaries, distanceChallenges];
}
