import 'package:flutter/material.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/models/sg_selector.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:priobike/logging/logger.dart';

final log = Logger("settings.dart");

class Settings with ChangeNotifier {
  var hasLoaded = false;

  /// Whether internal test features should be enabled.
  bool enableInternalFeatures;

  /// Whether beta features should be enabled.
  bool enableBetaFeatures;

  /// Whether the performance overlay should be enabled.
  bool enablePerformanceOverlay;

  /// Whether the user has seen the warning at the start of the ride.
  bool didViewWarning;

  /// The selected backend.
  Backend backend;

  /// The selected prediction mode.
  PredictionMode predictionMode;

  /// The selected positioning mode.
  PositioningMode positioningMode;

  /// The rerouting strategy.
  Rerouting rerouting;

  /// The routing endpoint.
  RoutingEndpoint routingEndpoint;

  /// The signal group labels mode.
  SGLabelsMode sgLabelsMode;

  /// The colorMode preference
  ColorMode colorMode;

  /// The selected speed mode.
  SpeedMode speedMode;

  /// The selected datastream mode.
  DatastreamMode datastreamMode;

  /// The counter of connection error in a row.
  int connectionErrorCounter;

  /// The selected signal groups selector.
  SGSelector sgSelector;

  Future<void> setEnableInternalFeatures(bool enableInternalFeatures) async {
    this.enableInternalFeatures = enableInternalFeatures;
    await store();
  }

  Future<void> setEnableBetaFeatures(bool enableBetaFeatures) async {
    this.enableBetaFeatures = enableBetaFeatures;
    await store();
  }

  Future<void> setEnablePerformanceOverlay(bool enablePerformanceOverlay) async {
    this.enablePerformanceOverlay = enablePerformanceOverlay;
    await store();
  }

  Future<void> setDidViewWarning(bool didViewWarning) async {
    this.didViewWarning = didViewWarning;
    await store();
  }

  Future<void> selectBackend(Backend backend) async {
    this.backend = backend;
    await store();
  }

