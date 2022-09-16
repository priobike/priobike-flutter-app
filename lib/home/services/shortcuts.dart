import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
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
  Future<void> saveNewShortcut(String name, BuildContext context) async {
    final routing = Provider.of<Routing>(context, listen: false);
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return;
    final newShortcut = Shortcut(name: name, waypoints: routing.selectedWaypoints!);
    if (shortcuts == null) await loadShortcuts(context);
    if (shortcuts == null) return;
    shortcuts = [newShortcut] + shortcuts!;
    await storeShortcuts(context);
    notifyListeners();
  }

  /// Update the shortcuts.
  Future<void> updateShortcuts(List<Shortcut> newShortcuts, BuildContext context) async {
    shortcuts = newShortcuts;
    await storeShortcuts(context);
    notifyListeners();
  }

  /// Store all shortcuts.
  Future<void> storeShortcuts(BuildContext context) async {
    if (shortcuts == null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;

    final jsonStr = jsonEncode(shortcuts!.map((e) => e.toJson()).toList());
    if (backend == Backend.production) {
      storage.setString("priobike.home.shortcuts.production", jsonStr);
    } else if (backend == Backend.staging) {
      storage.setString("priobike.home.shortcuts.staging", jsonStr);
    }
  }

  /// Load the custom shortcuts.
  Future<void> loadShortcuts(BuildContext context) async {
    if (shortcuts != null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;
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
}
