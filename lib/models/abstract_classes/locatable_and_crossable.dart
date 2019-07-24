import 'package:bike_now/models/abstract_classes/locatable.dart';
import 'package:bike_now/models/abstract_classes/crossable.dart';
import 'package:bike_now/models/latlng.dart';
import 'package:location/location.dart';

import 'dart:math' show cos, sqrt, asin;

mixin LocatableAndCrossable implements Crossable{
  double lon;
  double lat;
  double distance;

  double calculateDistanceTo(LatLng destination){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((destination.lat - lat) * p)/2 +
        c(lat * p) * c(destination.lat * p) *
            (1 - c((destination.lng - lon) * p))/2;
    return 12742 * asin(sqrt(a));
  }




}