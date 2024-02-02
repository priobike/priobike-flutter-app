import 'package:flutter/foundation.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/logging/logger.dart';

class RoutingPOI with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Routing-POI");

  /// The selected POI.
  POIElement? selectedPOI;

  /// The calculated position x of the POI.
  double? calculatedX;

  /// The calculated position x of the POI.
  double? calculatedY;

  RoutingPOI();

  /// Set POI Element.
  void setPOIElement(POIElement poiElement) {
    selectedPOI = poiElement;
    notifyListeners();
  }

  /// Unset POI Element.
  void unsetPOIElement() {
    selectedPOI = null;
    notifyListeners();
  }

  /// Set the pixel coordinates that are used to display the POI widget.
  void setPixelCoordinates(double? x, double? y) {
    calculatedX = x;
    calculatedY = y;

    notifyListeners();
  }

  /// Resets the service.
  reset() {
    calculatedX = null;
    calculatedY = null;
    selectedPOI = null;
  }
}
