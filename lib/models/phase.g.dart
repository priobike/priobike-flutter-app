// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Phase _$PhaseFromJson(Map<String, dynamic> json) {
  return Phase(
      json['start'] as String,
      json['end'] as String,
      json['duration'] as int,
      json['isGreen'] as bool,
      json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      json['midDate'] == null
          ? null
          : DateTime.parse(json['midDate'] as String),
      json['durationLeft'] as int,
      (json['distance'] as num)?.toDouble(),
      (json['speedToReachStart'] as num)?.toDouble(),
      (json['speedToReachMid'] as num)?.toDouble(),
      (json['speedToReachEnd'] as num)?.toDouble(),
      json['parentSG'] == null
          ? null
          : SG.fromJson(json['parentSG'] as Map<String, dynamic>),
      json['isInThePast'] as bool);
}

Map<String, dynamic> _$PhaseToJson(Phase instance) => <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'duration': instance.duration,
      'isGreen': instance.isGreen,
      'endDate': instance.endDate?.toIso8601String(),
      'startDate': instance.startDate?.toIso8601String(),
      'midDate': instance.midDate?.toIso8601String(),
      'durationLeft': instance.durationLeft,
      'distance': instance.distance,
      'speedToReachStart': instance.speedToReachStart,
      'speedToReachMid': instance.speedToReachMid,
      'speedToReachEnd': instance.speedToReachEnd,
      'parentSG': instance.parentSG,
      'isInThePast': instance.isInThePast
    };
