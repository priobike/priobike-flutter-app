import 'package:flutter/material.dart';

/// Enum which describes the different kinds of values of ride information in a ride summary.
enum RideInfo {
  distance,
  duration,
  elevationGain,
  elevationLoss,
  averageSpeed,
}

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
  StatInterval get statInterval => _statInterval;
  void setStatInterval(StatInterval type) {
    _statInterval = type;
    notifyListeners();
  }

  /// The ride info which shall be displayed.
  RideInfo _rideInfo = RideInfo.distance;
  RideInfo get rideInfo => _rideInfo;
  void setRideInfo(RideInfo type) {
    _rideInfo = type;
    notifyListeners();
  }

  /// Check if given ride info type is currently selected.
  bool isTypeSelected(RideInfo type) => type == _rideInfo;

  /// Get icon describing a given ride info type.
  static IconData getIconForInfoType(RideInfo type) {
    if (type == RideInfo.distance) return Icons.directions_bike;
    if (type == RideInfo.averageSpeed) return Icons.speed;
    if (type == RideInfo.duration) return Icons.timer;
    return Icons.question_mark;
  }
}
