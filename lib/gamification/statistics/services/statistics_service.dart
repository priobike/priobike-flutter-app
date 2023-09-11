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
  StatType _selectedType = StatType.distance;

  /// The date selected from the stats.
  DateTime? _selectedDate;

  /// Get the currently selected stat interval.
  StatInterval get statInterval => _statInterval;

  /// Get the currently selected stat type.
  StatType get selectedType => _selectedType;

  /// Get the currently selected date.
  DateTime? get selectedDate => _selectedDate;

  /// Change selected stat interval.
  void setStatInterval(StatInterval type) {
    _statInterval = type;
    notifyListeners();
  }

  /// Change selected stat type.
  void setStatType(StatType type) {
    _selectedType = type;
    notifyListeners();
  }

  /// Change selected date or set it to null.
  void selectDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Check if given ride info type is currently selected.
  bool isTypeSelected(StatType type) => type == _selectedType;
}
