import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_info_plus/system_info_plus.dart';

class MapDesign {
  /// The name of the map design.
  final String name;

  /// The style string for the light map.
  final String lightStyle;

  /// The light screenshot asset path.
  final String lightScreenshot;

  /// The style string for the dark map.
  final String darkStyle;

  /// The dark screenshot asset path.
  final String darkScreenshot;

  const MapDesign({
    required this.name,
    required this.lightStyle,
    required this.lightScreenshot,
    required this.darkStyle,
    required this.darkScreenshot,
  });

  factory MapDesign.fromJson(Map<String, dynamic> json) => MapDesign(
        name: json['name'],
        lightStyle: json['lightStyle'],
        lightScreenshot: json['lightScreenshot'],
        darkStyle: json['darkStyle'],
        darkScreenshot: json['darkScreenshot'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lightStyle': lightStyle,
        'lightScreenshot': lightScreenshot,
        'darkStyle': darkStyle,
        'darkScreenshot': darkScreenshot,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapDesign && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  /// The standard map design.
  static const standard = MapDesign(
    name: 'PrioBike',
    lightStyle: 'mapbox://styles/snrmtths/cl77mab5k000214mkk26ewqqu',
    lightScreenshot: 'assets/images/screenshots/standard-light.png',
    darkStyle: 'mapbox://styles/mapbox/dark-v10',
    darkScreenshot: 'assets/images/screenshots/standard-dark.png',
  );

  /// All available map designs.
  static const designs = [
    standard,
    MapDesign(
      name: 'Verkehr',
      lightStyle: MapboxStyles.TRAFFIC_DAY,
      lightScreenshot: 'assets/images/screenshots/traffic-light.png',
      darkStyle: MapboxStyles.TRAFFIC_NIGHT,
      darkScreenshot: 'assets/images/screenshots/traffic-dark.png',
    ),
    MapDesign(
      name: 'Satellit',
      lightStyle: MapboxStyles.SATELLITE_STREETS,
      lightScreenshot: 'assets/images/screenshots/satellite-streets.png',
      darkStyle: MapboxStyles.SATELLITE_STREETS,
      darkScreenshot: 'assets/images/screenshots/satellite-streets.png',
    ),
  ];
}

class Layers with ChangeNotifier {
  var hasLoaded = false;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

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

  /// The currently selected style of the map.
  MapDesign mapDesign;

  /// Whether the layers can be enabled.
  bool layersCanBeEnabled;

  /// The memory threshold in mB.
  // Generally this app uses between 500-1500 (expecting mapbox memory leak to occur).
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

  Future<void> setMapDesign(MapDesign mapDesign) async {
    this.mapDesign = mapDesign;
    await storePreferences();
  }

  Layers({
    this.showRentalStations = false,
    this.showParkingStations = false,
    this.showConstructionSites = false,
    this.showAirStations = false,
    this.showRepairStations = false,
    this.showAccidentHotspots = true,
    this.mapDesign = MapDesign.standard,
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

      final mapDesignStr = storage.getString("priobike.layers.style");
      if (mapDesignStr != null) {
        mapDesign = MapDesign.fromJson(jsonDecode(mapDesignStr));
      } else {
        mapDesign = MapDesign.standard;
      }
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
    await storage.setString("priobike.layers.style", jsonEncode(mapDesign.toJson()));

    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
