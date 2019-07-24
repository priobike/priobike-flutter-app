// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gh_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GHNode _$GHNodeFromJson(Map<String, dynamic> json) {
  return GHNode(
      (json['alt'] as num)?.toDouble(),
      (json['lon'] as num)?.toDouble(),
      json['id'] as int,
      (json['lat'] as num)?.toDouble(),
      json['isCrossed'] as bool,
      (json['distance'] as num)?.toDouble())
    ..referencedSG = json['referencedSG'] == null
        ? null
        : SG.fromJson(json['referencedSG'] as Map<String, dynamic>);
}

Map<String, dynamic> _$GHNodeToJson(GHNode instance) => <String, dynamic>{
      'lon': instance.lon,
      'lat': instance.lat,
      'distance': instance.distance,
      'alt': instance.alt,
      'id': instance.id,
      'referencedSG': instance.referencedSG,
      'isCrossed': instance.isCrossed
    };
