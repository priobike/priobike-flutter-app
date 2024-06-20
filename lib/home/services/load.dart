import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/node_status.dart';
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

  /// If the fallback backend should be used.
  bool useFallback = false;

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

      final nodeWorkload = NodeStatus.fromJson(json);

      // If one of the workloads is above 80%, we show a warning.
      if (nodeWorkload.warning) {
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

  /// Fetches the status data and returns if the given backend is usable.
  Future<bool> backendUsable(String baseUrl) async {
    try {
      final url = "https://$baseUrl/load-service/load.json";
      final endpoint = Uri.parse(url);

      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Error while fetching load status from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }

      final json = jsonDecode(response.body);

      final nodeStatus = NodeStatus.fromJson(json);

      // Load status is updated every minute.
      // If the timestamp of the status is older than 5 minutes, we assume the backend is not usable.
      if (DateTime.now().difference(nodeStatus.timestamp).inMinutes > 5) {
        return false;
      }

      return !nodeStatus.warning;
    } catch (e, stacktrace) {
      final hint = "Error while fetching load status: $e $stacktrace";
      log.e(hint);
      return false;
    }
  }

  /// Fetches the status data from release and production and decides which backend should be used.
  Future<Backend> getUsableBackend() async {
    final releaseBackendUsable = await backendUsable(Backend.release.path);
    if (releaseBackendUsable) return Backend.release;

    final productionBackendUsable = await backendUsable(Backend.production.path);
    if (productionBackendUsable) return Backend.production;

    // If both release and production have warnings, we should use release.
    return Backend.release;
  }

  /// Reset the status.
  Future<void> reset() async {
    hasWarning = false;
    isLoading = false;
    notifyListeners();
  }
}
