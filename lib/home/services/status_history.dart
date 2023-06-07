import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';

class StatusHistory with ChangeNotifier {
  /// TODO: Add documentation and maybe rename the variable.
  List<dynamic> weekAveragePredictionQuality = List.empty(growable: true);

  /// TODO: Add documentation and maybe rename the variable.
  List<dynamic> weekTotalPredictionCount = List.empty(growable: true);

  /// TODO: Add documentation and maybe rename the variable.
  List<dynamic> dayAveragePredictionQuality = List.empty(growable: true);

  /// TODO: Add documentation and maybe rename the variable.
  List<dynamic> dayTotalPredictionCount = List.empty(growable: true);

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

      final weekHistoryDecode = jsonDecode(responseWeekHistory.body);
      weekAveragePredictionQuality = weekHistoryDecode["average_prediction_service_predictions_count_total"];
      weekTotalPredictionCount = weekHistoryDecode["prediction_service_subscription_count_total"];

      final dayHistoryDecode = jsonDecode(responseDayHistory.body);
      dayAveragePredictionQuality = dayHistoryDecode["average_prediction_service_predictions_count_total"];
      dayTotalPredictionCount = dayHistoryDecode["prediction_service_subscription_count_total"];
    } catch (e) {
      log.e("Status History could not be fetched: $e");
      return;
    }
    hasLoaded = true;
    notifyListeners();
  }
}
