import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile with ChangeNotifier {
  var hasLoaded = false;

  /// The selected type of bike.
  BikeType? bikeType;

  /// The selected route preference.
  PreferenceType? preferenceType;

  /// The type of activity.
  ActivityType? activityType;

  Profile({this.bikeType, this.preferenceType, this.activityType});

  /// Load the stored profile.
  Future<void> loadProfile() async {
    if (hasLoaded) return;
    final storage = await SharedPreferences.getInstance();

    final bikeTypeStr = storage.getString("priobike.home.profile.bike");
    final preferenceTypeStr = storage.getString("priobike.home.profile.preferences");
    final activityTypeStr = storage.getString("priobike.home.profile.activity");

    bikeType = bikeTypeStr == null ? null : BikeType.values.byName(bikeTypeStr);
    preferenceType = preferenceTypeStr == null ? null : PreferenceType.values.byName(preferenceTypeStr);
    activityType = activityTypeStr == null ? null : ActivityType.values.byName(activityTypeStr);

    hasLoaded = true;
    notifyListeners();
  }

  /// Store the profile.
  Future<void> store() async {
    final storage = await SharedPreferences.getInstance();

    if (bikeType != null) await storage.setString("priobike.home.profile.bike", bikeType!.name);
    if (preferenceType != null) await storage.setString("priobike.home.profile.preferences", preferenceType!.name);
    if (activityType != null) await storage.setString("priobike.home.profile.activity", activityType!.name);

    notifyListeners();
  }
}
