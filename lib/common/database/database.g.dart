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
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
      'duration', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _elevationGainMeta =
      const VerificationMeta('elevationGain');
  @override
  late final GeneratedColumn<double> elevationGain = GeneratedColumn<double>(
      'elevation_gain', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _elevationLossMeta =
      const VerificationMeta('elevationLoss');
  @override
  late final GeneratedColumn<double> elevationLoss = GeneratedColumn<double>(
      'elevation_loss', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _averageSpeedMeta =
      const VerificationMeta('averageSpeed');
  @override
  late final GeneratedColumn<double> averageSpeed = GeneratedColumn<double>(
      'average_speed', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, distance, duration, elevationGain, elevationLoss, averageSpeed];
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
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    } else if (isInserting) {
      context.missing(_distanceMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('elevation_gain')) {
      context.handle(
          _elevationGainMeta,
          elevationGain.isAcceptableOrUnknown(
              data['elevation_gain']!, _elevationGainMeta));
    } else if (isInserting) {
      context.missing(_elevationGainMeta);
    }
    if (data.containsKey('elevation_loss')) {
      context.handle(
          _elevationLossMeta,
          elevationLoss.isAcceptableOrUnknown(
              data['elevation_loss']!, _elevationLossMeta));
    } else if (isInserting) {
      context.missing(_elevationLossMeta);
    }
    if (data.containsKey('average_speed')) {
      context.handle(
          _averageSpeedMeta,
          averageSpeed.isAcceptableOrUnknown(
              data['average_speed']!, _averageSpeedMeta));
    } else if (isInserting) {
      context.missing(_averageSpeedMeta);
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
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}duration'])!,
      elevationGain: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elevation_gain'])!,
      elevationLoss: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elevation_loss'])!,
      averageSpeed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}average_speed'])!,
    );
  }

  @override
  $RideSummariesTable createAlias(String alias) {
    return $RideSummariesTable(attachedDatabase, alias);
  }
}

