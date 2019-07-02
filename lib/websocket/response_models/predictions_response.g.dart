// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'predictions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebSocketResponsePredictions _$WebSocketResponsePredictionsFromJson(
    Map<String, dynamic> json) {
  return WebSocketResponsePredictions(
      mode: json['mode'] as int,
      predictions: (json['subscriptions'] as List)
          ?.map((e) => e == null
              ? null
              : LSAPrediction.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      method: json['method'] as int);
}

Map<String, dynamic> _$WebSocketResponsePredictionsToJson(
        WebSocketResponsePredictions instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'subscriptions': instance.predictions,
      'method': instance.method
    };
