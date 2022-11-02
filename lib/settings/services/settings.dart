import 'package:flutter/material.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/models/ride.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  var hasLoaded = false;

  /// Whether internal test features should be enabled.
  bool enableInternalFeatures;

  /// Whether beta features should be enabled.
  bool enableBetaFeatures;

  /// The selected backend.
  Backend backend;

  /// The selected positioning mode.
  PositioningMode positioningMode;

  /// The rerouting strategy.
  Rerouting rerouting;

  /// The routing endpoint.
  RoutingEndpoint routingEndpoint;

  /// The signal group labels mode.
  SGLabelsMode sgLabelsMode;

  /// The ride views preference.
  RidePreference? ridePreference;

  /// The colorMode preference
  ColorMode colorMode;

  /// The selected speed mode.
  SpeedMode speedMode;

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

  Future<void> selectPositioningMode(PositioningMode positioningMode) async {
    this.positioningMode = positioningMode;
    await store();
  }

  Future<void> selectRerouting(Rerouting rerouting) async {
    this.rerouting = rerouting;
    await store();
  }

  Future<void> selectRoutingEndpoint(RoutingEndpoint routingEndpoint) async {
    this.routingEndpoint = routingEndpoint;
    await store();
  }

  Future<void> selectSGLabelsMode(SGLabelsMode sgLabelsMode) async {
    this.sgLabelsMode = sgLabelsMode;
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

  Future<void> selectSpeedMode(SpeedMode speedMode) async {
    this.speedMode = speedMode;
    await store();
  }

  Settings({
    this.enableBetaFeatures = false,
    this.enableInternalFeatures = false,
    this.backend = Backend.production,
    this.positioningMode = PositioningMode.gnss,
    this.rerouting = Rerouting.enabled,
    this.routingEndpoint = RoutingEndpoint.graphhopper,
    this.sgLabelsMode = SGLabelsMode.disabled,
    this.ridePreference,
    this.speedMode = SpeedMode.max30kmh,
    this.colorMode = ColorMode.system,
  });

  /// Load the backend from the shared
  /// preferences, for the initial view build.
  static Future<Backend> loadBackendFromSharedPreferences() async {
    final storage = await SharedPreferences.getInstance();
    var backend = Backend.staging;
    final backendStr = storage.getString("priobike.settings.backend");
    if (backendStr != null) backend = Backend.values.byName(backendStr);
    return backend;
  }

  /// Load the stored settings.
  Future<void> loadSettings() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    enableBetaFeatures = storage.getBool("priobike.settings.enableBetaFeatures") ?? false;
    enableInternalFeatures = storage.getBool("priobike.settings.enableInternalFeatures") ?? false;

    final backendStr = storage.getString("priobike.settings.backend");
    final positioningModeStr = storage.getString("priobike.settings.positioningMode");
    final reroutingStr = storage.getString("priobike.settings.rerouting");
    final routingEndpointStr = storage.getString("priobike.settings.routingEndpoint");
    final sgLabelsModeStr = storage.getString("priobike.settings.sgLabelsMode");
    final ridePreferenceStr = storage.getString("priobike.settings.ridePreference");
    final colorModeStr = storage.getString("priobike.settings.colorMode");
    final speedModeStr = storage.getString("priobike.settings.speedMode");

    if (backendStr != null) {
      backend = Backend.values.byName(backendStr);
    }
    if (positioningModeStr != null) {
      positioningMode = PositioningMode.values.byName(positioningModeStr);
    }
    if (reroutingStr != null) {
      rerouting = Rerouting.values.byName(reroutingStr);
    }
    if (routingEndpointStr != null) {
      routingEndpoint = RoutingEndpoint.values.byName(routingEndpointStr);
    }
    if (sgLabelsModeStr != null) {
      sgLabelsMode = SGLabelsMode.values.byName(sgLabelsModeStr);
    }
    if (ridePreferenceStr != null) {
      ridePreference = RidePreference.values.byName(ridePreferenceStr);
    } else {
      ridePreference = null;
    }
    if (colorModeStr != null) {
      colorMode = ColorMode.values.byName(colorModeStr);
    }
    if (speedModeStr != null) {
      speedMode = SpeedMode.values.byName(speedModeStr);
    }

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setBool("priobike.settings.enableBetaFeatures", enableBetaFeatures);
    await storage.setBool("priobike.settings.enableInternalFeatures", enableInternalFeatures);
    await storage.setString("priobike.settings.backend", backend.name);
    await storage.setString("priobike.settings.positioningMode", positioningMode.name);
    await storage.setString("priobike.settings.rerouting", rerouting.name);
    await storage.setString("priobike.settings.routingEndpoint", routingEndpoint.name);
    await storage.setString("priobike.settings.colorMode", colorMode.name);
    await storage.setString("priobike.settings.sgLabelsMode", sgLabelsMode.name);
    await storage.setString("priobike.settings.speedMode", speedMode.name);

    if (ridePreference != null) {
      await storage.setString("priobike.settings.ridePreference", ridePreference!.name);
    } else {
      await storage.remove("priobike.settings.ridePreference");
    }

    notifyListeners();
  }

  /// Convert the settings to a json object.
  Map<String, dynamic> toJson() => {
        "enableBetaFeatures": enableBetaFeatures,
        "enableInternalFeatures": enableInternalFeatures,
        "backend": backend.name,
        "positioningMode": positioningMode.name,
        "rerouting": rerouting.name,
        "routingEndpoint": routingEndpoint.name,
        "sgLabelsMode": sgLabelsMode.name,
        "ridePreference": ridePreference?.name,
        "colorMode": colorMode.name,
        "speedMode": speedMode.name,
      };
}
