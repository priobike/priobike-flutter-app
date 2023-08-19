import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/hub/models/user_profile.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service which manages and provides the values of the gamification user profile.
class UserProfileService with ChangeNotifier {
  static const userPreferencesKey = 'priobike.game.profile.userPrefs';
  static const userTotalDistanceKey = 'priobike.game.profile.totalDistance';
  static const userTotalDurationKey = 'priobike.game.profile.totalDuration';
  static const userTotalElevationGainKey = 'priobike.game.profile.totalElevationGain';
  static const userTotalElevationLossKey = 'priobike.game.profile.totalElevationLoss';
  static const userAverageSpeedKey = 'priobike.game.profile.averageSpeed';
  static const userJoinDateKey = 'priobike.game.profile.joinDate';
  static const userNameKey = 'priobike.game.profile.username';

  /// Ride DAO needed to access ride summaries when updating the profile values.
  RideSummaryDao get rideDao => AppDatabase.instance.rideSummaryDao;

  /// Object which holds all the user profile values. If it is null, there is no user profile yet.
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  /// Returns true, if there is a valid user profile.
  bool get hasUserData => _userProfile != null;

  UserProfileService() {
    loadOrCreateProfile();
  }

  /// If the intro was finished and all necessary data was entered, create a user profile. If one was already create it,
  /// load it from the shared preferences and store it locally.
  Future<void> loadOrCreateProfile() async {
    var prefs = await SharedPreferences.getInstance();

    // If there is no username in the shared prefs, a user profile can't be created.
    var username = prefs.getString(userNameKey);
    if (username == null) return;

    // If there is no join date, the user profile hasn't been created and stored in the prefs, so it is done here.
    var joinDate = prefs.getString(userJoinDateKey);
    if (joinDate == null) {
      joinDate = DateTime.now().toIso8601String();
      prefs.setString(userJoinDateKey, joinDate);
      _userProfile = UserProfile(
        parsedJoinDate: joinDate,
        username: username,
      );
      await updateUserData();
    }

    // If the user values were already created, load them from prefs.
    else {
      _userProfile = UserProfile(
        totalDistanceMetres: prefs.getDouble(userTotalDistanceKey) ?? 0,
        totalDurationSeconds: prefs.getDouble(userTotalDurationKey) ?? 0,
        totalElevationGainMetres: prefs.getDouble(userTotalElevationGainKey) ?? 0,
        totalElevationLossMetres: prefs.getDouble(userTotalElevationLossKey) ?? 0,
        parsedJoinDate: joinDate,
        username: username,
      );
    }
  }

  /// Update user profile data according to database and user prefs and save in shared pref.
  Future<void> updateUserData() async {
    var rides = await rideDao.getAllObjects();
    var prefs = await SharedPreferences.getInstance();

    // If for some reason there is no user profile, return.
    if (_userProfile == null) return;

    if (rides.isNotEmpty) {
      // Calculate total distance as sum of all ride distances.
      _userProfile!.totalDistanceMetres = rides.map((r) => r.distanceMetres).reduce((a, b) => a + b);
      prefs.setDouble(userTotalDistanceKey, _userProfile!.totalDistanceMetres);

      // Calculate total duration as sum of all ride durations.
      _userProfile!.totalDurationSeconds = rides.map((r) => r.durationSeconds).reduce((a, b) => a + b);
      prefs.setDouble(userTotalDurationKey, _userProfile!.totalDurationSeconds);

      // Calculate total elevation gain as sum of all ride elevation gains.
      _userProfile!.totalElevationGainMetres = rides.map((r) => r.elevationGainMetres).reduce((a, b) => a + b);
      prefs.setDouble(userTotalElevationGainKey, _userProfile!.totalElevationGainMetres);

      // Calculate total elevation loss as sum of all ride elevation losses.
      _userProfile!.totalElevationLossMetres = rides.map((r) => r.elevationLossMetres).reduce((a, b) => a + b);
      prefs.setDouble(userTotalElevationLossKey, _userProfile!.totalElevationLossMetres);

      // Calculate average speed from distance and duration and convert to km/h instead of m/s
      _userProfile!.averageSpeedKmh = (_userProfile!.totalDistanceMetres / _userProfile!.totalDurationSeconds) * 3.6;
      prefs.setDouble(userAverageSpeedKey, _userProfile!.averageSpeedKmh);
    }

    notifyListeners();
  }

  /// Helper function which removes a created user profile. Just for tests currently.
  void resetUserProfile() async {
    var prefs = await SharedPreferences.getInstance();
    _userProfile = null;
    prefs.remove(userNameKey);
    prefs.remove(userJoinDateKey);
    prefs.remove(userAverageSpeedKey);
    prefs.remove(userTotalDistanceKey);
    prefs.remove(userTotalDurationKey);
    prefs.remove(userTotalElevationGainKey);
    prefs.remove(userTotalElevationLossKey);
    prefs.remove(userPreferencesKey);
    prefs.setBool(GameIntroService.finishedIntroKey, false);
    getIt<GameIntroService>().setUsername('');
    getIt<GameIntroService>().setStartedIntro(false);
    getIt<GameIntroService>().setConfirmedFeaturePage(false);
    getIt<GameIntroService>().loadValues();
  }
}
