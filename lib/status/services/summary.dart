import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/status/messages/summary.dart';
import 'package:priobike/logging/logger.dart';
import 'package:http/http.dart' as http;
import 'package:priobike/logging/toast.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class PredictionStatusSummary with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("PredictionStatus");

  /// The http client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// The current status of the predictions.
  StatusSummaryData? current;

  PredictionStatusSummary() {
    log.i("PredictionStatus started.");
  }

  /// Fetch the status of the prediction.
  Future<void> fetch(BuildContext context) async {
    if (isLoading || hadError) return;

    // If the last fetched status is not older than 5 minutes,
    // we do not need to fetch it again.
    if (current != null) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final lastFetched = current!.statusUpdateTime;
      if (now - lastFetched < 5 * 60) return;
    }

    isLoading = true;
    notifyListeners();

    hadError = false;

    try {
      final settings = Provider.of<Settings>(context, listen: false);
      final baseUrl = settings.backend.path;
      var url = "https://$baseUrl/prediction-monitor-nginx/status.json";
      final endpoint = Uri.parse(url);

      final response = await httpClient.get(endpoint);
      if (response.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching prediction status: ${response.statusCode}";
        log.e(err); ToastMessage.showError(err); throw Exception(err);
      }

      final json = jsonDecode(response.body);
      current = StatusSummaryData.fromJson(json);

      isLoading = false;
      hadError = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      final err = "Error while fetching prediction status: $e";
      log.e(err); ToastMessage.showError(err); throw Exception(err);
    }
  }

  /// Reset the status.
  Future<void> reset() async {
    current = null;
    isLoading = false;
    hadError = false;
    notifyListeners();
  }
}