import 'dart:async';

import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/main.dart';

/// This class continously checks the progress of a specific challenge, by listening to the finished rides in the db.
class ChallengeValidator {
  /// The challenge that needs to be validated.
  final Challenge _challenge;

  /// Stream sub of the db stream, to cancel it if not needed anymore.
  late StreamSubscription _streamSub;

  /// This bool determines, whether to start the stream of rides automatically.
  final bool _startStream;

  ChallengeValidator({required Challenge challenge, bool startStream = true})
      : _startStream = startStream,
        _challenge = challenge {
    if (_startStream) {
      // Listen to rides in the challenge interval and call validate if needed.
      _streamSub = AppDatabase.instance.rideSummaryDao
          .streamRidesInInterval(_challenge.startTime, _challenge.closingTime)
          .listen((rides) => validate(rides));
    }
  }

  /// Call this function when the validator is not needed anymore and the ride stream can be cancelt.
  void dispose() => _streamSub.cancel();

  /// Updates the progress of the validators challenge according to a given list of rides.
  Future<void> validate(List<RideSummary> rides) async {
    // Handle rides according to the challenge type.
    if (_challenge.isWeekly) {
      var type = WeeklyChallengeType.values.elementAt(_challenge.type);
      if (type == WeeklyChallengeType.overallDistance) await _handleDistanceChallenge(rides);
      if (type == WeeklyChallengeType.daysWithGoalsCompleted) await _handleDailyGoalsCompletedChallenge(rides);
      if (type == WeeklyChallengeType.routeRidesPerWeek) await _handleRidesChallenge(rides);
      if (type == WeeklyChallengeType.routeStreakInWeek) await _handleStreakChallenge(rides);
    } else {
      var type = DailyChallengeType.values.elementAt(_challenge.type);
      if (type == DailyChallengeType.distance) await _handleDistanceChallenge(rides);
      if (type == DailyChallengeType.duration) await _handleDurationChallenge(rides);
      if (type == DailyChallengeType.elevation) await _handleElevationChallenge(rides);
    }
  }

  /// Update challenge progress according to the overall ride distances.
  Future<void> _handleDistanceChallenge(List<RideSummary> rides) async {
    var totalDistance = ListUtils.getListSum(rides.map((ride) => ride.distanceMetres).toList()).toInt();
    return _updateChallenge(totalDistance);
  }

  /// Update challenge progress according to the overall ride durations.
  Future<void> _handleDurationChallenge(List<RideSummary> rides) async {
    var totalDuration = ListUtils.getListSum(rides.map((ride) => ride.durationSeconds).toList());
    var totalDurationMinutes = totalDuration ~/ 60;
    return _updateChallenge(totalDurationMinutes);
  }

  /// Update challenge progress according to the overall ride elevation gain.
  Future<void> _handleElevationChallenge(List<RideSummary> rides) async {
    var totalElevationGain = ListUtils.getListSum(rides.map((ride) => ride.elevationGainMetres).toList()).toInt();
    return _updateChallenge(totalElevationGain);
  }

  /// Update challenge progress according to the number of rides on the challenge route.
  Future<void> _handleRidesChallenge(List<RideSummary> rides) async {
    if (_challenge.routeId == null) return;
    var ridesWithShortcut = rides.where((ride) => ride.shortcutId == _challenge.routeId);
    _updateChallenge(ridesWithShortcut.length);
  }

  /// Update the challenge progress according to the number of rides on the challenge route on days in a row.
  Future<void> _handleStreakChallenge(List<RideSummary> rides) async {
    if (_challenge.routeId == null) return;
    var ridesWithShortcut = rides.where((ride) => ride.shortcutId == _challenge.routeId);

    // Get start and endtime of the first day of the challenge interval.
    var start = DateTime(_challenge.startTime.year, _challenge.startTime.month, _challenge.startTime.day);
    var end = start.add(const Duration(days: 1));

    // Iterate through all the days of the challenge interval, till the end of the interval or the current time
    // and increase the streak value accordingly.
    var streak = 0;
    while (!(end.isAfter(_challenge.closingTime) || start.isAfter(DateTime.now()))) {
      var ridesInInterval = ridesWithShortcut.where(
        (ride) => ride.startTime.isAfter(start) && ride.startTime.isBefore(end),
      );
      if (ridesInInterval.isEmpty) {
        streak = 0;
      } else {
        streak++;
      }
      if (streak >= _challenge.target) break;
      start = start.add(const Duration(days: 1));
      end = end.add(const Duration(days: 1));
    }

    _updateChallenge(streak);
  }

  /// Update challenge progress according to the daily goals of the user and the corresponding ride values.
  Future<void> _handleDailyGoalsCompletedChallenge(List<RideSummary> rides) async {
    if (_challenge.routeId == null) return;

    // Get start and endtime of the first day of the challenge interval.
    var start = DateTime(_challenge.startTime.year, _challenge.startTime.month, _challenge.startTime.day);
    var end = start.add(const Duration(days: 1));

    // Iterate through all the days of the challenge interval, till the end of the interval or the current time
    // and count the days where the daily goals were completed.
    var dailyGoals = getIt<GoalsService>().dailyGoals;
    var daysWithGoalsCompleted = 0;
    while (!(end.isAfter(_challenge.closingTime) || start.isAfter(DateTime.now()))) {
      var ridesOnDay = rides.where((ride) => ride.startTime.isAfter(start) && ride.startTime.isBefore(end));
      var distance = ListUtils.getListSum(ridesOnDay.map((ride) => ride.distanceMetres).toList()).toInt();
      var duration = ListUtils.getListSum(ridesOnDay.map((ride) => ride.durationSeconds).toList()).toInt() / 60;
      if (distance >= dailyGoals.distanceMetres && duration >= dailyGoals.durationMinutes) {
        daysWithGoalsCompleted++;
      }
      start = start.add(const Duration(days: 1));
      end = end.add(const Duration(days: 1));
    }

    _updateChallenge(daysWithGoalsCompleted);
  }

  /// Update the progress value of a challenge and store in database.
  Future<void> _updateChallenge(int newProgress) async {
    if (_challenge.progress != newProgress) {
      await AppDatabase.instance.challengeDao.updateObject(
        _challenge.copyWith(progress: newProgress),
      );
    }
  }
}
