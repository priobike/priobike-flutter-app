import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/goals/models/user_goals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserGoalsService with ChangeNotifier {
  static const userGoalsKey = 'priobike.gamification.goals';

  /// Instance of the shared preferences.
  SharedPreferences? _prefs;

  /// The user goals for the challenges
  UserGoals? userGoals;

  UserGoals get challengeGoals => userGoals ?? UserGoals.defaultGoals;

  UserGoalsService() {
    _loadData();
  }

  /// Load the profile from shared prefs, if there is one.
  Future<void> _loadData() async {
    _prefs ??= await SharedPreferences.getInstance();

    var goalStr = _prefs!.getString(userGoalsKey);
    if (goalStr != null) userGoals = UserGoals.fromJson(jsonDecode(goalStr));
  }

  /// Update the users' challenge goals and notify listeners.
  void updateUserGoals(UserGoals? goals) {
    userGoals = goals;
    if (goals != null) {
      _prefs!.setString(userGoalsKey, jsonEncode(goals.toJson()));
    } else {
      _prefs!.remove(userGoalsKey);
    }
    notifyListeners();
  }
}
