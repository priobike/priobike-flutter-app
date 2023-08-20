import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';

/// View model for a graph which manages the displayed ride data of a list of rides.
abstract class GraphViewModel with ChangeNotifier {
  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// List of database streams to gather the managed rides from.
  final List<Stream<List<RideSummary>>> _streams = [];

  /// List of stream subscription of currently listened streams.
  final List<StreamSubscription> _streamSubs = [];

  /// List of y values for the graph
  late List<double> _yValues;
  List<double> get yValues => _yValues;

  /// Type of ride info to be displayed in the graph.
  RideInfo _rideInfoType = RideInfo.distance;
  RideInfo get rideInfoType => _rideInfoType;
  void setRideInfoType(RideInfo type) {
    _rideInfoType = type;
    updateValues();
  }

  /// Index of selected graph bar. If null, no bar is selected.
  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;
  void setSelectedIndex(int? selected) {
    _selectedIndex = selected;
    notifyListeners();
  }

  /// Start all streams in currents stream list and update values when an update comes in.
  void startStreams() {
    _streams.forEachIndexed((i, stream) => stream.listen((update) {
          updateValues(update: update, index: i);
          notifyListeners();
        }));
  }

  /// Cancel all active stream subscriptions.
  void endStreams() {
    for (var sub in _streamSubs) {
      sub.cancel();
    }
  }

  /// Return overall value of current yValues. This value is either the sum, or the average, if the displayed
  /// information is the average ride speed. The return value is a string formatted according to the ride info type.
  String get overallValueStr {
    var overallVal = StatUtils.getOverallValueFromDouble(yValues, _rideInfoType);
    return StatUtils.getFormattedStrByRideType(overallVal, _rideInfoType);
  }

  /// Returns a string containing the value of the selected bar, formatted according to the ride info type.
  String get selectedValueStr {
    if (selectedIndex == null) return '';
    return StatUtils.getFormattedStrByRideType(yValues[selectedIndex!], _rideInfoType);
  }

  /// Return selected value, if a bar is selected, or overall value otherwise, as a formatted ride info string.
  String get selectedOrOverallValueStr {
    if (yValues.isEmpty) return '';
    if (selectedIndex == null) return overallValueStr;
    return selectedValueStr;
  }

  /// Returns average of the yValues as a formatted string according to the ride info type.
  String get valuesAverage {
    return StatUtils.getFormattedStrByRideType(yValues.average, _rideInfoType);
  }

  /// Returns either all rides or, if the selected index is not null, only the ones corresponding to the selected index.
  List<RideSummary> get selectedOrAllRides => _selectedIndex == null ? allRides : selectedRides;

  /// Return list of all rides currently displayed by the graph.
  List<RideSummary> get allRides;

  /// Returns all rides corresponding to the selected index.
  List<RideSummary> get selectedRides;

  /// Return string describing the time intervall of all displayed rides, or only the rides of the selected bar.
  String get rangeOrSelectedDateStr;

  /// Update yValues according to a given list of rides and an index of the stream from which the update came.
  void updateValues({List<RideSummary>? update, int? index});
}

/// View model for a graph of a single week.
class WeekGraphViewModel extends GraphViewModel {
  /// Start day of the week.
  final DateTime startDay;

  /// List of displayed rides.
  List<RideSummary> _rides = [];
  List<RideSummary> get rides => _rides;

  WeekGraphViewModel(this.startDay) {
    /// Intitalize yValues as a list of zeros and a stream for rides in the displayed week.
    _yValues = List.filled(7, 0);
    _streams.add(rideDao.streamSummariesOfWeek(startDay.year, startDay.month, startDay.day));
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    if (update != null) _rides = update;

    /// For each day of the week, save sum of current ride info values in yValues.
    for (int i = 0; i < 7; i++) {
      var weekDay = startDay.add(Duration(days: i)).day;
      var ridesOnDay = rides.where((ride) => ride.startTime.day == weekDay);
      _yValues[i] = StatUtils.getOverallValueFromSummaries(ridesOnDay.toList(), rideInfoType);
    }
  }

  @override
  String get rangeOrSelectedDateStr {
    if (selectedIndex == null) {
      return StatUtils.getFromToDateStr(startDay, startDay.add(const Duration(days: 6)));
    } else {
      return StatUtils.getDateStr(startDay.add(Duration(days: selectedIndex!)));
    }
  }

