import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';

/// Enum which describes different kinds of intervals for displayed statistics.
enum StatInterval {
  weeks,
  months,
  multipleWeeks,
}

/// This service manages what kind of statistics in what intervals are displayed.
class StatisticService with ChangeNotifier {
  /// The interval in which rides shall be displayed.
  StatInterval _statInterval = StatInterval.weeks;

  /// The ride info which shall be displayed.
  StatType _rideInfo = StatType.distance;

  DateTime? _selectedDate;

  StatInterval get statInterval => _statInterval;

  StatType get rideInfo => _rideInfo;

  DateTime? get selectedDate => _selectedDate;

  void setStatInterval(StatInterval type) {
    _statInterval = type;
    notifyListeners();
  }

  void setStatType(StatType type) {
    _rideInfo = type;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Check if given ride info type is currently selected.
  bool isTypeSelected(StatType type) => type == _rideInfo;

  /// Get icon describing a given ride info type.
  static IconData getIconForInfoType(StatType type) {
    if (type == StatType.distance) return Icons.directions_bike;
    if (type == StatType.speed) return Icons.speed;
    if (type == StatType.duration) return Icons.timer;
    return Icons.question_mark;
  }
}
