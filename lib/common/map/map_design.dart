import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
    darkStyle: 'mapbox://styles/snrmtths/cle4gkymg001t01nwazajfyod',
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

class MapDesigns with ChangeNotifier {
  var hasLoaded = false;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The currently selected style of the map.
  MapDesign mapDesign;

  /// Whether the layers can be enabled.
  bool designCanBeChanged;

  /// The memory threshold in MB.
  /// On low-end devices, this ensures that layers cannot be switched.
  static const memoryThreshold = 500;

  Future<void> setMapDesign(MapDesign mapDesign) async {
    this.mapDesign = mapDesign;
    await storePreferences();
  }

  MapDesigns({
    this.mapDesign = MapDesign.standard,
    this.designCanBeChanged = false,
  });

  /// Load the preferred settings.
  Future<void> loadPreferences() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();
    final systemMemory = await SystemInfoPlus.physicalMemory;

    // Use standard setup on insufficient RAM.
    if (systemMemory != null && systemMemory >= memoryThreshold) {
      designCanBeChanged = true;

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

    await storage.setString("priobike.layers.style", jsonEncode(mapDesign.toJson()));

    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
