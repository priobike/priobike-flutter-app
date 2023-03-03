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

  /// The json with prediction for traffic from -1 hour to next 5 hours.
  Map<String, dynamic>? json;

  /// The last time the status was checked. Only check every hour.
  DateTime? lastChecked;

  /// The lowest value of the prediction. Used for scaling the barchart.
  double? lowestValue;

  /// If the service has loaded the status.
  bool? hasLoaded;

  TrafficService();

  /// Fetch the status of the prediction.
  Future<void> fetch() async {
    hadError = false;

    if (isLoading) return;
    // Only check every 10 minutes.
    if ((lastChecked != null) && (DateTime.now().difference(lastChecked!) < const Duration(minutes: 10))) return;
    isLoading = true;
    notifyListeners();

    try {
      final settings = getIt<Settings>();

      final baseUrl = settings.backend.path;
      var url = "https://$baseUrl/traffic-service/prediction.json";
      final endpoint = Uri.parse(url);
      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching prediction status from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }
      json = jsonDecode(response.body);
      for (double? value in json!.values) {
        if (value == null) continue;
        lowestValue == null ? lowestValue = value : lowestValue = min(lowestValue!, value);
      }

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
      json = null;
      isLoading = false;
      hadError = false;
      hasLoaded = false;
      lastChecked = null;
      lowestValue = null;
      notifyListeners();
    }
  }
}
