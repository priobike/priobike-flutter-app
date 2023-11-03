import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class StatusHistory with ChangeNotifier {
  /// The count of predictions in the last week.
  Map<double, double> weekGoodPredictions = {};

  /// The count of subscriptions in the last week.
  Map<double, double> weekSubscriptions = {};

  /// The percentage of how many subscriptions also had a prediction in the last week.
  Map<double, double> weekPercentages = {};

  /// The count of predictions in the last day.
  Map<double, double> dayGoodPredictions = {};

  /// The count of subscriptions in the last day.
  Map<double, double> daySubscriptions = {};

  /// The percentage of how many subscriptions also had a prediction in the last day.
  Map<double, double> dayPercentages = {};

  /// If the service is currently loading the status history.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// Logger for the status history.
  final log = Logger("Status-History");

  StatusHistory();

  /// Parses the data from the json response.
  List parseData(dynamic json) {
    final Map<double, double> goodPredictions = {};
    final Map<double, double> subscriptions = {};
    final Map<double, double> percentages = {};
    double maxSubscriptions = 0;

    const predictionsKey = "prediction_service_good_prediction_total";
    const subscriptionsKey = "prediction_service_subscription_count_total";

    // Parse into maps and get max number of subscriptions.
    for (final entry in json[predictionsKey].entries) {
      final predictionValue = entry.value.toDouble();
      final double timestamp = double.parse(entry.key);

      goodPredictions[timestamp] = predictionValue;
      subscriptions[timestamp] = json[subscriptionsKey][entry.key].toDouble();
      if (subscriptions[timestamp]! > maxSubscriptions) {
        maxSubscriptions = subscriptions[timestamp]!;
      }
    }

    // Calculate percentages.
    for (final entry in goodPredictions.entries) {
      if (maxSubscriptions == 0) {
        percentages[entry.key] = 0;
        continue;
      }
      final percentage = entry.value / maxSubscriptions;
      percentages[entry.key] = percentage > 1 ? 1 : percentage;
    }

    return [goodPredictions, subscriptions, percentages];
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
      dayGoodPredictions = dayData[0];
      daySubscriptions = dayData[1];
      dayPercentages = dayData[2];
      final weekData = parseData(jsonWeek);
      weekGoodPredictions = weekData[0];
      weekSubscriptions = weekData[1];
      weekPercentages = weekData[2];

      isLoading = false;
      hadError = false;
      notifyListeners();
    } catch (e, stacktrace) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      final hint = "Error while fetching prediction history status: $e $stacktrace";
      log.e(hint);
    }
  }

  /// Reset the status.
  Future<void> reset() async {
    weekGoodPredictions = {};
    weekSubscriptions = {};
    weekPercentages = {};
    dayGoodPredictions = {};
    daySubscriptions = {};
    dayPercentages = {};
    isLoading = false;
    hadError = false;
    notifyListeners();
  }
}
