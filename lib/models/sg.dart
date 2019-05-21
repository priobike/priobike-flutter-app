import 'package:bike_now/models/abstract_classes/locatable.dart';
import 'package:bike_now/models/abstract_classes/crossable.dart';
import 'package:bike_now/models/phase.dart';
import 'package:bike_now/models/sg_subscription.dart';
import 'package:bike_now/models/subscription.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'gh_node.dart';
import 'lsa.dart';

enum SGAnnotationStatus {
  none,green,red
}

class SG with Locatable, Crossable{
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

  //SGAnnotation annotation;
  SGAnnotationStatus annotationStatus = SGAnnotationStatus.none;

  bool shouldUpdateAnnotation = false;

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


}