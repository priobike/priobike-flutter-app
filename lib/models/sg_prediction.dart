import 'package:bike_now_flutter/models/phase.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sg_prediction.g.dart';

@JsonSerializable()
class SGPrediction {
  String sgName;
  List<Phase> phases = [];

  SGPrediction(this.sgName, this.phases);

  factory SGPrediction.fromJson(Map<String, dynamic> json) =>
      _$SGPredictionFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SGPredictionToJson(this);
}
