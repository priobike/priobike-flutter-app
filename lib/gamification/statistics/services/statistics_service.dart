import 'package:flutter/material.dart';

enum RideInfoType {
  distance,
  duration,
  elevationGain,
  elevationLoss,
  averageSpeed,
}

enum RideStatsType {
  weeks,
  months,
  multipleWeeks,
}

class StatisticService with ChangeNotifier {
  RideStatsType _statsType = RideStatsType.weeks;

  RideStatsType get statsType => _statsType;

  void setRideStatsType(RideStatsType type) {
    _statsType = type;
    notifyListeners();
  }

  void changeStatsType() {
    if (statsType == RideStatsType.weeks) return setRideStatsType(RideStatsType.months);
    if (statsType == RideStatsType.months) return setRideStatsType(RideStatsType.multipleWeeks);
    if (statsType == RideStatsType.multipleWeeks) return setRideStatsType(RideStatsType.weeks);
  }

  RideInfoType _selectedRideInfo = RideInfoType.distance;

  RideInfoType get selectedRideInfo => _selectedRideInfo;

  void setRideInfoType(RideInfoType type) {
    _selectedRideInfo = type;
    notifyListeners();
  }

  bool isTypeSelected(RideInfoType type) => type == _selectedRideInfo;

  static IconData getIconForInfoType(RideInfoType type) {
    if (type == RideInfoType.distance) return Icons.directions_bike;
    if (type == RideInfoType.averageSpeed) return Icons.speed;
    if (type == RideInfoType.duration) return Icons.timer;
    return Icons.question_mark;
  }
}
