import 'dart:convert';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Migration {
  /// Load the privacy policy.
  Future<void> migrate() async {
    // List of things to migrate.
    await migrateShortcutsProduction();
    await migrateShortcutsStaging();
    await migrateSearchHistoryProduction();
    await migrateSearchHistoryStaging();
  }

  /// Migrate all shortcuts (production/release => Hamburg).
  Future<void> migrateShortcutsProduction() async {
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
  }

  /// Migrate all shortcuts (staging => Dresden).
  Future<void> migrateShortcutsStaging() async {
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
  Future<void> migrateSearchHistoryProduction() async {
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
  Future<void> migrateSearchHistoryStaging() async {
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
  Future<void> addTestMigrationData() async {
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
        waypoint: Waypoint(53.5415701077766, 9.984275605794686, address: "Staging-test"),
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
        waypoint: Waypoint(53.5415701077766, 9.984275605794686, address: "Staging-test"),
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
  }
}
