import 'package:flutter/material.dart';

enum RideInfoType {
  distance,
  duration,
  elevationGain,
  elevationLoss,
  averageSpeed,
}

class StatisticService with ChangeNotifier {
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
