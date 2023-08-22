import 'dart:math' as math;

import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/hub/challenges/utils/challenge_goals.dart';
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
  ValueRange getDailyChallengeValueRange(DailyChallengeType type, ChallengeGoals goals) {
    //TODO
    if (type == DailyChallengeType.distance) {
      var max = goals.dailyDistanceGoalMetres ~/ 500;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 500, 25);
    }
    if (type == DailyChallengeType.duration) {
      var max = goals.dailyDurationGoalMinutes ~/ 10;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 10, 25);
    }
    return ValueRange(0, 0, 0, 0);
  }

  ValueRange getWeeklyChallengeValueRange(WeeklyChallengeType type, ChallengeGoals goals) {
    //TODO
    if (type == WeeklyChallengeType.distance) {
      var max = goals.dailyDistanceGoalMetres ~/ 500 * 3;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 50);
    }
    if (type == WeeklyChallengeType.rides) {
      var max = goals.trackGoal!.perWeek;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 100);
    }
    if (type == WeeklyChallengeType.streak) {
      var max = goals.trackGoal!.perWeek;
      var min = max ~/ 2;
      return ValueRange(math.max(min, 1), max, 1, 150);
    }
    return ValueRange(0, 0, 0, 0);
  }

  String getLabel(var type) {
    if (type == DailyChallengeType.distance) return 'm';
    if (type == DailyChallengeType.duration) return 'min';
    if (type == WeeklyChallengeType.distance) return 'km';
    if (type == WeeklyChallengeType.rides) return 'Fahrten';
    if (type == WeeklyChallengeType.streak) return 'Fahrten';
    return '';
  }

  String buildDescriptionDaily(DailyChallengeType type, int value) {
    if (type == DailyChallengeType.distance) {
      return 'Bringe Heute eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == DailyChallengeType.duration) {
      return 'Verbringe Heute $value Minuten auf deinem Sattel!';
    }
    return '';
  }

  String buildDescriptionWeekly(WeeklyChallengeType type, int value, String? routeLabel) {
    if (type == WeeklyChallengeType.distance) {
      return 'Bringe diese Woche eine Strecke von $value Kilometern hinter Dich!';
    } else if (type == WeeklyChallengeType.rides) {
      return 'Fahre die Route $routeLabel diese Woche $value-mal mit dem Rad!';
    } else if (type == WeeklyChallengeType.streak) {
      return 'Fahre diese Woche an $value Tagen hintereinander die Route $routeLabel!';
    }
    return '';
  }

  ChallengesCompanion generateDailyChallenge() {
    var goals = getIt<GameSettingsService>().goals!;
    var now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    var type = DailyChallengeType.values.elementAt(math.Random().nextInt(DailyChallengeType.values.length));
    var range = getDailyChallengeValueRange(type, goals);
    var randomValue = range.max == range.min ? range.max : math.Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      start: start,
      end: start.add(const Duration(days: 1)),
      description: buildDescriptionDaily(type, randomValue * range.stepsize),
      target: randomValue * range.stepsize,
      progress: 0,
      isWeekly: false,
      isOpen: true,
      hasBeenCompleted: false,
      type: type.index,
      valueLabel: getLabel(type),
    );
  }

  ChallengesCompanion generateWeeklyChallenge() {
    var goals = getIt<GameSettingsService>().goals!;
    var now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    var type = (goals.trackGoal == null)
        ? WeeklyChallengeType.distance
        : WeeklyChallengeType.values.elementAt(math.Random().nextInt(WeeklyChallengeType.values.length));
    var range = getWeeklyChallengeValueRange(type, goals);
    var randomValue = range.max == range.min ? range.max : math.Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      start: start,
      end: start.add(const Duration(days: DateTime.daysPerWeek)),
      description: buildDescriptionWeekly(type, randomValue * range.stepsize, goals.trackGoal?.trackDescription),
      target: randomValue * range.stepsize,
      progress: 0,
      isWeekly: true,
      isOpen: true,
      hasBeenCompleted: false,
      type: type.index,
      valueLabel: getLabel(type),
    );
  }
}
