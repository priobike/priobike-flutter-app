import 'package:flutter/material.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/models/ride.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  var hasLoaded = false;

  /// Whether internal test features should be enabled.
  bool enableInternalFeatures;

  /// Whether beta features should be enabled.
  bool enableBetaFeatures;

  /// The selected backend.
  Backend backend;

  /// The selected positioning.
  Positioning positioning;

  /// The rerouting strategy.
  Rerouting rerouting;

  /// The ride views preference.
  RidePreference? ridePreference;

  /// The colorMode preference
  ColorMode colorMode;

  Future<void> setEnableInternalFeatures(bool enableInternalFeatures) async {
    this.enableInternalFeatures = enableInternalFeatures;
    await store();
  }

  Future<void> setEnableBetaFeatures(bool enableBetaFeatures) async {
    this.enableBetaFeatures = enableBetaFeatures;
    await store();
  }

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

  Future<void> selectRidePreference(RidePreference ridePreference) async {
    this.ridePreference = ridePreference;
    await store();
  }

  Future<void> selectColorMode(ColorMode colorMode) async {
    this.colorMode = colorMode;
    await store();
  }

  SettingsService({
    this.enableBetaFeatures = false,
    this.enableInternalFeatures = false,
    this.backend = Backend.production, 
    this.positioning = Positioning.gnss,
    this.rerouting = Rerouting.disabled,
    this.ridePreference,
    this.colorMode = ColorMode.system
  });

  /// Load the stored settings.
  Future<void> loadSettings() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    enableBetaFeatures = storage.getBool("priobike.settings.enableBetaFeatures") ?? false;
    enableInternalFeatures = storage.getBool("priobike.settings.enableInternalFeatures") ?? false;

    final backendStr = storage.getString("priobike.settings.backend");
    final positioningStr = storage.getString("priobike.settings.positioning");
    final reroutingStr = storage.getString("priobike.settings.rerouting");
    final ridePreferenceStr = storage.getString("priobike.settings.ridePreference");
    final colorModeStr = storage.getString("priobike.settings.colorMode");

    if (backendStr != null) backend = Backend.values.byName(backendStr);
    if (positioningStr != null) positioning = Positioning.values.byName(positioningStr);
    if (reroutingStr != null) rerouting = Rerouting.values.byName(reroutingStr);
    if (ridePreferenceStr != null) {
      ridePreference = RidePreference.values.byName(ridePreferenceStr);
    } else {
      ridePreference = null;
    }
    if (colorModeStr != null) colorMode = ColorMode.values.byName(colorModeStr);

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setBool("priobike.settings.enableBetaFeatures", enableBetaFeatures);
    await storage.setBool("priobike.settings.enableInternalFeatures", enableInternalFeatures);
    await storage.setString("priobike.settings.backend", backend.name);
    await storage.setString("priobike.settings.positioning", positioning.name);
    await storage.setString("priobike.settings.rerouting", rerouting.name);
    await storage.setString("priobike.settings.colorMode", colorMode.name);

    if (ridePreference != null) {
      await storage.setString("priobike.settings.ridePreference", ridePreference!.name);
    } else {
      await storage.remove("priobike.settings.ridePreference");
    }

    notifyListeners();
  }
}
