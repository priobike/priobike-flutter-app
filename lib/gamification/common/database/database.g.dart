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
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
      'start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
      'end', aliasedName, false,
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
      'type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _valueLabelMeta =
      const VerificationMeta('valueLabel');
  @override
  late final GeneratedColumn<String> valueLabel = GeneratedColumn<String>(
      'value_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        xp,
        start,
        end,
        description,
        target,
        progress,
        isWeekly,
        type,
        valueLabel
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
    if (data.containsKey('start')) {
      context.handle(
          _startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
          _endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    } else if (isInserting) {
      context.missing(_endMeta);
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
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value_label')) {
      context.handle(
          _valueLabelMeta,
          valueLabel.isAcceptableOrUnknown(
              data['value_label']!, _valueLabelMeta));
    } else if (isInserting) {
      context.missing(_valueLabelMeta);
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
      start: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      target: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      isWeekly: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_weekly'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!,
      valueLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_label'])!,
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
  final DateTime start;
  final DateTime end;
  final String description;
  final int target;
  final int progress;
  final bool isWeekly;
  final int type;
  final String valueLabel;
  const Challenge(
      {required this.id,
      required this.xp,
      required this.start,
      required this.end,
      required this.description,
      required this.target,
      required this.progress,
      required this.isWeekly,
      required this.type,
      required this.valueLabel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['xp'] = Variable<int>(xp);
    map['start'] = Variable<DateTime>(start);
    map['end'] = Variable<DateTime>(end);
    map['description'] = Variable<String>(description);
    map['target'] = Variable<int>(target);
    map['progress'] = Variable<int>(progress);
    map['is_weekly'] = Variable<bool>(isWeekly);
    map['type'] = Variable<int>(type);
    map['value_label'] = Variable<String>(valueLabel);
    return map;
  }

  ChallengesCompanion toCompanion(bool nullToAbsent) {
    return ChallengesCompanion(
      id: Value(id),
      xp: Value(xp),
      start: Value(start),
      end: Value(end),
      description: Value(description),
      target: Value(target),
      progress: Value(progress),
      isWeekly: Value(isWeekly),
      type: Value(type),
      valueLabel: Value(valueLabel),
    );
  }

  factory Challenge.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Challenge(
      id: serializer.fromJson<int>(json['id']),
      xp: serializer.fromJson<int>(json['xp']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime>(json['end']),
      description: serializer.fromJson<String>(json['description']),
      target: serializer.fromJson<int>(json['target']),
      progress: serializer.fromJson<int>(json['progress']),
      isWeekly: serializer.fromJson<bool>(json['isWeekly']),
      type: serializer.fromJson<int>(json['type']),
      valueLabel: serializer.fromJson<String>(json['valueLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'xp': serializer.toJson<int>(xp),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime>(end),
      'description': serializer.toJson<String>(description),
      'target': serializer.toJson<int>(target),
      'progress': serializer.toJson<int>(progress),
      'isWeekly': serializer.toJson<bool>(isWeekly),
      'type': serializer.toJson<int>(type),
      'valueLabel': serializer.toJson<String>(valueLabel),
    };
  }

  Challenge copyWith(
          {int? id,
          int? xp,
          DateTime? start,
          DateTime? end,
          String? description,
          int? target,
          int? progress,
          bool? isWeekly,
          int? type,
          String? valueLabel}) =>
      Challenge(
        id: id ?? this.id,
        xp: xp ?? this.xp,
        start: start ?? this.start,
        end: end ?? this.end,
        description: description ?? this.description,
        target: target ?? this.target,
        progress: progress ?? this.progress,
        isWeekly: isWeekly ?? this.isWeekly,
        type: type ?? this.type,
        valueLabel: valueLabel ?? this.valueLabel,
      );
  @override
  String toString() {
    return (StringBuffer('Challenge(')
          ..write('id: $id, ')
          ..write('xp: $xp, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('description: $description, ')
          ..write('target: $target, ')
          ..write('progress: $progress, ')
          ..write('isWeekly: $isWeekly, ')
          ..write('type: $type, ')
          ..write('valueLabel: $valueLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, xp, start, end, description, target,
      progress, isWeekly, type, valueLabel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Challenge &&
          other.id == this.id &&
          other.xp == this.xp &&
          other.start == this.start &&
          other.end == this.end &&
          other.description == this.description &&
          other.target == this.target &&
          other.progress == this.progress &&
          other.isWeekly == this.isWeekly &&
          other.type == this.type &&
          other.valueLabel == this.valueLabel);
}

class ChallengesCompanion extends UpdateCompanion<Challenge> {
  final Value<int> id;
  final Value<int> xp;
  final Value<DateTime> start;
  final Value<DateTime> end;
  final Value<String> description;
  final Value<int> target;
  final Value<int> progress;
  final Value<bool> isWeekly;
  final Value<int> type;
  final Value<String> valueLabel;
  const ChallengesCompanion({
    this.id = const Value.absent(),
    this.xp = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.description = const Value.absent(),
    this.target = const Value.absent(),
    this.progress = const Value.absent(),
    this.isWeekly = const Value.absent(),
    this.type = const Value.absent(),
    this.valueLabel = const Value.absent(),
  });
  ChallengesCompanion.insert({
    this.id = const Value.absent(),
    required int xp,
    required DateTime start,
    required DateTime end,
    required String description,
    required int target,
    required int progress,
    required bool isWeekly,
    required int type,
    required String valueLabel,
  })  : xp = Value(xp),
        start = Value(start),
        end = Value(end),
        description = Value(description),
        target = Value(target),
        progress = Value(progress),
        isWeekly = Value(isWeekly),
        type = Value(type),
        valueLabel = Value(valueLabel);
  static Insertable<Challenge> custom({
    Expression<int>? id,
    Expression<int>? xp,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<String>? description,
    Expression<int>? target,
    Expression<int>? progress,
    Expression<bool>? isWeekly,
    Expression<int>? type,
    Expression<String>? valueLabel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (xp != null) 'xp': xp,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (description != null) 'description': description,
      if (target != null) 'target': target,
      if (progress != null) 'progress': progress,
      if (isWeekly != null) 'is_weekly': isWeekly,
      if (type != null) 'type': type,
      if (valueLabel != null) 'value_label': valueLabel,
    });
  }

  ChallengesCompanion copyWith(
      {Value<int>? id,
      Value<int>? xp,
      Value<DateTime>? start,
      Value<DateTime>? end,
      Value<String>? description,
      Value<int>? target,
      Value<int>? progress,
      Value<bool>? isWeekly,
      Value<int>? type,
      Value<String>? valueLabel}) {
    return ChallengesCompanion(
      id: id ?? this.id,
      xp: xp ?? this.xp,
      start: start ?? this.start,
      end: end ?? this.end,
      description: description ?? this.description,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      isWeekly: isWeekly ?? this.isWeekly,
      type: type ?? this.type,
      valueLabel: valueLabel ?? this.valueLabel,
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
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
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
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (valueLabel.present) {
      map['value_label'] = Variable<String>(valueLabel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengesCompanion(')
          ..write('id: $id, ')
          ..write('xp: $xp, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('description: $description, ')
          ..write('target: $target, ')
          ..write('progress: $progress, ')
          ..write('isWeekly: $isWeekly, ')
          ..write('type: $type, ')
          ..write('valueLabel: $valueLabel')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [rideSummaries, challenges];
}
