import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/hub/models/user_profiles.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameService with ChangeNotifier {
  static const userPreferencesKey = 'priobike.game.profile.userPrefs';
  static const userTotalDistanceKey = 'priobike.game.profile.totalDistance';
  static const userTotalDurationKey = 'priobike.game.profile.totalDuration';
  static const userTotalElevationGainKey = 'priobike.game.profile.totalElevationGain';
  static const userTotalElevationLossKey = 'priobike.game.profile.totalElevationLoss';
  static const userAverageSpeedKey = 'priobike.game.profile.averageSpeed';
  static const userJoinDateKey = 'priobike.game.profile.joinDate';
  static const userNameKey = 'priobike.game.profile.username';

  static const prefsRideSummariesKey = "priobike.game.prefs.rideSummaries";

  UserProfile? _userProfile;

  RideSummaryDao get rideDao => AppDatabase.instance.rideSummaryDao;

  bool get hasUserData => _userProfile != null;

  double get totalDistanceMetres => _userProfile?.totalDistanceMetres ?? 0;

  double get totalDurationSeconds => _userProfile?.totalDurationSeconds ?? 0;

  double get totalElevationGainMetres => _userProfile?.totalElevationGainMetres ?? 0;

  double get totalElevationLossMetres => _userProfile?.totalElevationLossMetres ?? 0;

  double get averageSpeedKmh => _userProfile?.averageSpeedKmh ?? 0;

  List<String> get userPrefs => _userProfile?.prefs ?? [];

  String get username => _userProfile?.username ?? '';

  GameService() {
    loadOrCreateProfile();
  }

  Future<void> loadOrCreateProfile() async {
    var prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(GameIntroService.finishedTutorialKey) ?? false)) return;
    var joinDate = prefs.getString(userJoinDateKey);
    var username = prefs.getString(userNameKey);
    // If there is no join date, the user profile hasn't been created and stored in the prefs, so it is done here.
    if (joinDate == null && username != null) {
      joinDate = DateTime.now().toIso8601String();
      prefs.setString(userJoinDateKey, joinDate);
      _userProfile = UserProfile(
        parsedJoinDate: joinDate,
        username: username,
      );
      await updateUserData();
    }
    // If the user values were already created, load them from prefs.
    else if (joinDate != null && username != null) {
      _userProfile = UserProfile(
        totalDistanceMetres: prefs.getDouble(userTotalDistanceKey) ?? 0,
        totalDurationSeconds: prefs.getDouble(userTotalDurationKey) ?? 0,
        totalElevationGainMetres: prefs.getDouble(userTotalElevationGainKey) ?? 0,
        totalElevationLossMetres: prefs.getDouble(userTotalElevationLossKey) ?? 0,
        parsedJoinDate: joinDate,
        username: username,
        prefs: prefs.getStringList(userPreferencesKey) ?? [],
      );
    } else {
      throw Exception("No username set");
    }
  }

  Future<void> updateUserData() async {
    var rides = await rideDao.getAllObjects();
    var prefs = await SharedPreferences.getInstance();
    if (_userProfile == null) return;
    _userProfile!.totalDistanceMetres = rides.map((r) => r.distanceMetres).reduce((a, b) => a + b);
    prefs.setDouble(userTotalDistanceKey, totalDistanceMetres);
    _userProfile!.totalDurationSeconds = rides.map((r) => r.durationSeconds).reduce((a, b) => a + b);
    prefs.setDouble(userTotalDurationKey, totalDurationSeconds);
    _userProfile!.totalElevationGainMetres = rides.map((r) => r.elevationGainMetres).reduce((a, b) => a + b);
    prefs.setDouble(userTotalElevationGainKey, totalElevationGainMetres);
    _userProfile!.totalElevationLossMetres = rides.map((r) => r.elevationLossMetres).reduce((a, b) => a + b);
    prefs.setDouble(userTotalElevationLossKey, totalElevationLossMetres);
    _userProfile!.averageSpeedKmh = rides.map((r) => r.averageSpeedKmh).reduce((a, b) => a + b) / rides.length;
    prefs.setDouble(userAverageSpeedKey, averageSpeedKmh);
    _userProfile!.prefs = prefs.getStringList(userPreferencesKey) ?? [];
    notifyListeners();
  }
}
