import 'package:flutter/material.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  var hasLoaded = false;

  /// The selected backend.
  Backend backend;

  /// The selected positioning.
  Positioning positioning;

  Future<void> selectBackend(Backend backend) async {
    this.backend = backend;
    await store();
  }

  Future<void> selectPositioning(Positioning positioning) async {
    this.positioning = positioning;
    await store();
  }

  SettingsService({
    this.backend = Backend.production, 
    this.positioning = Positioning.gnss
  });

  /// Load the stored settings.
  Future<void> loadSettings() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final backendStr = storage.getString("priobike.settings.backend");
    final positioningStr = storage.getString("priobike.settings.positioning");

    if (backendStr != null) backend = Backend.values.byName(backendStr);
    if (positioningStr != null) positioning = Positioning.values.byName(positioningStr);

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setString("priobike.settings.backend", backend.name);
    await storage.setString("priobike.settings.positioning", positioning.name);

    notifyListeners();
  }
}
