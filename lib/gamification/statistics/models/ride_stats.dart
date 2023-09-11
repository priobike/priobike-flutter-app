import 'package:collection/collection.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';

abstract class RideStats {
  final double distanceKilometres;

  final double durationMinutes;

  final double elevationGainMetres;

  final double elevationLossMetres;

  final double averageSpeedKmh;

  double? distanceGoalKilometres;

  double? durationGoalMinutes;

  RideStats.fromSummaries(List<RideSummary> rides)
      : distanceKilometres = Utils.getListSum(rides.map((r) => r.distanceMetres / 1000).toList()),
        durationMinutes = Utils.getListSum(rides.map((r) => r.durationSeconds / 60).toList()),
        elevationGainMetres = Utils.getListSum(rides.map((r) => r.elevationGainMetres).toList()),
        elevationLossMetres = Utils.getListSum(rides.map((r) => r.elevationLossMetres).toList()),
        averageSpeedKmh = Utils.getListAvg(rides.map((r) => r.averageSpeedKmh).toList());

  RideStats.fromStats(List<RideStats> stats)
      : distanceKilometres = Utils.getListSum(stats.map((s) => s.distanceKilometres).toList()),
        durationMinutes = Utils.getListSum(stats.map((s) => s.durationMinutes).toList()),
        elevationGainMetres = Utils.getListSum(stats.map((s) => s.elevationGainMetres).toList()),
        elevationLossMetres = Utils.getListSum(stats.map((s) => s.elevationLossMetres).toList()),
        averageSpeedKmh = Utils.getListAvg(stats.map((s) => s.averageSpeedKmh).toList()) {
    distanceGoalKilometres = Utils.getListSum(stats.map((s) => s.distanceGoalKilometres).whereType<double>().toList());
    durationGoalMinutes = Utils.getListSum(stats.map((s) => s.durationGoalMinutes).whereType<double>().toList());
  }

  double getStatFromType(StatType type) {
    if (type == StatType.distance) return distanceKilometres;
    if (type == StatType.duration) return durationMinutes;
    if (type == StatType.elevationGain) return elevationGainMetres;
    if (type == StatType.elevationLoss) return elevationLossMetres;
    if (type == StatType.speed) return averageSpeedKmh;
    return 0;
  }

  double? getGoalFromType(StatType type) {
    if (type == StatType.distance) return distanceGoalKilometres;
    if (type == StatType.duration) return durationGoalMinutes;
    return null;
  }

  String getTimeDescription(int? index);

  List<RideSummary> get rides;
}

class DayStats extends RideStats {
  final DateTime date;

  @override
  final List<RideSummary> rides;

  DayStats(int year, int month, int day, this.rides, DailyGoals? goals)
      : date = DateTime(year, month, day),
        super.fromSummaries(rides) {
    setGoals(goals);
  }

  DayStats.empty(int year, int month, int day, DailyGoals? goals)
      : date = DateTime(year, month, day),
        rides = [],
        super.fromSummaries([]) {
    setGoals(goals);
  }

  void setGoals(DailyGoals? goals) {
    if (goals != null && goals.weekdays[date.weekday - 1]) {
      distanceGoalKilometres = goals.distanceMetres / 1000;
      durationGoalMinutes = goals.durationMinutes;
    } else {
      distanceGoalKilometres = null;
      durationGoalMinutes = null;
    }
  }

  bool isOnDay(tmpDate) {
    return date.year == tmpDate.year && date.month == tmpDate.month && date.day == tmpDate.day;
  }

  @override
  String getTimeDescription(int? index) => StringFormatter.getDateStr(date);
}

class ListOfRideStats<T extends RideStats> extends RideStats {
  final List<T> list;

  final double avgDistanceKilometres;

  final double avgDurationMinutes;

  final double avgElevationGainMetres;

  final double avgElevationLossMetres;

  ListOfRideStats(this.list)
      : avgDistanceKilometres = list.map((d) => d.distanceKilometres).average,
        avgDurationMinutes = list.map((d) => d.durationMinutes).average,
        avgElevationGainMetres = list.map((d) => d.elevationGainMetres).average,
        avgElevationLossMetres = list.map((d) => d.elevationLossMetres).average,
        super.fromStats(list);

  double getMaxForType(StatType type) {
    List<double> values = [];
    if (type == StatType.distance) {
      values = list.map((day) => day.distanceKilometres).toList() +
          list.map((day) => day.distanceGoalKilometres ?? 0).toList();
    } else if (type == StatType.duration) {
      values =
          list.map((day) => day.durationMinutes).toList() + list.map((day) => day.durationGoalMinutes ?? 0).toList();
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
    if (type == StatType.distance) return avgDistanceKilometres;
    if (type == StatType.duration) return avgDurationMinutes;
    if (type == StatType.elevationGain) return avgElevationGainMetres;
    if (type == StatType.elevationLoss) return avgElevationLossMetres;
    if (type == StatType.speed) return averageSpeedKmh;
    return 0;
  }

  int? isDayInList(DateTime? day) {
    if (day == null) return null;
    for (int i = 0; i < list.length; i++) {
      var element = list[i];
      if (element is DayStats && element.isOnDay(day)) return i;
      if (element is ListOfRideStats && element.isDayInList(day) != null) return i;
    }
    return null;
  }

  @override
  String getTimeDescription(int? index) {
    if (index == null || index > list.length - 1) {
      var firstElement = list.first;
      if (firstElement is WeekStats) {
        var lastWeek = list.last as WeekStats;
        return StringFormatter.getFromToDateStr(firstElement.mondayDate, lastWeek.list.last.date);
      } else {
        return '${list.first.getTimeDescription(null)} - ${list.last.getTimeDescription(null)}';
      }
    } else {
      var element = list.elementAt(index);
      return element.getTimeDescription(null);
    }
  }

  @override
  List<RideSummary> get rides => list.map((e) => e.rides).reduce((a, b) => a + b);
}

class WeekStats extends ListOfRideStats<DayStats> {
  final DateTime mondayDate;

  WeekStats(List<DayStats> days)
      : mondayDate = days.first.date,
        super(days);

  @override
  String getTimeDescription(int? index) {
    if (index == null || index > list.length - 1) {
      return StringFormatter.getFromToDateStr(list.first.date, list.last.date);
    } else {
      return StringFormatter.getDateStr(list.elementAt(index).date);
    }
  }
}

class MonthStats extends ListOfRideStats<DayStats> {
  final int year;

  final int month;

  MonthStats(List<DayStats> days)
      : year = days.first.date.year,
        month = days.first.date.month,
        super(days);

  @override
  String getTimeDescription(int? index) {
    if (index == null || index > list.length - 1) {
      return StringFormatter.getMonthAndYearStr(month, year);
    } else {
      return StringFormatter.getDateStr(list.elementAt(index).date);
    }
  }
}
