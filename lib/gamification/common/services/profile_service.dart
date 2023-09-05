import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/challenges/models/challenge_goals.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/models/game_profile.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service which manages and provides the values of the gamification user profile, including the users' settings.
class GameProfileService with ChangeNotifier {
  static const userProfileKey = 'priobike.game.userProfile';
  static const profileExistsKey = 'priobike.game.profileExists';
  static const enabledFeatureListKey = 'priobike.game.prefs.enabledFeatures';
  static const gameFeatureStatisticsKey = 'priobike.game.features.statistics';
  static const gameFeatureChallengesKey = 'priobike.game.features.challenges';
  static const challengeGoalsKey = 'priobike.game.challenges.goals';

  /// Instance of the shared preferences.
  SharedPreferences? _prefs;

  /// The user goals for the challenges
  UserGoals? _challengeGoals;
  UserGoals get challengeGoals => _challengeGoals ?? UserGoals.def;

  /// Check, if the user has set challenge goals already.
  bool get challengeGoalsSet => _challengeGoals != null;

  /// List of the selected game preferences of the user as string keys.
  List<String> _enabledFeatures = [];
  List<String> get enabledFeatures => _enabledFeatures;

  /// Ride DAOs to access rides and challenges.
  RideSummaryDao get rideDao => AppDatabase.instance.rideSummaryDao;
  ChallengeDao get challengeDao => AppDatabase.instance.challengeDao;

  /// Object which holds all the user profile values. If it is null, there is no user profile yet.
  GameProfile? _profile;
  GameProfile? get profile => _profile;

  /// Returns true, if there is a valid user profile.
  bool get hasProfile => _profile != null;

  /// This bool describes, whether the profiles medal value has been changed.
  bool medalsChanged = false;

  /// This bool describes, whether the profiles trophy value has been changed.
  bool trophiesChanged = false;

  GameProfileService() {
    _loadProfile();
  }

  /// Start challenges and rides database streams to update user profile accordingly.
  void startDatabaseStreams() {
    rideDao.streamAllObjects().listen((update) => updateStatistics(update));
    // Only challenges which are closed and completed, since open challenges are not regarded for the rewards yet.
    challengeDao.streamClosedCompletedChallenges().listen((update) => updateRewards(update));
  }

  /// This function updates the profiles rewards according to a given list of completed challenges.
  Future<void> updateRewards(List<Challenge> challenges) async {
    // If for some reason there is no user profile, return.
    if (_profile == null) return;

    // Save the old state of the trophies and medals to determine if they change.
    var oldMedals = _profile!.medals;
    var oldTrophies = _profile!.trophies;

    // Update rewards according to the completed challenges.
    _profile!.xp = Utils.getListSum(challenges.map((c) => c.xp.toDouble()).toList()).toInt();
    _profile!.medals = challenges.where((c) => !c.isWeekly).length;
    _profile!.trophies = challenges.where((c) => c.isWeekly).length;

    // If the medals or trophies changed, update the bools accordingly.
    medalsChanged = oldMedals < _profile!.medals;
    trophiesChanged = oldTrophies < _profile!.trophies;

    updateProfile();
  }

  /// Create a user profile with a given username and save in shared prefs.
  Future<bool> createProfile(String username) async {
    _prefs ??= await SharedPreferences.getInstance();

    /// Create profile and set join date to now.
    _profile = GameProfile(
      joinDate: DateTime.now(),
      username: username,
    );

    /// Try to save profile in shared prefs and return false if not successful.
    if (!(await _prefs?.setString(userProfileKey, jsonEncode(_profile!.toJson().toString())) ?? false)) {
      return false;
    }

    /// Try to set profile exists string and return false if not successful
    if (!(await _prefs?.setBool(profileExistsKey, true) ?? false)) return false;

    /// Start the database stream of rides, to update the profile data accordingly.
    startDatabaseStreams();

    return true;
  }

  /// Load the profile from shared prefs, if there is one.
  Future<void> _loadProfile() async {
    _prefs ??= await SharedPreferences.getInstance();

    /// Return, if the profile exists value is not true or set;
    if (!(_prefs?.getBool(profileExistsKey) ?? false)) return;

    /// Try to load profile string from prefs and parse to user profile if possible.
    var parsedProfile = _prefs?.getString(userProfileKey);
    if (parsedProfile == null) return;
    _profile = GameProfile.fromJson(jsonDecode(parsedProfile));

    _prefs ??= await SharedPreferences.getInstance();
    _enabledFeatures = _prefs!.getStringList(enabledFeatureListKey) ?? [];

    var goalStr = _prefs!.getString(challengeGoalsKey);
    if (goalStr != null) _challengeGoals = UserGoals.fromJson(jsonDecode(goalStr));

    /// If a profile was loaded, start the database stream of rides, to update the profile data accordingly.
    startDatabaseStreams();
  }

  /// Update user profile statistics according to database and user prefs and save in shared pref.
  Future<void> updateStatistics(List<RideSummary> rides) async {
    // If for some reason there is no user profile, return.
    if (_profile == null) return;

    /// Update profile statistics according to rides.
    _profile!.totalDistanceKilometres = Utils.getOverallValueFromSummaries(rides, RideInfo.distance);
    _profile!.totalDurationMinutes = Utils.getOverallValueFromSummaries(rides, RideInfo.duration);
    _profile!.totalElevationGainMetres = Utils.getOverallValueFromSummaries(rides, RideInfo.elevationGain);
    _profile!.totalElevationLossMetres = Utils.getOverallValueFromSummaries(rides, RideInfo.elevationLoss);
    _profile!.averageSpeedKmh = Utils.getOverallValueFromSummaries(rides, RideInfo.averageSpeed);

    updateProfile();
  }

  /// Update profile data stored in shared prefs and notify listeners.
  Future<void> updateProfile() async {
    /// Update profile in shared preferences.
    _prefs ??= await SharedPreferences.getInstance();
    _prefs?.setString(userProfileKey, jsonEncode(_profile!.toJson()));

    notifyListeners();
  }

  /// Update the users' challenge goals and notify listeners.
  void setChallengeGoals(UserGoals? goals) {
    _challengeGoals = goals;
    if (goals != null) {
      _prefs!.setString(challengeGoalsKey, jsonEncode(goals.toJson()));
    } else {
      _prefs!.remove(challengeGoalsKey);
    }
    notifyListeners();
  }

  /// Returns true, if a given string key is inside of the list of selected game prefs.
  bool isFeatureEnabled(String key) => _enabledFeatures.contains(key);

  /// Removes a key out of the enabled feature, if the key is inside the lits. Otherwise adds it to the list.
  void enableOrDisableFeature(String key) async {
    if (_enabledFeatures.contains(key)) {
      _enabledFeatures.remove(key);
    } else {
      _enabledFeatures.add(key);
    }
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setStringList(enabledFeatureListKey, _enabledFeatures);
    notifyListeners();
  }

  /// Helper function which removes a created user profile. Just for tests currently.
  void resetUserProfile() async {
    var prefs = await SharedPreferences.getInstance();
    _profile = null;
    prefs.remove(userProfileKey);
    prefs.remove(profileExistsKey);
    prefs.remove(enabledFeatureListKey);
    _enabledFeatures.clear();
    AppDatabase.instance.challengeDao.clearObjects();
    notifyListeners();
  }
}
