import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/main.dart';

/// This viewmodel aggregates and managages statistics for all rides the user has made in a given timeframe.
class StatisticsViewModel with ChangeNotifier {
  /// Just a duration of one day.
  static const Duration _oneDay = Duration(days: 1);

  /// Goal service to update the saved daily goals accordingly.
  final GoalsService _goalsService = getIt<GoalsService>();

  /// Ride stream to listen for all the rides the user has made and update the statistics accordingly.
  StreamSubscription? _rideStream;

  /// The start date of the time frame to be observed.
  DateTime startDate;

  /// The end date of the time frame to be observed.
  DateTime endDate;

  /// The daily stats of all days in the observed timeframe.
  List<DayStats> days = [];

  /// The stats of all weeks in the observed timeframe.
  List<WeekStats> weeks = [];

  /// The stats of all months in the observed timeframe.
  List<MonthStats> months = [];

  /// The current daily distance and duration goals of the user.
  DailyGoals? get _goals => _goalsService.dailyGoals;

  /// Just a helper function that returns a list of all dates in the timeframe to be observed by this view model.
  List<DateTime> get daysInTimeFrame {
    List<DateTime> days = [];
    var tmpDate = startDate;
    while (!tmpDate.isAfter(endDate)) {
      days.add(tmpDate);
      tmpDate = tmpDate.add(_oneDay);
    }
    return days;
  }

  StatisticsViewModel({
    required this.startDate,
    required this.endDate,
  }) {
    /// First fill up the days and rides list.
    updateRides([]);

    /// Then listen to changes in goals and rides and update the lists accordingly.
    _goalsService.addListener(updateGoals);
    _rideStream = AppDatabase.instance.rideSummaryDao
        .streamRidesInInterval(startDate, endDate.add(_oneDay))
        .listen((rides) => updateRides(rides));
  }

  /// End the data streams and dispose the change notifier.
  @override
  void dispose() {
    _rideStream?.cancel();
    _goalsService.removeListener(updateGoals);
    super.dispose();
  }

  /// Update the saved days, weeks, and months according to new daily goals.
  void updateGoals() {
    for (var day in days) {
      day.setGoals(_goals);
    }
    updateWeeks();
    updateMonths();
    notifyListeners();
  }

  /// Update the saved days, weeks and months according to new ride data.
  void updateRides(List<RideSummary> rides) {
    days.clear();
    for (var day in daysInTimeFrame) {
      var ridesOnDay = rides.where((ride) {
        var rideDay = ride.startTime;
        return rideDay.year == day.year && rideDay.month == day.month && rideDay.day == day.day;
      }).toList();
      days.add(DayStats(day.year, day.month, day.day, ridesOnDay, _goals));
    }
    updateWeeks();
    updateMonths();
    notifyListeners();
  }

  /// Update the saved weeks according to the saved days.
  void updateWeeks() {
    weeks.clear();
    var monday = startDate.subtract(Duration(days: startDate.weekday - 1));
    while (!monday.isAfter(endDate)) {
      List<DayStats> stats = [];
      var tmpDay = monday;
      for (int i = 0; i < DateTime.daysPerWeek; i++) {
        var weekdayStats = days.firstWhere((day) => day.isOnDay(tmpDay),
            orElse: () => DayStats.empty(tmpDay.year, tmpDay.month, tmpDay.day, _goals));
        stats.add(weekdayStats);
        tmpDay = tmpDay.add(_oneDay);
      }
      weeks.add(WeekStats(stats));
      monday = tmpDay;
    }
  }

  /// Update the saved months according to the saved days.
  void updateMonths() {
    months.clear();
    var firstDayOfMonth = DateTime(startDate.year, startDate.month, 1);
    while (!firstDayOfMonth.isAfter(endDate)) {
      List<DayStats> stats = [];
      var tmpDay = firstDayOfMonth;
      while (tmpDay.month == firstDayOfMonth.month) {
        var dayStats = days.firstWhere((day) => day.isOnDay(tmpDay),
            orElse: () => DayStats.empty(tmpDay.year, tmpDay.month, tmpDay.day, _goals));
        stats.add(dayStats);
        tmpDay = tmpDay.add(_oneDay);
      }
      months.add(MonthStats(stats));
      firstDayOfMonth = DateTime(tmpDay.year, tmpDay.month, 1);
    }
  }
}
