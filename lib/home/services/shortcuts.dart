import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/v4.dart';

class Shortcuts with ChangeNotifier {
  /// All available shortcuts.
  List<Shortcut>? shortcuts;

  Shortcuts();

  /// Reset the shortcuts service.
  Future<void> reset() async {
    shortcuts = null;
  }

  /// Save a new route shortcut.
  Future<void> saveNewShortcutRoute(String name) async {
    final routing = getIt<Routing>();
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return;

    // Check if waypoint contains "Standort" as address and change it to geolocation.
    for (Waypoint waypoint in routing.selectedWaypoints!) {
      if (waypoint.address == null) {
        final geocoding = getIt<Geocoding>();
        final String? address = await geocoding.reverseGeocodeLatLng(waypoint.lat, waypoint.lon);
        // address can (but usually should not) be null
        if (address == null) {
          log.i("Address for waypoint with reverseGeocode not found");
        }
        waypoint.address = address;
      }
    }

    final newShortcut = ShortcutRoute(
      id: const UuidV4().generate(),
      name: name,
      waypoints: routing.selectedWaypoints!.whereType<Waypoint>().toList(),
      routeTimeText: routing.selectedRoute?.timeText,
      routeLengthText: routing.selectedRoute?.lengthText,
    );
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = <Shortcut>[newShortcut] + shortcuts!;
    await storeShortcuts();

    // Complete the tutorial.
    getIt<Tutorial>().complete("priobike.tutorial.select-shortcut");

    notifyListeners();
  }

  /// Save a new location shortcut.
  Future<void> saveNewShortcutLocation(String name, Waypoint waypoint) async {
    final newShortcut = ShortcutLocation(id: const UuidV4().generate(), name: name, waypoint: waypoint);
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = <Shortcut>[newShortcut] + shortcuts!;
    await storeShortcuts();

    // Complete the tutorial.
    getIt<Tutorial>().complete("priobike.tutorial.select-shortcut");

    notifyListeners();
  }

  /// Update a shortcuts name.
  Future<void> updateShortcutName(String name, int idx) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    if (shortcuts!.length <= idx) return;

    Shortcut foundShortcut = shortcuts![idx];
    foundShortcut.name = name;
    shortcuts![idx] = foundShortcut;

    await storeShortcuts();
    notifyListeners();
  }

  /// Save a new shortcut (Shortcut object given).
  Future<void> saveNewShortcutObject(Shortcut shortcut) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = [shortcut] + shortcuts!;
    await storeShortcuts();

    // Complete the tutorial.
    getIt<Tutorial>().complete("priobike.tutorial.select-shortcut");

    if (shortcut.runtimeType == ShortcutRoute) {
      getIt<Toast>().showSuccess("Route gespeichert!");
    } else if (shortcut.runtimeType == ShortcutLocation) {
      getIt<Toast>().showSuccess("Ort gespeichert!");
    } else {
      final hint = "Error unknown type ${shortcut.runtimeType} in saveNewShortcutObject.";
      log.e(hint);
    }
    notifyListeners();
  }

  /// Update the shortcuts.
  Future<void> updateShortcuts(List<Shortcut> newShortcuts) async {
    shortcuts = newShortcuts;
    await storeShortcuts();
    notifyListeners();
  }

  /// Store all shortcuts.
  Future<void> storeShortcuts() async {
    if (shortcuts == null) return;
    final storage = await SharedPreferences.getInstance();

    final city = getIt<Settings>().city;
    final jsonStr = jsonEncode(shortcuts!.map((e) => e.toJson()).toList());
    storage.setString("priobike.home.shortcuts.${city.nameDE}", jsonStr);

    // Activates the tutorial if more then 3 (+2 default shortcuts) shortcuts were stored.
    if (shortcuts!.length >= 5) {
      getIt<Tutorial>().activate("priobike.tutorial.share-shortcut");
    }
  }

  /// Load the custom shortcuts.
  Future<void> loadShortcuts() async {
    if (shortcuts != null) return;
    final storage = await SharedPreferences.getInstance();

    final city = getIt<Settings>().city;
    final jsonStr = storage.getString("priobike.home.shortcuts.${city.nameDE}");

    if (jsonStr == null) {
      shortcuts = city.defaultShortcuts;
      await storeShortcuts();
    } else {
      // Init shortcuts.
      shortcuts = getShortcutsFromJson(jsonStr);
    }
    notifyListeners();
  }

  /// Creates a list of shortcut objects from a json string.
  List<Shortcut> getShortcutsFromJson(String jsonStr) {
    List<Shortcut> shortcuts = [];
    // Loop through all json Shortcuts and add correct shortcuts to shortcuts.
    for (final e in jsonDecode(jsonStr) as List) {
      if (e["type"] != null) {
        switch (e["type"]) {
          case "ShortcutLocation":
            shortcuts.add(ShortcutLocation.fromJson(e));
            break;
          case "ShortcutRoute":
            shortcuts.add(ShortcutRoute.fromJson(e));
            break;
          default:
            final hint = "Error unknown type ${e["type"]} in loadShortcuts.";
            log.e(hint);
        }
      } else {
        // Only for backwards compatibility.
        if (e["waypoint"] != null) shortcuts.add(ShortcutLocation.fromJson(e));
        if (e["waypoints"] != null) shortcuts.add(ShortcutRoute.fromJson(e));
      }
    }
    return shortcuts;
  }

  /// Delete a shortcut.
  Future<void> deleteShortcut(Shortcut shortcutItem) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    if (!shortcuts!.contains(shortcutItem)) {
      log.e("Trying to delete non-existing shortcut");
      return;
    }
    shortcuts!.remove(shortcutItem);
    await storeShortcuts();
    notifyListeners();
  }
}
