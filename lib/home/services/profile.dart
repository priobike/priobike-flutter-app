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

  bool? showTrafficLights;

  bool? avoidTrafficLights;

  bool? avoidAscents;

  bool? avoidTraffic;

  ProfileService(
      {this.bikeType,
      this.preferenceType,
      this.activityType,
      this.showTrafficLights,
      this.avoidTrafficLights,
      this.avoidAscents,
      this.avoidTraffic});

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

    notifyListeners();
  }
}
