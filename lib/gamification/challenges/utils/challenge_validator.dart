import 'dart:async';

import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
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
      if (type == WeeklyChallengeType.daysWithGoalsCompleted) await _handleDailyGoalsWeeklyChallenge(rides);
      if (type == WeeklyChallengeType.routeRidesPerWeek) await _handleRidesOnRouteChallenge(rides);
      if (type == WeeklyChallengeType.routeStreakInWeek) await _handleStreakChallenge(rides);
    } else {
      var type = DailyChallengeType.values.elementAt(_challenge.type);
      if (type == DailyChallengeType.distance) await _handleDistanceChallenge(rides);
      if (type == DailyChallengeType.duration) await _handleDurationChallenge(rides);
      if (type == DailyChallengeType.dailyGoals) await _handleDailyGoalsChallenge(rides);
      if (type == DailyChallengeType.routeGoal) await _handleRidesOnRouteChallenge(rides);
    }
  }

  /// Update challenge progress according to the overall ride distances.
  Future<void> _handleDailyGoalsChallenge(List<RideSummary> rides) async {
    var goals = getIt<GoalsService>().dailyGoals;
    if (goals == null) return;

    var stats = RideStats.fromSummaries(rides);

    if (stats.distanceKilometres >= goals.distanceMetres / 1000 && stats.durationMinutes >= goals.durationMinutes) {
      _updateChallenge(1);
    }

    _updateChallenge(0);
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

  /// Update challenge progress according to the number of rides on the challenge route.
  Future<void> _handleRidesOnRouteChallenge(List<RideSummary> rides) async {
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

    var streak = 0;
    final today = DateTime.now();
    // Iterate through all the days of the challenge interval, till the end of the interval or the current time
    // and increase the streak value accordingly.
    while (end.isBefore(_challenge.closingTime)) {
      var ridesInInterval = ridesWithShortcut.where(
        (ride) => ride.startTime.isAfter(start) && ride.startTime.isBefore(end),
      );
      // Update streak, if user drove the route on the checked day.
      if (ridesInInterval.isNotEmpty) streak++;
      // End while loop, if the user reached the target value.
      if (streak >= _challenge.target) break;
      // End while loop, if the current day is checked, since future dates do not need to be checked.
      if (today.isAfter(start) && today.isBefore(end)) break;
      // Reset streak, if the checked date is not the current date and there are no rides on the route.
      if (ridesInInterval.isEmpty) streak = 0;
      // Increase the checked date.
      start = start.add(const Duration(days: 1));
      end = end.add(const Duration(days: 1));
    }

    _updateChallenge(streak);
  }

  /// Update challenge progress according to the daily goals of the user and the corresponding ride values.
  Future<void> _handleDailyGoalsWeeklyChallenge(List<RideSummary> rides) async {
    // Get start and endtime of the first day of the challenge interval.
    var start = DateTime(_challenge.startTime.year, _challenge.startTime.month, _challenge.startTime.day);
    var end = start.add(const Duration(days: 1));

    // Iterate through all the days of the challenge interval, till the end of the interval or the current time
    // and count the days where the daily goals were completed.
    var goals = getIt<GoalsService>().dailyGoals ?? DailyGoals.defaultGoals;
    var daysWithGoalsCompleted = 0;
    while (!(end.isAfter(_challenge.closingTime) || start.isAfter(DateTime.now()))) {
      var ridesOnDay = rides.where((ride) => ride.startTime.isAfter(start) && ride.startTime.isBefore(end)).toList();
      var stats = RideStats.fromSummaries(ridesOnDay);
      if (stats.distanceKilometres >= goals.distanceMetres / 1000 && stats.durationMinutes >= goals.durationMinutes) {
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
