import 'dart:convert';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Migration {
  /// Load the privacy policy.
  static Future<void> migrate() async {
    // List of things to migrate.
    // Migrate shortcuts to new naming scheme.
    await migrateShortcutsProduction();
    await migrateShortcutsStaging();
    await migrateSearchHistoryProduction();
    await migrateSearchHistoryStaging();
    // Migrate shortcuts to new shortcuts model.
    await migrateShortcutsValues();

    // Migrate new background images.
    // Since beta 8.0 check if the image directory has images and remove them.
    // Then the background images will load again when they are needed.
    await migrateBackgroundImages();

    // Migrate the ebike routing profile to the citybike bike type.
    await migrateEBikeToCityBike();
    // Migrate the comfortable routing profile to the balanced preference type.
    await migrateComfortableToBalanced();
  }

  /// Migrate all background images.
  static Future<void> migrateBackgroundImages() async {
    if (getIt<Settings>().didMigrateBackgroundImages) return;

    // Deleting all images.
    await MapboxTileImageCache.deleteAllImages(false);
    // Set didMigrateBackgroundImages true.
    await getIt<Settings>().setDidMigrateBackgroundImages(true);
  }

  /// Migrate all shortcuts (production/release => Hamburg).
  static Future<void> migrateShortcutsProduction() async {
    final storage = await SharedPreferences.getInstance();

    Shortcuts shortcuts = getIt<Shortcuts>();

    // Get the current shortcuts of the currently used backend.
    final jsonStrProduction = storage.getString("priobike.home.shortcuts.${Backend.production.name}");
    final jsonStrRelease = storage.getString("priobike.home.shortcuts.${Backend.release.name}");
    // Return on no old key found.
    if (jsonStrProduction == null && jsonStrRelease == null) return;
    final jsonStrReleaseNew = storage.getString("priobike.home.shortcuts.${Backend.release.regionName}");

    List<Shortcut> shortcutsRelease = [];
    List<Shortcut> shortcutsProduction = [];
    List<Shortcut> shortcutsReleaseNew = [];

    if (jsonStrRelease != null) {
      shortcutsRelease = shortcuts.getShortcutsFromJson(jsonStrRelease);
    }

    if (jsonStrProduction != null) {
      shortcutsProduction = shortcuts.getShortcutsFromJson(jsonStrProduction);
    }

    if (jsonStrReleaseNew != null) {
      shortcutsReleaseNew = shortcuts.getShortcutsFromJson(jsonStrReleaseNew);
    }

    // Concat all.
    shortcutsReleaseNew.addAll(shortcutsRelease);
    shortcutsReleaseNew.addAll(shortcutsProduction);

    final jsonStr = jsonEncode(shortcutsReleaseNew.map((e) => e.toJson()).toList());

    // Save shortcuts under region name (Hamburg, Dresden) so that production and release use the same shortcuts.
    storage.setString("priobike.home.shortcuts.${Backend.release.regionName}", jsonStr);
    // Remove the unused shortcuts.
    storage.remove("priobike.home.shortcuts.${Backend.production.name}");
    storage.remove("priobike.home.shortcuts.${Backend.release.name}");
  }

  /// Migrate all shortcuts (staging => Dresden).
  static Future<void> migrateShortcutsStaging() async {
    final storage = await SharedPreferences.getInstance();

    Shortcuts shortcuts = getIt<Shortcuts>();

    // Get the current shortcuts of the currently used backend.
    final jsonStrStaging = storage.getString("priobike.home.shortcuts.${Backend.staging.name}");
    // Return on no old key found.
    if (jsonStrStaging == null) return;
    final jsonStrStagingNew = storage.getString("priobike.home.shortcuts.${Backend.staging.regionName}");

    List<Shortcut> shortcutsStagingNew = [];

    List<Shortcut> shortcutsStaging = shortcuts.getShortcutsFromJson(jsonStrStaging);

    if (jsonStrStagingNew != null) {
      shortcutsStagingNew = shortcuts.getShortcutsFromJson(jsonStrStagingNew);
    }

    // Concat all.
    shortcutsStagingNew.addAll(shortcutsStaging);

    final jsonStr = jsonEncode(shortcutsStagingNew.map((e) => e.toJson()).toList());

    // Save shortcuts under region name (Hamburg, Dresden) so that production and release use the same shortcuts.
    storage.setString("priobike.home.shortcuts.${Backend.staging.regionName}", jsonStr);
    // Remove the unused shortcuts.
    storage.remove("priobike.home.shortcuts.${Backend.staging.name}");
  }

  /// Migrate the search history (production/release => Hamburg).
  static Future<void> migrateSearchHistoryProduction() async {
    final storage = await SharedPreferences.getInstance();

    // Load production and release lists.
    List<String>? searchHistoryListProduction =
        storage.getStringList("priobike.routing.searchHistory.${Backend.production.name}");
    // Return on no key found.
    if (searchHistoryListProduction == null) return;

    List<String> searchHistoryListRelease =
        storage.getStringList("priobike.routing.searchHistory.${Backend.release.name}") ?? [];
    // Concat both lists.
    searchHistoryListRelease.addAll(searchHistoryListProduction);
    // Store concatenated list.
    await storage.setStringList(
        "priobike.routing.searchHistory.${Backend.release.regionName}", searchHistoryListRelease);
    // Remove old list.
    await storage.remove("priobike.routing.searchHistory.${Backend.production.name}");
  }

  /// Migrate the search history (staging => Dresden).
  static Future<void> migrateSearchHistoryStaging() async {
    final storage = await SharedPreferences.getInstance();

    // Load production and release lists.
    List<String>? searchHistoryListStaging =
        storage.getStringList("priobike.routing.searchHistory.${Backend.staging.name}");
    // Return on no key found.
    if (searchHistoryListStaging == null) return;

    List<String> searchHistoryListStagingNew =
        storage.getStringList("priobike.routing.searchHistory.${Backend.staging.regionName}") ?? [];
    // Concat both lists.
    searchHistoryListStagingNew.addAll(searchHistoryListStaging);
    // Store concatenated list.
    await storage.setStringList(
        "priobike.routing.searchHistory.${Backend.staging.regionName}", searchHistoryListStagingNew);
    // Remove old list.
    await storage.remove("priobike.routing.searchHistory.${Backend.staging.name}");
  }

  /// Adds test migration data for all backends.
  static Future<void> addTestMigrationData() async {
    final storage = await SharedPreferences.getInstance();

    // Create old data for Staging.
    List<Shortcut> stagingList = [
      ShortcutLocation(
        id: UniqueKey().toString(),
        name: "Staging-Location-Test",
        waypoint: Waypoint(51.038294, 13.703280, address: "Clara-Viebig-Straße 9"),
      ),
      ShortcutRoute(
        id: UniqueKey().toString(),
        name: "Staging-Route-Test",
        waypoints: [
          Waypoint(51.038294, 13.703280, address: "Clara-Viebig-Straße 9"),
          Waypoint(50.979067, 13.882596, address: "Elberadweg Heidenau"),
        ],
      ),
    ];

    final jsonStrStaging = jsonEncode(stagingList.map((e) => e.toJson()).toList());

    storage.setString("priobike.home.shortcuts.${Backend.staging.name}", jsonStrStaging);

    // Create old data for Production.
    List<Shortcut> productionList = [
      ShortcutLocation(
        id: UniqueKey().toString(),
        name: "Production-Location-Test",
        waypoint: Waypoint(53.5415701077766, 9.984275605794686, address: "Production-Location-Test"),
      ),
      ShortcutRoute(
        id: UniqueKey().toString(),
        name: "Production-Route-Test",
        waypoints: [
          Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg"),
          Waypoint(53.564378, 9.978001, address: "Rentzelstraße 55, 20146 Hamburg"),
        ],
      ),
    ];

    final jsonStrProduction = jsonEncode(productionList.map((e) => e.toJson()).toList());

    storage.setString("priobike.home.shortcuts.${Backend.production.name}", jsonStrProduction);

    // Create old data for Release.
    List<Shortcut> releaseList = [
      ShortcutLocation(
        id: UniqueKey().toString(),
        name: "Release-Location-Test",
        waypoint: Waypoint(53.5415701077766, 9.984275605794686, address: "Release-Location-Test"),
      ),
      ShortcutRoute(
        id: UniqueKey().toString(),
        name: "Release-Route-Test",
        waypoints: [
          Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg"),
          Waypoint(53.564378, 9.978001, address: "Rentzelstraße 55, 20146 Hamburg"),
        ],
      ),
    ];

    final jsonStrRelease = jsonEncode(releaseList.map((e) => e.toJson()).toList());

    storage.setString("priobike.home.shortcuts.${Backend.release.name}", jsonStrRelease);

    // Create old search history data.
    await storage.setStringList("priobike.routing.searchHistory.${Backend.staging.name}",
        [json.encode(Waypoint(51.038294, 13.703280, address: "Clara-Viebig-Straße 9").toJSON())]);
    await storage.setStringList("priobike.routing.searchHistory.${Backend.production.name}",
        [json.encode(Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg").toJSON())]);
    await storage.setStringList("priobike.routing.searchHistory.${Backend.release.name}",
        [json.encode(Waypoint(53.560863, 9.990909, address: "Theodor-Heuss-Platz, Hamburg").toJSON())]);

    await storage.remove("priobike.shortcuts.checked.${Backend.release.regionName}");
    await storage.remove("priobike.shortcuts.checked.${Backend.staging.regionName}");
  }

  /// Migrates all shortcuts to set values for time and length.
  /// Also checks for 'Aktueller Standort' as waypoint name.
  static Future<void> migrateShortcutsValues() async {
    final storage = await SharedPreferences.getInstance();
    final Backend backend = getIt<Settings>().backend;
    Shortcuts shortcuts = getIt<Shortcuts>();

    await shortcuts.loadShortcuts();

    // Load the list of checked shortcuts.
    List<String> checkedShortcutsList = storage.getStringList("priobike.shortcuts.checked.${backend.regionName}") ?? [];

    // Loop through shortcuts and fill missing values.
    // Skip if lists are equally long.
    if (shortcuts.shortcuts == null && shortcuts.shortcuts!.length == checkedShortcutsList.length) return;

    Routing routing = getIt<Routing>();
    Geocoding geocoding = getIt<Geocoding>();

    for (Shortcut shortcut in shortcuts.shortcuts!) {
      // Skip checked shortcuts.
      if (checkedShortcutsList.contains(shortcut.id)) continue;
      // Skip and add ShortcutLocations.
      if (shortcut is ShortcutLocation) {
        checkedShortcutsList.add(shortcut.id);
        continue;
      }
      shortcut = shortcut as ShortcutRoute;
      // Check waypoint addresses.
      for (Waypoint waypoint in shortcut.getWaypoints()) {
        // Skip addresses not 'Aktueller Standort'.
        if (waypoint.address != "Aktueller Standort") continue;
        String? address = await geocoding.reverseGeocode(LatLng(waypoint.lat, waypoint.lon));
        if (address == null) {
          log.i("Address for waypoint with reverseGeocode not found");
        }
        waypoint.address = address;
      }

      // Check route length text.
      if (shortcut.routeLengthText == null ||
          shortcut.routeLengthText == "" ||
          shortcut.routeTimeText == null ||
          shortcut.routeTimeText == "") {
        await getIt<Boundary>().loadBoundaryCoordinates();
        r.Route? route = await routing.loadRouteFromShortcutRouteForMigration(shortcut);
        if (route != null) {
          shortcut.routeTimeText = route.timeText;
          shortcut.routeLengthText = route.lengthText;
          // Only add if route was found.
          checkedShortcutsList.add(shortcut.id);
        }
      }
    }
    // Save the migrated shortcuts.
    await shortcuts.storeShortcuts();
    // Save the migrated shortcuts to skip them in the future.
    storage.setStringList("priobike.shortcuts.checked.${backend.regionName}", checkedShortcutsList);
  }

  /// Migrates the ebike profile to the new citybike bike type.
  static Future<void> migrateEBikeToCityBike() async {
    final storage = await SharedPreferences.getInstance();

    final bikeTypeStr = storage.getString("priobike.home.profile.bike");
    if (bikeTypeStr != null && bikeTypeStr == "ebike") {
      await storage.setString("priobike.home.profile.bike", BikeType.citybike.name);
      log.i("Migrated ebike to citybike bike type.");
    }
  }

  /// Migrates the comfortable profile to the new balanced preference type.
  static Future<void> migrateComfortableToBalanced() async {
    final storage = await SharedPreferences.getInstance();

    final preferenceTypeStr = storage.getString("priobike.home.profile.preferences");
    // "comfortible" contains a type but is not an accident.
    // It was a typo in the past and we need to reference it like that.
    if (preferenceTypeStr != null && preferenceTypeStr == "comfortible") {
      await storage.setString("priobike.home.profile.preferences", PreferenceType.balanced.name);
      log.i("Migrated comfortable to balanced preference type.");
    }
  }
}
