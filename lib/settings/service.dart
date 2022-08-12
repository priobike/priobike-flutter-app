import 'package:flutter/material.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  var hasLoaded = false;

  /// The selected backend.
  Backend? backend;

  SettingsService({this.backend});

  /// Load the stored settings.
  Future<void> loadSettings() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final backendStr = storage.getString("priobike.settings.backend");
    
    if (backendStr != null) backend = Backend.values.byName(backendStr);

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    if (backend != null) await storage.setString("priobike.settings.backend", backend!.name);

    notifyListeners();
  }
}
