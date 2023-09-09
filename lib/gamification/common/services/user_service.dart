import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/models/user_profile.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service which manages and provides the values of the gamification user profile, including the users' settings.
class GamificationUserService with ChangeNotifier {
  static const userProfileKey = 'priobike.gamification.userProfile';
  static const gamificationEnabledKey = 'priobike.gamification.enabled';
  static const enabledFeatureListKey = 'priobike.gamification.prefs.enabledFeatures';
  static const gameFeatureStatisticsKey = 'priobike.gamification.feature.statistics';
  static const gameFeatureChallengesKey = 'priobike.gamification.feature.challenges';

  static const gamificationFeatures = [
    gameFeatureChallengesKey,
    gameFeatureStatisticsKey,
  ];

  /// Instance of the shared preferences.
  SharedPreferences? _prefs;

  /// List of the selected game preferences of the user as string keys.
  List<String> _enabledFeatures = [];

  /// Object which holds all the user profile values. If it is null, there is no user profile yet.
  UserProfile? _profile;

  /// Ride DAOs to access rides.
  RideSummaryDao get rideDao => AppDatabase.instance.rideSummaryDao;

  UserProfile? get profile => _profile;

  List<String> get enabledFeatures => _enabledFeatures;

  List<String> get disabledFeatures =>
      gamificationFeatures.whereNot((feature) => enabledFeatures.contains(feature)).toList();

  /// Returns true, if there is a valid user profile.
  bool get hasProfile => _profile != null;

  GamificationUserService() {
    _loadData();
  }

  /// Start rides database stream to update user profile accordingly.
  void startDatabaseStream() {
    rideDao.streamAllObjects().listen((update) => updateOverallStats(update));
  }

  /// Create a user profile with a given username and save in shared prefs.
  Future<bool> createProfile() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Create profile and set join date to now.
    _profile = UserProfile(
      joinDate: DateTime.now(),
    );
    // Try to save profile in shared prefs and return false if not successful.
    if (!(await _prefs?.setString(userProfileKey, jsonEncode(_profile!.toJson().toString())) ?? false)) {
      return false;
    }
    // Try to set profile exists string and return false if not successful
    if (!(await _prefs?.setBool(gamificationEnabledKey, true) ?? false)) return false;
    // Start the database stream of rides, to update the profile data accordingly.
    startDatabaseStream();
    return true;
  }

  /// Load the profile from shared prefs, if there is one.
  Future<void> _loadData() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Return, if the profile exists value is not true or set;
    if (!(_prefs?.getBool(gamificationEnabledKey) ?? false)) return;
    // Try to load profile string from prefs and parse to user profile if possible.
    var parsedProfile = _prefs?.getString(userProfileKey);
    if (parsedProfile == null) return;
    _profile = UserProfile.fromJson(jsonDecode(parsedProfile));
    _enabledFeatures = _prefs!.getStringList(enabledFeatureListKey) ?? [];
    // If a profile was loaded, start the database stream of rides, to update the profile data accordingly.
    startDatabaseStream();
  }

  /// Update user profile statistics according to database and user prefs and save in shared pref.
  Future<void> updateOverallStats(List<RideSummary> rides) async {
    // If for some reason there is no user profile, return.
    if (_profile == null) return;
    // Update profile statistics according to rides.
    _profile!.totalDistanceKilometres = Utils.getOverallValueFromSummaries(rides, RideInfo.distance);
    _profile!.totalDurationMinutes = Utils.getOverallValueFromSummaries(rides, RideInfo.duration);
    _profile!.totalElevationGainMetres = Utils.getOverallValueFromSummaries(rides, RideInfo.elevationGain);
    _profile!.totalElevationLossMetres = Utils.getOverallValueFromSummaries(rides, RideInfo.elevationLoss);
    _profile!.averageSpeedKmh = Utils.getOverallValueFromSummaries(rides, RideInfo.averageSpeed);
    updateProfile();
  }

  /// Update profile data stored in shared prefs and notify listeners.
  Future<void> updateProfile() async {
    // Update profile in shared preferences.
    _prefs ??= await SharedPreferences.getInstance();
    _prefs?.setString(userProfileKey, jsonEncode(_profile!.toJson()));
    notifyListeners();
  }

  /// Returns true, if a given string key is inside of the list of selected game prefs.
  bool isFeatureEnabled(String key) => _enabledFeatures.contains(key);

  Future<void> enableFeature(String key) async {
    if (_enabledFeatures.contains(key)) return;
    _enabledFeatures.add(key);
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setStringList(enabledFeatureListKey, _enabledFeatures);
    notifyListeners();
  }

  void disableFeature(String key) async {
    if (!_enabledFeatures.contains(key)) return;
    _enabledFeatures.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setStringList(enabledFeatureListKey, _enabledFeatures);
    notifyListeners();
  }

  void moveFeatureUp(String key) {
    if (_enabledFeatures.firstOrNull == key) return;
    int index = _enabledFeatures.indexOf(key);
    _enabledFeatures.remove(key);
    _enabledFeatures.insert(index - 1, key);
    notifyListeners();
  }

  void moveFeatureDown(String key) {
    if (_enabledFeatures.lastOrNull == key) return;
    int index = _enabledFeatures.indexOf(key);
    _enabledFeatures.remove(key);
    _enabledFeatures.insert(index + 1, key);
    notifyListeners();
  }

  Future<void> reset() async {
    var prefs = await SharedPreferences.getInstance();
    _profile = null;
    _enabledFeatures.clear();
    prefs.remove(userProfileKey);
    prefs.remove(gamificationEnabledKey);
    prefs.remove(enabledFeatureListKey);
    notifyListeners();
  }
}
