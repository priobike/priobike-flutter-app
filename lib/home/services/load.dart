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

      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));

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

  /// Reset the status.
  Future<void> reset() async {
    hasWarning = false;
    isLoading = false;
    notifyListeners();
  }
}
