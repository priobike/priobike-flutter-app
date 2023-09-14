import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';

/// Fixed long duration for animations and stuff.
class LongDuration extends Duration {
  const LongDuration() : super(milliseconds: 1000);
}

/// Fixed medium duration for animations and stuff.
class MediumDuration extends Duration {
  const MediumDuration() : super(milliseconds: 500);
}

/// Fixed short duration for animations and stuff.
class ShortDuration extends Duration {
  const ShortDuration() : super(milliseconds: 250);
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

  /// Get formatted string for a given double by rounding it and giving it appending a fitting label.
  static String getFormattedStrByRideType(double value, StatType type) {
    return '${getRoundedStrByRideType(value, type)} ${getLabelForRideType(type)}';
  }

  /// Returns a fitting label for a given ride type, consisting of the unit describing the type.
  static String getLabelForRideType(StatType type) {
    if (type == StatType.distance) return 'km';
    if (type == StatType.duration) return 'min';
    if (type == StatType.speed) return 'km/h';
    if (type == StatType.elevationGain) return 'm';
    if (type == StatType.elevationLoss) return 'm';
    return '';
  }

  /// Rounds and returns a given value for a given challenge type as a string.
  static getRoundStrByChallengeType(int value, var type) {
    if (type == DailyChallengeType.distance || type == WeeklyChallengeType.overallDistance) {
      double valueInKm = value / 1000;
      if (valueInKm - valueInKm.floor() == 0) return valueInKm.toStringAsFixed(0);
      return valueInKm.toStringAsFixed(1);
    }
    return value.toString();
  }

  /// Returns a label for the values of a given challenge type as a string.
  static String getLabelForChallengeType(var type) {
    if (type == DailyChallengeType.distance) return 'km';
    if (type == WeeklyChallengeType.overallDistance) return 'km';
    if (type == DailyChallengeType.duration) return 'min';
    if (type == DailyChallengeType.elevation) return 'm';
    if (type == WeeklyChallengeType.daysWithGoalsCompleted) return 'Tage';
    if (type == WeeklyChallengeType.routeRidesPerWeek) return 'Fahrten';
    if (type == WeeklyChallengeType.routeStreakInWeek) return 'Fahrten';
    return '';
  }

  /// Round a given value according to a given ride info type.
  static String getRoundedStrByRideType(double value, StatType type) {
    if ((type == StatType.distance || type == StatType.speed) && value < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Returns a fitting string for a given month and year.
  static String getMonthAndYearStr(int month, int year) => '${getMonthStr(month)} $year';

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
