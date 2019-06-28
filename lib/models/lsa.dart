import 'package:bike_now/models/lsa_prediction.dart';
import 'package:bike_now/models/sg.dart';
import 'package:bike_now/models/sg_prediction.dart';

import 'abstract_classes/locatable.dart';
import 'abstract_classes/crossable.dart';

import 'package:json_annotation/json_annotation.dart';

part 'lsa.g.dart';

@JsonSerializable()
class LSA with Crossable, Locatable{
  int id;
  String name;
  List<SG> sgs;
  List<SGPrediction> sgPredictions = new List<SGPrediction>();


  LSA(this.id, this.name, this.sgs, this.sgPredictions);

  factory LSA.fromJson(Map<String, dynamic> json) => _$LSAFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$LSAToJson(this);

  SG getSG(){

  }



  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    // TODO: implement calculateIsCrossed
    return null;
  }

}