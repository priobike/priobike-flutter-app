import 'dart:convert';

import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
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

  /// Migrate the search history (staging => Dresden).
  Future<void> migrateSearchHistoryStaging() async {
    final preferences = await SharedPreferences.getInstance();

    // Load production and release lists.
    List<String>? searchHistoryListStaging =
        preferences.getStringList("priobike.routing.searchHistory.${Backend.staging.name}");
    // Return on no key found.
    if (searchHistoryListStaging == null) return;

    List<String> searchHistoryListStagingNew =
        preferences.getStringList("priobike.routing.searchHistory.${Backend.staging.regionName}") ?? [];
    // Concat both lists.
    searchHistoryListStagingNew.addAll(searchHistoryListStaging);
    // Store concatenated list.
    await preferences.setStringList(
        "priobike.routing.searchHistory.${Backend.staging.regionName}", searchHistoryListStagingNew);
    // Remove old list.
    await preferences.remove("priobike.routing.searchHistory.${Backend.staging.name}");
  }
}
