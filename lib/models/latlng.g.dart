// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latlng.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LatLng _$LatLngFromJson(Map<String, dynamic> json) {
  return LatLng((json['lat'] as num)?.toDouble(),
      (json['lng'] as num)?.toDouble(), (json['accuracy'] as num)?.toDouble());
}

Map<String, dynamic> _$LatLngToJson(LatLng instance) => <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy': instance.accuracy
    };
