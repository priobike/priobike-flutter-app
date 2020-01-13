// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lsa_prediction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LSAPrediction _$LSAPredictionFromJson(Map<String, dynamic> json) {
  return LSAPrediction(
    json['lsaId'] as int,
    (json['sgArray'] as List)
        ?.map((e) =>
            e == null ? null : SGPrediction.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$LSAPredictionToJson(LSAPrediction instance) =>
    <String, dynamic>{
      'lsaId': instance.lsaId,
      'sgArray': instance.sgPredictions,
    };
