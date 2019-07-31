import 'package:bike_now/models/lsa_prediction.dart';
import 'package:json_annotation/json_annotation.dart';

part 'websocket_response_predictions.g.dart';

@JsonSerializable()
class WebSocketResponsePredictions {
  int mode;
  @JsonKey(name: 'subscriptions')
  List<LSAPrediction> predictions;
  int method;

  WebSocketResponsePredictions(this.mode, this.predictions, this.method);

  factory WebSocketResponsePredictions.fromJson(Map<String, dynamic> json) =>
      _$WebSocketResponsePredictionsFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$WebSocketResponsePredictionsToJson(this);
}
