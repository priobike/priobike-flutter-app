import 'package:priobike/home/services/poi.dart';

class POIPopup {
  /// The POI element.
  final POIElement poiElement;

  /// The screen coordinate X.
  double screenCoordinateX;

  /// The screen coordinate Y.
  double screenCoordinateY;

  /// The opacity of the poi popup.
  double poiOpacity;

  POIPopup({
    required this.poiElement,
    required this.screenCoordinateX,
    required this.screenCoordinateY,
    required this.poiOpacity,
  });

  void updatePopUp(double x, double y, double opacity) {
    screenCoordinateX = x;
    screenCoordinateY = y;
    poiOpacity = opacity;
  }
}
