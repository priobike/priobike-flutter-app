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
      (json['speedToReachStart'] as num)?.toDouble(),
      (json['speedToReachMid'] as num)?.toDouble(),
      (json['speedToReachEnd'] as num)?.toDouble(),
      json['parentSG'] == null
          ? null
          : SG.fromJson(json['parentSG'] as Map<String, dynamic>),
      json['isInThePast'] as bool)
    ..endDate = json['endDate'] == null
        ? null
        : DateTime.parse(json['endDate'] as String)
    ..startDate = json['startDate'] == null
        ? null
        : DateTime.parse(json['startDate'] as String)
    ..durationLeft = json['durationLeft'] as int
    ..distance = (json['distance'] as num)?.toDouble();
}

Map<String, dynamic> _$PhaseToJson(Phase instance) => <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'duration': instance.duration,
      'isGreen': instance.isGreen,
      'endDate': instance.endDate?.toIso8601String(),
      'startDate': instance.startDate?.toIso8601String(),
      'durationLeft': instance.durationLeft,
      'distance': instance.distance,
      'speedToReachStart': instance.speedToReachStart,
      'speedToReachMid': instance.speedToReachMid,
      'speedToReachEnd': instance.speedToReachEnd,
      'parentSG': instance.parentSG,
      'isInThePast': instance.isInThePast
    };
