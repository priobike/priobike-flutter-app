import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/challenges/models/challenge_goals.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This services manages the game settings of the user.
class GameSettingsService with ChangeNotifier {
  static const enabledFeatureListKey = 'priobike.game.prefs.enabledFeatures';
  static const gameFeatureStatisticsKey = 'priobike.game.features.statistics';
  static const gameFeatureChallengesKey = 'priobike.game.features.challenges';
  static const challengeGoalsKey = 'priobike.game.challenges.goals';

  /// Map of the feature keys to describing labels.
  static Map<String, String> get gameFeaturesLabelMap => {
        gameFeatureChallengesKey: 'PrioBike Challenges',
        gameFeatureStatisticsKey: 'Fahrtstatistiken',
      };

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

  GameSettingsService() {
    _loadSettings();
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

  /// Load settings from shared preferences and store in local variables.
  void _loadSettings() async {
    _prefs ??= await SharedPreferences.getInstance();
    _enabledFeatures = _prefs!.getStringList(enabledFeatureListKey) ?? [];

    var goalStr = _prefs!.getString(challengeGoalsKey);
    if (goalStr != null) _challengeGoals = UserGoals.fromJson(jsonDecode(goalStr));
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

  void reset() {
    _enabledFeatures.clear();
    notifyListeners();
  }
}
