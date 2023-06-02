import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
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

  /// Save a new shortcut.
  Future<void> saveNewShortcut(String name) async {
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

    final newShortcut = Shortcut(name: name, waypoints: routing.selectedWaypoints!.whereType<Waypoint>().toList());
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = [newShortcut] + shortcuts!;
    await storeShortcuts();

    notifyListeners();
  }

  /// Update a shortcuts name.
  Future<void> updateShortcutName(String name, int idx) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    if (shortcuts!.length <= idx) return;

    // update name.
    shortcuts![idx] = Shortcut(name: name, waypoints: shortcuts![idx].waypoints);

    await storeShortcuts();
    notifyListeners();
  }

  /// Save a new shortcut (Shortcut object given).
  Future<void> saveNewShortcutObject(Shortcut shortcut) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = [shortcut] + shortcuts!;
    await storeShortcuts();

    ToastMessage.showSuccess("Route gespeichert!");
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
      shortcuts = (jsonDecode(jsonStr) as List).map((e) => Shortcut.fromJson(e)).toList();
    }

    notifyListeners();
  }

  /// Delete a shortcut.
  Future<void> deleteShortcut(Shortcut shortcutItem) async {
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    if (!shortcuts!.contains(shortcutItem)) log.e("Trying to delete non-existing shortcut");
    shortcuts!.remove(shortcutItem);
    await storeShortcuts();
    notifyListeners();
  }
}
