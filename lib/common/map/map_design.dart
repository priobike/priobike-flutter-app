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

  /// The style string for the light map without text.
  final String lightStyleNoText;

  /// The light screenshot asset path.
  final String fallbackLightScreenshot;

  /// The style string for the dark map.
  final String darkStyle;

  /// The style string for the dark map without text.
  final String darkStyleNoText;

  /// The dark screenshot asset path.
  final String fallbackDarkScreenshot;

  const MapDesign({
    required this.name,
    required this.lightStyle,
    required this.lightStyleNoText,
    required this.fallbackLightScreenshot,
    required this.darkStyle,
    required this.darkStyleNoText,
    required this.fallbackDarkScreenshot,
  });

  factory MapDesign.fromJson(Map<String, dynamic> json) => MapDesign(
        name: json['name'],
        lightStyle: json['lightStyle'],
        lightStyleNoText: json['lightStyleNoText'],
        fallbackLightScreenshot: json['fallbackLightScreenshot'],
        darkStyle: json['darkStyle'],
        darkStyleNoText: json['darkStyleNoText'],
        fallbackDarkScreenshot: json['fallbackDarkScreenshot'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lightStyle': lightStyle,
        'lightStyleNoText': lightStyleNoText,
        'fallbackLightScreenshot': fallbackLightScreenshot,
        'darkStyle': darkStyle,
        'darkStyleNoText': darkStyleNoText,
        'fallbackDarkScreenshot': fallbackDarkScreenshot,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapDesign && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  /// The standard map design.
  static const standard = MapDesign(
    name: 'PrioBike',
    lightStyle: 'mapbox://styles/priobike/clxsxd37v00qr01r25md4dyd5',
    lightStyleNoText: 'mapbox://styles/priobike/clxsxf2pv00p201qqek90dhtw',
    fallbackLightScreenshot: 'assets/images/screenshots/standard-light.png',
    darkStyle: 'mapbox://styles/priobike/clxsx540g00rg01pc212c0bh5',
    darkStyleNoText: 'mapbox://styles/priobike/clxsx6zvl00r301pfcabdebhv',
    fallbackDarkScreenshot: 'assets/images/screenshots/standard-dark.png',
  );

  /// All available map designs.
  static const designs = [
    standard,
    MapDesign(
      name: 'Satellit',
      lightStyle: MapboxStyles.SATELLITE_STREETS,
      lightStyleNoText: 'mapbox://styles/priobike/clxsxf2pv00p201qqek90dhtw',
      fallbackLightScreenshot: 'assets/images/screenshots/satellite-streets.png',
      darkStyle: MapboxStyles.SATELLITE_STREETS,
      darkStyleNoText: 'mapbox://styles/priobike/clxsx6zvl00r301pfcabdebhv',
      fallbackDarkScreenshot: 'assets/images/screenshots/satellite-streets.png',
    ),
  ];
}

class MapDesigns with ChangeNotifier {
  var hasLoaded = false;

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

      try {
        final String? mapDesignName = storage.getString("priobike.layers.styleName");
        if (mapDesignName != null) {
          // Load the map design from the preferences.
          bool found = false;
          for (final design in MapDesign.designs) {
            if (design.name == mapDesignName) {
              mapDesign = design;
              found = true;
              break;
            }
          }
          if (!found) {
            throw Exception("Unknown map design in shared prefs: $mapDesignName. Setting MapDesign to standard.");
          }
        } else {
          throw Exception("No map design found in preferences. Setting MapDesign to standard.");
        }
      } catch (e) {
        await setMapDesign(MapDesign.standard);
      }
    }
    notifyListeners();
  }

  /// Store the preferred settings.
  Future<void> storePreferences() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setString("priobike.layers.styleName", jsonEncode(mapDesign.name));

    notifyListeners();
  }
}
