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

  static const prefsRideSummariesKey = 'priobike.game.prefs.rideSummaries';
  static const presRideStatisticsKey = 'priobike.game.prefs.rideStatistics';

  /// Object which holds all the user profile values. If it is null, there is no user profile yet.
  UserProfile? _userProfile;

  /// Ride DAO needed to access ride summaries when updating the profile values.
  RideSummaryDao get rideDao => AppDatabase.instance.rideSummaryDao;

  /// Returns true, if there is a valid user profile.
  bool get hasUserData => _userProfile != null;

  /// Returns the total distance covered by the user.
  double get totalDistanceMetres => _userProfile?.totalDistanceMetres ?? 0;

  /// Returns the total duration the user drove while using the app.
  double get totalDurationSeconds => _userProfile?.totalDurationSeconds ?? 0;

  /// Returns the total elevation gain the user covered.
  double get totalElevationGainMetres => _userProfile?.totalElevationGainMetres ?? 0;

  /// Returns the total elevation loss the user covered.
  double get totalElevationLossMetres => _userProfile?.totalElevationLossMetres ?? 0;

  /// Returns the average speed the user has when driving.
  double get averageSpeedKmh => _userProfile?.averageSpeedKmh ?? 0;

  /// Returns the gamification features the user wants to have enabled as a list of string keys.
  List<String> get userPrefs => _userProfile?.prefs ?? [];

  /// Returns the username of the user.
  String get username => _userProfile?.username ?? '';

  UserProfileService() {
    loadOrCreateProfile();
  }

  /// If the intro was finished and all necessary data was entered, create a user profile. If one was already create it,
  /// load it from the shared preferences and store it locally.
  Future<void> loadOrCreateProfile() async {
    var prefs = await SharedPreferences.getInstance();
    var username = prefs.getString(userNameKey);

    // If there is no username in the shared prefs, a user profile can't be created.
    if (username == null) return;

    var joinDate = prefs.getString(userJoinDateKey);
    // If there is no join date, the user profile hasn't been created and stored in the prefs, so it is done here.
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
        prefs: prefs.getStringList(userPreferencesKey) ?? [],
      );
    }
  }

  /// Update user profile data according to database and user prefs and save in shared pref.
  Future<void> updateUserData() async {
    var rides = await rideDao.getAllObjects();
    var prefs = await SharedPreferences.getInstance();

    // If for some reason there is no user profile, return.
    if (_userProfile == null) return;

    // Calculate total distance as sum of all ride distances.
    _userProfile!.totalDistanceMetres = rides.map((r) => r.distanceMetres).reduce((a, b) => a + b);
    prefs.setDouble(userTotalDistanceKey, totalDistanceMetres);

    // Calculate total duration as sum of all ride durations.
    _userProfile!.totalDurationSeconds = rides.map((r) => r.durationSeconds).reduce((a, b) => a + b);
    prefs.setDouble(userTotalDurationKey, totalDurationSeconds);

    // Calculate total elevation gain as sum of all ride elevation gains.
    _userProfile!.totalElevationGainMetres = rides.map((r) => r.elevationGainMetres).reduce((a, b) => a + b);
    prefs.setDouble(userTotalElevationGainKey, totalElevationGainMetres);

    // Calculate total elevation loss as sum of all ride elevation losses.
    _userProfile!.totalElevationLossMetres = rides.map((r) => r.elevationLossMetres).reduce((a, b) => a + b);
    prefs.setDouble(userTotalElevationLossKey, totalElevationLossMetres);

    // Calculate average speed from distance and duration and convert to km/h instead of m/s
    _userProfile!.averageSpeedKmh = (_userProfile!.totalDistanceMetres / _userProfile!.totalDurationSeconds) * 3.6;
    prefs.setDouble(userAverageSpeedKey, averageSpeedKmh);

    // Get user prefs from shared preferences.
    _userProfile!.prefs = prefs.getStringList(userPreferencesKey) ?? [];

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
    getIt<GameIntroService>().setPrefsSet(false);
    getIt<GameIntroService>().loadValues();
  }
}
