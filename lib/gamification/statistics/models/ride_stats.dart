import 'package:collection/collection.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';

/// This object holds some kind of aggregation of ride statistics.
class RideStats {
  /// Distance in kilometres.
  final double distanceKilometres;

  /// Duration in minutes.
  final double durationMinutes;

  /// Elevation gain in metres.
  final double elevationGainMetres;

  /// Elevation loss in metres.
  final double elevationLossMetres;

  /// A goal value for the distance in kilometres.
  double? distanceGoalKilometres;

  /// A goal value for the duration in minutes.
  double? durationGoalMinutes;

  /// Average speed in kilometres per hour.
  double get averageSpeedKmh {
    if (durationMinutes > 0) return distanceKilometres / (durationMinutes / 60);
    return 0;
  }

  /// Get ride stats from a list of summaries, by summing up all the ride values and averaging the speed.
  RideStats.fromSummaries(List<RideSummary> rides)
      : distanceKilometres = ListUtils.getListSum(rides.map((r) => r.distanceMetres / 1000).toList()),
        durationMinutes = ListUtils.getListSum(rides.map((r) => r.durationSeconds / 60).toList()),
        elevationGainMetres = ListUtils.getListSum(rides.map((r) => r.elevationGainMetres).toList()),
        elevationLossMetres = ListUtils.getListSum(rides.map((r) => r.elevationLossMetres).toList());

  /// Get ride stats from a list of ride stats, by summing up all the ride values and averaging the speed.
  RideStats.fromStats(List<RideStats> stats)
      : distanceKilometres = ListUtils.getListSum(stats.map((s) => s.distanceKilometres).toList()),
        durationMinutes = ListUtils.getListSum(stats.map((s) => s.durationMinutes).toList()),
        elevationGainMetres = ListUtils.getListSum(stats.map((s) => s.elevationGainMetres).toList()),
        elevationLossMetres = ListUtils.getListSum(stats.map((s) => s.elevationLossMetres).toList()) {
    distanceGoalKilometres =
        ListUtils.getListSum(stats.map((s) => s.distanceGoalKilometres).whereType<double>().toList());
    durationGoalMinutes = ListUtils.getListSum(stats.map((s) => s.durationGoalMinutes).whereType<double>().toList());
  }

  /// Get ride stat value for a given stat type.
  double getStatFromType(StatType type) {
    if (type == StatType.distance) return distanceKilometres;
    if (type == StatType.duration) return durationMinutes;
    if (type == StatType.elevationGain) return elevationGainMetres;
    if (type == StatType.elevationLoss) return elevationLossMetres;
    if (type == StatType.speed) return averageSpeedKmh;
    return 0;
  }

  /// Get goal value for a given stat type.
  double? getGoalFromType(StatType type) {
    if (type == StatType.distance) return distanceGoalKilometres;
    if (type == StatType.duration) return durationGoalMinutes;
    return null;
  }

  /// Get textual description of the time frame the stats are in.
  String getTimeDescription(int? index) => '';

  /// Get ride summaries corresponding to the stats.
  List<RideSummary> get rides => [];
}

/// This object holds ride statistics for a concrete day.
class DayStats extends RideStats {
  /// The date of the day.
  final DateTime date;

  @override
  final List<RideSummary> rides;

  /// The object can be retreived from given goals and rides and date.
  DayStats(int year, int month, int day, this.rides, DailyGoals? goals)
      : date = DateTime(year, month, day),
        super.fromSummaries(rides) {
    setGoals(goals);
  }

  /// Create an empty stat object from given date and goals.
  DayStats.empty(int year, int month, int day, DailyGoals? goals)
      : date = DateTime(year, month, day),
        rides = [],
        super.fromSummaries([]) {
    setGoals(goals);
  }

  /// Set goal values of the object according to given goals.
  void setGoals(DailyGoals? goals) {
    if (goals != null && goals.weekdays[date.weekday - 1]) {
      distanceGoalKilometres = goals.distanceMetres / 1000;
      durationGoalMinutes = goals.durationMinutes;
    } else {
      distanceGoalKilometres = null;
      durationGoalMinutes = null;
    }
  }

  /// Whether a given date is on the same day as this day stats.
  bool isOnDay(tmpDate) {
    return date.year == tmpDate.year && date.month == tmpDate.month && date.day == tmpDate.day;
  }

  @override
  String getTimeDescription(int? index) => StringFormatter.getDateStr(date);
}

/// This objects aggregates a list of ride stats in an object holding the concrete list,
/// the corresponding ride stats and, in addition, average values.
class ListOfRideStats<T extends RideStats> extends RideStats {
  /// The corresponding list of ride stats.
  final List<T> list;

  /// The average distance covered by all ride stats in the list.
  final double avgDistanceKilometres;

  /// The average duration of all ride stats in the list.
  final double avgDurationMinutes;

  /// The average elevation gain of all ride stats in the list.
  final double avgElevationGainMetres;

  /// The average elevation loss of all ride stats in the list.
  final double avgElevationLossMetres;

  /// Get object from list of ride stats by calculating averages.
  ListOfRideStats(this.list)
      : avgDistanceKilometres = list.map((d) => d.distanceKilometres).average,
        avgDurationMinutes = list.map((d) => d.durationMinutes).average,
        avgElevationGainMetres = list.map((d) => d.elevationGainMetres).average,
        avgElevationLossMetres = list.map((d) => d.elevationLossMetres).average,
        super.fromStats(list);

  /// Get max of values and goals of all elements in the stat list.
  double getMaxForType(StatType type) {
    var listOfValues = list.map((e) => e.getStatFromType(type)).toList();
    var listOfGoalValues = list.map((e) => e.getGoalFromType(type)).whereType<double>().toList();
    return (listOfValues + listOfGoalValues).maxOrNull ?? 0;
  }

  /// Get average value for given stat type.
  double getAvgFromType(StatType type) {
    if (type == StatType.distance) return avgDistanceKilometres;
    if (type == StatType.duration) return avgDurationMinutes;
    if (type == StatType.elevationGain) return avgElevationGainMetres;
    if (type == StatType.elevationLoss) return avgElevationLossMetres;
    if (type == StatType.speed) return averageSpeedKmh;
    return 0;
  }

  /// Whether the list hold ride stats for a given day.
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

/// This object holds ride statistics for a week.
class WeekStats extends ListOfRideStats<DayStats> {
  /// Date of the monday of the week.
  final DateTime mondayDate;

  /// Get stats from list of days of the week.
  WeekStats(super.days) : mondayDate = days.first.date;

  @override
  String getTimeDescription(int? index) {
    if (index == null || index > list.length - 1) {
      return StringFormatter.getFromToDateStr(list.first.date, list.last.date);
    } else {
      return StringFormatter.getDateStr(list.elementAt(index).date);
    }
  }
}

/// This object holds ride statistics for a month.
class MonthStats extends ListOfRideStats<DayStats> {
  /// Year of the month.
  final int year;

  /// Index of the month from 1 to 12.
  final int month;

  /// Get stats from list of days of the month.
  MonthStats(super.days)
      : year = days.first.date.year,
        month = days.first.date.month;

  @override
  String getTimeDescription(int? index) {
    if (index == null || index > list.length - 1) {
      return StringFormatter.getMonthAndYearStr(month, year);
    } else {
      return StringFormatter.getDateStr(list.elementAt(index).date);
    }
  }
}
