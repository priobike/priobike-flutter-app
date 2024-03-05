import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_info_plus/system_info_plus.dart';

class Layers with ChangeNotifier {
  var hasLoaded = false;

  /// If rental stations are currently visible.
  bool showRentalStations;

  /// If parking stations are currently visible.
  bool showParkingStations;

  /// If construction sites are currently visible.
  bool showConstructionSites;

  /// If air stations are currently visible.
  bool showAirStations;

  /// If repair stations are currently visible.
  bool showRepairStations;

  /// If accident hotspots are currently visible.
  bool showAccidentHotspots;

  /// If the green wave layer is currently visible.
  bool showGreenWaveLayer;

  /// If the velo routes layer is currently visible.
  bool showVeloRoutesLayer;

  /// If the traffic layer is currently visible.
  bool showTrafficLayer;

  /// If the intersections layer is currently visible.
  bool showIntersectionsLayer;

  /// Whether the layers can be enabled.
  bool layersCanBeEnabled;

  /// The memory threshold in MB.
  /// Generally this app uses between 500-1500 (expecting mapbox memory leak to occur).
  static const memoryThreshold = 2000;

  Future<void> setShowRentalStations(bool showRentalStations) async {
    this.showRentalStations = showRentalStations;
    await storePreferences();
  }

  Future<void> setShowParkingStations(bool showParkingStations) async {
    this.showParkingStations = showParkingStations;
    await storePreferences();
  }

  Future<void> setShowConstructionSites(bool showConstructionSites) async {
    this.showConstructionSites = showConstructionSites;
    await storePreferences();
  }

  Future<void> setShowAirStations(bool showAirStations) async {
    this.showAirStations = showAirStations;
    await storePreferences();
  }

  Future<void> setShowRepairStations(bool showRepairStations) async {
    this.showRepairStations = showRepairStations;
    await storePreferences();
  }

  Future<void> setShowAccidentHotspots(bool showAccidentHotspots) async {
    this.showAccidentHotspots = showAccidentHotspots;
    await storePreferences();
  }

  Future<void> setShowGreenWaveLayer(bool showGreenWaveLayer) async {
    this.showGreenWaveLayer = showGreenWaveLayer;
    await storePreferences();
  }

  Future<void> setShowVeloRoutesLayer(bool showVeloRoutesLayer) async {
    this.showVeloRoutesLayer = showVeloRoutesLayer;
    await storePreferences();
  }

  Future<void> setShowTrafficLayer(bool showTrafficLayer) async {
    this.showTrafficLayer = showTrafficLayer;
    await storePreferences();
  }

  Future<void> setShowIntersectionsLayer(bool showIntersectionsLayer) async {
    this.showIntersectionsLayer = showIntersectionsLayer;
    await storePreferences();
  }

  Layers({
    this.showRentalStations = false,
    this.showParkingStations = false,
    this.showConstructionSites = false,
    this.showAirStations = false,
    this.showRepairStations = false,
    this.showAccidentHotspots = true,
    this.showGreenWaveLayer = false,
    this.showVeloRoutesLayer = false,
    this.showTrafficLayer = false,
    this.showIntersectionsLayer = true,
    this.layersCanBeEnabled = false,
  });

  /// Load the preferred settings.
  Future<void> loadPreferences() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();
    final systemMemory = await SystemInfoPlus.physicalMemory;

    // Use standard setup on insufficient RAM.
    if (systemMemory != null && systemMemory >= memoryThreshold) {
      layersCanBeEnabled = true;

      showRentalStations = storage.getBool("priobike.layers.showRentalStations") ?? false;
      showParkingStations = storage.getBool("priobike.layers.showParkingStations") ?? false;
      showConstructionSites = storage.getBool("priobike.layers.showConstructionSites") ?? true;
      showAirStations = storage.getBool("priobike.layers.showAirStations") ?? false;
      showRepairStations = storage.getBool("priobike.layers.showRepairStations") ?? false;
      showAccidentHotspots = storage.getBool("priobike.layers.showAccidentHotspots") ?? false;
      showGreenWaveLayer = storage.getBool("priobike.layers.showGreenWaveLayer") ?? false;
      showVeloRoutesLayer = storage.getBool("priobike.layers.showVeloRoutesLayer") ?? false;
      showTrafficLayer = storage.getBool("priobike.layers.showTrafficLayer") ?? false;
      showIntersectionsLayer = storage.getBool("priobike.layers.showIntersectionsLayer") ?? true;
    }
    notifyListeners();
  }

  /// Store the preferred settings.
  Future<void> storePreferences() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setBool("priobike.layers.showRentalStations", showRentalStations);
    await storage.setBool("priobike.layers.showParkingStations", showParkingStations);
    await storage.setBool("priobike.layers.showConstructionSites", showConstructionSites);
    await storage.setBool("priobike.layers.showAirStations", showAirStations);
    await storage.setBool("priobike.layers.showRepairStations", showRepairStations);
    await storage.setBool("priobike.layers.showAccidentHotspots", showAccidentHotspots);
    await storage.setBool("priobike.layers.showGreenWaveLayer", showGreenWaveLayer);
    await storage.setBool("priobike.layers.showVeloRoutesLayer", showVeloRoutesLayer);
    await storage.setBool("priobike.layers.showTrafficLayer", showTrafficLayer);
    await storage.setBool("priobike.layers.showIntersectionsLayer", showIntersectionsLayer);

    notifyListeners();
  }
}
