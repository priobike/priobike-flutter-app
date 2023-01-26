import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// A loader for mapbox map symbols.
class SymbolLoader {
  /// The associated map controller.
  MapboxMap mapController;

  /// Create a new symbol loader.
  SymbolLoader(this.mapController);

  /// Load all symbols into the map controller.
  /// Make sure that all symbols are added to the pubspec.yaml file.
  Future<void> loadSymbols() async {
    await addImageFromAsset(
        "trafficlightdisconnecteddark", "assets/images/trafficlights/disconnected-dark.png", 200, 200);
    await addImageFromAsset(
        "trafficlightdisconnectedlight", "assets/images/trafficlights/disconnected-light.png", 200, 200);
    await addImageFromAsset(
        "trafficlightonlinedarknocheck", "assets/images/trafficlights/online-dark-no-check.png", 200, 200);
    await addImageFromAsset(
        "trafficlightonlinelightnocheck", "assets/images/trafficlights/online-light-no-check.png", 200, 200);
    await addImageFromAsset("trafficlightonlinedark", "assets/images/trafficlights/online-dark.png", 200, 200);
    await addImageFromAsset("trafficlightonlinelight", "assets/images/trafficlights/online-light.png", 200, 200);
    await addImageFromAsset(
        "trafficlightonlinegreendark", "assets/images/trafficlights/online-green-dark.png", 400, 400);
    await addImageFromAsset(
        "trafficlightonlinegreenlight", "assets/images/trafficlights/online-green-light.png", 400, 400);
    await addImageFromAsset("trafficlightonlinereddark", "assets/images/trafficlights/online-red-dark.png", 400, 400);
    await addImageFromAsset("trafficlightonlineredlight", "assets/images/trafficlights/online-red-light.png", 400, 400);
    await addImageFromAsset(
        "trafficlightonlineamberdark", "assets/images/trafficlights/online-amber-dark.png", 400, 400);
    await addImageFromAsset(
        "trafficlightonlineamberlight", "assets/images/trafficlights/online-amber-light.png", 400, 400);
    await addImageFromAsset("trafficlightonlinedarkdark", "assets/images/trafficlights/online-dark-dark.png", 400, 400);
    await addImageFromAsset(
        "trafficlightonlinedarklight", "assets/images/trafficlights/online-dark-light.png", 400, 400);

    await addImageFromAsset("alert", "assets/images/alert.drawio.png", 104, 104);
    await addImageFromAsset("start", "assets/images/start.drawio.png", 83, 83);
    await addImageFromAsset("destination", "assets/images/destination.drawio.png", 84, 84);
    await addImageFromAsset("waypoint", "assets/images/waypoint.drawio.png", 84, 84);

    await addImageFromAsset("airdark", "assets/images/air-dark.png", 201, 201);
    await addImageFromAsset("airlight", "assets/images/air-light.png", 201, 201);
    await addImageFromAsset("constructiondark", "assets/images/construction-dark.png", 201, 201);
    await addImageFromAsset("constructionlight", "assets/images/construction-light.png", 201, 201);
    await addImageFromAsset("parkdark", "assets/images/park-dark.png", 201, 201);
    await addImageFromAsset("parklight", "assets/images/park-light.png", 201, 201);
    await addImageFromAsset("positiondark", "assets/images/position-dark.png", 400, 400);
    await addImageFromAsset("positionlight", "assets/images/position-light.png", 400, 400);
    await addImageFromAsset("positionstaticdark", "assets/images/position-static-dark.png", 400, 400);
    await addImageFromAsset("positionstaticlight", "assets/images/position-static-light.png", 400, 400);
    await addImageFromAsset("rentdark", "assets/images/rent-dark.png", 201, 201);
    await addImageFromAsset("rentlight", "assets/images/rent-light.png", 201, 201);
    await addImageFromAsset("repairdark", "assets/images/repair-dark.png", 201, 201);
    await addImageFromAsset("repairlight", "assets/images/repair-light.png", 201, 201);
    await addImageFromAsset("accidentdark", "assets/images/accident-dark.png", 201, 201);
    await addImageFromAsset("accidentlight", "assets/images/accident-light.png", 201, 201);
    await addImageFromAsset("route-label-pmm", "assets/images/route-label-pmm.png", 201, 201);
    await addImageFromAsset("route-label-smm", "assets/images/route-label-smm.png", 201, 201);

    await addImageFromAsset("potholes", "assets/images/potholes-map.png", 201, 201);
    await addImageFromAsset("obstacle", "assets/images/obstacle-map.png", 201, 201);
    await addImageFromAsset("dangerspot", "assets/images/dangerspot-map.png", 200, 201);
  }

  /// Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName, int width, int height) async {
    final bytes = await rootBundle.load(assetName);
    final bytesArr = bytes.buffer.asUint8List();
    return mapController.style
        .addStyleImage(name, 1, MbxImage(width: width, height: height, data: bytesArr), false, [], [], null);
  }
}