class RideSummary extends DataClass implements Insertable<RideSummary> {
  final int id;
  final double distance;
  final double duration;
  final double elevationGain;
  final double elevationLoss;
  final double averageSpeed;
  const RideSummary(
      {required this.id,
      required this.distance,
      required this.duration,
      required this.elevationGain,
      required this.elevationLoss,
      required this.averageSpeed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['distance'] = Variable<double>(distance);
    map['duration'] = Variable<double>(duration);
    map['elevation_gain'] = Variable<double>(elevationGain);
    map['elevation_loss'] = Variable<double>(elevationLoss);
    map['average_speed'] = Variable<double>(averageSpeed);
    return map;
  }

  RideSummariesCompanion toCompanion(bool nullToAbsent) {
    return RideSummariesCompanion(
      id: Value(id),
      distance: Value(distance),
      duration: Value(duration),
      elevationGain: Value(elevationGain),
      elevationLoss: Value(elevationLoss),
      averageSpeed: Value(averageSpeed),
    );
  }

  factory RideSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideSummary(
      id: serializer.fromJson<int>(json['id']),
      distance: serializer.fromJson<double>(json['distance']),
      duration: serializer.fromJson<double>(json['duration']),
      elevationGain: serializer.fromJson<double>(json['elevationGain']),
      elevationLoss: serializer.fromJson<double>(json['elevationLoss']),
      averageSpeed: serializer.fromJson<double>(json['averageSpeed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'distance': serializer.toJson<double>(distance),
      'duration': serializer.toJson<double>(duration),
      'elevationGain': serializer.toJson<double>(elevationGain),
      'elevationLoss': serializer.toJson<double>(elevationLoss),
      'averageSpeed': serializer.toJson<double>(averageSpeed),
    };
  }

  RideSummary copyWith(
          {int? id,
          double? distance,
          double? duration,
          double? elevationGain,
          double? elevationLoss,
          double? averageSpeed}) =>
      RideSummary(
        id: id ?? this.id,
        distance: distance ?? this.distance,
        duration: duration ?? this.duration,
        elevationGain: elevationGain ?? this.elevationGain,
        elevationLoss: elevationLoss ?? this.elevationLoss,
        averageSpeed: averageSpeed ?? this.averageSpeed,
      );
  @override
  String toString() {
    return (StringBuffer('RideSummary(')
          ..write('id: $id, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('elevationLoss: $elevationLoss, ')
          ..write('averageSpeed: $averageSpeed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, distance, duration, elevationGain, elevationLoss, averageSpeed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideSummary &&
          other.id == this.id &&
          other.distance == this.distance &&
          other.duration == this.duration &&
          other.elevationGain == this.elevationGain &&
          other.elevationLoss == this.elevationLoss &&
          other.averageSpeed == this.averageSpeed);
}

class RideSummariesCompanion extends UpdateCompanion<RideSummary> {
  final Value<int> id;
  final Value<double> distance;
  final Value<double> duration;
  final Value<double> elevationGain;
  final Value<double> elevationLoss;
  final Value<double> averageSpeed;
  const RideSummariesCompanion({
    this.id = const Value.absent(),
    this.distance = const Value.absent(),
    this.duration = const Value.absent(),
    this.elevationGain = const Value.absent(),
    this.elevationLoss = const Value.absent(),
    this.averageSpeed = const Value.absent(),
  });
  RideSummariesCompanion.insert({
    this.id = const Value.absent(),
    required double distance,
    required double duration,
    required double elevationGain,
    required double elevationLoss,
    required double averageSpeed,
  })  : distance = Value(distance),
        duration = Value(duration),
        elevationGain = Value(elevationGain),
        elevationLoss = Value(elevationLoss),
        averageSpeed = Value(averageSpeed);
  static Insertable<RideSummary> custom({
    Expression<int>? id,
    Expression<double>? distance,
    Expression<double>? duration,
    Expression<double>? elevationGain,
    Expression<double>? elevationLoss,
    Expression<double>? averageSpeed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (distance != null) 'distance': distance,
      if (duration != null) 'duration': duration,
      if (elevationGain != null) 'elevation_gain': elevationGain,
      if (elevationLoss != null) 'elevation_loss': elevationLoss,
      if (averageSpeed != null) 'average_speed': averageSpeed,
    });
  }

  RideSummariesCompanion copyWith(
      {Value<int>? id,
      Value<double>? distance,
      Value<double>? duration,
      Value<double>? elevationGain,
      Value<double>? elevationLoss,
      Value<double>? averageSpeed}) {
    return RideSummariesCompanion(
      id: id ?? this.id,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      averageSpeed: averageSpeed ?? this.averageSpeed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (elevationGain.present) {
      map['elevation_gain'] = Variable<double>(elevationGain.value);
    }
    if (elevationLoss.present) {
      map['elevation_loss'] = Variable<double>(elevationLoss.value);
    }
    if (averageSpeed.present) {
      map['average_speed'] = Variable<double>(averageSpeed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RideSummariesCompanion(')
          ..write('id: $id, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('elevationLoss: $elevationLoss, ')
          ..write('averageSpeed: $averageSpeed')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _totalDistanceMeta =
      const VerificationMeta('totalDistance');
  @override
  late final GeneratedColumn<double> totalDistance = GeneratedColumn<double>(
      'total_distance', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalDurationMeta =
      const VerificationMeta('totalDuration');
  @override
  late final GeneratedColumn<double> totalDuration = GeneratedColumn<double>(
      'total_duration', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalElevationGainMeta =
      const VerificationMeta('totalElevationGain');
  @override
  late final GeneratedColumn<double> totalElevationGain =
      GeneratedColumn<double>('total_elevation_gain', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalElevationLossMeta =
      const VerificationMeta('totalElevationLoss');
  @override
  late final GeneratedColumn<double> totalElevationLoss =
      GeneratedColumn<double>('total_elevation_loss', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _joinDateMeta =
      const VerificationMeta('joinDate');
  @override
  late final GeneratedColumn<DateTime> joinDate = GeneratedColumn<DateTime>(
      'join_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        totalDistance,
        totalDuration,
        totalElevationGain,
        totalElevationLoss,
        joinDate
      ];
  @override
  String get aliasedName => _alias ?? 'user_profiles';
  @override
  String get actualTableName => 'user_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('total_distance')) {
      context.handle(
          _totalDistanceMeta,
          totalDistance.isAcceptableOrUnknown(
              data['total_distance']!, _totalDistanceMeta));
    } else if (isInserting) {
      context.missing(_totalDistanceMeta);
    }
    if (data.containsKey('total_duration')) {
      context.handle(
          _totalDurationMeta,
          totalDuration.isAcceptableOrUnknown(
              data['total_duration']!, _totalDurationMeta));
    } else if (isInserting) {
      context.missing(_totalDurationMeta);
    }
    if (data.containsKey('total_elevation_gain')) {
      context.handle(
          _totalElevationGainMeta,
          totalElevationGain.isAcceptableOrUnknown(
              data['total_elevation_gain']!, _totalElevationGainMeta));
    } else if (isInserting) {
      context.missing(_totalElevationGainMeta);
    }
    if (data.containsKey('total_elevation_loss')) {
      context.handle(
          _totalElevationLossMeta,
          totalElevationLoss.isAcceptableOrUnknown(
              data['total_elevation_loss']!, _totalElevationLossMeta));
    } else if (isInserting) {
      context.missing(_totalElevationLossMeta);
    }
    if (data.containsKey('join_date')) {
      context.handle(_joinDateMeta,
          joinDate.isAcceptableOrUnknown(data['join_date']!, _joinDateMeta));
    } else if (isInserting) {
      context.missing(_joinDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      totalDistance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_distance'])!,
      totalDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_duration'])!,
      totalElevationGain: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_elevation_gain'])!,
      totalElevationLoss: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_elevation_loss'])!,
      joinDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}join_date'])!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final int id;
  final double totalDistance;
  final double totalDuration;
  final double totalElevationGain;
  final double totalElevationLoss;
  final DateTime joinDate;
  const UserProfile(
      {required this.id,
      required this.totalDistance,
      required this.totalDuration,
      required this.totalElevationGain,
      required this.totalElevationLoss,
      required this.joinDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['total_distance'] = Variable<double>(totalDistance);
    map['total_duration'] = Variable<double>(totalDuration);
    map['total_elevation_gain'] = Variable<double>(totalElevationGain);
    map['total_elevation_loss'] = Variable<double>(totalElevationLoss);
    map['join_date'] = Variable<DateTime>(joinDate);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      totalDistance: Value(totalDistance),
      totalDuration: Value(totalDuration),
      totalElevationGain: Value(totalElevationGain),
      totalElevationLoss: Value(totalElevationLoss),
      joinDate: Value(joinDate),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<int>(json['id']),
      totalDistance: serializer.fromJson<double>(json['totalDistance']),
      totalDuration: serializer.fromJson<double>(json['totalDuration']),
      totalElevationGain:
          serializer.fromJson<double>(json['totalElevationGain']),
      totalElevationLoss:
          serializer.fromJson<double>(json['totalElevationLoss']),
      joinDate: serializer.fromJson<DateTime>(json['joinDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'totalDistance': serializer.toJson<double>(totalDistance),
      'totalDuration': serializer.toJson<double>(totalDuration),
      'totalElevationGain': serializer.toJson<double>(totalElevationGain),
      'totalElevationLoss': serializer.toJson<double>(totalElevationLoss),
      'joinDate': serializer.toJson<DateTime>(joinDate),
    };
  }

  UserProfile copyWith(
          {int? id,
          double? totalDistance,
          double? totalDuration,
          double? totalElevationGain,
          double? totalElevationLoss,
          DateTime? joinDate}) =>
      UserProfile(
        id: id ?? this.id,
        totalDistance: totalDistance ?? this.totalDistance,
        totalDuration: totalDuration ?? this.totalDuration,
        totalElevationGain: totalElevationGain ?? this.totalElevationGain,
        totalElevationLoss: totalElevationLoss ?? this.totalElevationLoss,
        joinDate: joinDate ?? this.joinDate,
      );
  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('totalDuration: $totalDuration, ')
          ..write('totalElevationGain: $totalElevationGain, ')
          ..write('totalElevationLoss: $totalElevationLoss, ')
          ..write('joinDate: $joinDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, totalDistance, totalDuration,
      totalElevationGain, totalElevationLoss, joinDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.totalDistance == this.totalDistance &&
          other.totalDuration == this.totalDuration &&
          other.totalElevationGain == this.totalElevationGain &&
          other.totalElevationLoss == this.totalElevationLoss &&
          other.joinDate == this.joinDate);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<int> id;
  final Value<double> totalDistance;
  final Value<double> totalDuration;
  final Value<double> totalElevationGain;
  final Value<double> totalElevationLoss;
  final Value<DateTime> joinDate;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.totalDuration = const Value.absent(),
    this.totalElevationGain = const Value.absent(),
    this.totalElevationLoss = const Value.absent(),
    this.joinDate = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    required double totalDistance,
    required double totalDuration,
    required double totalElevationGain,
    required double totalElevationLoss,
    required DateTime joinDate,
  })  : totalDistance = Value(totalDistance),
        totalDuration = Value(totalDuration),
        totalElevationGain = Value(totalElevationGain),
        totalElevationLoss = Value(totalElevationLoss),
        joinDate = Value(joinDate);
  static Insertable<UserProfile> custom({
    Expression<int>? id,
    Expression<double>? totalDistance,
    Expression<double>? totalDuration,
    Expression<double>? totalElevationGain,
    Expression<double>? totalElevationLoss,
    Expression<DateTime>? joinDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalDistance != null) 'total_distance': totalDistance,
      if (totalDuration != null) 'total_duration': totalDuration,
      if (totalElevationGain != null)
        'total_elevation_gain': totalElevationGain,
      if (totalElevationLoss != null)
        'total_elevation_loss': totalElevationLoss,
      if (joinDate != null) 'join_date': joinDate,
    });
  }

  UserProfilesCompanion copyWith(
      {Value<int>? id,
      Value<double>? totalDistance,
      Value<double>? totalDuration,
      Value<double>? totalElevationGain,
      Value<double>? totalElevationLoss,
      Value<DateTime>? joinDate}) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      totalElevationGain: totalElevationGain ?? this.totalElevationGain,
      totalElevationLoss: totalElevationLoss ?? this.totalElevationLoss,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (totalDistance.present) {
      map['total_distance'] = Variable<double>(totalDistance.value);
    }
    if (totalDuration.present) {
      map['total_duration'] = Variable<double>(totalDuration.value);
    }
    if (totalElevationGain.present) {
      map['total_elevation_gain'] = Variable<double>(totalElevationGain.value);
    }
    if (totalElevationLoss.present) {
      map['total_elevation_loss'] = Variable<double>(totalElevationLoss.value);
    }
    if (joinDate.present) {
      map['join_date'] = Variable<DateTime>(joinDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('totalDuration: $totalDuration, ')
          ..write('totalElevationGain: $totalElevationGain, ')
          ..write('totalElevationLoss: $totalElevationLoss, ')
          ..write('joinDate: $joinDate')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $RideSummariesTable rideSummaries = $RideSummariesTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final RideSummaryDao rideSummaryDao =
      RideSummaryDao(this as AppDatabase);
  late final UserProfileDao userProfileDao =
      UserProfileDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [rideSummaries, userProfiles];
}
