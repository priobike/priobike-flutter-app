import 'dart:math' as math;

import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/challenges/utils/challenge_goals.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/main.dart';

class ValueRange {
  final int min;
  final int max;
  final int stepsize;
  final int xpFactor;
  ValueRange(this.min, this.max, this.stepsize, this.xpFactor);
}

class ChallengeGenerator {
  static const List<ChallengeType> weeklyTypes = [ChallengeType.distance, ChallengeType.rides, ChallengeType.streak];
  static const List<ChallengeType> dailyTypes = [ChallengeType.distance, ChallengeType.duration];

  ValueRange getDailyChallengeValueRange(ChallengeType type, ChallengeGoals goals) {
    //TODO
    if (type == ChallengeType.distance) {
      var max = goals.dailyDistanceGoalMetres ~/ 500;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 500, 25);
    }
    if (type == ChallengeType.duration) {
      var max = goals.dailyDurationGoalMinutes ~/ 10;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 10, 25);
    }
    return ValueRange(0, 0, 0, 0);
  }

  ValueRange getWeeklyChallengeValueRange(ChallengeType type, ChallengeGoals goals) {
    //TODO
    if (type == ChallengeType.distance) {
      var max = goals.dailyDistanceGoalMetres ~/ 500 * 3;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 500, 50);
    }
    if (type == ChallengeType.rides) {
      var max = goals.trackGoal!.perWeek;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 100);
    }
    if (type == ChallengeType.streak) {
      var max = goals.trackGoal!.perWeek;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 150);
    }
    return ValueRange(0, 0, 0, 0);
  }

  String buildDescriptionDaily(ChallengeType type, int value) {
    if (type == ChallengeType.distance) {
      return 'Bringe Heute eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == ChallengeType.duration) {
      return 'Verbringe Heute $value Minuten auf deinem Sattel!';
    }
    return '';
  }

  String buildDescriptionWeekly(ChallengeType type, int value, String? routeLabel) {
    if (type == ChallengeType.distance) {
      return 'Bringe diese Woche eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == ChallengeType.rides) {
      return 'Fahre die Route $routeLabel diese Woche $value-mal mit dem Rad!';
    } else if (type == ChallengeType.streak) {
      return 'Fahre diese Woche an $value Tagen hintereinander die Route $routeLabel!';
    }
    return '';
  }

  ChallengesCompanion generateDailyChallenge() {
    var goals = getIt<GameSettingsService>().challengeGoals!;
    var now = DateTime.now();
    var begin = DateTime(now.year, now.month, now.day);
    var type = dailyTypes.elementAt(math.Random().nextInt(dailyTypes.length));
    var range = getDailyChallengeValueRange(type, goals);
    var randomValue = range.max == range.min ? range.max : math.Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      begin: begin,
      end: begin.add(const Duration(days: 1)),
      description: buildDescriptionDaily(type, randomValue * range.stepsize),
      target: randomValue * range.stepsize,
      progress: 0,
      isWeekly: false,
      isOpen: true,
      type: type.index,
      userStartTime: now,
    );
  }

  ChallengesCompanion generateWeeklyChallenge() {
    var goals = getIt<GameSettingsService>().challengeGoals!;
    var now = DateTime.now();
    var begin = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    var type = (goals.trackGoal == null)
        ? ChallengeType.distance
        : weeklyTypes.elementAt(math.Random().nextInt(weeklyTypes.length));
    var range = getWeeklyChallengeValueRange(type, goals);
    var randomValue = range.max == range.min ? range.max : math.Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      begin: begin,
      end: begin.add(const Duration(days: DateTime.daysPerWeek)),
      description: buildDescriptionWeekly(type, randomValue * range.stepsize, goals.trackGoal?.trackDescription),
      target: randomValue * range.stepsize,
      progress: 0,
      isWeekly: true,
      isOpen: true,
      type: type.index,
      userStartTime: now,
    );
  }
}
