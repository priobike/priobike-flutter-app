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
  static ValueRange getDailyChallengeValueRange(ChallengeType type) {
    if (type == ChallengeType.distance) return ValueRange(3, 10, 500, 25);
    if (type == ChallengeType.duration) return ValueRange(1, 6, 15, 25);
    if (type == ChallengeType.rides) return ValueRange(1, 2, 1, 100);
    return ValueRange(0, 0, 0, 0);
  }

  static ValueRange getWeeklyChallengeValueRange(ChallengeType type) {
    if (type == ChallengeType.distance) return ValueRange(10, 20, 1000, 50);
    if (type == ChallengeType.duration) return ValueRange(2, 4, 60, 100);
    if (type == ChallengeType.rides) return ValueRange(4, 6, 1, 100);
    return ValueRange(0, 0, 0, 0);
  }

  static String getLabel(ChallengeType type) {
    if (type == ChallengeType.distance) return 'm';
    if (type == ChallengeType.duration) return 'min';
    if (type == ChallengeType.rides) return 'Fahrten';
    return '';
  }

  static String buildDescription(ChallengeType type, int value, bool isWeekly) {
    var timeDesc = isWeekly ? 'diese Woche' : 'Heute';
    if (type == ChallengeType.distance) {
      return 'Bringe $timeDesc eine Strecke von ${value / 1000} Kilometern hinter Dich!';
    } else if (type == ChallengeType.duration) {
      return 'Verbringe $timeDesc $value Minuten auf deinem Sattel!';
    } else if (type == ChallengeType.rides) {
      return 'Fahre $timeDesc $value-mal mit dem Fahrrad zur Arebit!';
    }
    return '';
  }

  static ChallengesCompanion generateDailyChallenge() {
    var now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    var type = ChallengeType.values.elementAt(Random().nextInt(ChallengeType.values.length));
    var range = getDailyChallengeValueRange(type);
    var randomValue = Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      start: start,
      end: start.add(const Duration(days: 1)),
      description: buildDescription(type, randomValue * range.stepsize, false),
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
    var type = ChallengeType.values.elementAt(Random().nextInt(ChallengeType.values.length));
    var range = getWeeklyChallengeValueRange(type);
    var randomValue = Random().nextInt(range.max - range.min) + range.min;
    return ChallengesCompanion.insert(
      xp: randomValue * range.xpFactor,
      start: start,
      end: start.add(const Duration(days: DateTime.daysPerWeek)),
      description: buildDescription(type, randomValue * range.stepsize, true),
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
