import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';

class StatUtils {
  static double getFittingMax(List<double> values) {
    if (values.isEmpty) return 0;
    var num = values.max;
    if (num <= 5) return num;
    if (num <= 10) return num.ceilToDouble();
    if (num <= 50) return roundUpToInterval(num, 5);
    if (num <= 100) return roundUpToInterval(num, 10);
    return roundUpToInterval(num, 50);
  }

  static double roundUpToInterval(double num, int interval) {
    return interval * (num / interval).ceilToDouble();
  }

  static String getDateStr(DateTime date) {
    return DateFormat("dd.MM").format(date);
  }

  static String getFromToStr(DateTime first, DateTime last) {
    return '${getDateStr(first)} - ${getDateStr(last)}';
  }

  static double getOverallValueFromSummaries(List<RideSummary> list, RideInfoType type) {
    if (list.isEmpty) return 0;
    return getOverallValueFromDouble(list.map((ride) => getRideValueFromType(ride, type)).toList(), type);
  }

  static double getOverallValueFromDouble(List<double> list, RideInfoType type) {
    if (type == RideInfoType.averageSpeed) {
      return list.average;
    }
    return getListSum(list);
  }

  static String getFormattedStrByRideType(double value, RideInfoType type) {
    String result = value.toStringAsFixed(0);
    if ((type == RideInfoType.distance || type == RideInfoType.duration) && value < 100) {
      result = value.toStringAsFixed(1);
    } else {
      result = value.toStringAsFixed(0);
    }
    if (type == RideInfoType.distance) result += ' km';
    if (type == RideInfoType.duration) result += ' min';
    if (type == RideInfoType.averageSpeed) result += ' km/h';
    return result;
  }

  static double getListSum(List<double> list) {
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b);
  }

  static double getRideValueFromType(RideSummary ride, RideInfoType infoType) {
    if (infoType == RideInfoType.distance) return ride.distanceMetres / 1000;
    if (infoType == RideInfoType.duration) return ride.durationSeconds / 60;
    if (infoType == RideInfoType.averageSpeed) return ride.averageSpeedKmh;
    if (infoType == RideInfoType.elevationGain) return ride.elevationGainMetres;
    if (infoType == RideInfoType.elevationLoss) return ride.elevationLossMetres;
    return 0;
  }

  static String getWeekStr(int i) {
    if (i == 0) return 'Mo';
    if (i == 1) return 'Di';
    if (i == 2) return 'Mi';
    if (i == 3) return 'Do';
    if (i == 4) return 'Fr';
    if (i == 5) return 'Sa';
    return 'So';
  }

  static String getMonthStr(int i) {
    if (i == 1) return 'Januar';
    if (i == 2) return 'Februar';
    if (i == 3) return 'März';
    if (i == 4) return 'April';
    if (i == 5) return 'Mai';
    if (i == 6) return 'Juni';
    if (i == 7) return 'Juli';
    if (i == 8) return 'August';
    if (i == 9) return 'September';
    if (i == 10) return 'Oktober';
    if (i == 11) return 'November';
    return 'Dezember';
  }
}
