import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class Traffic with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Traffic");

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// The predictions for traffic from t-1 hour to next t+5 hours.
  Map<int, double?>? trafficData;

  /// The last time the status was checked. Only check every hour.
  DateTime? lastChecked;

  /// The the score for the current hour.
  double? scoreNow;

  /// The historic average score for the current hour.
  double? historicScore;

  /// If the service has loaded the status.
  bool hasLoaded = false;

  /// The classification of the current traffic flow.
  String? get trafficClass {
    if (scoreNow == null || historicScore == null) {
      return "Keine Daten";
    }
    if (historicScore == 0) {
      return "Keine Daten";
    }
    if (scoreNow! > 0.98) {
      return "Kaum Verkehr";
    } else if (scoreNow! > 0.97) {
      return "Leichter Verkehr";
    } else if (scoreNow! > 0.96) {
      return "Mäßiger Verkehr";
    } else if (scoreNow! > 0.95) {
      return "Starker Verkehr";
    } else {
      return "Sehr starker Verkehr";
    }
  }

  /// The color of the current traffic flow.
  Color? get trafficColor {
    if (scoreNow == null) {
      return null;
    }
    if (scoreNow! > 0.96) {
      return CI.blue;
    } else {
      return CI.blue;
    }
  }

  /// The difference of the current traffic flow compared to the historic average.
  String? get trafficDifference {
    if (scoreNow == null || historicScore == null) {
      return "Keine Daten";
    }
    if (historicScore == 0) {
      return "Keine Daten";
    }
    double difference = scoreNow! - historicScore!;
    // difference > 0 => less traffic than usual
    // difference < 0 => more traffic than usual
    if (difference > 0.006) {
      return "Deutlich weniger als gewöhnlich";
    } else if (difference > 0.001) {
      return "Weniger als gewöhnlich";
    } else if (difference < -0.006) {
      return "Deutlich mehr als gewöhnlich";
    } else if (difference < -0.001) {
      return "Mehr als gewöhnlich";
    } else {
      return "Wie immer zu dieser Zeit";
    }
  }

  Traffic();

  /// Fetch the status of the prediction.
  Future<void> fetch() async {
    hadError = false;

    if (isLoading) return;
    // No need to check more than once per minute.
    if ((lastChecked != null) && (DateTime.now().difference(lastChecked!) < const Duration(minutes: 1))) return;
    isLoading = true;
    hasLoaded = false;

    try {
      final settings = getIt<Settings>();

      final baseUrl = settings.backend.path;
      String url = "https://$baseUrl/traffic-service/prediction.json";
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
        // if the JSON contains other keys, this needs to be updated.
        if (key.startsWith("quality") || key.startsWith("now")) {
          continue;
        }
        trafficData![int.parse(key)] = data[key] as double?;
      }
      scoreNow = data["now"];
      historicScore = trafficData![DateTime.now().hour];
      isLoading = false;
      hadError = false;
      hasLoaded = true;
      lastChecked = DateTime.now();
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      log.e("Error while fetching traffic-service prediction: $e");
    }
  }
}
