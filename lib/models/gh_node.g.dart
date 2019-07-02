// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gh_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GHNode _$GHNodeFromJson(Map<String, dynamic> json) {
  return GHNode(
      alt: (json['alt'] as num)?.toDouble(),
      lon: (json['lon'] as num)?.toDouble(),
      id: json['id'] as int,
      lat: (json['lat'] as num)?.toDouble(),
      latidude: (json['latidude'] as num)?.toDouble(),
      longitude: (json['longitude'] as num)?.toDouble(),
      isCrossed: json['isCrossed'] as bool,
      distance: (json['distance'] as num)?.toDouble())
    ..referencedSG = json['referencedSG'] == null
        ? null
        : SG.fromJson(json['referencedSG'] as Map<String, dynamic>);
}

Map<String, dynamic> _$GHNodeToJson(GHNode instance) => <String, dynamic>{
      'alt': instance.alt,
      'lon': instance.lon,
      'id': instance.id,
      'lat': instance.lat,
      'referencedSG': instance.referencedSG,
      'distance': instance.distance,
      'isCrossed': instance.isCrossed,
      'latidude': instance.latidude,
      'longitude': instance.longitude
    };
