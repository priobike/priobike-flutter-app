import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/main.dart';

class StatisticsViewModel with ChangeNotifier {
  static const Duration oneDay = Duration(days: 1);

  final GoalsService goalsService = getIt<GoalsService>();

  StreamSubscription? rideStream;

  DateTime startDate;

  DateTime endDate;

  List<DayStats> days = [];

  List<WeekStats> weeks = [];

  List<MonthStats> months = [];

  int? _selectedDay;

  int? get selectedDay => _selectedDay;

  DailyGoals? get goals => goalsService.dailyGoals;

  StatisticsViewModel({
    required this.startDate,
    required this.endDate,
  }) {
    updateRides([]);
    goalsService.addListener(updateGoals);
    rideStream = AppDatabase.instance.rideSummaryDao
        .streamRidesInInterval(startDate, endDate)
        .listen((rides) => updateRides(rides));
  }

  @override
  void dispose() {
    rideStream?.cancel();
    goalsService.removeListener(updateGoals);
    super.dispose();
  }

  void setSelectedDay(int? day) {
    _selectedDay = day;
    notifyListeners();
  }

  void updateGoals() {
    for (var day in days) {
      day.setGoals(goals);
    }
    updateWeeks();
    updateMonths();
    notifyListeners();
  }

  void updateRides(List<RideSummary> rides) {
    days.clear();
    for (var day in daysInTimeFrame) {
      var ridesOnDay = rides.where((ride) {
        var rideDay = ride.startTime;
        return rideDay.year == day.year && rideDay.month == day.month && rideDay.day == day.day;
      }).toList();
      days.add(DayStats(day.year, day.month, day.day, ridesOnDay, goals));
    }
    updateWeeks();
    updateMonths();
    notifyListeners();
  }

  void updateWeeks() {
    weeks.clear();
    var monday = startDate.subtract(Duration(days: startDate.weekday - 1));
    while (!monday.isAfter(endDate)) {
      List<DayStats> stats = [];
      var tmpDay = monday;
      for (int i = 0; i < DateTime.daysPerWeek; i++) {
        var weekdayStats = days.firstWhere((day) => day.isOnDay(tmpDay),
            orElse: () => DayStats.empty(tmpDay.year, tmpDay.month, tmpDay.day, goals));
        stats.add(weekdayStats);
        tmpDay = tmpDay.add(oneDay);
      }
      weeks.add(WeekStats(stats));
      monday = tmpDay;
    }
  }

  void updateMonths() {
    months.clear();
    var firstDayOfMonth = DateTime(startDate.year, startDate.month, 1);
    while (!firstDayOfMonth.isAfter(endDate)) {
      List<DayStats> stats = [];
      var tmpDay = firstDayOfMonth;
      while (tmpDay.month == firstDayOfMonth.month) {
        var dayStats = days.firstWhere((day) => day.isOnDay(tmpDay),
            orElse: () => DayStats.empty(tmpDay.year, tmpDay.month, tmpDay.day, goals));
        stats.add(dayStats);
        tmpDay = tmpDay.add(oneDay);
      }
      months.add(MonthStats(stats));
      firstDayOfMonth = DateTime(tmpDay.year, tmpDay.month, 1);
    }
  }

  List<DateTime> get daysInTimeFrame {
    List<DateTime> days = [];
    var tmpDate = startDate;
    while (!tmpDate.isAfter(endDate)) {
      days.add(tmpDate);
      tmpDate = tmpDate.add(oneDay);
    }
    return days;
  }
}
