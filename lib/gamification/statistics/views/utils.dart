import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/common/database/database.dart';

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

  static String convertDoubleToStr(double num) {
    if (num < 10) return num.toStringAsFixed(1);
    return num.round().toString();
  }

  static String getListSumStr(List<double> list) {
    return StatUtils.convertDoubleToStr(list.reduce((a, b) => a + b));
  }

  static String getDateStr(DateTime date) {
    return DateFormat("dd.MM").format(date);
  }

  static String getFromToStr(DateTime first, DateTime last) {
    return '${getDateStr(first)} - ${getDateStr(last)}';
  }

  static double getDistanceSum(List<RideSummary> list) {
    if (list.isEmpty) return 0;
    var sum = list.map((r) => r.distanceMetres).reduce((a, b) => a + b) / 1000;
    if (sum > 10) sum = sum.floorToDouble();
    return sum;
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
