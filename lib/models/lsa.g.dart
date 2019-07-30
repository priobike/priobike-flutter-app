// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lsa.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LSA _$LSAFromJson(Map<String, dynamic> json) {
  return LSA(
      json['id'] as int,
      json['sgSize'] as int,
      json['name'] as String,
      (json['sgArray'] as List)
          ?.map(
              (e) => e == null ? null : SG.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['sgPredictions'] as List)
          ?.map((e) => e == null
              ? null
              : SGPrediction.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['distance'] as num)?.toDouble(),
      (json['lon'] as num)?.toDouble(),
      (json['lat'] as num)?.toDouble());
}

Map<String, dynamic> _$LSAToJson(LSA instance) => <String, dynamic>{
      'lon': instance.lon,
      'lat': instance.lat,
      'distance': instance.distance,
      'id': instance.id,
      'sgSize': instance.sgSize,
      'name': instance.name,
      'sgArray': instance.sgs,
      'sgPredictions': instance.sgPredictions
    };
