import 'package:flutter/material.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  var hasLoaded = false;

  /// The selected backend.
  Backend backend;

  /// The selected positioning.
  Positioning positioning;

  /// The rerouting strategy.
  Rerouting rerouting;

  Future<void> selectBackend(Backend backend) async {
    this.backend = backend;
    await store();
  }

  Future<void> selectPositioning(Positioning positioning) async {
    this.positioning = positioning;
    await store();
  }

  Future<void> selectRerouting(Rerouting rerouting) async {
    this.rerouting = rerouting;
    await store();
  }

  SettingsService({
    this.backend = Backend.production, 
    this.positioning = Positioning.gnss,
    this.rerouting = Rerouting.disabled,
  });

  /// Load the stored settings.
  Future<void> loadSettings() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final backendStr = storage.getString("priobike.settings.backend");
    final positioningStr = storage.getString("priobike.settings.positioning");
    final reroutingStr = storage.getString("priobike.settings.rerouting");

    if (backendStr != null) backend = Backend.values.byName(backendStr);
    if (positioningStr != null) positioning = Positioning.values.byName(positioningStr);
    if (reroutingStr != null) rerouting = Rerouting.values.byName(reroutingStr);

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setString("priobike.settings.backend", backend.name);
    await storage.setString("priobike.settings.positioning", positioning.name);
    await storage.setString("priobike.settings.rerouting", rerouting.name);

    notifyListeners();
  }
}
