import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/logging/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Profile");

  /// Whether the profile has already been loaded.
  bool hasLoaded = false;

  /// The selected type of bike. Default is [BikeType.citybike].
  BikeType bikeType = BikeType.citybike;

  /// The selected route preference. Default is [PreferenceType.balanced].
  PreferenceType preferenceType = PreferenceType.balanced;

  /// The type of activity. Default is [ActivityType.avoidIncline].
  ActivityType activityType = ActivityType.avoidIncline;

  /// Load the stored profile.
  Future<void> loadProfile() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final bikeTypeStr = storage.getString("priobike.home.profile.bike");
    if (bikeTypeStr != null) {
      try {
        bikeType = BikeType.values.byName(bikeTypeStr);
      } catch (e) {
        log.e("Failed to load bike type: $e");
      }
    }

    final preferenceTypeStr = storage.getString("priobike.home.profile.preferences");
    if (preferenceTypeStr != null) {
      try {
        preferenceType = PreferenceType.values.byName(preferenceTypeStr);
      } catch (e) {
        log.e("Failed to load preference type: $e");
      }
    }

    final activityTypeStr = storage.getString("priobike.home.profile.activity");
    if (activityTypeStr != null) {
      try {
        activityType = ActivityType.values.byName(activityTypeStr);
      } catch (e) {
        log.e("Failed to load activity type: $e");
      }
    }

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    await storage.setString("priobike.home.profile.bike", bikeType.name);
    await storage.setString("priobike.home.profile.preferences", preferenceType.name);
    await storage.setString("priobike.home.profile.activity", activityType.name);

    notifyListeners();
  }
}
