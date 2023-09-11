import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/main.dart';

/// View model for a ride stats in a certain time frame.
abstract class StatsForTimeFrameViewModel with ChangeNotifier {
  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  final UserGoalsService goalsService = getIt<UserGoalsService>();

  /// List of database streams to gather the managed rides from.
  final List<Stream<List<RideSummary>>> _streams = [];

  /// List of stream subscription of currently listened streams.
  final List<StreamSubscription> _streamSubs = [];

  /// List of y values for a graph displaying the stats of the rides.
  late List<double> _yValues;
  List<double> get yValues => _yValues;

  /// Determines which of the ride values should be displayed by a graph connected to the view model.
  StatType _rideInfoType = StatType.distance;

  /// Index of a selected y value.
  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;
  void setSelectedIndex(int? selected) {
    _selectedIndex = selected;
    notifyListeners();
  }

  /// Start all streams in currents stream list and update values when an update comes in.
  void _startStreams() {
    _streams.forEachIndexed((i, stream) => stream.listen((update) {
          updateValues(update: update, index: i);
          notifyListeners();
        }));
  }

  @override
  void dispose() {
    for (var sub in _streamSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  /// Return overall value of current yValues. This value is either the sum, or the average, if the displayed
  /// information is the average ride speed. The return value is a string formatted according to the ride info type.
  String get overallValueStr {
    var overallVal = Utils.getOverallValueFromDouble(yValues, _rideInfoType);
    return StringFormatter.getFormattedStrByRideType(overallVal, _rideInfoType);
  }

  /// Returns a string containing the value of the selected bar, formatted according to the ride info type.
  String get selectedValueStr {
    if (selectedIndex == null) return '';
    return StringFormatter.getFormattedStrByRideType(yValues[selectedIndex!], _rideInfoType);
  }

  /// Return selected value, if a bar is selected, or overall value otherwise, as a formatted ride info string.
  String get selectedOrOverallValueStr {
    if (yValues.isEmpty) return '';
    if (selectedIndex == null) return overallValueStr;
    return selectedValueStr;
  }

  /// Returns average of the yValues as a formatted string according to the ride info type.
  String get valuesAverage {
    var valuesToBeAveraged = _rideInfoType == StatType.speed ? yValues.where((val) => val > 0) : yValues;
    var average = valuesToBeAveraged.isEmpty ? 0.0 : valuesToBeAveraged.average;
    return StringFormatter.getFormattedStrByRideType(average, _rideInfoType);
  }

  List<double?> mapGoalsToValues(DailyGoals goals) => mapGoalsToDays(goals);

  List<double?> mapGoalsToDays(DailyGoals goals) {
    return daysInTimeFrame.map((day) {
      var hasGoal = goals.weekdays.elementAt(day.weekday - 1);
      if (hasGoal) {
        if (_rideInfoType == StatType.distance) return goals.distanceMetres / 1000;
        if (_rideInfoType == StatType.duration) return goals.durationMinutes;
      }
      return null;
    }).toList();
  }

  /// Return list of all rides in the time frame.
  List<RideSummary> get allRides;

  List<DateTime> get daysInTimeFrame;

  /// Return string describing the time intervall of all displayed rides, or only the rides of the selected bar.
  String get rangeOrSelectedDateStr => (_selectedIndex == null) ? rangeStr : selectedDateStr;

  /// Return string describing the time intervall of all displayed rides.
  String get rangeStr;

  /// Return string describing the time intervall of only the rides of the selected bar.
  String get selectedDateStr;

  /// Update yValues according to a given list of rides and an index of the stream from which the update came.
  void updateValues({List<RideSummary>? update, int? index});
}

/// View model for rides in a single week.
class WeekStatsViewModel extends StatsForTimeFrameViewModel {
  /// Start day of the week.
  final DateTime startDay;

  /// List of displayed rides.
  List<RideSummary> _rides = [];
  List<RideSummary> get rides => _rides;

  WeekStatsViewModel(this.startDay) : super() {
    // Intitalize yValues as a list of zeros and a stream for rides in the displayed week.
    _yValues = List.filled(7, 0);
    _streams.add(rideDao.streamRidesInWeek(startDay));
    _startStreams();
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    if (update != null) _rides = update;
    // For each day of the week, save sum of current ride info values in yValues.
    for (int i = 0; i < 7; i++) {
      var weekDay = startDay.add(Duration(days: i)).day;
      var ridesOnDay = rides.where((ride) => ride.startTime.day == weekDay);
      _yValues[i] = Utils.getOverallValueFromSummaries(ridesOnDay.toList(), _rideInfoType);
    }
  }

  @override
  List<RideSummary> get allRides => _rides;

  @override
  List<RideSummary> get selectedRides => _rides.where((ride) => ride.startTime.weekday == _selectedIndex! + 1).toList();

  @override
  String get rangeStr => StringFormatter.getFromToDateStr(startDay, startDay.add(const Duration(days: 6)));

  @override
  String get selectedDateStr => StringFormatter.getDateStr(startDay.add(Duration(days: selectedIndex!)));

  @override
  List<DateTime> get daysInTimeFrame {
    List<DateTime> days = [];
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      days.add(startDay.add(Duration(days: i)));
    }
    return days;
  }
}

/// View model for a rides in a single month.
class MonthStatsViewModel extends StatsForTimeFrameViewModel {
  final int year, month;

