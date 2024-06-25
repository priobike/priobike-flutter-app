import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/backend_status.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';

class LoadStatus with ChangeNotifier {
  /// If there exists a warning.
  bool hasWarning = false;

  /// If the fallback backend should be used.
  bool useFallback = false;

  /// Logger for the status history.
  final log = Logger("Load");

  LoadStatus();

  /// Fetches the status data and returns if the given backend is usable.
  /// Otherwise also checking the fallback backend.
  /// If both backends are not usable, the default is used.
  Future<void> checkLoad() async {
    final baseUrl = getIt<Settings>().city.defaultBackend.path;
    var (hasWarning, recommendOtherBackend) = await fetchLoad(baseUrl);
    useFallback = recommendOtherBackend;
    this.hasWarning = hasWarning;

    if (recommendOtherBackend) {
      // If the default backend should not be used, we try to fetch the status of the fallback backend.
      // If the fallback backend is not usable, we use the default backend anyway.
      try {
        final baseUrl = getIt<Settings>().city.fallbackBackend?.path;

        if (baseUrl == null) {
          throw Exception("No fallback backend available");
        }

        var (_, recommendOtherBackend) = await fetchLoad(baseUrl);
        useFallback = !recommendOtherBackend;
      } catch (e, stacktrace) {
        final hint = "Error while checking fallback backend: $e $stacktrace";
        log.e(hint);
        useFallback = false;
      }
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

  /// Returns if a warning should be shown and if another backend should be used.
  Future<(bool, bool)> fetchLoad(String baseUrl) async {
    bool hasWarning = false;
    bool recommendOtherBackend = false;
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
        recommendOtherBackend = true;
        log.w("Load status is older than 5 minutes");
      } else {
        hasWarning = backendStatus.warning;
        recommendOtherBackend = backendStatus.recommendOtherBackend;
      }
    } catch (e, stacktrace) {
      final hint = "Error while fetching load status for backend: $e $stacktrace";
      log.e(hint);
      hasWarning = true;
    }
    return (hasWarning, recommendOtherBackend);
  }
}
