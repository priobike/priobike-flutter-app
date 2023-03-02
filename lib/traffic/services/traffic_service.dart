import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';

import '../../settings/services/settings.dart';

class TrafficService with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("TrafficService");

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  Map<String, double>? json;

  TrafficService();

  /// Fetch the status of the prediction.
  Future<void> fetch() async {
    hadError = false;

    if (isLoading) return;
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
      isLoading = false;
      hadError = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      final hint = "Error while fetching traffic-service prediction: $e";
      log.e(hint);
    }

    /// Reset the status.
    Future<void> reset() async {
      json = null;
      isLoading = false;
      hadError = false;
      notifyListeners();
    }
  }
}
