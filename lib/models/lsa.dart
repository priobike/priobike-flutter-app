import 'package:bike_now/models/lsa_prediction.dart';
import 'package:bike_now/models/sg.dart';
import 'package:bike_now/models/sg_prediction.dart';
import 'package:logging/logging.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'abstract_classes/locatable.dart';
import 'abstract_classes/crossable.dart';
import 'abstract_classes/locatable_and_crossable.dart';
import 'package:bike_now/models/models.dart' as BikeNowModels;
import 'package:json_annotation/json_annotation.dart';

part 'lsa.g.dart';

@JsonSerializable()
class LSA with LocatableAndCrossable{
  int id;
  int sgSize;
  String name;
  @JsonKey(name: 'sgArray')
  List<SG> sgs;
  List<SGPrediction> sgPredictions = new List<SGPrediction>();


  LSA(this.id, this.sgSize, this.name, this.sgs, this.sgPredictions, double distance, bool isCrossed, double lon, double lat){
    super.distance = distance;
    super.lon = lon;
    super.lat = lat;
    this.isCrossed = isCrossed;
  }

  factory LSA.fromJson(Map<String, dynamic> json) => _$LSAFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$LSAToJson(this);

  SG getSG(String name){
    return sgs.firstWhere((sg) => sg.sgName == name);
  }

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    if (sgs.first != null){
      if(sgs.first.isCrossed == null) return true;
      return !sgs.first.isCrossed;
    }
    return sgs.first == null;
  }

  bool _isCrossed = false;

  @override
  void set isCrossed(bool _isCrossed) {
    if(_isCrossed == false && isCrossed){
      Logger.root.fine("LSA with name $name has been crossed.");
    }
    this._isCrossed = _isCrossed;
  }
  @override
  bool get isCrossed => _isCrossed;








}