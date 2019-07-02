import 'package:bike_now/models/sg.dart';
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
  double lon;
  int id;
  double lat;
  SG referencedSG;

  GHNode({this.alt, this.lon, this.id, this.lat, this.latidude, this.longitude, this.isCrossed, this.distance});

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

  @override
  double distance;

  @override
  bool isCrossed;

  @override
  double latidude;

  @override
  double longitude;

  @override
  double calculateDistanceTo(BikeNow.LatLng destination) {
    // TODO: implement calculateDistanceTo
    return null;
  }
}
