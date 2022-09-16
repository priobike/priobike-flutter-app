import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/status/messages/status.dart';
import 'package:priobike/logging/logger.dart';
import 'package:http/http.dart' as http;
import 'package:priobike/logging/toast.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class PredictionStatus with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("PredictionStatus");

  /// The http client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// The current status of the prediction.
  PredictionMonitorStatusResponse? status;

  PredictionStatus() {
    log.i("PredictionStatus started.");
  }

  /// Fetch the status of the prediction.
  Future<void> fetchStatus(BuildContext context) async {
    if (isLoading || status != null || hadError) return;

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
      status = PredictionMonitorStatusResponse.fromJson(json);

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
    status = null;
    isLoading = false;
    hadError = false;
    notifyListeners();
  }
}