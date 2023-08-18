import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';

abstract class GraphViewModel with ChangeNotifier {
  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  RideInfoType _rideInfoType = RideInfoType.distance;

  void setRideInfoType(RideInfoType type) {
    _rideInfoType = type;
    updateValues();
  }

  List<RideSummary> get allRides;

  RideInfoType get rideInfoType => _rideInfoType;

  late List<double> _yValues;
  List<double> get yValues => _yValues;

  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;

  void setSelectedIndex(int? selected) {
    _selectedIndex = selected;
    notifyListeners();
  }

  final List<Stream> _streams = [];

  final List<StreamSubscription> _streamSubs = [];

  void endStreams() {
    for (var sub in _streamSubs) {
      sub.cancel();
    }
  }

  void startStreams() {
    _streams.forEachIndexed((i, stream) => stream.listen((update) {
          updateValues(update: update, index: i);
          notifyListeners();
        }));
  }

  void updateValues({List<RideSummary>? update, int? index});

  String get overallValueStr {
    var overallVal = StatUtils.getOverallValueFromDouble(yValues, _rideInfoType);
    return StatUtils.getFormattedStrByRideType(overallVal, _rideInfoType);
  }

  String get selectedValueStr {
    if (selectedIndex == null) return '';
    return StatUtils.getFormattedStrByRideType(yValues[selectedIndex!], _rideInfoType);
  }

  String get selectedOrOverallValueStr {
    if (yValues.isEmpty) return '';
    if (selectedIndex == null) return overallValueStr;
    return selectedValueStr;
  }

  String get valuesAverage => StatUtils.getFormattedStrByRideType(yValues.average, _rideInfoType);

  String get rangeOrSelectedDateStr;
}

class WeekGraphViewModel extends GraphViewModel {
  final DateTime startDay;
  List<RideSummary> _rides = [];

  List<RideSummary> get rides => _rides;

  WeekGraphViewModel(this.startDay) {
    _yValues = List.filled(7, 0);
    _streams.add(rideDao.streamSummariesOfWeek(startDay.year, startDay.month, startDay.day));
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    if (update != null) _rides = update;
    for (int i = 0; i < 7; i++) {
      var weekDay = startDay.add(Duration(days: i)).day;
      var ridesOnDay = rides.where((ride) => ride.startTime.day == weekDay);
      _yValues[i] = StatUtils.getOverallValueFromSummaries(ridesOnDay.toList(), _rideInfoType);
    }
  }

  @override
  String get rangeOrSelectedDateStr {
    if (selectedIndex == null) {
      return StatUtils.getFromToStr(startDay, startDay.add(const Duration(days: 6)));
    } else {
      return StatUtils.getDateStr(startDay.add(Duration(days: selectedIndex!)));
    }
  }

  @override
  List<RideSummary> get allRides => _rides;
}

class MonthGraphViewModel extends GraphViewModel {
  final int year;
  final int month;

  List<RideSummary> _rides = [];

  List<RideSummary> get rides => _rides;

  final DateTime firstDay;

  int numberOfDays = 0;

  MonthGraphViewModel(this.year, this.month) : firstDay = DateTime(year, month) {
    numberOfDays = getNumberOfDays();
    _yValues = List.filled(numberOfDays, 0);
    _streams.add(rideDao.streamSummariesOfMonth(year, month));
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    if (update != null) _rides = update;
    for (int i = 0; i < numberOfDays; i++) {
      _yValues[i] =
          StatUtils.getOverallValueFromSummaries(rides.where((r) => r.startTime.day == i).toList(), _rideInfoType);
    }
  }

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
}

class MultipleWeeksGraphViewModel extends GraphViewModel {
  final DateTime lastWeekStartDay;
  final int numOfWeeks;

  final Map<DateTime, List<RideSummary>> _rideMap = {};

  Map<DateTime, List<RideSummary>> get rideMap => _rideMap;

  MultipleWeeksGraphViewModel(this.lastWeekStartDay, this.numOfWeeks) {
    _yValues = [];
    var tmpStartDay = lastWeekStartDay;
    tmpStartDay = tmpStartDay.subtract(Duration(days: 7 * (numOfWeeks - 1)));
    for (int i = 0; i < numOfWeeks; i++) {
      yValues.add(0);
      _rideMap[tmpStartDay] = [];
      tmpStartDay = tmpStartDay.add(const Duration(days: 7));
    }
    for (var key in _rideMap.keys) {
      _streams.add(rideDao.streamSummariesOfWeek(key.year, key.month, key.day));
    }
  }

  @override
  void updateValues({List<RideSummary>? update, int? index}) {
    if (update != null && index != null) _rideMap[_rideMap.keys.elementAt(index)] = update;
    _rideMap.values.forEachIndexed(
        (i, ridesInWeek) => yValues[i] = StatUtils.getOverallValueFromSummaries(ridesInWeek, _rideInfoType));
  }

  @override
  String get rangeOrSelectedDateStr {
    if (rideMap.keys.isEmpty) return '';
    if (selectedIndex == null) {
      return StatUtils.getFromToStr(rideMap.keys.first, rideMap.keys.last.add(const Duration(days: 6)));
    }
    var currentWeekFirstDay = rideMap.keys.elementAt(selectedIndex!);
    return StatUtils.getFromToStr(currentWeekFirstDay, currentWeekFirstDay.add(const Duration(days: 6)));
  }

  @override
  List<RideSummary> get allRides => _rideMap.values.expand((rides) => rides).toList();
}
