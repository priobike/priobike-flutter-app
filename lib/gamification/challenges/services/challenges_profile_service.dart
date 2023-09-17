import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/challenges/models/challenges_profile.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/challenges/models/level.dart';
import 'package:priobike/gamification/common/services/evaluation_data_service.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This service updates the challenges profile according to the user interaction.
class ChallengesProfileService with ChangeNotifier {
  /// Key to store the challenges profile in the shared prefs.
  static const profileKey = 'priobike.gamification.challenges.profile';

  /// Instance of the shared preferences.
  SharedPreferences? _prefs;

  /// Object which holds all the user profile values. If it is null, there is no user profile yet.
  ChallengesProfile? _profile;

  /// This bool describes, whether the profiles medal value has been changed.
  bool medalsChanged = false;

  /// This bool describes, whether the profiles trophy value has been changed.
  bool trophiesChanged = false;

  /// Dao to access the challenges completed by the user.
  ChallengeDao get _challengeDao => AppDatabase.instance.challengeDao;

  /// The current state of the users challenge profile.
  ChallengesProfile? get profile => _profile;

  /// Returns list of upgrades allowed for the user according to their current level.
  List<ProfileUpgrade> get upgradesForNextLevel => getUpgradesForLevel(_profile!.level + 1);

  ChallengesProfileService() {
    _loadData();
  }

  /// Load profile data from shared preferences.
  Future<void> _loadData() async {
    _prefs ??= await SharedPreferences.getInstance();
    var parsedProfile = _prefs?.getString(profileKey);
    if (parsedProfile == null) return;
    _profile = ChallengesProfile.fromJson(jsonDecode(parsedProfile));

    // If a profile was loaded, start the database stream of rides, to update the profile according to the challenges.
    startDatabaseStreams();
  }

  /// Create a challenge profile for the user, store it an prefs and start streams to observe completed challenges.
  Future<bool> createProfile() async {
    if (_profile != null) return false;
    _profile = ChallengesProfile();
    if (!(await _prefs?.setString(profileKey, jsonEncode(_profile!.toJson().toString())) ?? false)) {
      return false;
    }
    sendProfileDataToBackend();
    startDatabaseStreams();
    return true;
  }

  /// Start challenges database stream to update user profile accordingly.
  void startDatabaseStreams() {
    // Only challenges which are closed and completed, since open challenges are not regarded for the rewards yet.
    _challengeDao.streamClosedCompletedChallenges().listen((update) => updateRewards(update));
  }

  /// Update profile data stored in shared prefs and notify listeners.
  Future<void> storeProfile() async {
    _prefs ??= await SharedPreferences.getInstance();
    _prefs?.setString(profileKey, jsonEncode(_profile!.toJson()));
    notifyListeners();
  }

  /// This function updates the profiles rewards according to a given list of completed challenges.
  Future<void> updateRewards(List<Challenge> challenges) async {
    // If for some reason there is no user profile, return.
    if (_profile == null) return;
    // Save the old state of the trophies and medals to determine if they change.
    var oldMedals = _profile!.medals;
    var oldTrophies = _profile!.trophies;
    // Update rewards according to the completed challenges.
    _profile!.xp = ListUtils.getListSum(challenges.map((c) => c.xp.toDouble()).toList()).toInt();
    _profile!.medals = challenges.where((c) => !c.isWeekly).length;
    _profile!.trophies = challenges.where((c) => c.isWeekly).length;
    // If the medals or trophies changed, update the bools accordingly.
    medalsChanged = oldMedals < _profile!.medals;
    trophiesChanged = oldTrophies < _profile!.trophies;
    storeProfile();
  }

  /// Perform a level up on the user profile with a given profile upgrade.
  void levelUp(ProfileUpgrade? upgrade) {
    var newUpgrade = upgrade ?? upgradesForNextLevel.firstOrNull;
    // If there is an upgrade to apply, do that according to the upgrade type.
    if (newUpgrade != null) {
      if (newUpgrade.type == ProfileUpgradeType.addDailyChoice) {
        profile!.dailyChallengeChoices += 1;
      } else if (newUpgrade.type == ProfileUpgradeType.addWeeklyChoice) {
        profile!.weeklyChallengeChoices += 1;
      }
    }
    _profile!.level = min(_profile!.level + 1, levels.length - 1);
    // Save changed profile in shared prefs.
    storeProfile();
    sendProfileDataToBackend();
  }

  /// Reset all challenges and the their influence on the challenges profile.
  Future<void> resetChallenges() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_profile == null) return;
    _profile = ChallengesProfile();
    storeProfile();
    _challengeDao.clearObjects();
  }

  /// Reset everything connected to the challenge feature.
  Future<void> reset() async {
    _prefs ??= await SharedPreferences.getInstance();
    _profile = null;
    _prefs!.remove(profileKey);
    _challengeDao.clearObjects();
    notifyListeners();
  }

  Future<void> sendProfileDataToBackend() async {
    if (_profile == null) return;
    Map<String, dynamic> data = {
      'level': _profile!.level,
    };
    getIt<EvaluationDataService>().sendJsonToAddress('challenges/profile-update/', data);
  }
}
