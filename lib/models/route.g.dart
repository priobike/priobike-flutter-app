// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Route _$RouteFromJson(Map<String, dynamic> json) {
  return Route(
      (json['instructions'] as List)
          ?.map((e) => e == null
              ? null
              : Instruction.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['descend'] as num)?.toDouble(),
      (json['ascend'] as num)?.toDouble(),
      (json['distance'] as num)?.toDouble(),
      json['time'] as int,
      json['duration'] as int,
      json['arrivalTime'] == null
          ? null
          : DateTime.parse(json['arrivalTime'] as String),
      (json['coordinates'] as List)
          ?.map((e) =>
              e == null ? null : LatLng.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'instructions': instance.instructions,
      'descend': instance.descend,
      'ascend': instance.ascend,
      'distance': instance.distance,
      'time': instance.time,
      'duration': instance.duration,
      'arrivalTime': instance.arrivalTime?.toIso8601String(),
      'coordinates': instance.coordinates
    };
