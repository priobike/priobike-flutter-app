import 'dart:math';

import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';

class ValueRange {
  final int min;
  final int max;
  final int stepsize;
  final int xpFactor;
  ValueRange(this.min, this.max, this.stepsize, this.xpFactor);
}

class ChallengeGenerator {
  static ValueRange getDailyChallengeValueRange(DailyChallengeType type) {
    if (type == DailyChallengeType.distance) return ValueRange(3, 10, 500, 25);
    if (type == DailyChallengeType.duration) return ValueRange(1, 6, 15, 25);
    return ValueRange(0, 0, 0, 0);
  }

  static ValueRange getWeeklyChallengeValueRange(WeeklyChallengeType type) {
    if (type == WeeklyChallengeType.distance) return ValueRange(10, 20, 1, 50);
    if (type == WeeklyChallengeType.rides) return ValueRange(4, 6, 1, 100);
    if (type == WeeklyChallengeType.streak) return ValueRange(3, 5, 1, 150);
    return ValueRange(0, 0, 0, 0);
  }

  static String getLabel(var type) {
    if (type == DailyChallengeType.distance) return 'm';
    if (type == DailyChallengeType.duration) return 'min';
    if (type == WeeklyChallengeType.distance) return 'km';
    if (type == WeeklyChallengeType.rides) return 'Fahrten';
    if (type == WeeklyChallengeType.streak) return 'Fahrten';
    return '';
  }

  static String buildDescriptionDaily(DailyChallengeType type, int value) {
    if (type == DailyChallengeType.distance) {
      return 'Bringe Heute eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == DailyChallengeType.duration) {
      return 'Verbringe Heute $value Minuten auf deinem Sattel!';
    }
    return '';
  }

  static String buildDescriptionWeekly(WeeklyChallengeType type, int value) {
    if (type == WeeklyChallengeType.distance) {
      return 'Bringe diese Woche eine Strecke von $value Kilometern hinter Dich!';
    } else if (type == WeeklyChallengeType.rides) {
      return 'Fahre diese Woche $value-mal mit dem Rad zur Arbeit!';
    } else if (type == WeeklyChallengeType.streak) {
      return 'Fahre diese Woche an $value Tagen hintereinander mit dem Rad zur Arbeit!';
    }
    return '';
  }

  static ChallengesCompanion generateDailyChallenge() {
    var now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    var type = DailyChallengeType.values.elementAt(Random().nextInt(DailyChallengeType.values.length));
    var range = getDailyChallengeValueRange(type);
    var randomValue = Random().nextInt(range.max - range.min) + range.min;
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

  static ChallengesCompanion generateWeeklyChallenge() {
    var now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    var type = WeeklyChallengeType.values.elementAt(Random().nextInt(WeeklyChallengeType.values.length));
    var range = getWeeklyChallengeValueRange(type);
    var randomValue = Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      start: start,
      end: start.add(const Duration(days: DateTime.daysPerWeek)),
      description: buildDescriptionWeekly(type, randomValue * range.stepsize),
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
