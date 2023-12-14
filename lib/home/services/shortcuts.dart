import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/http.dart';
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

    final newShortcut = ShortcutRoute(
      id: UniqueKey().toString(),
      name: name,
      waypoints: routing.selectedWaypoints!.whereType<Waypoint>().toList(),
    );
    if (shortcuts == null) await loadShortcuts();
    if (shortcuts == null) return;
    shortcuts = <Shortcut>[newShortcut] + shortcuts!;
    await storeShortcuts();

    notifyListeners();
  }

  /// Save a new location shortcut.
  Future<void> saveNewShortcutLocation(String name, Waypoint waypoint) async {
    final newShortcut = ShortcutLocation(id: UniqueKey().toString(), name: name, waypoint: waypoint);
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
    storage.setString("priobike.home.shortcuts.${backend.regionName}", jsonStr);
  }

  /// Load the custom shortcuts.
  Future<void> loadShortcuts() async {
    if (shortcuts != null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;
    final jsonStr = storage.getString("priobike.home.shortcuts.${backend.regionName}");

    if (jsonStr == null) {
      shortcuts = backend.defaultShortcuts;
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

  Future<Shortcut?> getShortcutFromShortLink(String shortLink) async {
    List<String> subUrls = shortLink.split('/');
    if (subUrls.length == 6 && subUrls[4] == 'link') {
      // TODO staging vs production
      final parseShortLinkEndpoint =
          Uri.parse('https://priobike.vkw.tu-dresden.de/staging/link/rest/v3/short-urls/${subUrls[5]}');
      final longLinkResponse =
          await Http.get(parseShortLinkEndpoint, headers: {'X-Api-Key': '8a1e47f1-36ac-44e8-b648-aae112f97208'});
      final String longUrl = json.decode(longLinkResponse.body)['longUrl'];
      subUrls = longUrl.split('/');
      final shortcutBase64 = subUrls.last;
      final shortcutBytes = base64.decode(shortcutBase64);
      final shortcutUTF8 = utf8.decode(shortcutBytes);
      final Map<String, dynamic> shortcutJson = json.decode(shortcutUTF8);
      shortcutJson['id'] = UniqueKey().toString();
      Shortcut shortcut;
      if (shortcutJson['type'] == "ShortcutLocation") {
        shortcut = ShortcutLocation.fromJson(shortcutJson);
      } else {
        shortcut = ShortcutRoute.fromJson(shortcutJson);
      }
      return shortcut;
    }
    return null;
  }

  void createShortcutFromShortLink(String shortLink) {
    getShortcutFromShortLink(shortLink).then((shortcut) {
      if (shortcut != null) getIt<Shortcuts>().saveNewShortcutObject(shortcut);
    });
  }
}
