import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class TrafficService with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("TrafficService");

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// The predictions for traffic from t-1 hour to next t+5 hours.
  Map<String, dynamic>? trafficData;

  /// The last time the status was checked. Only check every hour.
  DateTime? lastChecked;

  /// The lowest value of the prediction. Used for scaling the barchart.
  double? lowestValue;

  /// The the score for the current hour.
  double? scoreNow;

  /// The historic average score for the current hour.
  double? historicScoreNow;

  /// If the service has loaded the status.
  bool? hasLoaded;

  /// The status of the score right now compared to the historic average.
  String? trafficStatus;

  TrafficService();

  /// Evaluate the traffic status.
  String evaluateTraffic() {
    double difference = scoreNow! / historicScoreNow!;
    if (difference > 1.03) {
      return "deutlich besser als gewöhnlich";
    } else if (difference < 0.97) {
      return "deutlich schlechter als gewöhnlich";
    } else if (difference > 1) {
      return "besser als gewöhnlich";
    } else if (difference < 1) {
      return "schlechter als gewöhnlich";
    } else {
      return "wie gewöhnlich";
    }
  }

  /// Fetch the status of the prediction.
  Future<void> fetch() async {
    hadError = false;

    if (isLoading) return;
    // No need to check more than once per minute.
    if ((lastChecked != null) && (DateTime.now().difference(lastChecked!) < const Duration(minutes: 1))) return;
    isLoading = true;

    try {
      final settings = getIt<Settings>();

      final baseUrl = settings.backend.path;
      var url = "https://$baseUrl/traffic-service/prediction.json";
      final endpoint = Uri.parse(url);
      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        isLoading = false;
        final err = "Error while fetching prediction status from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }
      trafficData = {};
      Map<String, dynamic> data = jsonDecode(response.body);
      for (String key in data.keys) {
        if (key.startsWith("quality") || key.startsWith("now")) {
          continue;
        }
        trafficData![key] = data[key];
      }
      for (double? value in trafficData!.values) {
        if (value == null) continue;
        lowestValue == null ? lowestValue = value : lowestValue = min(lowestValue!, value);
      }
      scoreNow = data["now"];
      historicScoreNow = trafficData![DateTime.now().hour.toString()];
      trafficStatus = evaluateTraffic();
      isLoading = false;
      hadError = false;
      hasLoaded = true;
      lastChecked = DateTime.now();
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hadError = true;
      hasLoaded = false;
      notifyListeners();
      log.e("Error while fetching traffic-service prediction: $e");
    }

    /// Reset the status.
    Future<void> reset() async {
      trafficData = null;
      isLoading = false;
      hadError = false;
      hasLoaded = false;
      lastChecked = null;
      scoreNow = null;
      historicScoreNow = null;
      lowestValue = null;
      trafficStatus = null;
      notifyListeners();
    }
  }
}