  /// List of displayed rides.
  List<RideSummary> _rides = [];
  List<RideSummary> get rides => _rides;

  /// First day of the displayed months.
  final DateTime firstDay;

  /// Number of days the displayed month has.
  int numberOfDays = 0;

  MonthStatsViewModel(this.year, this.month)
      : firstDay = DateTime(year, month),
        super() {
    // Calculate number of days and intialize yValues as zeros and a stream of rides in the given month.
    numberOfDays = getNumberOfDays();
    _yValues = List.filled(numberOfDays, 0);
    _streams.add(rideDao.streamRidesInMonth(year, month));
    _startStreams();
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    if (update != null) _rides = update;
    // For each day in the month, save sum of ride info values on that day.
    for (int i = 0; i < numberOfDays; i++) {
      var ridesOnDay = rides.where((r) => r.startTime.day - 1 == i).toList();
      _yValues[i] = Utils.getOverallValueFromSummaries(ridesOnDay, _rideInfoType);
    }
  }

  /// Calculates and returns the number of days for the corresponding month.
  int getNumberOfDays() {
    var isDecember = firstDay.month == 12;
    var lastDay = DateTime(isDecember ? firstDay.year + 1 : firstDay.year, (isDecember ? 0 : firstDay.month + 1), 0);
    return lastDay.day;
  }

  @override
  List<RideSummary> get allRides => _rides;

  @override
  List<RideSummary> get selectedRides => _rides.where((ride) => ride.startTime.day == _selectedIndex).toList();

  @override
  String get rangeStr => StringFormatter.getMonthAndYearStr(month, year);

  @override
  String get selectedDateStr =>
      '${selectedIndex == null ? null : selectedIndex! + 1}. ${StringFormatter.getMonthAndYearStr(month, year)}';

  @override
  List<DateTime> get daysInTimeFrame {
    List<DateTime> days = [];
    for (int i = 0; i < numberOfDays; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    return days;
  }
}

/// View model for rides in multiple weeks.
class MultipleWeeksStatsViewModel extends StatsForTimeFrameViewModel {
  /// The first day of the last week, of weeks which should be displayed.
  final DateTime lastWeekStartDay;

  /// The number of weeks to be displayed.
  final int numOfWeeks;

  /// The displayed rides mapped to the week starts.
  final Map<DateTime, List<RideSummary>> _rideMap = {};
  Map<DateTime, List<RideSummary>> get rideMap => _rideMap;

  MultipleWeeksStatsViewModel(this.lastWeekStartDay, this.numOfWeeks) : super() {
    _yValues = [];
    // Create map containing all the start days of the weeks to be displayed.
    var tmpStartDay = lastWeekStartDay;
    tmpStartDay = tmpStartDay.subtract(Duration(days: 7 * (numOfWeeks - 1)));
    for (int i = 0; i < numOfWeeks; i++) {
      yValues.add(0);
      _rideMap[tmpStartDay] = [];
      tmpStartDay = tmpStartDay.add(const Duration(days: 7));
    }
    // Create database stream for each week.
    for (var key in _rideMap.keys) {
      _streams.add(rideDao.streamRidesInWeek(key));
    }
    _startStreams();
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    // Update rides in map according to given stream index.
    if (update != null && index != null) _rideMap[_rideMap.keys.elementAt(index)] = update;
    // Update yValues as sum of ride info values for each week in the ride map.
    _rideMap.values.forEachIndexed(
        (i, ridesInWeek) => yValues[i] = Utils.getOverallValueFromSummaries(ridesInWeek, _rideInfoType));
  }

  @override
  List<RideSummary> get allRides => _rideMap.values.expand((rides) => rides).toList();

  @override
  List<RideSummary> get selectedRides => _rideMap.values.elementAt(_selectedIndex!);

  @override
  String get rangeStr {
    if (rideMap.keys.isEmpty) return '';
    return StringFormatter.getFromToDateStr(rideMap.keys.first, rideMap.keys.last.add(const Duration(days: 6)));
  }

  @override
  String get selectedDateStr {
    if (rideMap.keys.isEmpty) return '';
    var currentWeekFirstDay = rideMap.keys.elementAt(selectedIndex!);
    return StringFormatter.getFromToDateStr(currentWeekFirstDay, currentWeekFirstDay.add(const Duration(days: 6)));
  }

  @override
  List<DateTime> get daysInTimeFrame {
    List<DateTime> days = [];
    for (var weekStart in _rideMap.keys) {
      for (int i = 0; i < DateTime.daysPerWeek; i++) {
        days.add(weekStart.add(Duration(days: i)));
      }
    }
    return days;
  }

  @override
  List<double?> mapGoalsToValues(DailyGoals goals) {
    List<double?> goalsForWeeks = [];
    var goalsForDays = mapGoalsToDays(goals);
    for (int i = 0; i < numOfWeeks; i++) {
      double? goalSum;
      for (int e = 0; e < DateTime.daysPerWeek; e++) {
        var goalOnDay = goalsForDays[i * DateTime.daysPerWeek + e];
        if (goalOnDay != null) {
          if (goalSum == null) {
            goalSum = goalOnDay;
          } else {
            goalSum += goalOnDay;
          }
        }
      }
      goalsForWeeks.add(goalSum);
    }
    return goalsForWeeks;
  }
}
