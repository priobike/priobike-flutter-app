import 'package:bike_now/models/sg.dart';

import 'abstract_classes/crossable.dart';
import 'abstract_classes/locatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:bike_now/models/latlng.dart';
import 'package:bike_now/models/abstract_classes/locatable_and_crossable.dart';

part 'gh_node.g.dart';

@JsonSerializable()
class GHNode with LocatableAndCrossable {
  double alt;
  double lon;
  int id;
  double lat;
  SG referencedSG;

  GHNode({this.alt, this.lon, this.id, this.lat});

  factory GHNode.fromJson(Map<String, dynamic> json) => _$GHNodeFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$GHNodeToJson(this);

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    // TODO: implement calculateIsCrossed
    return null;
  }
}
