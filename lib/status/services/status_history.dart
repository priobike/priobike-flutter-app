import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class StatusHistory with ChangeNotifier {
  /// TODO: Add documentation and maybe rename the variable.
  Map<DateTime, double> weekPredictions = {};

  /// TODO: Add documentation and maybe rename the variable.
  Map<DateTime, double> weekSubscriptions = {};

  /// TODO: Add documentation and maybe rename the variable.
  Map<DateTime, double> dayPredictions = {};

  /// TODO: Add documentation and maybe rename the variable.
  Map<DateTime, double> daySubscriptions = {};

  double maxSubscriptionsWeek = 0;

  double maxSubscriptionsDay = 0;

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// Logger for the status history.
  final log = Logger("StatusHistory");

  StatusHistory();

  List parseData(dynamic json) {
    final Map<DateTime, double> predictions = {};
    final Map<DateTime, double> subscriptions = {};
    double maxSubscriptions = 0;

    const predictionsKey = "average_prediction_service_predictions_count_total";
    const subscriptionsKey = "prediction_service_subscription_count_total";

    for (final entry in json[predictionsKey].entries) {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
      final predictionValue = entry.value.toDouble();

      predictions[date] = predictionValue;
      subscriptions[date] = json[subscriptionsKey][entry.key].toDouble();
      if (subscriptions[date]! > maxSubscriptions) {
        maxSubscriptions = subscriptions[date]!;
      }
    }

    return [predictions, subscriptions, maxSubscriptions];
  }

  /// Fetches the status history data from priobike-prediction-monitor.
  Future<void> fetch() async {
    hadError = false;

    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.backend.path;

      final urlDay = "https://$baseUrl/prediction-monitor-nginx/day-history.json";
      final urlWeek = "https://$baseUrl/prediction-monitor-nginx/week-history.json";
      final endpointDay = Uri.parse(urlDay);
      final endpointWeek = Uri.parse(urlWeek);

      final responseDay = await Http.get(endpointDay).timeout(const Duration(seconds: 4));
      if (responseDay.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching prediction status history from $endpointDay: ${responseDay.statusCode}";
        throw Exception(err);
      }

      final responseWeek = await Http.get(endpointWeek).timeout(const Duration(seconds: 4));
      if (responseWeek.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching prediction status history from $endpointWeek: ${responseWeek.statusCode}";
        throw Exception(err);
      }

      final jsonDay = jsonDecode(responseDay.body);
      final jsonWeek = jsonDecode(responseWeek.body);

      final dayData = parseData(jsonDay);
      dayPredictions = dayData[0];
      daySubscriptions = dayData[1];
      maxSubscriptionsDay = dayData[2];
      final weekData = parseData(jsonWeek);
      weekPredictions = weekData[0];
      weekSubscriptions = weekData[1];
      maxSubscriptionsWeek = weekData[2];

      isLoading = false;
      hadError = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      final hint = "Error while fetching prediction history status: $e";
      log.e(hint);
    }
  }

  /// Reset the status.
  Future<void> reset() async {
    weekPredictions = {};
    weekSubscriptions = {};
    maxSubscriptionsWeek = 0;
    dayPredictions = {};
    daySubscriptions = {};
    maxSubscriptionsDay = 0;
    isLoading = false;
    hadError = false;
    notifyListeners();
  }
}
