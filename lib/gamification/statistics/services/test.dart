import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/main.dart';

enum StatType {
  distance,
  duration,
  elevationGain,
  elevationLoss,
  speed,
}

abstract class RideStats {
  final double distanceMetres;

  final double durationMinutes;

  final double elevationGainMetres;

  final double elevationLossMetres;

  final double averageSpeedKmh;

  double? distanceGoalMetres;

  double? durationGoalMinutes;

  RideStats.fromSummaries(List<RideSummary> rides)
      : distanceMetres = Utils.getListSum(rides.map((r) => r.distanceMetres).toList()),
        durationMinutes = Utils.getListSum(rides.map((r) => r.durationSeconds / 60).toList()),
        elevationGainMetres = Utils.getListSum(rides.map((r) => r.elevationGainMetres).toList()),
        elevationLossMetres = Utils.getListSum(rides.map((r) => r.elevationLossMetres).toList()),
        averageSpeedKmh = Utils.getListAvg(rides.map((r) => r.averageSpeedKmh).toList());

  RideStats.fromStats(List<RideStats> stats)
      : distanceMetres = Utils.getListSum(stats.map((s) => s.distanceMetres).toList()),
        durationMinutes = Utils.getListSum(stats.map((s) => s.durationMinutes).toList()),
        elevationGainMetres = Utils.getListSum(stats.map((s) => s.elevationGainMetres).toList()),
        elevationLossMetres = Utils.getListSum(stats.map((s) => s.elevationLossMetres).toList()),
        averageSpeedKmh = Utils.getListAvg(stats.map((s) => s.averageSpeedKmh).toList()) {
    distanceGoalMetres = Utils.getListSum(stats.map((s) => s.distanceGoalMetres).whereType<double>().toList());
    durationGoalMinutes = Utils.getListSum(stats.map((s) => s.durationGoalMinutes).whereType<double>().toList());
  }

  double getStatFromType(StatType type) {
    if (type == StatType.distance) return distanceMetres;
    if (type == StatType.duration) return durationMinutes;
    if (type == StatType.elevationGain) return elevationGainMetres;
    if (type == StatType.elevationLoss) return elevationLossMetres;
    if (type == StatType.speed) return averageSpeedKmh;
    return 0;
  }

  double? getGoalFromType(StatType type) {
    if (type == StatType.distance) return distanceGoalMetres;
    if (type == StatType.duration) return durationGoalMinutes;
    return null;
  }
}

class DayStats extends RideStats {
  final DateTime date;

  final List<RideSummary> rides;

  DayStats(int year, int month, int day, this.rides, DailyGoals? goals)
      : date = DateTime(year, month, day),
        super.fromSummaries(rides) {
    setGoals(goals);
  }

  DayStats.empty(int year, int month, int day)
      : date = DateTime(year, month, day),
        rides = [],
        super.fromSummaries([]);

  void setGoals(DailyGoals? goals) {
    if (goals != null && goals.weekdays[date.weekday - 1]) {
      distanceGoalMetres = goals.distanceMetres;
      durationGoalMinutes = goals.durationMinutes;
    } else {
      distanceGoalMetres = null;
      durationGoalMinutes = null;
    }
  }
}

class ListOfRideStats<T extends RideStats> extends RideStats {
  final List<T> list;

  final double avgDistanceMetres;

  final double avgDurationMinutes;

  final double avgElevationGainMetres;

  final double avgElevationLossMetres;

  ListOfRideStats(this.list)
      : avgDistanceMetres = list.map((d) => d.distanceMetres).average,
        avgDurationMinutes = list.map((d) => d.durationMinutes).average,
        avgElevationGainMetres = list.map((d) => d.elevationGainMetres).average,
        avgElevationLossMetres = list.map((d) => d.elevationLossMetres).average,
        super.fromStats(list);

  double getMaxForType(StatType type) {
    List<double> values = [];
    if (type == StatType.distance) {
      values = list.map((day) => day.distanceMetres).toList() + list.map((day) => day.distanceGoalMetres ?? 0).toList();
    } else if (type == StatType.duration) {
      values = list.map((day) => day.distanceMetres).toList() + list.map((day) => day.distanceGoalMetres ?? 0).toList();
    } else if (type == StatType.elevationGain) {
      values = list.map((day) => day.elevationGainMetres).toList();
    } else if (type == StatType.elevationLoss) {
      values = list.map((day) => day.elevationLossMetres).toList();
    } else if (type == StatType.speed) {
      values = list.map((day) => day.averageSpeedKmh).toList();
    }
    return values.maxOrNull ?? 0;
  }

  double getAvgFromType(StatType type) {
    if (type == StatType.distance) return avgDistanceMetres;
    if (type == StatType.duration) return avgDurationMinutes;
    if (type == StatType.elevationGain) return avgElevationGainMetres;
    if (type == StatType.elevationLoss) return avgElevationLossMetres;
    if (type == StatType.speed) return averageSpeedKmh;
    return 0;
  }
}

class WeekStats extends ListOfRideStats<DayStats> {
  final DateTime mondayDate;

  WeekStats(List<DayStats> days)
      : mondayDate = days.first.date,
        super(days);
}

class MonthStats extends ListOfRideStats<DayStats> {
  final int year;

  final int month;

  MonthStats(List<DayStats> days)
      : year = days.first.date.year,
        month = days.first.date.month,
        super(days);
}

class StatisticsViewModel with ChangeNotifier {
  static const Duration oneDay = Duration(days: 1);

  final UserGoalsService goalsService = getIt<UserGoalsService>();

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
      log.e("while 1");
      List<DayStats> stats = [];
      var weekday = monday;
      for (int i = 0; i < DateTime.daysPerWeek; i++) {
        var weekdayStats = days.firstWhere((day) => sameDay(day.date, weekday),
            orElse: () => DayStats.empty(weekday.year, weekday.month, weekday.day));
        stats.add(weekdayStats);
        weekday.add(oneDay);
      }
      weeks.add(WeekStats(stats));
      monday = weekday.add(oneDay);
    }
  }

  void updateMonths() {
    months.clear();
    var firstDayOfMonth = DateTime(startDate.year, startDate.month, 1);
    while (!firstDayOfMonth.isAfter(endDate)) {
      log.e("while 2");
      List<DayStats> stats = [];
      var tmpDay = firstDayOfMonth;
      while (tmpDay.month == firstDayOfMonth.month) {
        var dayStats = days.firstWhere((day) => sameDay(day.date, tmpDay),
            orElse: () => DayStats.empty(tmpDay.year, tmpDay.month, tmpDay.day));
        stats.add(dayStats);
        tmpDay.add(oneDay);
        log.e("while 2.1");
      }
      months.add(MonthStats(stats));
      firstDayOfMonth = tmpDay;
    }
  }

  bool sameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year && day1.month == day2.month && day1.day == day2.day;
  }

  List<DateTime> get daysInTimeFrame {
    List<DateTime> days = [];
    var tmpDate = startDate;
    while (!tmpDate.isAfter(endDate)) {
      log.e('while 0');
      days.add(tmpDate);
      tmpDate.add(oneDay);
    }
    return days;
  }
}
