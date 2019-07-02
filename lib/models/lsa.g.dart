// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lsa.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LSA _$LSAFromJson(Map<String, dynamic> json) {
  return LSA(
      json['id'] as int,
      json['name'] as String,
      (json['sgs'] as List)
          ?.map(
              (e) => e == null ? null : SG.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['sgPredictions'] as List)
          ?.map((e) => e == null
              ? null
              : SGPrediction.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['distance'] as num)?.toDouble(),
      json['isCrossed'] as bool,
      (json['lon'] as num)?.toDouble(),
      (json['lat'] as num)?.toDouble());
}

Map<String, dynamic> _$LSAToJson(LSA instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sgs': instance.sgs,
      'sgPredictions': instance.sgPredictions,
      'distance': instance.distance,
      'isCrossed': instance.isCrossed,
      'lat': instance.lat,
      'lon': instance.lon
    };
