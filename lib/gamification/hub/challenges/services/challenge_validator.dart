import 'dart:async';

import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';

class ChallengeValidator {
  final Challenge challenge;

  late StreamSubscription streamSub;

  ChallengeValidator({required this.challenge}) {
    var rideDao = AppDatabase.instance.rideSummaryDao;
    Stream<List<RideSummary>> rideStream;
    Future<List<RideSummary>> rideFuture;
    var now = DateTime.now();
    if (challenge.isWeekly) {
      rideFuture = rideDao.getRidesInWeek(now);
      rideStream = rideDao.streamRidesInWeek(now);
    } else {
      rideFuture = rideDao.getRidesOnDay(now);
      rideStream = rideDao.streamRidesOnDay(DateTime.now());
    }
    rideFuture.then((rides) => handleUpdate(rides));
    streamSub = rideStream.listen((rides) => handleUpdate(rides));
  }

  void dispose() => streamSub.cancel();

  void handleUpdate(List<RideSummary> rides) {
    var type = ChallengeType.values.elementAt(challenge.type);
    if (type == ChallengeType.distance) handleDistanceChallenge(rides);
    if (type == ChallengeType.duration) handleDurationChallenge(rides);
    if (type == ChallengeType.rides) handleRidesChallenge(rides);
    if (type == ChallengeType.streak) handleStreakChallenge(rides);
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
