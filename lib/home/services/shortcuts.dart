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
import 'package:shared_preferences/shared_preferences.dart';

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

    // Check if waypoint contains "Standort" as address and change it to geolocation
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

    final newShortcut = ShortcutRoute(name: name, waypoints: routing.selectedWaypoints!.whereType<Waypoint>().toList());
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = <Shortcut>[newShortcut] + shortcuts!;
    await storeShortcuts();

    notifyListeners();
  }

  /// Save a new location shortcut.
  Future<void> saveNewShortcutLocation(String name, Waypoint waypoint) async {
    final newShortcut = ShortcutLocation(name: name, waypoint: waypoint);
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = <Shortcut>[newShortcut] + shortcuts!;
    await storeShortcuts();

    notifyListeners();
  }

  /// Update a shortcuts name.
  Future<void> updateShortcutName(String name, int idx) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    if (shortcuts!.length <= idx) return;

    Shortcut foundShortcut = shortcuts![idx];

    // Check type.
    if (foundShortcut.runtimeType == ShortcutRoute) {
      // update name.
      shortcuts![idx] = ShortcutRoute(name: name, waypoints: (foundShortcut as ShortcutRoute).waypoints);
    } else if (foundShortcut.runtimeType == ShortcutLocation) {
      // update name.
      shortcuts![idx] = ShortcutLocation(name: name, waypoint: (foundShortcut as ShortcutLocation).waypoint);
    } else {
      final hint = "Error unknown type ${foundShortcut.runtimeType} in updateShortcutName.";
      log.e(hint);
    }

    await storeShortcuts();
    notifyListeners();
  }

  /// Save a new shortcut (Shortcut object given).
  Future<void> saveNewShortcutObject(Shortcut shortcut) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = [shortcut] + shortcuts!;
    await storeShortcuts();

    if (shortcut.runtimeType == ShortcutRoute) {
      ToastMessage.showSuccess("Route gespeichert!");
    } else if (shortcut.runtimeType == ShortcutLocation) {
      ToastMessage.showSuccess("Ort gespeichert!");
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

    final backend = getIt<Settings>().backend;

    final jsonStr = jsonEncode(shortcuts!.map((e) => e.toJson()).toList());
    if (backend == Backend.production) {
      storage.setString("priobike.home.shortcuts.production", jsonStr);
    } else if (backend == Backend.staging) {
      storage.setString("priobike.home.shortcuts.staging", jsonStr);
    }
  }

  /// Load the custom shortcuts.
  Future<void> loadShortcuts() async {
    if (shortcuts != null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;
    String? jsonStr;
    if (backend == Backend.production) {
      jsonStr = storage.getString("priobike.home.shortcuts.production");
    } else if (backend == Backend.staging) {
      jsonStr = storage.getString("priobike.home.shortcuts.staging");
    }

    if (jsonStr == null) {
      shortcuts = backend.defaultShortcuts;
    } else {
      shortcuts = (jsonDecode(jsonStr) as List).map((e) {
        if (e["type"] != null) {
          switch (e["type"]) {
            case "ShortcutLocation":
              return ShortcutLocation.fromJson(e);
            case "ShortcutRoute":
              return ShortcutRoute.fromJson(e);
          }
        }
        // Only for backwards compatibility.
        return e["waypoint"] != null ? ShortcutLocation.fromJson(e) : ShortcutRoute.fromJson(e);
      }).toList();
    }

    notifyListeners();
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
