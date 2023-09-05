import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';

/// Fixed duration for long animation.
class LongDuration extends Duration {
  LongDuration() : super(milliseconds: 1000);
}

/// Fixed duration for a short animation.
class ShortDuration extends Duration {
  ShortDuration() : super(milliseconds: 500);
}

class TinyDuration extends Duration {
  TinyDuration() : super(milliseconds: 250);
}

/// Simple fade tranistion to let widgets appear smooth.
class CustomFadeTransition extends FadeTransition {
  CustomFadeTransition({
    Key? key,
    required AnimationController controller,
    required Widget child,
    Interval? interval,
  }) : super(key: key, opacity: getFadeAnimation(controller, interval), child: child);

  static Animation<double> getFadeAnimation(var controller, var interval) => CurvedAnimation(
        parent: controller,
        curve: interval ?? const Interval(0, 1, curve: Curves.easeIn),
      );
}

/// A bunch of utility methods for processing ride data.
class Utils {
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
    return Utils.getOverallValueFromDouble(
      list.map((ride) => Utils.getConvertedRideValueFromType(ride, type)).toList(),
      type,
    );
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

  /// Calculate sum of values in list.
  static double getListSum(List<double> list) {
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b);
  }
}

/// A bunch of methods to format different information into strings.
class StringFormatter {
  /// Get date string as day and month from given date.
  static String getDateStr(DateTime date) => DateFormat("dd.MM").format(date);

  /// Get time string as hour and monuts from given date.
  static String getTimeStr(DateTime date) => DateFormat('hh.mm').format(date);

  /// Get string for a time interval between to dates.
  static String getFromToDateStr(DateTime first, DateTime last) => '${getDateStr(first)} - ${getDateStr(last)}';

  /// Returns a string describing how much time the user has left for a challenge.
  static String getTimeLeftStr(DateTime date) {
    var timeLeft = date.difference(DateTime.now());
    var result = '';
    var daysLeft = timeLeft.inDays;
    if (daysLeft > 0) result += '$daysLeft ${daysLeft > 1 ? 'Tage' : 'Tag'} ';
    var formatter = NumberFormat('00');
    result += '${formatter.format(timeLeft.inHours % 24)}:${formatter.format(timeLeft.inMinutes % 60)}h';
    return result;
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
}
