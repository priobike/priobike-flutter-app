import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// A loader for mapbox map symbols.
class SymbolLoader {
  /// The associated map controller.
  MapboxMapController mapController;

  /// Create a new symbol loader.
  SymbolLoader(this.mapController);

  /// Load all symbols into the map controller.
  /// Make sure that all symbols are added to the pubspec.yaml file.
  Future<void> loadSymbols() async {
    await addImageFromAsset("trafficlightdisconnecteddark", "assets/images/trafficlights/disconnected-dark.png");
    await addImageFromAsset("trafficlightdisconnectedlight", "assets/images/trafficlights/disconnected-light.png");
    await addImageFromAsset("trafficlightofflinedark", "assets/images/trafficlights/offline-dark.png");
    await addImageFromAsset("trafficlightofflinelight", "assets/images/trafficlights/offline-light.png");
    await addImageFromAsset("trafficlightonlinedark", "assets/images/trafficlights/online-dark.png");
    await addImageFromAsset("trafficlightonlinelight", "assets/images/trafficlights/online-light.png");
    await addImageFromAsset("trafficlightonlinegreendark", "assets/images/trafficlights/online-green-dark.png");
    await addImageFromAsset("trafficlightonlinegreenlight", "assets/images/trafficlights/online-green-light.png");
    await addImageFromAsset("trafficlightonlinereddark", "assets/images/trafficlights/online-red-dark.png");
    await addImageFromAsset("trafficlightonlineredlight", "assets/images/trafficlights/online-red-light.png");
    await addImageFromAsset("trafficlightonlineamberdark", "assets/images/trafficlights/online-amber-dark.png");
    await addImageFromAsset("trafficlightonlineamberlight", "assets/images/trafficlights/online-amber-light.png");
    await addImageFromAsset("trafficlightonlinedarkdark", "assets/images/trafficlights/online-dark-dark.png");
    await addImageFromAsset("trafficlightonlinedarklight", "assets/images/trafficlights/online-dark-light.png");

    await addImageFromAsset("alert", "assets/images/alert.drawio.png");
    await addImageFromAsset("start", "assets/images/start.drawio.png");
    await addImageFromAsset("destination", "assets/images/destination.drawio.png");
    await addImageFromAsset("waypoint", "assets/images/waypoint.drawio.png");

    await addImageFromAsset("airdark", "assets/images/air-dark.png");
    await addImageFromAsset("airlight", "assets/images/air-light.png");
    await addImageFromAsset("constructiondark", "assets/images/construction-dark.png");
    await addImageFromAsset("constructionlight", "assets/images/construction-light.png");
    await addImageFromAsset("parkdark", "assets/images/park-dark.png");
    await addImageFromAsset("parklight", "assets/images/park-light.png");
    await addImageFromAsset("positiondark", "assets/images/position-dark.png");
    await addImageFromAsset("positionlight", "assets/images/position-light.png");
    await addImageFromAsset("rentdark", "assets/images/rent-dark.png");
    await addImageFromAsset("rentlight", "assets/images/rent-light.png");
    await addImageFromAsset("repairdark", "assets/images/repair-dark.png");
    await addImageFromAsset("repairlight", "assets/images/repair-light.png");
    await addImageFromAsset("accidentdark", "assets/images/accident-dark.png");
    await addImageFromAsset("accidentlight", "assets/images/accident-light.png");
    await addImageFromAsset("route-label-pmm", "assets/images/route-label-pmm.png");
    await addImageFromAsset("route-label-smm", "assets/images/route-label-smm.png");
    await addImageFromAsset("potholes", "assets/images/potholes-map.png");
    await addImageFromAsset("obstacle", "assets/images/obstacle-map.png");
    await addImageFromAsset("dangerspot", "assets/images/dangerspot-map.png");
  }

  /// Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final bytesArr = bytes.buffer.asUint8List();
    return mapController.addImage(name, bytesArr);
  }
}
