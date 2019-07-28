// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SG _$SGFromJson(Map<String, dynamic> json) {
  return SG(
      json['baseId'] as int,
      json['sgName'] as String,
      json['sign'] as int,
      json['signFlags'] as int,
      json['bear'] as int,
      json['hasPredictions'] as bool,
      json['vehicleFlags'] as int,
      json['uniqueName'] as String,
      json['coordinate'] == null
          ? null
          : LatLng.fromJson(json['coordinate'] as Map<String, dynamic>),
      json['parentLSA'] == null
          ? null
          : LSA.fromJson(json['parentLSA'] as Map<String, dynamic>),
      json['referencedGHNode'] == null
          ? null
          : GHNode.fromJson(json['referencedGHNode'] as Map<String, dynamic>),
      (json['phases'] as List)
          ?.map((e) =>
              e == null ? null : Phase.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      _$enumDecodeNullable(
          _$SGAnnotationStatusEnumMap, json['annotationStatus']),
      json['shouldUpdateAnnotation'] as bool,
      (json['lat'] as num)?.toDouble(),
      (json['lon'] as num)?.toDouble(),
      (json['distance'] as num)?.toDouble());
}

Map<String, dynamic> _$SGToJson(SG instance) => <String, dynamic>{
      'lon': instance.lon,
      'lat': instance.lat,
      'distance': instance.distance,
      'baseId': instance.baseId,
      'sgName': instance.sgName,
      'sign': instance.sign,
      'signFlags': instance.signFlags,
      'bear': instance.bear,
      'hasPredictions': instance.hasPredictions,
      'vehicleFlags': instance.vehicleFlags,
      'uniqueName': instance.uniqueName,
      'coordinate': instance.coordinate,
      'parentLSA': instance.parentLSA,
      'referencedGHNode': instance.referencedGHNode,
      'phases': instance.phases,
      'annotationStatus':
          _$SGAnnotationStatusEnumMap[instance.annotationStatus],
      'shouldUpdateAnnotation': instance.shouldUpdateAnnotation
    };

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
}

const _$SGAnnotationStatusEnumMap = <SGAnnotationStatus, dynamic>{
  SGAnnotationStatus.none: 'none',
  SGAnnotationStatus.green: 'green',
  SGAnnotationStatus.red: 'red'
};
