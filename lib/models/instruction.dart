import 'package:bike_now/models/latlng.dart';

import 'abstract_classes/locatable.dart';
import 'abstract_classes/crossable.dart';
import 'abstract_classes/locatable_and_crossable.dart';
import 'gh_node.dart';
import 'lsa.dart';
import 'package:json_annotation/json_annotation.dart';

part 'instruction.g.dart';

@JsonSerializable()
class Instruction with LocatableAndCrossable{
  int sign;
  String name;
  String text;
  String info;
  @JsonKey(name: 'lsaArray')
  List<LSA> lsas;
  @JsonKey(name: 'nodeArray')
  List<GHNode> nodes;


  Instruction(this.sign, this.name, this.text, this.info, this.lsas,
      this.nodes, double distance, this.isCrossed){

      super.lon = 0;
      super.lat = 0;


    super.distance = distance;
  }

  factory Instruction.fromJson(Map<String, dynamic> json) => _$InstructionFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$InstructionToJson(this);

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    // TODO: implement calculateIsCrossed
    return distance <= 0.1;
  }

  @JsonKey(name: 'dist')
  @override
  // TODO: implement distance
  double get distance => super.distance;
  @override
  void set distance(double _distance) {
    // TODO: implement distance
    super.distance = _distance;
  }

  @override
  bool isCrossed;

  @override
  // TODO: implement lat
  double get lat => super.lat;

  @override
  void set lon(double _lon) {
    // TODO: implement lon
    super.lon = _lon;
  }
}