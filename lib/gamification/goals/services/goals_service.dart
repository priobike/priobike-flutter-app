import 'dart:convert';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This service manages the users goal setting.
class GoalsService with ChangeNotifier {
  /// A key to store the users daily goals in the shared prefs.
  static const dailyGoalsKey = 'priobike.gamification.dailyGoals';

  /// A key to store the users route goals in the shared prefs.
  static const routeGoalsKey = 'priobike.gamification.routeGoals';

  /// Instance of the shared preferences.
  SharedPreferences? _prefs;

  /// The users daily goals.
  DailyGoals? _dailyGoals;

  /// The users goals for a specific route.
  RouteGoals? _routeGoals;

  /// Get the users daily goals, or the default goals, if they are null.
  DailyGoals? get dailyGoals => _dailyGoals;

  /// Get the users route goals or null, if there are none.
  RouteGoals? get routeGoals => _routeGoals;

  GoalsService() {
    _loadData();

    /// Listen to shortcut events and remove a route goal, if the corresponding shortcut is deleted.
    getIt<Shortcuts>().addListener(() {
      if (_routeGoals == null) return;
      var shortcuts = getIt<Shortcuts>().shortcuts ?? [];
      if (shortcuts.where((s) => s.id == _routeGoals!.routeID).isNotEmpty) return;
      updateRouteGoals(null);
    });
  }

  /// Load goal data from shared prefs.
  Future<void> _loadData() async {
    _prefs ??= await SharedPreferences.getInstance();
    var dailyGoalsJson = _prefs!.getString(dailyGoalsKey);
    if (dailyGoalsJson != null) _dailyGoals = DailyGoals.fromJson(jsonDecode(dailyGoalsJson));
    var routeGoalsJson = _prefs!.getString(routeGoalsKey);
    if (routeGoalsJson != null) _routeGoals = RouteGoals.fromJson(jsonDecode(routeGoalsJson));
  }

  /// Update daily goals according to a given goal object.
  Future<void> updateDailyGoals(DailyGoals? goals) async {
    _prefs ??= await SharedPreferences.getInstance();
    _dailyGoals = goals;
    if (goals == null) _prefs!.remove(dailyGoalsKey);
    if (goals != null) _prefs!.setString(dailyGoalsKey, jsonEncode(goals.toJson()));
    notifyListeners();
  }

  /// Update route goals according to a given goal object.
  Future<void> updateRouteGoals(RouteGoals? goals) async {
    _prefs ??= await SharedPreferences.getInstance();
    _routeGoals = goals;
    if (goals == null) _prefs!.remove(routeGoalsKey);
    if (goals != null) _prefs!.setString(routeGoalsKey, jsonEncode(goals.toJson()));
    notifyListeners();
  }

  /// Reset all user goals.
  Future<void> reset() async {
    _prefs ??= await SharedPreferences.getInstance();
    _dailyGoals = null;
    _routeGoals = null;
    _prefs!.remove(dailyGoalsKey);
    _prefs!.remove(routeGoalsKey);
    notifyListeners();
  }
}
