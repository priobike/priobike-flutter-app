import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/fcm.dart';
import 'package:priobike/home/services/load.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart' hide Simulator;
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/models/sg_selector.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/models/tracking.dart';
import 'package:priobike/simulator/services/simulator.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/weather/service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  var hasLoaded = false;

  static final log = Logger("Settings");

  /// The scaling factor of the map for the battery save mode.
  static const double scalingFactor = 2.5;

  /// Whether the logs should be persisted.
  bool enableLogPersistence;

  /// Whether the traffic light search bar should be enabled.
  bool enableTrafficLightSearchBar;

  /// Whether the performance overlay should be enabled.
  bool enablePerformanceOverlay;

  /// Whether the user has seen the warning at the start of the ride.
  bool didViewWarning;

  /// The selected backend.
  Backend backend;

  /// The selected positioning mode.
  PositioningMode positioningMode;

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

  /// The selected signal group selector mode.
  SGSelector sgSelector;

  /// The selected tracking submission policy.
  TrackingSubmissionPolicy trackingSubmissionPolicy;

  /// The counter of connection error in a row.
  int connectionErrorCounter;

  /// The counter of use of the app.
  int useCounter;

  /// If the save battery mode is enabled.
  bool saveBatteryModeEnabled;

  /// If the save battery mode is enabled.
  bool dismissedSurvey;

  /// If the audio instructions are enabled.
  bool audioInstructionsEnabled;

  /// Whether the user has seen the user transfer dialog.
  bool didViewUserTransfer;

  /// If the user is transferring.
  bool isUserTransferring = false;

  /// If the user had migrate background images.
  bool didMigrateBackgroundImages = false;

  /// Enable simulator mode for app.
  bool enableSimulatorMode;

  /// If the filter for the free ride view is enabled.
  bool isFreeRideFilterEnabled;

  /// If we want to show the speed with increased precision in the speedometer.
  bool isIncreasedSpeedPrecisionInSpeedometerEnabled = false;

  static const enableLogPersistenceKey = "priobike.settings.enableLogPersistence";
  static const defaultEnableLogPersistence = false;

  Future<bool> setEnableLogPersistence(bool enableLogPersistence, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.enableLogPersistence;
    this.enableLogPersistence = enableLogPersistence;
    final bool success = await storage.setBool(enableLogPersistenceKey, enableLogPersistence);
    if (!success) {
      log.e("Failed to set enableLogPersistence to $enableLogPersistence");
      this.enableLogPersistence = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const enableTrafficLightSearchBarKey = "priobike.settings.enableTrafficLightSearchBar";
  static const defaultEnableTrafficLightSearchBar = false;

  Future<bool> setEnableTrafficLightSearchBar(bool enableTrafficLightSearchBar, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.enableTrafficLightSearchBar;
    this.enableTrafficLightSearchBar = enableTrafficLightSearchBar;
    final bool success = await storage.setBool(enableTrafficLightSearchBarKey, enableTrafficLightSearchBar);
    if (!success) {
      log.e("Failed to set enableTrafficLightSearchBar to $enableTrafficLightSearchBar");
      this.enableTrafficLightSearchBar = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const enablePerformanceOverlayKey = "priobike.settings.enablePerformanceOverlay";
  static const defaultEnablePerformanceOverlay = false;

  Future<bool> setEnablePerformanceOverlay(bool enablePerformanceOverlay, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.enablePerformanceOverlay;
    this.enablePerformanceOverlay = enablePerformanceOverlay;
    final bool success = await storage.setBool(enablePerformanceOverlayKey, enablePerformanceOverlay);
    if (!success) {
      log.e("Failed to set enablePerformanceOverlay to $enablePerformanceOverlay");
      this.enablePerformanceOverlay = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const didViewWarningKey = "priobike.routing.warning";
  static const defaultDidViewWarning = false;

  Future<bool> setDidViewWarning(bool didViewWarning, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.didViewWarning;
    this.didViewWarning = didViewWarning;
    final bool success = await storage.setBool(didViewWarningKey, didViewWarning);
    if (!success) {
      log.e("Failed to set didViewWarning to $didViewWarning");
      this.didViewWarning = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const backendKey = "priobike.settings.backend";

  Future<bool> setBackend(Backend backend, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.backend;
    this.backend = backend;
    final bool success = await storage.setString(backendKey, backend.name);
    if (!success) {
      log.e("Failed to set backend to $backend");
      this.backend = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const positioningModeKey = "priobike.settings.positioningMode";
  static const defaultPositioningMode = PositioningMode.gnss;

  Future<bool> setPositioningMode(PositioningMode positioningMode, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.positioningMode;
    this.positioningMode = positioningMode;
    final bool success = await storage.setString(positioningModeKey, positioningMode.name);
    if (!success) {
      log.e("Failed to set positioningMode to $positioningMode");
      this.positioningMode = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const routingEndpointKey = "priobike.settings.routingEndpoint";
  static const defaultRoutingEndpoint = RoutingEndpoint.graphhopperDRN;

  Future<bool> setRoutingEndpoint(RoutingEndpoint routingEndpoint, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.routingEndpoint;
    this.routingEndpoint = routingEndpoint;
    final bool success = await storage.setString(routingEndpointKey, routingEndpoint.name);
    if (!success) {
      log.e("Failed to set routingEndpoint to $routingEndpoint");
      this.routingEndpoint = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const sgLabelsModeKey = "priobike.settings.sgLabelsMode";
  static const defaultSGLabelsMode = SGLabelsMode.disabled;

  Future<bool> setSGLabelsMode(SGLabelsMode sgLabelsMode, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.sgLabelsMode;
    this.sgLabelsMode = sgLabelsMode;
    final bool success = await storage.setString(sgLabelsModeKey, sgLabelsMode.name);
    if (!success) {
      log.e("Failed to set sgLabelsMode to $sgLabelsMode");
      this.sgLabelsMode = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const colorModeKey = "priobike.settings.colorMode";
  static const defaultColorMode = ColorMode.system;

  Future<bool> setColorMode(ColorMode colorMode, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.colorMode;
    this.colorMode = colorMode;
    final bool success = await storage.setString(colorModeKey, colorMode.name);
    if (!success) {
      log.e("Failed to set colorMode to $colorMode");
      this.colorMode = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const speedModeKey = "priobike.settings.speedMode";
  static const defaultSpeedMode = SpeedMode.max30kmh;

  Future<bool> setSpeedMode(SpeedMode speedMode, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.speedMode;
    this.speedMode = speedMode;
    final bool success = await storage.setString(speedModeKey, speedMode.name);
    if (!success) {
      log.e("Failed to set speedMode to $speedMode");
      this.speedMode = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const datastreamModeKey = "priobike.settings.datastreamMode";
  static const defaultDatastreamMode = DatastreamMode.disabled;

  Future<bool> setDatastreamMode(DatastreamMode datastreamMode, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.datastreamMode;
    this.datastreamMode = datastreamMode;
    final bool success = await storage.setString(datastreamModeKey, datastreamMode.name);
    if (!success) {
      log.e("Failed to set datastreamMode to $datastreamMode");
      this.datastreamMode = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const connectionErrorCounterKey = "priobike.settings.connectionErrorCounter";
  static const defaultConnectionErrorCounter = 0;

  Future<bool> incrementConnectionErrorCounter([SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = connectionErrorCounter;
    connectionErrorCounter += 1;
    final bool success = await storage.setInt(connectionErrorCounterKey, connectionErrorCounter);
    if (!success) {
      log.e("Failed to increment connectionErrorCounter to $connectionErrorCounter");
      connectionErrorCounter = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const useCounterKey = "priobike.settings.useCounter";
  static const defaultUseCounter = 0;

  Future<bool> incrementUseCounter([SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = useCounter;
    useCounter += 1;
    final bool success = await storage.setInt(useCounterKey, useCounter);
    if (!success) {
      log.e("Failed to increment useCounter to $useCounter");
      useCounter = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  Future<bool> resetConnectionErrorCounter([SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = connectionErrorCounter;
    connectionErrorCounter = defaultConnectionErrorCounter;
    final bool success = await storage.setInt(connectionErrorCounterKey, connectionErrorCounter);
    if (!success) {
      log.e("Failed to reset connectionErrorCounter to $connectionErrorCounter");
      connectionErrorCounter = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const sgSelectorKey = "priobike.settings.sgSelector";
  static const defaultSGSelector = SGSelector.ml;

  Future<bool> setSGSelector(SGSelector sgSelector, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.sgSelector;
    this.sgSelector = sgSelector;
    final bool success = await storage.setString(sgSelectorKey, sgSelector.name);
    if (!success) {
      log.e("Failed to set sgSelector to $sgSelector");
      this.sgSelector = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const dismissedSurveyKey = "priobike.settings.dissmissedSurvey";
  static const defaultDismissedSurvey = false;

  Future<bool> setDismissedSurvey(bool dismissedSurvey, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.dismissedSurvey;
    this.dismissedSurvey = dismissedSurvey;
    final bool success = await storage.setBool(dismissedSurveyKey, dismissedSurvey);
    if (!success) {
      log.e("Failed to set sgSelector to $sgSelector");
      this.dismissedSurvey = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const trackingSubmissionPolicyKey = "priobike.settings.trackingSubmissionPolicy";
  static const defaultTrackingSubmissionPolicy = TrackingSubmissionPolicy.always;

  Future<bool> setTrackingSubmissionPolicy(
    TrackingSubmissionPolicy trackingSubmissionPolicy, [
    SharedPreferences? storage,
  ]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.trackingSubmissionPolicy;
    this.trackingSubmissionPolicy = trackingSubmissionPolicy;
    final bool success = await storage.setString(trackingSubmissionPolicyKey, trackingSubmissionPolicy.name);
    if (!success) {
      log.e("Failed to set trackingSubmissionPolicy to $trackingSubmissionPolicy");
      this.trackingSubmissionPolicy = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const saveBatteryModeEnabledKey = "priobike.settings.saveBatteryModeEnabled";
  static const defaultSaveBatteryModeEnabled = true;

  Future<bool> setSaveBatteryModeEnabled(bool saveBatteryModeEnabled, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.saveBatteryModeEnabled;
    this.saveBatteryModeEnabled = saveBatteryModeEnabled;
    final bool success = await storage.setBool(saveBatteryModeEnabledKey, saveBatteryModeEnabled);
    if (!success) {
      log.e("Failed to set saveBatteryModeEnabled to $saveBatteryModeEnabled");
      this.saveBatteryModeEnabled = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const audioInstructionsEnabledKey = "priobike.settings.audioInstructionsEnabled";
  static const defaultSaveAudioInstructionsEnabled = false;

  Future<bool> setAudioInstructionsEnabled(bool audioInstructionsEnabled, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.audioInstructionsEnabled;
    this.audioInstructionsEnabled = audioInstructionsEnabled;
    final bool success = await storage.setBool(audioInstructionsEnabledKey, audioInstructionsEnabled);
    if (!success) {
      log.e("Failed to set audioInstructionsEnabled to $audioInstructionsEnabled");
      this.audioInstructionsEnabled = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const didViewUserTransferKey = "priobike.settings.didViewUserTransfer";
  static const defaultDidViewUserTransfer = false;

  Future<bool> setDidViewUserTransfer(bool didViewUserTransfer, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.didViewUserTransfer;
    this.didViewUserTransfer = didViewUserTransfer;
    final bool success = await storage.setBool(didViewUserTransferKey, didViewUserTransfer);
    if (!success) {
      log.e("Failed to set didViewUserTransfer to $didViewUserTransfer");
      this.didViewUserTransfer = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const defaultSimulatorMode = false;

  Future<void> setSimulatorMode(bool enableSimulatorMode) async {
    this.enableSimulatorMode = enableSimulatorMode;
    if (enableSimulatorMode) {
      getIt<Simulator>().makeReadyForRide();
    } else {
      getIt<Simulator>().cleanUp();
    }
    notifyListeners();
  }

  static const didMigrateBackgroundImagesKey = "priobike.settings.didMigrateBackgroundImages";
  static const defaultDidMigrateBackgroundImages = false;

  Future<bool> setDidMigrateBackgroundImages(bool didMigrateBackgroundImages, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.didMigrateBackgroundImages;
    this.didMigrateBackgroundImages = didMigrateBackgroundImages;
    final bool success = await storage.setBool(didMigrateBackgroundImagesKey, didMigrateBackgroundImages);
    if (!success) {
      log.e("Failed to set didMigrateBackgroundImages to $didMigrateBackgroundImagesKey");
      this.didMigrateBackgroundImages = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const isFreeRideFilterEnabledKey = "priobike.settings.isFreeRideFilterEnabled";
  static const defaultIsFreeRideFilterEnabled = false;

  Future<bool> setFreeRideFilterEnabled(bool isFreeRideFilterEnabled, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.isFreeRideFilterEnabled;
    this.isFreeRideFilterEnabled = isFreeRideFilterEnabled;
    final bool success = await storage.setBool(isFreeRideFilterEnabledKey, isFreeRideFilterEnabled);
    if (!success) {
      log.e("Failed to set isFreeRideFilterEnabled to $isFreeRideFilterEnabled");
      this.isFreeRideFilterEnabled = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  static const isIncreasedSpeedPrecisionInSpeedometerEnabledKey =
      "priobike.settings.isIncreasedSpeedPrecisionInSpeedometerEnabled";
  static const defaultIsIncreasedSpeedPrecisionInSpeedometerEnabled = false;

  Future<bool> setIncreasedSpeedPrecisionInSpeedometerEnabled(bool isIncreasedSpeedPrecisionInSpeedometerEnabled,
      [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prev = this.isIncreasedSpeedPrecisionInSpeedometerEnabled;
    this.isIncreasedSpeedPrecisionInSpeedometerEnabled = isIncreasedSpeedPrecisionInSpeedometerEnabled;
    final bool success = await storage.setBool(
        isIncreasedSpeedPrecisionInSpeedometerEnabledKey, isIncreasedSpeedPrecisionInSpeedometerEnabled);
    if (!success) {
      log.e(
          "Failed to set isIncreasedSpeedPrecisionInSpeedometerEnabled to $isIncreasedSpeedPrecisionInSpeedometerEnabled");
      this.isIncreasedSpeedPrecisionInSpeedometerEnabled = prev;
    } else {
      notifyListeners();
    }
    return success;
  }

  Settings(
    this.backend, {
    this.enableLogPersistence = defaultEnableLogPersistence,
    this.enableTrafficLightSearchBar = defaultEnableTrafficLightSearchBar,
    this.enablePerformanceOverlay = defaultEnablePerformanceOverlay,
    this.didViewWarning = defaultDidViewWarning,
    this.positioningMode = defaultPositioningMode,
    this.routingEndpoint = defaultRoutingEndpoint,
    this.sgLabelsMode = defaultSGLabelsMode,
    this.speedMode = defaultSpeedMode,
    this.colorMode = defaultColorMode,
    this.datastreamMode = defaultDatastreamMode,
    this.connectionErrorCounter = defaultConnectionErrorCounter,
    this.sgSelector = defaultSGSelector,
    this.trackingSubmissionPolicy = defaultTrackingSubmissionPolicy,
    this.saveBatteryModeEnabled = defaultSaveBatteryModeEnabled,
    this.audioInstructionsEnabled = defaultSaveAudioInstructionsEnabled,
    this.useCounter = defaultUseCounter,
    this.dismissedSurvey = defaultDismissedSurvey,
    this.didViewUserTransfer = defaultDidViewUserTransfer,
    this.didMigrateBackgroundImages = defaultDidMigrateBackgroundImages,
    this.enableSimulatorMode = defaultSimulatorMode,
    this.isFreeRideFilterEnabled = defaultIsFreeRideFilterEnabled,
    this.isIncreasedSpeedPrecisionInSpeedometerEnabled = defaultIsIncreasedSpeedPrecisionInSpeedometerEnabled,
  });

  /// Load the internal settings from the shared preferences.
  Future<void> loadInternalSettings(SharedPreferences storage) async {
    enableLogPersistence = storage.getBool(enableLogPersistenceKey) ?? defaultEnableLogPersistence;
    enableTrafficLightSearchBar = storage.getBool(enableTrafficLightSearchBarKey) ?? defaultEnableTrafficLightSearchBar;
    enablePerformanceOverlay = storage.getBool(enablePerformanceOverlayKey) ?? defaultEnablePerformanceOverlay;
    didViewWarning = storage.getBool(didViewWarningKey) ?? defaultDidViewWarning;

    try {
      backend = Backend.values.byName(storage.getString(backendKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      positioningMode = PositioningMode.values.byName(storage.getString(positioningModeKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      sgLabelsMode = SGLabelsMode.values.byName(storage.getString(sgLabelsModeKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      datastreamMode = DatastreamMode.values.byName(storage.getString(datastreamModeKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      sgSelector = SGSelector.values.byName(storage.getString(sgSelectorKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      routingEndpoint = RoutingEndpoint.values.byName(storage.getString(routingEndpointKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      isFreeRideFilterEnabled = storage.getBool(isFreeRideFilterEnabledKey) ?? defaultIsFreeRideFilterEnabled;
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      isIncreasedSpeedPrecisionInSpeedometerEnabled =
          storage.getBool(isIncreasedSpeedPrecisionInSpeedometerEnabledKey) ??
              defaultIsIncreasedSpeedPrecisionInSpeedometerEnabled;
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      audioInstructionsEnabled = storage.getBool(audioInstructionsEnabledKey) ?? defaultSaveAudioInstructionsEnabled;
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
  }

  /// Load the stored settings.
  Future<void> loadSettings(bool canEnableInternalFeatures, bool canEnableBetaFeatures) async {
    if (hasLoaded) return;

    final storage = await SharedPreferences.getInstance();

    // All internal settings - use the default values if internal features are disabled.
    if (canEnableInternalFeatures) await loadInternalSettings(storage);

    // All remaining settings.
    connectionErrorCounter = storage.getInt(connectionErrorCounterKey) ?? defaultConnectionErrorCounter;
    useCounter = storage.getInt(useCounterKey) ?? defaultUseCounter;
    try {
      colorMode = ColorMode.values.byName(storage.getString(colorModeKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      speedMode = SpeedMode.values.byName(storage.getString(speedModeKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      trackingSubmissionPolicy =
          TrackingSubmissionPolicy.values.byName(storage.getString(trackingSubmissionPolicyKey)!);
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      saveBatteryModeEnabled = storage.getBool(saveBatteryModeEnabledKey) ?? defaultSaveBatteryModeEnabled;
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      dismissedSurvey = storage.getBool(dismissedSurveyKey) ?? defaultDismissedSurvey;
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      didViewUserTransfer = storage.getBool(didViewUserTransferKey) ?? defaultDidViewUserTransfer;
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }
    try {
      didMigrateBackgroundImages = storage.getBool(didMigrateBackgroundImagesKey) ?? defaultDidMigrateBackgroundImages;
    } catch (e) {
      /* Do nothing and use the default value given by the constructor. */
    }

    hasLoaded = true;
    notifyListeners();
  }

  /// Transfer a user to the given backend.
  Future<void> transferUser(Backend backend) async {
    if (isUserTransferring) return;
    isUserTransferring = true;
    notifyListeners();
    // Set release backend.
    await setBackend(backend);

    // Tell the fcm service that we selected the new backend.
    await FCM.selectTopic(backend);

    PredictionStatusSummary predictionStatusSummary = getIt<PredictionStatusSummary>();
    LoadStatus loadStatus = getIt<LoadStatus>();
    Shortcuts shortcuts = getIt<Shortcuts>();
    Routing routing = getIt<Routing>();
    News news = getIt<News>();
    Weather weather = getIt<Weather>();
    Boundary boundary = getIt<Boundary>();

    // Reset the associated services.
    await predictionStatusSummary.reset();
    await shortcuts.reset();
    await routing.reset();
    await news.reset();

    // Load stuff for the new backend.
    await news.getArticles();
    await shortcuts.loadShortcuts();
    await predictionStatusSummary.fetch();
    await loadStatus.fetch();
    loadStatus.sendAppStartNotification();
    await weather.fetch();
    await boundary.loadBoundaryCoordinates();

    // Set did view user transfer screen.
    await setDidViewUserTransfer(true);
    isUserTransferring = false;
    notifyListeners();
  }
}
