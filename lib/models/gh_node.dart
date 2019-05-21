import 'package:bike_now/models/sg.dart';
import 'package:mapbox_gl/mapbox_gl.dart';


import 'abstract_classes/crossable.dart';
import 'abstract_classes/locatable.dart';


class GHNode with Crossable, Locatable{
  int id;

  LatLng coordinate;

  bool shouldUpdateOverlay;
  SG referencedSG;

  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    // TODO: implement calculateIsCrossed
    return null;
  }

}