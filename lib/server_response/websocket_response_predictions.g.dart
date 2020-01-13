// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_response_predictions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebSocketResponsePredictions _$WebSocketResponsePredictionsFromJson(
    Map<String, dynamic> json) {
  return WebSocketResponsePredictions(
    json['mode'] as int,
    (json['subscriptions'] as List)
        ?.map((e) => e == null
            ? null
            : LSAPrediction.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    json['method'] as int,
  );
}

Map<String, dynamic> _$WebSocketResponsePredictionsToJson(
        WebSocketResponsePredictions instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'subscriptions': instance.predictions,
      'method': instance.method,
    };
