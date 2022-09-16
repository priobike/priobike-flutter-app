import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService with ChangeNotifier {
  var hasLoaded = false;

  /// The selected type of bike.
  BikeType? bikeType;

  /// The selected route preference.
  PreferenceType? preferenceType;

  /// The type of activity.
  ActivityType? activityType;

  /// The visibility of traffic lights
  bool? showTrafficLights;

  /// The preference of avoiding traffic lights
  bool? avoidTrafficLights;

  /// The preference of avoiding ascents
  bool? avoidAscents;

  /// The preference of avoiding traffic
  bool? avoidTraffic;

  /// The visibility of general point of interests
  bool? showGeneralPOIs;

  /// The preference of setting location as start
  bool? setLocationAsStart;

  /// The preference of saving search history
  bool? saveSearchHistory;

  ProfileService(
      {this.bikeType,
      this.preferenceType,
      this.activityType,
      this.showTrafficLights,
      this.avoidTrafficLights,
      this.avoidAscents,
      this.avoidTraffic,
      this.showGeneralPOIs,
      this.setLocationAsStart,
      this.saveSearchHistory});

  /// Load the stored profile.
  Future<void> loadProfile() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final bikeTypeStr = storage.getString("priobike.home.profile.bike");
    final preferenceTypeStr =
        storage.getString("priobike.home.profile.preferences");
    final activityTypeStr = storage.getString("priobike.home.profile.activity");
    showTrafficLights =
        storage.getBool("priobike.home.profile.showTrafficLights") ?? false;
    avoidTrafficLights =
        storage.getBool("priobike.home.profile.avoidTrafficLights") ?? false;
    avoidAscents =
        storage.getBool("priobike.home.profile.avoidAscents") ?? false;
    avoidTraffic =
        storage.getBool("priobike.home.profile.avoidTraffic") ?? false;
    showGeneralPOIs =
        storage.getBool("priobike.home.profile.showGeneralPOIs") ?? false;
    setLocationAsStart =
        storage.getBool("priobike.home.profile.setLocationAsStart") ?? false;
    saveSearchHistory =
        storage.getBool("priobike.home.profile.saveSearchHistory") ?? false;

    if (bikeTypeStr != null) bikeType = BikeType.values.byName(bikeTypeStr);
    if (preferenceTypeStr != null)
      preferenceType = PreferenceType.values.byName(preferenceTypeStr);
    if (activityTypeStr != null)
      activityType = ActivityType.values.byName(activityTypeStr);

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    if (bikeType != null)
      await storage.setString("priobike.home.profile.bike", bikeType!.name);
    if (preferenceType != null)
      await storage.setString(
          "priobike.home.profile.preferences", preferenceType!.name);
    if (activityType != null)
      await storage.setString(
          "priobike.home.profile.activity", activityType!.name);
    if (showTrafficLights != null)
      await storage.setBool(
          "priobike.home.profile.showTrafficLights", showTrafficLights!);
    if (avoidTrafficLights != null)
      await storage.setBool(
          "priobike.home.profile.avoidTrafficLights", avoidTrafficLights!);
    if (avoidAscents != null)
      await storage.setBool(
          "priobike.home.profile.avoidAscents", avoidAscents!);
    if (avoidTraffic != null)
      await storage.setBool(
          "priobike.home.profile.avoidTraffic", avoidTraffic!);
    if (showGeneralPOIs != null)
      await storage.setBool(
          "priobike.home.profile.showGeneralPOIs", showGeneralPOIs!);
    if (setLocationAsStart != null)
      await storage.setBool(
          "priobike.home.profile.setLocationAsStart", setLocationAsStart!);
    if (saveSearchHistory != null)
      await storage.setBool(
          "priobike.home.profile.avoidTraffic", saveSearchHistory!);

    notifyListeners();
  }
}
