import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Layers with ChangeNotifier {
  var hasLoaded = false;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// If rental stations are currently visible.
  bool showRentalStations;

  /// If parking stations are currently visible.
  bool showParkingStations;

  /// If construction sites are currently visible.
  bool showConstructionSites;

  /// If air stations are currently visible.
  bool showAirStations;

  /// If repair stations are currently visible.
  bool showRepairStations;

  Future<void> setShowRentalStations(bool showRentalStations) async {
    this.showRentalStations = showRentalStations;
    await storePreferences();
  }

  Future<void> setShowParkingStations(bool showParkingStations) async {
    this.showParkingStations = showParkingStations;
    await storePreferences();
  }

  Future<void> setShowConstructionSites(bool showConstructionSites) async {
    this.showConstructionSites = showConstructionSites;
    await storePreferences();
  }

  Future<void> setShowAirStations(bool showAirStations) async {
    this.showAirStations = showAirStations;
    await storePreferences();
  }

  Future<void> setShowRepairStations(bool showRepairStations) async {
    this.showRepairStations = showRepairStations;
    await storePreferences();
  }

  Layers({
    this.showRentalStations = false,
    this.showParkingStations = false,
    this.showConstructionSites = true,
    this.showAirStations = false,
    this.showRepairStations = false,
  });

  /// Load the preferred settings.
  Future<void> loadPreferences() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    showRentalStations =
        storage.getBool("priobike.layers.showRentalStations") ?? false;
    showParkingStations =
        storage.getBool("priobike.layers.showParkingStations") ?? false;
    showConstructionSites =
        storage.getBool("priobike.layers.showConstructionSites") ?? true;
    showAirStations =
        storage.getBool("priobike.layers.showAirStations") ?? false;
    showRepairStations =
        storage.getBool("priobike.layers.showRepairStations") ?? false;

    notifyListeners();
  }

  /// Store the preferred settings.
  Future<void> storePreferences() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setBool(
        "priobike.layers.showRentalStations", showRentalStations);
    await storage.setBool(
        "priobike.layers.showParkingStations", showParkingStations);
    await storage.setBool(
        "priobike.layers.showConstructionSites", showConstructionSites);
    await storage.setBool("priobike.layers.showAirStations", showAirStations);
    await storage.setBool(
        "priobike.layers.showRepairStations", showRepairStations);

    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
