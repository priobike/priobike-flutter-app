import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';

class StatusHistory with ChangeNotifier {
  /// The status history data of the last week.
  var weekHistoryData = <int, String>{};

  /// The status history data of the last day.
  var dayHistoryData = <int, String>{};

  /// An indicator if the data of this notifier changed.
  bool hasLoaded = false;

  /// Logger for the status history.
  final log = Logger("StatusHistory");

  StatusHistory() {
    fetch();
  }

  /// Fetches the status history data from priobike-prediction-monitor.
  Future<void> fetch() async {
    hasLoaded = false;
    const String urlWeekHistory =
        "http://priobike.vkw.tu-dresden.de/staging/prediction-monitor-nginx/week-history.json";
    const String urlDayHistory = "http://priobike.vkw.tu-dresden.de/staging/prediction-monitor-nginx/day-history.json";

    try {
      final responseWeekHistory = await Http.get(Uri.parse(urlWeekHistory)).timeout(const Duration(seconds: 4));
      final responseDayHistory = await Http.get(Uri.parse(urlDayHistory)).timeout(const Duration(seconds: 4));

      if (responseDayHistory.statusCode != 200 || responseWeekHistory.statusCode != 200) {
        final err =
            "Status History could not be fetched. Response from Week History: ${responseWeekHistory.body}, Response from Day History: ${responseDayHistory.body}";
        log.e(err);
        throw Exception(err);
      }

      weekHistoryData = jsonDecode(responseWeekHistory.body);
      dayHistoryData = jsonDecode(responseDayHistory.body);
    } catch (e) {
      log.e("Status History could not be fetched: $e");
      return;
    }
    hasLoaded = true;
    notifyListeners();
  }
}
