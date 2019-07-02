// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sg_prediction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SGPrediction _$SGPredictionFromJson(Map<String, dynamic> json) {
  return SGPrediction(
      json['sgName'] as String,
      (json['phases'] as List)
          ?.map((e) =>
              e == null ? null : Phase.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$SGPredictionToJson(SGPrediction instance) =>
    <String, dynamic>{'sgName': instance.sgName, 'phases': instance.phases};
