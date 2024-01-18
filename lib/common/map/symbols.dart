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
    await add("trafficlightdisconnecteddark", "assets/images/trafficlights/disconnected-dark.png", 400, 400);
    await add("trafficlightdisconnectedlight", "assets/images/trafficlights/disconnected-light.png", 400, 400);
    await add("trafficlightonlinedarknocheck", "assets/images/trafficlights/online-dark-no-check.png", 300, 400);
    await add("trafficlightonlinelightnocheck", "assets/images/trafficlights/online-light-no-check.png", 300, 400);
    await add("trafficlightclicklayer", "assets/images/trafficlights/traffic-light-click-layer-debug.png", 60, 176);
    await add("trafficlightonlinedark", "assets/images/trafficlights/online-dark.png", 400, 400);
    await add("trafficlightonlinelight", "assets/images/trafficlights/online-light.png", 400, 400);
    await add("trafficlightonlinegreendark", "assets/images/trafficlights/online-green-dark.png", 300, 400);
    await add("trafficlightonlinegreenlight", "assets/images/trafficlights/online-green-light.png", 300, 400);
    await add("trafficlightonlinereddark", "assets/images/trafficlights/online-red-dark.png", 300, 400);
    await add("trafficlightonlineredlight", "assets/images/trafficlights/online-red-light.png", 300, 400);
    await add("trafficlightonlineamberdark", "assets/images/trafficlights/online-amber-dark.png", 300, 400);
    await add("trafficlightonlineamberlight", "assets/images/trafficlights/online-amber-light.png", 300, 400);
    await add("trafficlightonlinedarkdark", "assets/images/trafficlights/online-dark-dark.png", 300, 400);
    await add("trafficlightonlinedarklight", "assets/images/trafficlights/online-dark-light.png", 300, 400);

    await add("trafficlighttouchindicatordark", "assets/images/trafficlights/touch-indicator-dark.png", 400, 400);
    await add("trafficlighttouchindicatorlight", "assets/images/trafficlights/touch-indicator-light.png", 400, 400);

    await add("dangerspot", "assets/images/dangerspot.png", 400, 400);
    await add("start", "assets/images/start.drawio.png", 83, 83);
    await add("destination", "assets/images/destination.drawio.png", 84, 84);
    await add("waypoint", "assets/images/waypoint.drawio.png", 84, 84);

    await add("airdark", "assets/images/air-dark.png", 200, 200);
    await add("airlight", "assets/images/air-light.png", 200, 200);
    await add("constructiondark", "assets/images/construction-dark.png", 200, 200);
    await add("constructionlight", "assets/images/construction-light.png", 200, 200);
    await add("parkdark", "assets/images/park-dark.png", 200, 200);
    await add("parklight", "assets/images/park-light.png", 200, 200);
    await add("positiondark", "assets/images/position-dark.png", 400, 400);
    await add("positionlight", "assets/images/position-light.png", 400, 400);
    await add("positionstaticdark", "assets/images/position-static-dark.png", 400, 400);
    await add("positionstaticlight", "assets/images/position-static-light.png", 400, 400);
    await add("rentdark", "assets/images/rent-dark.png", 200, 200);
    await add("rentlight", "assets/images/rent-light.png", 200, 200);
    await add("repairdark", "assets/images/repair-dark.png", 200, 200);
    await add("repairlight", "assets/images/repair-light.png", 200, 200);
    await add("accidentdark", "assets/images/accident-dark.png", 200, 200);
    await add("accidentlight", "assets/images/accident-light.png", 200, 200);
    await add("greenwavedark", "assets/images/green-wave-dark.png", 200, 200);
    await add("greenwavelight", "assets/images/green-wave-light.png", 200, 200);

    await add("route-label-primary-left", "assets/images/route-label-primary-left.png", 201, 63);
    await add("route-label-primary-right", "assets/images/route-label-primary-right.png", 201, 63);
    await add("route-label-primary-top", "assets/images/route-label-primary-top.png", 151, 113);
    await add("route-label-primary-bottom", "assets/images/route-label-primary-bottom.png", 151, 113);
    await add("route-label-secondary-left", "assets/images/route-label-secondary-left.png", 200, 63);
    await add("route-label-secondary-right", "assets/images/route-label-secondary-right.png", 200, 63);
    await add("route-label-secondary-top", "assets/images/route-label-secondary-top.png", 150, 113);
    await add("route-label-secondary-bottom", "assets/images/route-label-secondary-bottom.png", 150, 113);
  }

  /// Adds an asset image to the currently displayed style
  Future<void> add(String name, String assetName, int width, int height) async {
    if (await mapController.style.hasStyleImage(name)) return;
    final bytes = await rootBundle.load(assetName);
    final bytesArr = bytes.buffer.asUint8List();
    return mapController.style
        .addStyleImage(name, 1, MbxImage(width: width, height: height, data: bytesArr), false, [], [], null);
  }
}
