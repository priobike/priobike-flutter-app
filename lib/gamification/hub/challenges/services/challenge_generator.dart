import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';

class ChallengeGenerator {
  static ChallengesCompanion generateDailyChallenge() {
    var now = DateTime.now();
    var dayStart = DateTime(now.year, now.month, now.day);
    return ChallengesCompanion.insert(
      xp: 150,
      start: dayStart,
      end: dayStart.add(const Duration(days: 1)),
      description: 'Fahre heute 3,5 Kilometer mit dem Rad.',
      target: 3500,
      progress: 1700,
      isWeekly: false,
      isOpen: true,
      hasBeenCompleted: false,
      type: ChallengeType.distance.index,
      valueLabel: 'm',
    );
  }

  static ChallengesCompanion generateWeeklyChallenge() {
    var now = DateTime.now();
    var dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return ChallengesCompanion.insert(
      xp: 750,
      start: dayStart,
      end: dayStart.add(const Duration(days: DateTime.daysPerWeek)),
      description: 'Fahre 5 mal diese Woche mit dem Rad zur Arbeit.',
      target: 5,
      progress: 6,
      isWeekly: true,
      isOpen: true,
      hasBeenCompleted: false,
      type: ChallengeType.rides.index,
      valueLabel: 'Fahrten',
    );
  }
}
