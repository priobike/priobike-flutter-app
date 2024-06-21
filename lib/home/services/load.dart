import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/node_status.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/features.dart';

class LoadStatus with ChangeNotifier {
  /// If the service is currently loading the status history.
  bool isLoading = false;

  /// If there exists a warning.
  bool hasWarning = false;

  /// If the fallback backend should be used.
  bool useFallback = false;

  /// Logger for the status history.
  final log = Logger("Load");

  LoadStatus();

  /// Fetches the status data and returns if the given backend is usable.
  Future<void> checkLoad(String baseUrl) async {
    try {
      final url = "https://$baseUrl/load-service/load.json";
      final endpoint = Uri.parse(url);

      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Error while fetching load status from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }

      final json = jsonDecode(response.body);
      final backendStatus = BackendStatus.fromJson(json);

      // Load status is updated every minute.
      // If the timestamp of the status is older than 5 minutes, we assume the backend is not usable.
      if (DateTime.now().difference(backendStatus.timestamp).inMinutes > 5) {
        hasWarning = true;
        useFallback = true;
        log.w("Load status is older than 5 minutes");
      } else {
        hasWarning = backendStatus.warning;
        useFallback = backendStatus.recommendOtherBackend;
      }
    } catch (e, stacktrace) {
      final hint = "Error while fetching load status: $e $stacktrace";
      log.e(hint);
    }

    if (getIt<Feature>().canEnableInternalFeatures) {
      // Don't switch the backend if the internal version is used. We want to keep the possibility
      // to manually set the backend.
      if (useFallback) {
        ToastMessage.showError(
            "Fallback müsste benutzt werden. Aufgrund der internen Version wird das Fallback jedoch nicht benutzt.");
      }
      useFallback = false;
    }

    notifyListeners();
  }

  /// Reset the status.
  Future<void> reset() async {
    hasWarning = false;
    isLoading = false;
    notifyListeners();
  }
}