  Future<void> selectPredictionMode(PredictionMode predictionMode) async {
    this.predictionMode = predictionMode;
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

  Future<void> selectColorMode(ColorMode colorMode) async {
    this.colorMode = colorMode;
    await store();
  }

  Future<void> selectSpeedMode(SpeedMode speedMode) async {
    this.speedMode = speedMode;
    await store();
  }

  Future<void> selectDatastreamMode(DatastreamMode datastreamMode) async {
    this.datastreamMode = datastreamMode;
    await store();
  }

  Future<void> selectSGSelector(SGSelector sgSelector) async {
    this.sgSelector = sgSelector;
    await store();
  }

  Future<void> incrementConnectionErrorCounter() async {
    connectionErrorCounter += 1;
    await store();
  }

  Future<void> resetConnectionErrorCounter() async {
    connectionErrorCounter = 0;
    await store();
  }

  Future<void> deleteWarning() async {
    final storage = await SharedPreferences.getInstance();
    await storage.setBool("priobike.routing.warning", false);
    didViewWarning = false;
    notifyListeners();
  }

  Settings({
    this.enableBetaFeatures = false,
    this.enableInternalFeatures = false,
    this.enablePerformanceOverlay = false,
    this.didViewWarning = false,
    this.backend = Backend.production,
    this.predictionMode = PredictionMode.usePredictionService,
    this.positioningMode = PositioningMode.gnss,
    this.rerouting = Rerouting.enabled,
    this.routingEndpoint = RoutingEndpoint.graphhopper,
    this.sgLabelsMode = SGLabelsMode.disabled,
    this.speedMode = SpeedMode.max30kmh,
    this.colorMode = ColorMode.system,
    this.datastreamMode = DatastreamMode.disabled,
    this.connectionErrorCounter = 0,
    this.sgSelector = SGSelector.algorithmic,
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

  /// Load the beta settings from the shared preferences.
  Future<void> loadBetaSettings(SharedPreferences storage) async {
    enableBetaFeatures = (storage.getBool("priobike.settings.enableBetaFeatures") ?? false);

    final reroutingStr = storage.getString("priobike.settings.rerouting");
    final routingEndpointStr = storage.getString("priobike.settings.routingEndpoint");

    try {
      rerouting = Rerouting.values.byName(reroutingStr!);
    } catch (e) {
      log.i("Invalid reroutingStr: " +
          reroutingStr.toString() +
          ". Setting rerouting to default value " +
          Rerouting.enabled.toString() +
          ".");
      rerouting = Rerouting.enabled;
    }
    try {
      routingEndpoint = RoutingEndpoint.values.byName(routingEndpointStr!);
    } catch (e) {
      log.i("Invalid routingEndpointStr: " +
          routingEndpointStr.toString() +
          ". Setting routingEndpoint to default value " +
          RoutingEndpoint.graphhopper.toString() +
          ".");
      routingEndpoint = RoutingEndpoint.graphhopper;
    }
  }

  /// Load the internal settings from the shared preferences.
  Future<void> loadInternalSettings(SharedPreferences storage) async {
    enableInternalFeatures = (storage.getBool("priobike.settings.enableInternalFeatures") ?? false);
    enablePerformanceOverlay = (storage.getBool("priobike.settings.enablePerformanceOverlay") ?? false);
    didViewWarning = (storage.getBool("priobike.routing.warning") ?? false);

    final backendStr = storage.getString("priobike.settings.backend");
    final predictionModeStr = storage.getString("priobike.settings.predictionMode");
    final positioningModeStr = storage.getString("priobike.settings.positioningMode");
    final sgLabelsModeStr = storage.getString("priobike.settings.sgLabelsMode");
    final datastreamModeStr = storage.getString("priobike.settings.datastreamMode");

    try {
      backend = Backend.values.byName(backendStr!);
    } catch (e) {
      log.i("Invalid backendStr: " +
          backendStr.toString() +
          ". Setting backend to default value " +
          Backend.production.toString() +
          ".");
      backend = Backend.production;
    }
    try {
      predictionMode = PredictionMode.values.byName(predictionModeStr!);
    } catch (e) {
      log.i("Invalid predictionModeStr: " +
          predictionModeStr.toString() +
          ". Setting predictionMode to default value " +
          PredictionMode.usePredictionService.toString() +
          ".");
      predictionMode = PredictionMode.usePredictionService;
    }
    try {
      positioningMode = PositioningMode.values.byName(positioningModeStr!);
    } catch (e) {
      log.i("Invalid positioningModeStr: " +
          positioningModeStr.toString() +
          ". Setting positioningMode to default value " +
          PositioningMode.gnss.toString() +
          ".");
      positioningMode = PositioningMode.gnss;
    }
    try {
      sgLabelsMode = SGLabelsMode.values.byName(sgLabelsModeStr!);
    } catch (e) {
      log.i("Invalid sgLabelsModeStr: " +
          sgLabelsModeStr.toString() +
          ". Setting sgLabelsMode to default value " +
          SGLabelsMode.disabled.toString() +
          ".");
      sgLabelsMode = SGLabelsMode.disabled;
    }
    try {
      datastreamMode = DatastreamMode.values.byName(datastreamModeStr!);
    } catch (e) {
      log.i("Invalid datastreamModeStr: " +
          datastreamModeStr.toString() +
          ". Setting datastreamMode to default value " +
          DatastreamMode.disabled.toString() +
          ".");
      datastreamMode = DatastreamMode.disabled;
    }
  }

  /// Load the stored settings.
  Future<void> loadSettings(bool canEnableInternalFeatures, bool canEnableBetaFeatures) async {
    if (hasLoaded) return;

    final storage = await SharedPreferences.getInstance();

    // All internal settings.
    if (canEnableInternalFeatures) await loadInternalSettings(storage);

    // All beta settings.
    if (canEnableBetaFeatures) await loadBetaSettings(storage);

    // All remaining settings.
    final colorModeStr = storage.getString("priobike.settings.colorMode");
    final speedModeStr = storage.getString("priobike.settings.speedMode");
    final connectionErrorCounterValue = storage.getInt("priobike.settings.connectionErrorCounter");

    try {
      colorMode = ColorMode.values.byName(colorModeStr!);
    } catch (e) {
      log.i("Invalid colorModeStr: " +
          colorModeStr.toString() +
          ". Setting colorMode to default value " +
          ColorMode.system.toString() +
          ".");
      colorMode = ColorMode.system;
    }
    try {
      speedMode = SpeedMode.values.byName(speedModeStr!);
    } catch (e) {
      log.i("Invalid speedModeStr: " +
          speedModeStr.toString() +
          ". Setting speedMode to default value " +
          SpeedMode.max30kmh.toString() +
          ".");
      speedMode = SpeedMode.max30kmh;
    }
    if (connectionErrorCounterValue != null) {
      connectionErrorCounter = connectionErrorCounterValue;
    }

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setBool("priobike.settings.enableBetaFeatures", enableBetaFeatures);
    await storage.setBool("priobike.settings.enableInternalFeatures", enableInternalFeatures);
    await storage.setBool("priobike.settings.enablePerformanceOverlay", enablePerformanceOverlay);
    await storage.setBool("priobike.routing.warning", didViewWarning);
    await storage.setString("priobike.settings.backend", backend.name);
    await storage.setString("priobike.settings.predictionMode", predictionMode.name);
    await storage.setString("priobike.settings.positioningMode", positioningMode.name);
    await storage.setString("priobike.settings.rerouting", rerouting.name);
    await storage.setString("priobike.settings.routingEndpoint", routingEndpoint.name);
    await storage.setString("priobike.settings.colorMode", colorMode.name);
    await storage.setString("priobike.settings.sgLabelsMode", sgLabelsMode.name);
    await storage.setString("priobike.settings.speedMode", speedMode.name);
    await storage.setString("priobike.settings.datastreamMode", datastreamMode.name);
    await storage.setInt("priobike.settings.connectionErrorCounter", connectionErrorCounter);
    await storage.setString("priobike.settings.sgSelector", sgSelector.name);

    notifyListeners();
  }

  /// Convert the settings to a json object.
  Map<String, dynamic> toJson() => {
        "enableBetaFeatures": enableBetaFeatures,
        "enableInternalFeatures": enableInternalFeatures,
        "enablePerformanceOverlay": enablePerformanceOverlay,
        "didViewWarning": didViewWarning,
        "backend": backend.name,
        "predictionMode": predictionMode.name,
        "positioningMode": positioningMode.name,
        "rerouting": rerouting.name,
        "routingEndpoint": routingEndpoint.name,
        "sgLabelsMode": sgLabelsMode.name,
        "colorMode": colorMode.name,
        "speedMode": speedMode.name,
        "datastreamMode": datastreamMode.name,
        "connectionErrorCounter": connectionErrorCounter,
        "sgSelector": sgSelector.name
      };
}
