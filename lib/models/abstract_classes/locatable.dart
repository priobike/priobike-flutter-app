import 'dart:math' show cos, sqrt, asin;
import 'package:bike_now_flutter/models/models.dart';

abstract class Locatable {
  double lon;
  double lat;
  double distance;

  double calculateDistanceTo(LatLng destination) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((destination.lat - lat) * p) / 2 +
        c(lat * p) *
            c(destination.lat * p) *
            (1 - c((destination.lng - lon) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }
}
