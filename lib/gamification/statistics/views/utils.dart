import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';

/// A bunch of utility methods for converting ride data such that it makes sense I guess.
class StatUtils {
  /// Get date string as day and month from given date.
  static String getDateStr(DateTime date) => DateFormat("dd.MM").format(date);

  /// Get time string as hour and monuts from given date.
  static String getTimeStr(DateTime date) => DateFormat('hh.mm').format(date);

  /// Get string for a time interval between to dates.
  static String getFromToDateStr(DateTime first, DateTime last) => '${getDateStr(first)} - ${getDateStr(last)}';

  /// Calculate overall value from given list of values according to a given ride info type.
  static double getOverallValueFromDouble(List<double> list, RideInfo type) {
    if (type == RideInfo.averageSpeed) {
      return list.average;
    }
    return getListSum(list);
  }

  /// Calculate overall value from a given list of rides.
  static double getOverallValueFromSummaries(List<RideSummary> list, RideInfo type) {
    if (list.isEmpty) return 0;
    return StatUtils.getOverallValueFromDouble(
      list.map((ride) => StatUtils.getConvertedRideValueFromType(ride, type)).toList(),
      type,
    );
  }

  /// Get formatted string for a given double by rounding it and giving it
  /// a fitting label, all according to a given ride info type.
  static String getFormattedStrByRideType(double value, RideInfo type) {
    String label = '';
    if (type == RideInfo.distance) label = 'km';
    if (type == RideInfo.duration) label = 'min';
    if (type == RideInfo.averageSpeed) label = 'km/h';

    return '${getRoundedStrByRideType(value, type)} $label';
  }

  /// Round a given value according to a given ride info type.
  static String getRoundedStrByRideType(double value, RideInfo type) {
    if ((type == RideInfo.distance || type == RideInfo.averageSpeed) && value < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Calculate sum of values in list.
  static double getListSum(List<double> list) {
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b);
  }

  /// Get ride info value from given ride according to a given ride info type. Also convert m to km and s to min.
  static double getConvertedRideValueFromType(RideSummary ride, RideInfo infoType) {
    if (infoType == RideInfo.distance) return ride.distanceMetres / 1000;
    if (infoType == RideInfo.duration) return ride.durationSeconds / 60;
    if (infoType == RideInfo.averageSpeed) return ride.averageSpeedKmh;
    if (infoType == RideInfo.elevationGain) return ride.elevationGainMetres;
    if (infoType == RideInfo.elevationLoss) return ride.elevationLossMetres;
    return 0;
  }

  /// Convert weekday index to simple string.
  static String getWeekStr(int i) {
    if (i == 0) return 'Mo';
    if (i == 1) return 'Di';
    if (i == 2) return 'Mi';
    if (i == 3) return 'Do';
    if (i == 4) return 'Fr';
    if (i == 5) return 'Sa';
    return 'So';
  }

  /// Convert month index to its name.
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
