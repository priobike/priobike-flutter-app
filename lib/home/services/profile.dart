import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile with ChangeNotifier {
  /// Whether the profile has already been loaded.
  bool hasLoaded = false;

  /// The selected type of bike.
  BikeType? bikeType;

  /// The selected route preference.
  PreferenceType? preferenceType;

  /// The type of activity.
  ActivityType? activityType;

  Profile({
    this.bikeType,
    this.preferenceType,
    this.activityType,
  });

  /// Load the stored profile.
  Future<void> loadProfile() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final bikeTypeStr = storage.getString("priobike.home.profile.bike");
    if (bikeTypeStr != null) {
      try {
        bikeType = BikeType.values.byName(bikeTypeStr);
      } catch (e) {
        bikeType = null;
      }
    }

    // Set default
    bikeType ??= BikeType.citybike;

    final preferenceTypeStr = storage.getString("priobike.home.profile.preferences");
    if (preferenceTypeStr != null) {
      try {
        preferenceType = PreferenceType.values.byName(preferenceTypeStr);
      } catch (e) {
        preferenceType = null;
      }
    }

    // Set default
    preferenceType ??= PreferenceType.balanced;

    final activityTypeStr = storage.getString("priobike.home.profile.activity");
    if (activityTypeStr != null) {
      try {
        activityType = ActivityType.values.byName(activityTypeStr);
      } catch (e) {
        activityType = null;
      }
    }

    // Set default
    activityType ??= ActivityType.avoidIncline;

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    if (bikeType != null) {
      await storage.setString("priobike.home.profile.bike", bikeType!.name);
    } else {
      await storage.remove("priobike.home.profile.bike");
    }
    if (preferenceType != null) {
      await storage.setString("priobike.home.profile.preferences", preferenceType!.name);
    } else {
      await storage.remove("priobike.home.profile.preferences");
    }
    if (activityType != null) {
      await storage.setString("priobike.home.profile.activity", activityType!.name);
    } else {
      await storage.remove("priobike.home.profile.activity");
    }

    notifyListeners();
  }
}
