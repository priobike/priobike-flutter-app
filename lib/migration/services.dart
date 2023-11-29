import 'dart:convert';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Migration with ChangeNotifier {
  /// Load the privacy policy.
  Future<void> migrate() async {
    // List of things to migrate.
    await migrateShortcuts();
    await migrateSearchHistory();
  }

  /// Migrate all shortcuts (Hamburg beta => Hamburg).
  Future<void> migrateShortcuts() async {
    final storage = await SharedPreferences.getInstance();

    // Get the current shortcuts of the currently used backend.
    final jsonStrProduction = storage.getString("priobike.home.shortcuts.${Backend.production.name}");
    // Return on no old key found.
    if (jsonStrProduction == null) return;
    final jsonStrRelease = storage.getString("priobike.home.shortcuts.${Backend.release.name}");

    List<Shortcut> shortcutsRelease = [];
    List<Shortcut> shortcutsProduction = [];

    if (jsonStrRelease != null) {
      // Loop through all json Shortcuts and add correct shortcuts to shortcutsRelease.
      for (final e in jsonDecode(jsonStrRelease) as List) {
        if (e["type"] != null) {
          switch (e["type"]) {
            case "ShortcutLocation":
              shortcutsRelease.add(ShortcutLocation.fromJson(e));
              break;
            case "ShortcutRoute":
              shortcutsRelease.add(ShortcutRoute.fromJson(e));
              break;
            default:
              final hint = "Error unknown type ${e["type"]} in loadShortcuts.";
              log.e(hint);
          }
        } else {
          // Only for backwards compatibility.
          if (e["waypoint"] != null) shortcutsRelease.add(ShortcutLocation.fromJson(e));
          if (e["waypoints"] != null) shortcutsRelease.add(ShortcutRoute.fromJson(e));
        }
      }
    }

    // Init shortcuts.
    // Loop through all json Shortcuts and add correct shortcuts to shortcutsProduction.
    for (final e in jsonDecode(jsonStrProduction) as List) {
      if (e["type"] != null) {
        switch (e["type"]) {
          case "ShortcutLocation":
            shortcutsProduction.add(ShortcutLocation.fromJson(e));
            break;
          case "ShortcutRoute":
            shortcutsProduction.add(ShortcutRoute.fromJson(e));
            break;
          default:
            final hint = "Error unknown type ${e["type"]} in loadShortcuts.";
            log.e(hint);
        }
      } else {
        // Only for backwards compatibility.
        if (e["waypoint"] != null) shortcutsProduction.add(ShortcutLocation.fromJson(e));
        if (e["waypoints"] != null) shortcutsProduction.add(ShortcutRoute.fromJson(e));
      }
    }

    // Concat both.
    shortcutsRelease.addAll(shortcutsProduction);

    final jsonStr = jsonEncode(shortcutsRelease.map((e) => e.toJson()).toList());

    // Save shortcuts under region name (Hamburg, Dresden) so that production and release use the same shortcuts.
    storage.setString("priobike.home.shortcuts.${Backend.release.regionName}", jsonStr);
    // Remove the unused shortcuts.
    storage.remove("priobike.home.shortcuts.${Backend.production.name}");
  }

  /// Migrate the search history (Hamburg beta => Hamburg).
  Future<void> migrateSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();

    // Load production and release lists.
    List<String>? searchHistoryListProduction =
        preferences.getStringList("priobike.routing.searchHistory.${Backend.production.name}");
    // Return on no key found.
    if (searchHistoryListProduction == null) return;

    List<String> searchHistoryListRelease =
        preferences.getStringList("priobike.routing.searchHistory.${Backend.release.name}") ?? [];
    // Concat both lists.
    searchHistoryListRelease.addAll(searchHistoryListProduction);
    // Store concatenated list.
    await preferences.setStringList(
        "priobike.routing.searchHistory.${Backend.release.regionName}", searchHistoryListRelease);
    // Remove old list.
    await preferences.remove("priobike.routing.searchHistory.${Backend.production.name}");
  }
}
