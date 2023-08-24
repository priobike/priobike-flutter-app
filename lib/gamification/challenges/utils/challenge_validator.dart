import 'dart:async';

import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/common/utils.dart';

/// This class continously checks the progress of a specific challenge, by listening to the finished rides in the db.
class ChallengeValidator {
  /// The challenge that needs to be validated.
  final Challenge challenge;

  /// Stream sub of the db stream, to cancel it if not needed anymore.
  late StreamSubscription streamSub;

  /// This bool determines, whether to start the stream of rides automatically.
  final bool startStream;

  ChallengeValidator({required this.challenge, this.startStream = true}) {
    if (startStream) {
      // Listen to rides in the challenge interval and call validate if needed.
      streamSub = AppDatabase.instance.rideSummaryDao
          .streamRidesInInterval(challenge.begin, challenge.end)
          .listen((rides) => validate(rides));
    }
  }

  /// Call this function when the validator is not needed anymore and the ride stream can be cancelt.
  void dispose() => streamSub.cancel();

  /// Updates the progress of the validators challenge according to a given list of rides.
  Future<void> validate(List<RideSummary> rides) async {
    // Get all rides that started after the user started the challenge.
    var relevantRides = rides.where((ride) => ride.startTime.isAfter(challenge.userStartTime)).toList();
    // Handle rides according to the challenge type.
    var type = ChallengeType.values.elementAt(challenge.type);
    if (type == ChallengeType.distance) await _handleDistanceChallenge(relevantRides);
    if (type == ChallengeType.duration) await _handleDurationChallenge(relevantRides);
    if (type == ChallengeType.rides) await _handleRidesChallenge(relevantRides);
    if (type == ChallengeType.streak) await _handleStreakChallenge(relevantRides);
  }

  /// Update challenge progress according to the ride distances.
  Future<void> _handleDistanceChallenge(List<RideSummary> rides) async {
    var totalDistance = Utils.getListSum(rides.map((ride) => ride.distanceMetres).toList()).toInt();
    return _updateChallenge(totalDistance);
  }

  /// Update challenge progress according to the ride durations.
  Future<void> _handleDurationChallenge(List<RideSummary> rides) async {
    var totalDuration = Utils.getListSum(rides.map((ride) => ride.durationSeconds).toList());
    var totalDurationMinutes = totalDuration ~/ 60;
    return _updateChallenge(totalDurationMinutes);
  }

  Future<void> _handleRidesChallenge(List<RideSummary> rides) async {}

  Future<void> _handleStreakChallenge(List<RideSummary> rides) async {}

  /// Update the progress value of a challenge and store in database.
  Future<void> _updateChallenge(int newProgress) async {
    if (challenge.progress != newProgress) {
      await AppDatabase.instance.challengesDao.updateObject(
        challenge.copyWith(progress: newProgress),
      );
    }
  }
}
