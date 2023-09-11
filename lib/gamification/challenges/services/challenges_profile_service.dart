import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/challenges/models/challenges_profile.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengesProfileService with ChangeNotifier {
  static const profileKey = 'priobike.gamification.challenges.profile';
  static const activatedUpgradesKey = 'priobike.gamification.challenges.activatedUpgrades';

  /// Instance of the shared preferences.
  SharedPreferences? _prefs;

  /// Object which holds all the user profile values. If it is null, there is no user profile yet.
  ChallengesProfile? _profile;

  /// This bool describes, whether the profiles medal value has been changed.
  bool medalsChanged = false;

  /// This bool describes, whether the profiles trophy value has been changed.
  bool trophiesChanged = false;

  /// List of the activated profile upgrades.
  List<ProfileUpgrade> _activatedUpgrades = [];

  ChallengeDao get challengeDao => AppDatabase.instance.challengeDao;

  ChallengesProfile? get profile => _profile;

  List<ProfileUpgrade> get allowedUpgrades => ProfileUpgrade.upgrades
      .where(
        (upgrade) =>
            upgrade.levelToActivate <= profile!.level + 1 && !_activatedUpgrades.map((u) => u.id).contains(upgrade.id),
      )
      .toList();

  ChallengesProfileService() {
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Try to load profile string from prefs and parse to user profile if possible.
    var parsedProfile = _prefs?.getString(profileKey);
    if (parsedProfile == null) return;
    _profile = ChallengesProfile.fromJson(jsonDecode(parsedProfile));
    var activatedUpgrades = _prefs!.getStringList(activatedUpgradesKey) ?? [];
    _activatedUpgrades = activatedUpgrades.map((e) => ProfileUpgrade.fromJson(jsonDecode(e))).toList();
    // If a profile was loaded, start the database stream of rides, to update the profile according to the challenges.
    startDatabaseStreams();
  }

  /// Create a user profile with a given username and save in shared prefs.
  Future<bool> createProfile() async {
    if (_profile != null) return false;
    // Create profile and set join date to now.
    _profile = ChallengesProfile();
    // Try to save profile in shared prefs and return false if not successful.
    if (!(await _prefs?.setString(profileKey, jsonEncode(_profile!.toJson().toString())) ?? false)) {
      return false;
    }
    // Start the database stream of rides, to update the profile data accordingly.
    startDatabaseStreams();
    return true;
  }

  /// Start challenges database stream to update user profile accordingly.
  void startDatabaseStreams() {
    // Only challenges which are closed and completed, since open challenges are not regarded for the rewards yet.
    challengeDao.streamClosedCompletedChallenges().listen((update) => updateRewards(update));
  }

  /// Update profile data stored in shared prefs and notify listeners.
  Future<void> storeProfile() async {
    // Update profile in shared preferences.
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

  void levelUp(ProfileUpgrade? upgrade) {
    _profile!.level = min(_profile!.level + 1, levels.length - 1);
    if (allowedUpgrades.isNotEmpty) {
      var newUpgrade = upgrade ?? allowedUpgrades.first;
      if (newUpgrade.type == ProfileUpgradeType.addDailyChoice) {
        profile!.dailyChallengeChoices += 1;
      } else if (newUpgrade.type == ProfileUpgradeType.addWeeklyChoice) {
        profile!.weeklyChallengeChoices += 1;
      }
      _activatedUpgrades.add(newUpgrade);
      updateUpgrades();
    }
    storeProfile();
  }

  void updateUpgrades() {
    _prefs!.setStringList(
      activatedUpgradesKey,
      _activatedUpgrades
          .map(
            (upgrade) => jsonEncode(
              upgrade.toJson(),
            ),
          )
          .toList(),
    );
  }

  Future<void> resetChallenges() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_profile == null) return;
    _profile = ChallengesProfile();
    _activatedUpgrades.clear();
    _prefs!.remove(activatedUpgradesKey);
    storeProfile();
    challengeDao.clearObjects();
  }

  Future<void> reset() async {
    _prefs ??= await SharedPreferences.getInstance();
    _profile = null;
    _activatedUpgrades.clear();
    _prefs!.remove(activatedUpgradesKey);
    _prefs!.remove(profileKey);
    challengeDao.clearObjects();
    notifyListeners();
  }
}
