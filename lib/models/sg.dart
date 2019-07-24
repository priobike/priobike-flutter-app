import 'package:bike_now/controller/crossing_controller.dart';
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
  int baseId;
  String sgName;
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
  List<Phase> _phases;

  List<Phase> get phases => _phases;

  set phases(List<Phase> value) {
    _phases = value;
    phases.forEach((phase) {
      phase.parentSG = this;
    });
    var validPhase = phases.firstWhere((phase) => !phase.isInThePast);
    hasPredictions = validPhase != null;
  }

  @JsonKey(ignore: true)
  void Function(SG) handleSGSubscribtion;
  @JsonKey(ignore: true)
  void Function(SG) handleSGUnSubscribe;

  //SGAnnotation annotation;
  SGAnnotationStatus annotationStatus = SGAnnotationStatus.none;

  bool shouldUpdateAnnotation = false;

  @JsonKey(ignore: true)
  CrossingController crossingController  = CrossingController(0.0, 100.0, 0.8, 2);


  SG(this.baseId, this.sgName, this.sign, this.signFlags, this.bear,
      this.hasPredictions, this.vehicleFlags, this.uniqueName, this.coordinate,
      this.isGreen, this.isSubscribed, this.parentLSA, this.referencedGHNode,
      List<Phase> phases, this.annotationStatus, this.shouldUpdateAnnotation, double lat, double lon,this.isCrossed, double distance){
    super.distance = distance;
    super.lat = lat;
    super.lon = lon;
    this.phases = phases;

  }

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
    return SGSubscription(sgName, isSubscribed);


  }

  Subscription makeSubscription(){
    int lsaId = parentLSA.id;
    String lsaName = parentLSA.name;
    SGSubscription sgSubscription = makeSGSubscription();

    return Subscription(lsaId, lsaName, [sgSubscription]);

  }


  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    if (distance <= 100.0) {
    return crossingController.run( distance,accuracy);
    }

    return false;
  }

  @override
  bool isCrossed = false;




}