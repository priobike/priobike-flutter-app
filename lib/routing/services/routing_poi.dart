import 'package:flutter/foundation.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/logging/logger.dart';

class RoutingPOI with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Routing-POI");

  /// The selected POI.
  POIElement? selectedPOI;

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
}
