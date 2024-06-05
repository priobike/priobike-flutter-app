import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/node_workload.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class LoadStatus with ChangeNotifier {
  /// If the service is currently loading the status history.
  bool isLoading = false;

  /// If there exists a warning.
  bool hasWarning = false;

  /// Logger for the status history.
  final log = Logger("Load");

  LoadStatus();

  /// Fetches the status data from the priobike-load-service.
  Future<void> fetch() async {
    if (isLoading) return;
    isLoading = true;

    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.backend.path;

      final url = "https://$baseUrl/load-service/load.json";
      final endpoint = Uri.parse(url);

      // FIXME Do we want basic auth here? Needs to be placed in auth service then.
      const user = "";
      const pw = "";
      String basicAuth = 'Basic ${base64.encode(utf8.encode('$user:$pw'))}';

      final response = await Http.get(endpoint, headers: <String, String>{'authorization': basicAuth})
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching load status from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }

      final json = jsonDecode(response.body);

      final nodeWorkload = NodeWorkload.fromJson(json);

      if (nodeWorkload.stateful > 0.8) {
        hasWarning = true;
      } else {
        hasWarning = false;
      }

      isLoading = false;
      notifyListeners();
    } catch (e, stacktrace) {
      isLoading = false;
      notifyListeners();
      final hint = "Error while fetching load status: $e $stacktrace";
      log.e(hint);
    }
  }

  /// Sends an app start notification to the load service in the backend.
  Future<void> sendAppStartNotification() async {
    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.backend.path;

      final url = "https://$baseUrl/load-service/app/start";
      final endpoint = Uri.parse(url);

      final response = await Http.post(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Error while sending app start to load service $endpoint: ${response.statusCode}";
        throw Exception(err);
      }
    } catch (e, stacktrace) {
      final hint = "Error while sending app start to load service: $e $stacktrace";
      log.e(hint);
    }
  }

  /// Reset the status.
  Future<void> reset() async {
    hasWarning = false;
    isLoading = false;
    notifyListeners();
  }
}
