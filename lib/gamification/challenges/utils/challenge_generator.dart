import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/main.dart';

/// This enum describes the different kind of daily challenges.
enum DailyChallengeType {
  distance,
  duration,
  elevation,
}

/// This enum describes the different kind of weekly challenges.
enum WeeklyChallengeType {
  overallDistance,
  overallDuration,
  distanceOnDays,
  durationOnDays,
  routeRidesPerWeek,
  routeStreakInWeek,
}

/// Helper object which describes a possible range of values for a challenge target.
class ValueRange {
  final int min;
  final int max;
  final int stepsize;
  final int xpFactor;
  ValueRange(this.min, this.max, this.stepsize, this.xpFactor);
}

/// A class that implements this class can be used, to generate a new challenge according to the user goals.
abstract class ChallengeGenerator {
  static IconData getChallengeIcon(Challenge challenge) {
    if (challenge.isWeekly) {
      var type = WeeklyChallengeType.values.elementAt(challenge.type);
      if (type == WeeklyChallengeType.overallDistance) return CustomGameIcons.distance_trophy;
      if (type == WeeklyChallengeType.overallDuration) return CustomGameIcons.duration_trophy;
      return CustomGameIcons.blank_trophy;
    } else {
      var type = DailyChallengeType.values.elementAt(challenge.type);
      if (type == DailyChallengeType.distance) return CustomGameIcons.distance_medal;
      if (type == DailyChallengeType.duration) return CustomGameIcons.duration_medal;
      if (type == DailyChallengeType.elevation) return CustomGameIcons.elevation_medal;
      return CustomGameIcons.blank_medal;
    }
  }

  ChallengesCompanion generate();
}

/// This class can be used to generate new daily challenges.
class DailyChallengeGenerator extends ChallengeGenerator {
  /// This function returns a fitting value range for a given challenge type and user goals.
  ValueRange getDailyChallengeValueRange(DailyChallengeType type, DailyGoals goals) {
    //TODO
    if (type == DailyChallengeType.distance) {
      var max = goals.distanceMetres ~/ 500;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 500, 25);
    }
    if (type == DailyChallengeType.duration) {
      var max = goals.durationMinutes ~/ 10;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 10, 25);
    }
    return ValueRange(0, 0, 0, 0);
  }

  /// This function returns a fitting challenge description for a given challenge type and the target value.
  String buildDescriptionDaily(DailyChallengeType type, int value) {
    if (type == DailyChallengeType.distance) {
      return 'Bringe Heute eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == DailyChallengeType.duration) {
      return 'Verbringe Heute $value Minuten auf deinem Sattel!';
    }
    return '';
  }

  @override
  ChallengesCompanion generate() {
    var goals = getIt<UserGoalsService>().dailyGoals;
    var now = DateTime.now();
    var type = DailyChallengeType.values.elementAt(math.Random().nextInt(DailyChallengeType.values.length));
    var range = getDailyChallengeValueRange(type, goals);
    var randomValue = range.max == range.min ? range.max : math.Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      startTime: now,
      closingTime: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      description: buildDescriptionDaily(type, randomValue * range.stepsize),
      target: randomValue * range.stepsize,
      progress: 0,
      isWeekly: false,
      isOpen: true,
      type: DailyChallengeType.values.indexOf(type),
    );
  }
}

class WeeklyChallengeGenerator extends ChallengeGenerator {
  List<WeeklyChallengeType> getAllowedChallengeTypes(bool withRoutes) {
    var types = List<WeeklyChallengeType>.from(WeeklyChallengeType.values);
    if (!withRoutes) {
      types.remove(WeeklyChallengeType.routeRidesPerWeek);
      types.remove(WeeklyChallengeType.routeStreakInWeek);
    }
    return types;
  }

  /// This function returns a fitting value range for a given challenge type and user goals.
  ValueRange getWeeklyChallengeValueRange(WeeklyChallengeType type, DailyGoals dailyGoals, RouteGoals? routeGoals) {
    //TODO
    if (type == WeeklyChallengeType.overallDistance) {
      var max = dailyGoals.distanceMetres ~/ 500 * 3;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 500, 50);
    }
    if (type == WeeklyChallengeType.routeRidesPerWeek) {
      var max = routeGoals!.numOfDays;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 100);
    }
    if (type == WeeklyChallengeType.routeStreakInWeek) {
      var max = routeGoals!.numOfDays;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 150);
    }
    return ValueRange(0, 0, 0, 0);
  }

  /// This function returns a fitting challenge description for a given challenge type and the target value.
  String buildDescriptionWeekly(WeeklyChallengeType type, int value, String? routeLabel) {
    if (type == WeeklyChallengeType.overallDistance) {
      return 'Bringe diese Woche eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == WeeklyChallengeType.routeRidesPerWeek) {
      return 'Fahre die Route $routeLabel diese Woche $value-mal mit dem Rad!';
    } else if (type == WeeklyChallengeType.routeStreakInWeek) {
      return 'Fahre diese Woche an $value Tagen hintereinander die Route $routeLabel!';
    }
    return '';
  }

  @override
  ChallengesCompanion generate() {
    var dailyGoals = getIt<UserGoalsService>().dailyGoals;
    var now = DateTime.now();
    var end = DateTime(now.year, now.month, now.day).add(Duration(days: 8 - now.weekday));
    var routeGoals = getIt<UserGoalsService>().routeGoals;
    var allowedTypes = getAllowedChallengeTypes(routeGoals != null && routeGoals.numOfDays > 0);
    var type = allowedTypes.elementAt(math.Random().nextInt(allowedTypes.length));
    var range = getWeeklyChallengeValueRange(type, dailyGoals, routeGoals);
    var randomValue = range.max == range.min ? range.max : math.Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      startTime: now,
      closingTime: end,
      description: buildDescriptionWeekly(type, randomValue * range.stepsize, routeGoals?.routeName),
      target: randomValue * range.stepsize,
      progress: 0,
      isWeekly: true,
      isOpen: true,
      type: WeeklyChallengeType.values.indexOf(type),
      routeId: Value(routeGoals?.routeID),
    );
  }
}