  @override
  List<RideSummary> get allRides => _rides;

  @override
  List<RideSummary> get selectedRides => _rides.where((ride) => ride.startTime.weekday == _selectedIndex! + 1).toList();
}

/// View model for a graph of a single month.
class MonthGraphViewModel extends GraphViewModel {
  final int year, month;

  /// List of displayed rides.
  List<RideSummary> _rides = [];
  List<RideSummary> get rides => _rides;

  /// First day of the displayed months.
  final DateTime firstDay;

  /// Number of days the displayed month has.
  int numberOfDays = 0;

  MonthGraphViewModel(this.year, this.month) : firstDay = DateTime(year, month) {
    /// Calculate number of days and intialize yValues as zeros and a stream of rides in the given month.
    numberOfDays = getNumberOfDays();
    _yValues = List.filled(numberOfDays, 0);
    _streams.add(rideDao.streamSummariesOfMonth(year, month));
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    if (update != null) _rides = update;

    /// For each day in the month, save sum of ride info values on that day.
    for (int i = 0; i < numberOfDays; i++) {
      _yValues[i] =
          StatUtils.getOverallValueFromSummaries(rides.where((r) => r.startTime.day == i).toList(), rideInfoType);
    }
  }

  /// Calculates and returns the number of days for the corresponding month.
  int getNumberOfDays() {
    var isDecember = firstDay.month == 12;
    var lastDay = DateTime(isDecember ? firstDay.year + 1 : firstDay.year, (isDecember ? 0 : firstDay.month + 1), 0);
    return lastDay.day;
  }

  @override
  String get rangeOrSelectedDateStr {
    return (selectedIndex == null ? '' : '$selectedIndex. ') + StatUtils.getMonthStr(month);
  }

  @override
  List<RideSummary> get allRides => _rides;

  @override
  List<RideSummary> get selectedRides => _rides.where((ride) => ride.startTime.day == _selectedIndex).toList();
}

/// View model for a graph of multiple weeks.
class MultipleWeeksGraphViewModel extends GraphViewModel {
  /// The first day of the last week, of weeks which should be displayed.
  final DateTime lastWeekStartDay;

  /// The number of weeks to be displayed.
  final int numOfWeeks;

  /// The displayed rides mapped to the week starts.
  final Map<DateTime, List<RideSummary>> _rideMap = {};
  Map<DateTime, List<RideSummary>> get rideMap => _rideMap;

  MultipleWeeksGraphViewModel(this.lastWeekStartDay, this.numOfWeeks) {
    _yValues = [];

    /// Create map containing all the start days of the weeks to be displayed.
    var tmpStartDay = lastWeekStartDay;
    tmpStartDay = tmpStartDay.subtract(Duration(days: 7 * (numOfWeeks - 1)));
    for (int i = 0; i < numOfWeeks; i++) {
      yValues.add(0);
      _rideMap[tmpStartDay] = [];
      tmpStartDay = tmpStartDay.add(const Duration(days: 7));
    }

    /// Create database stream for each week.
    for (var key in _rideMap.keys) {
      _streams.add(rideDao.streamSummariesOfWeek(key.year, key.month, key.day));
    }
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    /// Update rides in map according to given stream index.
    if (update != null && index != null) _rideMap[_rideMap.keys.elementAt(index)] = update;

    /// Update yValues as sum of ride info values for each week in the ride map.
    _rideMap.values.forEachIndexed(
        (i, ridesInWeek) => yValues[i] = StatUtils.getOverallValueFromSummaries(ridesInWeek, rideInfoType));
  }

  @override
  String get rangeOrSelectedDateStr {
    if (rideMap.keys.isEmpty) return '';
    if (selectedIndex == null) {
      return StatUtils.getFromToDateStr(rideMap.keys.first, rideMap.keys.last.add(const Duration(days: 6)));
    }
    var currentWeekFirstDay = rideMap.keys.elementAt(selectedIndex!);
    return StatUtils.getFromToDateStr(currentWeekFirstDay, currentWeekFirstDay.add(const Duration(days: 6)));
  }

  @override
  List<RideSummary> get allRides => _rideMap.values.expand((rides) => rides).toList();

  @override
  List<RideSummary> get selectedRides => _rideMap.values.elementAt(_selectedIndex!);
}
