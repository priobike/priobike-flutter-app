import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';

/// Fixed long duration for animations and stuff.
class LongDuration extends Duration {
  LongDuration() : super(milliseconds: 1000);
}

/// Fixed medium duration for animations and stuff.
class MediumDuration extends Duration {
  MediumDuration() : super(milliseconds: 500);
}

/// Fixed short duration for animations and stuff.
class ShortDuration extends Duration {
  ShortDuration() : super(milliseconds: 250);
}

/// A bunch of utility methods for processing ride data.
class ListUtils {
  /// Calculate sum of values in list.
  static double getListSum(List<double> list) {
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b);
  }

  /// Calculate average of values in list.
  static double getListAvg(List<double> list) {
    if (list.isEmpty) return 0;
    return list.average;
  }
}

/// A bunch of methods to format different information into strings.
class StringFormatter {
  /// Get date string as day and month from given date.
  static String getDateStr(DateTime date) =>
      '${DateFormat("dd").format(date)}. ${getMonthStr(date.month)} ${date.year}';

  static String getShortDateStr(DateTime date) => DateFormat("dd.MM").format(date);

  /// Get time string as hour and monuts from given date.
  static String getTimeStr(DateTime date) => DateFormat('hh.mm').format(date);

  /// Get string for a time interval between to dates.
  static String getFromToDateStr(DateTime first, DateTime last) {
    if (first.month == last.month) {
      return '${DateFormat("dd").format(first)}. - ${DateFormat("dd").format(last)}. ${getMonthStr(first.month)} ${first.year}';
    } else {
      return '${DateFormat("dd").format(first)}. ${getMonthStr(first.month)} - ${DateFormat("dd").format(last)}. ${getMonthStr(last.month)} ${first.year}';
    }
  }

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
  static String getFormattedStrByRideType(double value, StatType type) {
    String label = '';
    if (type == StatType.distance) label = 'km';
    if (type == StatType.duration) label = 'min';
    if (type == StatType.speed) label = 'km/h';

    return '${getRoundedStrByRideType(value, type)} $label';
  }

  /// Round a given value according to a given ride info type.
  static String getRoundedStrByRideType(double value, StatType type) {
    if ((type == StatType.distance || type == StatType.speed) && value < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  static String getMonthAndYearStr(int month, int year) {
    return '${getMonthStr(month)} $year';
  }

  /// Convert month index to its name.
  static String getMonthStr(int i) {
    if (i == 1) return 'Jan.';
    if (i == 2) return 'Feb.';
    if (i == 3) return 'März';
    if (i == 4) return 'April';
    if (i == 5) return 'Mai';
    if (i == 6) return 'Juni';
    if (i == 7) return 'Juli';
    if (i == 8) return 'Aug.';
    if (i == 9) return 'Sept.';
    if (i == 10) return 'Okt.';
    if (i == 11) return 'Nov.';
    return 'Dez.';
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
