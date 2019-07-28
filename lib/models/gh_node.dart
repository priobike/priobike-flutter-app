import 'package:bike_now/controller/crossing_controller.dart';
import 'package:bike_now/models/sg.dart';
import 'package:logging/logging.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'abstract_classes/crossable.dart';
import 'abstract_classes/locatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:bike_now/models/latlng.dart';
import 'package:bike_now/models/abstract_classes/locatable_and_crossable.dart';
import 'package:bike_now/models/models.dart' as BikeNow;

part 'gh_node.g.dart';

@JsonSerializable()
class GHNode with LocatableAndCrossable {
  double alt;
  int id;
  SG referencedSG;

  @JsonKey(ignore: true)
  bool shouldUpdateOverlay = false;

  @JsonKey(ignore: true)
  CrossingController crossingController  = CrossingController(0.0, 125.0, 0.67, 2);

  GHNode(this.alt, double lon, this.id, double lat, double distance){
    super.distance = distance;
    super.lon = lon;
    super.lat = lat;
  }

  factory GHNode.fromJson(Map<String, dynamic> json) => _$GHNodeFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$GHNodeToJson(this);

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    if (distance <= 125.0) {
    return crossingController.run(distance, accuracy);
    }
    return false;
  }
  bool _isCrossed = false;

  @override
  void set isCrossed(bool _isCrossed) {
    if (isCrossed == false && _isCrossed && id != null && id >= 0){
      shouldUpdateOverlay = true;
      Logger.root.fine("GHNode with id $id has been crossed.");
    }
    this._isCrossed = _isCrossed;
  }
  @JsonKey(ignore: true)
  @override
  // TODO: implement isCrossed
  bool get isCrossed => _isCrossed;



}
