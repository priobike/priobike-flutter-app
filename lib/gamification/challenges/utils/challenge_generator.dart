import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/main.dart';

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
      var type = WeeklyChallengeGenerator.weeklyTypes.elementAt(challenge.type);
      if (type == ChallengeType.overallDistance) return CustomGameIcons.distance_trophy;
      if (type == ChallengeType.overallDuration) return CustomGameIcons.duration_trophy;
      return CustomGameIcons.blank_trophy;
    } else {
      var type = DailyChallengeGenerator.dailyTypes.elementAt(challenge.type);
      if (type == ChallengeType.overallDistance) return CustomGameIcons.distance_medal;
      if (type == ChallengeType.overallDuration) return CustomGameIcons.duration_medal;
      return CustomGameIcons.blank_medal;
    }
  }

  ChallengesCompanion generate();
}

/// This class can be used to generate new daily challenges.
class DailyChallengeGenerator extends ChallengeGenerator {
  /// The challenge types, which a daily challenge can be.
  static const List<ChallengeType> dailyTypes = [ChallengeType.overallDistance, ChallengeType.overallDuration];

  /// This function returns a fitting value range for a given challenge type and user goals.
  ValueRange getDailyChallengeValueRange(ChallengeType type, DailyGoals goals) {
    //TODO
    if (type == ChallengeType.overallDistance) {
      var max = goals.distanceMetres ~/ 500;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 500, 25);
    }
    if (type == ChallengeType.overallDuration) {
      var max = goals.durationMinutes ~/ 10;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 10, 25);
    }
    return ValueRange(0, 0, 0, 0);
  }

  /// This function returns a fitting challenge description for a given challenge type and the target value.
  String buildDescriptionDaily(ChallengeType type, int value) {
    if (type == ChallengeType.overallDistance) {
      return 'Bringe Heute eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == ChallengeType.overallDuration) {
      return 'Verbringe Heute $value Minuten auf deinem Sattel!';
    }
    return '';
  }

  @override
  ChallengesCompanion generate() {
    var goals = getIt<UserGoalsService>().dailyGoals;
    var now = DateTime.now();
    var type = dailyTypes.elementAt(math.Random().nextInt(dailyTypes.length));
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
      type: dailyTypes.indexOf(type),
    );
  }
}

class WeeklyChallengeGenerator extends ChallengeGenerator {
  /// The challenge types, which a weekly challenge can be.
  static const List<ChallengeType> weeklyTypes = [
    ChallengeType.overallDistance,
    ChallengeType.routeRidesPerWeek,
    ChallengeType.routeStreakInWeek
  ];

  /// This function returns a fitting value range for a given challenge type and user goals.
  ValueRange getWeeklyChallengeValueRange(ChallengeType type, DailyGoals dailyGoals, RouteGoals? routeGoals) {
    //TODO
    if (type == ChallengeType.overallDistance) {
      var max = dailyGoals.distanceMetres ~/ 500 * 3;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 500, 50);
    }
    if (type == ChallengeType.routeRidesPerWeek) {
      var max = routeGoals!.numOfDays;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 100);
    }
    if (type == ChallengeType.routeStreakInWeek) {
      var max = routeGoals!.numOfDays;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 150);
    }
    return ValueRange(0, 0, 0, 0);
  }

  /// This function returns a fitting challenge description for a given challenge type and the target value.
  String buildDescriptionWeekly(ChallengeType type, int value, String? routeLabel) {
    if (type == ChallengeType.overallDistance) {
      return 'Bringe diese Woche eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == ChallengeType.routeRidesPerWeek) {
      return 'Fahre die Route $routeLabel diese Woche $value-mal mit dem Rad!';
    } else if (type == ChallengeType.routeStreakInWeek) {
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
    var type = (routeGoals == null || routeGoals.numOfDays == 0)
        ? ChallengeType.overallDistance
        : weeklyTypes.elementAt(math.Random().nextInt(weeklyTypes.length));
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
      type: weeklyTypes.indexOf(type),
      routeId: Value(routeGoals?.routeID),
    );
  }
}
