// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SG _$SGFromJson(Map<String, dynamic> json) {
  return SG(
      json['id'] as int,
      json['name'] as int,
      json['sign'] as int,
      json['signFlags'] as int,
      json['bear'] as int,
      json['hasPredictions'] as bool,
      json['vehicleFlags'] as int,
      json['uniqueName'] as String,
      json['coordinate'] == null
          ? null
          : LatLng.fromJson(json['coordinate'] as Map<String, dynamic>),
      json['isGreen'] as bool,
      json['isSubscribed'] as bool,
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
      json['shouldUpdateAnnotation'] as bool);
}

Map<String, dynamic> _$SGToJson(SG instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sign': instance.sign,
      'signFlags': instance.signFlags,
      'bear': instance.bear,
      'hasPredictions': instance.hasPredictions,
      'vehicleFlags': instance.vehicleFlags,
      'uniqueName': instance.uniqueName,
      'coordinate': instance.coordinate,
      'isGreen': instance.isGreen,
      'isSubscribed': instance.isSubscribed,
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
