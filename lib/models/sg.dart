import 'package:bike_now_flutter/controller/crossing_controller.dart';
import 'package:bike_now_flutter/models/abstract_classes/locatable_and_crossable.dart';

import 'package:bike_now_flutter/models/phase.dart';
import 'package:bike_now_flutter/models/sg_subscription.dart';
import 'package:bike_now_flutter/models/subscription.dart';

import 'package:bike_now_flutter/models/latlng.dart';
import 'package:logging/logging.dart';
import 'gh_node.dart';
import 'lsa.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sg.g.dart';

enum SGAnnotationStatus { none, green, red }

@JsonSerializable()
class SG with LocatableAndCrossable {
  int baseId;
  String sgName;
  int sign;
  int signFlags;
  int bear;
  bool hasPredictions;
  int vehicleFlags;

  String uniqueName;
  LatLng coordinate;

  bool _isGreen = false;

  @JsonKey(ignore: true)
  bool get isGreen => _isGreen;

  set isGreen(bool value) {
    var oldValue = isGreen;
    _isGreen = value;

    if (isGreen != oldValue) {
      shouldUpdateAnnotation = true;

      if (isGreen != null) {
        if (isGreen) {
          annotationStatus = SGAnnotationStatus.green;
        } else {
          annotationStatus = SGAnnotationStatus.red;
        }
      } else {
        return;
      }
    }
  }

  bool _isSubscribed = false;
  @JsonKey(ignore: true)
  bool get isSubscribed => _isSubscribed;
  set isSubscribed(bool value) {
    var oldValue = isSubscribed;
    _isSubscribed = value;

    if (isSubscribed && oldValue == false) {
      shouldUpdateAnnotation = true;
      Logger.root.fine("Did subscribe to SG with name $sgName.");
      handleSGSubscribtion(this);
    } else if (!isSubscribed && oldValue == true) {
      Logger.root.fine("Did unsubscribe from SG with name $sgName).");

      handleSGUnSubscribe(this);
    }
  }

  LSA parentLSA;
  GHNode referencedGHNode;
  List<Phase> _phases;

  List<Phase> get phases => _phases;

  set phases(List<Phase> value) {
    _phases = value;
    phases?.forEach((phase) {
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
  CrossingController crossingController =
      CrossingController(0.0, 100.0, 0.8, 2);

  SG(
      this.baseId,
      this.sgName,
      this.sign,
      this.signFlags,
      this.bear,
      this.hasPredictions,
      this.vehicleFlags,
      this.uniqueName,
      this.coordinate,
      this.parentLSA,
      this.referencedGHNode,
      List<Phase> phases,
      this.annotationStatus,
      this.shouldUpdateAnnotation,
      double lat,
      double lon,
      double distance) {
    super.distance = distance;
    super.lat = lat;
    super.lon = lon;
  }

  factory SG.fromJson(Map<String, dynamic> json) => _$SGFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SGToJson(this);

  Phase getNextValidPhase(double currentSpeed) {
    var validPhase = phases.firstWhere((phase) {
      var validPhase = phase.getValidPhase(currentSpeed);
      return validPhase != null;
    });
    return validPhase;
  }

  /*SGAnnotation createSGAnnotation(){

  }*/

  SGSubscription makeSGSubscription() {
    return SGSubscription(sgName, isSubscribed);
  }

  Subscription makeSubscription() {
    int lsaId = parentLSA.id;
    String lsaName = parentLSA.name;
    SGSubscription sgSubscription = makeSGSubscription();

    return Subscription(lsaId, lsaName, [sgSubscription]);
  }

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    if (distance <= 100.0) {
      return crossingController.run(distance, accuracy);
    }

    return false;
  }

  bool _isCrossed = false;
  @JsonKey(ignore: true)
  @override
  bool get isCrossed => _isCrossed;

  @override
  void set isCrossed(bool _isCrossed) {
    bool oldValue = isCrossed;
    this._isCrossed = _isCrossed;

    if (isCrossed && oldValue == false) {
      annotationStatus = SGAnnotationStatus.none;
      shouldUpdateAnnotation = true;
      isSubscribed = false;

      Logger.root.fine("SG with name $sgName) has been crossed.");
    }
  }
}
