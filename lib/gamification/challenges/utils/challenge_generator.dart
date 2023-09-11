import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
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
  daysWithGoalsCompleted,
  routeRidesPerWeek,
  routeStreakInWeek,
}

/// Helper object which describes a possible range of values for a challenge target.
class ValueRange {
  final int min;
  final int max;
  final int stepsize;

  ValueRange.fromMax(int maxVal, this.stepsize)
      : max = math.max(maxVal, 1),
        min = math.max((maxVal ~/ 3) * 2, 1);

  int getRandomValue() {
    return math.Random().nextInt(max - min + 1) + min;
  }

  int getXpForValue(int minXp, int xpStepSize, int maxSteps, int value) {
    if (max == min) return minXp + maxSteps * xpStepSize;
    if (value == min) return minXp;
    return minXp + ((value - min) / (max - min) * maxSteps).round() * xpStepSize;
  }
}

/// A class that implements this class can be used, to generate a new challenge according to the user goals.
abstract class ChallengeGenerator {
  static IconData getChallengeIcon(Challenge challenge) {
    if (challenge.isWeekly) {
      var type = WeeklyChallengeType.values.elementAt(challenge.type);
      if (type == WeeklyChallengeType.overallDistance) return CustomGameIcons.distance_trophy;
      if (type == WeeklyChallengeType.daysWithGoalsCompleted) return CustomGameIcons.explore_trophy;
      if (type == WeeklyChallengeType.routeRidesPerWeek) return CustomGameIcons.map_trophy;
      if (type == WeeklyChallengeType.routeStreakInWeek) return CustomGameIcons.map_trophy;

      return CustomGameIcons.blank_trophy;
    } else {
      var type = DailyChallengeType.values.elementAt(challenge.type);
      if (type == DailyChallengeType.distance) return CustomGameIcons.distance_medal;
      if (type == DailyChallengeType.duration) return CustomGameIcons.duration_medal;
      if (type == DailyChallengeType.elevation) return CustomGameIcons.elevation_medal;
      return CustomGameIcons.blank_medal;
    }
  }

  List<ChallengesCompanion> generateChallenges(int number) {
    List<ChallengesCompanion> challenges = [];
    while (challenges.length < number) {
      var newChallenge = generate();
      var similar = challenges.where((c) => c.type == newChallenge.type && c.xp == newChallenge.xp);
      if (similar.isEmpty) challenges.add(newChallenge);
    }
    return challenges;
  }

  RouteGoals? get routeGoals => getIt<GoalsService>().routeGoals;

  DailyGoals get dailyGoals => getIt<GoalsService>().dailyGoals;

  ChallengesCompanion generate();
}

/// This class can be used to generate new daily challenges.
class DailyChallengeGenerator extends ChallengeGenerator {
  final int minXP = 10;
  final int xpMaxSteps = 8;
  final int xpStepSize = 5;

  /// This function returns a fitting value range for a given challenge type and user goals.
  ValueRange getDailyChallengeValueRange(DailyChallengeType type) {
    //TODO
    if (type == DailyChallengeType.distance) {
      var max = dailyGoals.distanceMetres ~/ 500;
      return ValueRange.fromMax(max, 500);
    } else if (type == DailyChallengeType.duration) {
      var max = dailyGoals.durationMinutes ~/ 10;
      return ValueRange.fromMax(max, 10);
    } else if (type == DailyChallengeType.elevation) {
      var max = dailyGoals.distanceMetres ~/ 1000 * 3;
      return ValueRange.fromMax(max, 10);
    }
    return ValueRange.fromMax(1, 1);
  }

  /// This function returns a fitting challenge description for a given challenge type and the target value.
  String buildDescriptionDaily(DailyChallengeType type, int value) {
    if (type == DailyChallengeType.distance) {
      return 'Fahre eine Strecke von ${value / 1000} Kilometern!';
    } else if (type == DailyChallengeType.duration) {
      return 'Verbringe $value Minuten auf deinem Sattel!';
    } else if (type == DailyChallengeType.elevation) {
      return 'Bewältige einen Anstieg von $value Metern';
    }
    return '';
  }

  @override
  ChallengesCompanion generate() {
    var now = DateTime.now();
    var type = DailyChallengeType.values.elementAt(math.Random().nextInt(DailyChallengeType.values.length));
    var range = getDailyChallengeValueRange(type);
    var randomValue = range.getRandomValue();
    return ChallengesCompanion.insert(
      xp: range.getXpForValue(minXP, xpStepSize, xpMaxSteps, randomValue),
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
  final int minXP = 50;
  final int xpMaxSteps = 10;
  final int xpStepSize = 10;

  List<WeeklyChallengeType> getAllowedChallengeTypes(bool withRoutes) {
    var types = List<WeeklyChallengeType>.from(WeeklyChallengeType.values);
    if (!withRoutes) {
      types.remove(WeeklyChallengeType.routeRidesPerWeek);
      types.remove(WeeklyChallengeType.routeStreakInWeek);
    }
    return types;
  }

  /// This function returns a fitting value range for a given challenge type and user goals.
  ValueRange getWeeklyChallengeValueRange(WeeklyChallengeType type) {
    //TODO
    if (type == WeeklyChallengeType.overallDistance) {
      var max = dailyGoals.distanceMetres ~/ 500 * 5;
      return ValueRange.fromMax(max, 500);
    } else if (type == WeeklyChallengeType.routeRidesPerWeek) {
      var max = routeGoals!.numOfDays;
      return ValueRange.fromMax(max, 1);
    } else if (type == WeeklyChallengeType.routeStreakInWeek) {
      var max = routeGoals!.numOfDays;
      return ValueRange.fromMax(max, 1);
    } else if (type == WeeklyChallengeType.daysWithGoalsCompleted) {
      return ValueRange.fromMax(5, 1);
    }
    return ValueRange.fromMax(1, 1);
  }

  /// This function returns a fitting challenge description for a given challenge type and the target value.
  String buildDescriptionWeekly(WeeklyChallengeType type, int value, String? routeLabel) {
    if (type == WeeklyChallengeType.overallDistance) {
      return 'Bringe diese Woche eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == WeeklyChallengeType.routeRidesPerWeek) {
      return 'Fahre die Route $routeLabel diese Woche $value mal mit dem Rad!';
    } else if (type == WeeklyChallengeType.routeStreakInWeek) {
      return 'Fahre diese Woche an $value Tagen hintereinander die Route $routeLabel!';
    } else if (type == WeeklyChallengeType.daysWithGoalsCompleted) {
      return 'Erreiche diese Woche mindesens $value mal dein Tagesziel';
    }
    return '';
  }

  @override
  ChallengesCompanion generate() {
    var now = DateTime.now();
    var end = DateTime(now.year, now.month, now.day).add(Duration(days: 8 - now.weekday));
    var allowedTypes = getAllowedChallengeTypes(routeGoals != null && routeGoals!.numOfDays > 0);
    var type = allowedTypes.elementAt(math.Random().nextInt(allowedTypes.length));
    var range = getWeeklyChallengeValueRange(type);
    var randomValue = range.getRandomValue();
    return ChallengesCompanion.insert(
      xp: range.getXpForValue(minXP, xpStepSize, xpMaxSteps, randomValue),
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
