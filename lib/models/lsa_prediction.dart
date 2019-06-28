import 'package:bike_now/models/phase.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:bike_now/models/sg_prediction.dart';

part 'lsa_prediction.g.dart';

@JsonSerializable()
class LSAPrediction{
  int lsaId;
  List<SGPrediction> sgPredictions;

  LSAPrediction(this.lsaId, this.sgPredictions);

  factory LSAPrediction.fromJson(Map<String, dynamic> json) => _$LSAPredictionFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$LSAPredictionToJson(this);


}
