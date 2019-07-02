import 'package:bike_now/models/abstract_classes/locatable.dart';
import 'package:bike_now/models/abstract_classes/crossable.dart';
import 'package:bike_now/models/abstract_classes/locatable_and_crossable.dart';

import 'package:bike_now/models/phase.dart';
import 'package:bike_now/models/sg_subscription.dart';
import 'package:bike_now/models/subscription.dart';

import 'package:bike_now/models/latlng.dart';
import 'gh_node.dart';
import 'lsa.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sg.g.dart';


enum SGAnnotationStatus {
  none,green,red
}


@JsonSerializable()
class SG with LocatableAndCrossable{
  int id;
  int name;
  int sign;
  int signFlags;
  int bear;
  bool hasPredictions;
  int vehicleFlags;

  String uniqueName;
  LatLng coordinate;

  bool isGreen;
  bool isSubscribed;
  LSA parentLSA;
  GHNode referencedGHNode;
  List<Phase> phases;

  @JsonKey(ignore: true)
  void Function(SG) handleSGSubscribtion;
  @JsonKey(ignore: true)
  void Function(SG) handleSGUnSubscribe;

  //SGAnnotation annotation;
  SGAnnotationStatus annotationStatus = SGAnnotationStatus.none;

  bool shouldUpdateAnnotation = false;


  SG(this.id, this.name, this.sign, this.signFlags, this.bear,
      this.hasPredictions, this.vehicleFlags, this.uniqueName, this.coordinate,
      this.isGreen, this.isSubscribed, this.parentLSA, this.referencedGHNode,
      this.phases, this.annotationStatus, this.shouldUpdateAnnotation, this.lat, this.lon,this.isCrossed,this.distance);

  factory SG.fromJson(Map<String, dynamic> json) => _$SGFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SGToJson(this);

  Phase getNextValidPhase(){

  }

  /*SGAnnotation createSGAnnotation(){

  }*/

  SGSubscription makeSGSubscription(){

  }

  Subscription makeSubscription(){

  }


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
  double lat;

  @override
  double lon;

  @override
  double calculateDistanceTo(LatLng destination) {
    // TODO: implement calculateDistanceTo
    return null;
  }


}