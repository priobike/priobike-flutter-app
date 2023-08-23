import 'dart:async';

import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';

class ChallengeValidator {
  final Challenge challenge;

  late StreamSubscription streamSub;

  ChallengeValidator({required this.challenge}) {
    streamSub = AppDatabase.instance.rideSummaryDao
        .streamRidesInInterval(challenge.begin, challenge.end)
        .listen((rides) => handleUpdate(rides));
  }

  void dispose() => streamSub.cancel();

  void handleUpdate(List<RideSummary> rides) {
    // Get all rides that started after the user started the challenge.
    var relevantRides = rides.where((ride) => ride.startTime.isAfter(challenge.userStartTime)).toList();
    // Handle rides according to the challenge type.
    var type = ChallengeType.values.elementAt(challenge.type);
    if (type == ChallengeType.distance) handleDistanceChallenge(relevantRides);
    if (type == ChallengeType.duration) handleDurationChallenge(relevantRides);
    if (type == ChallengeType.rides) handleRidesChallenge(relevantRides);
    if (type == ChallengeType.streak) handleStreakChallenge(relevantRides);
  }

  void handleDistanceChallenge(List<RideSummary> rides) {
    var totalDistance = StatUtils.getListSum(rides.map((ride) => ride.distanceMetres).toList()).toInt();
    updateChallenge(totalDistance);
  }

  void handleDurationChallenge(List<RideSummary> rides) {
    var totalDuration = StatUtils.getListSum(rides.map((ride) => ride.durationSeconds).toList());
    var totalDurationMinutes = totalDuration ~/ 60;
    updateChallenge(totalDurationMinutes);
  }

  void handleRidesChallenge(List<RideSummary> rides) {}

  void handleStreakChallenge(List<RideSummary> rides) {}

  void updateChallenge(int newProgress) {
    if (challenge.progress != newProgress) {
      AppDatabase.instance.challengesDao.updateObject(
        challenge.copyWith(progress: newProgress),
      );
    }
  }
}
