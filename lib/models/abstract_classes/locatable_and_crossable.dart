import 'package:bike_now/models/abstract_classes/locatable.dart';
import 'package:bike_now/models/abstract_classes/crossable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;

abstract class LocatableAndCrossable{

  bool isCrossed;
  bool calculateIsCrossed(double distance, double accuracy);

  double longitude;
  double latidude;
  double distance;

  double calculateDistanceTo(LatLng destination){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((destination.latitude - latidude) * p)/2 +
        c(latidude * p) * c(destination.latitude * p) *
            (1 - c((destination.longitude - longitude) * p))/2;
    return 12742 * asin(sqrt(a));
  }


}