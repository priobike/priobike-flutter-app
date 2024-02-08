import 'package:priobike/home/services/poi.dart';

class POIPopup {
  /// The POI element.
  final POIElement poiElement;

  /// The screen coordinate X.
  double screenCoordinateX;

  /// The screen coordinate Y.
  double screenCoordinateY;

  POIPopup({
    required this.poiElement,
    required this.screenCoordinateX,
    required this.screenCoordinateY,
  });

  void updateScreenCoordinates(double x, double y) {
    screenCoordinateX = x;
    screenCoordinateY = y;
  }
}
