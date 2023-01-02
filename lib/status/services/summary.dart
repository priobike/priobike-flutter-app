import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/status/messages/summary.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class PredictionStatusSummary with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("PredictionStatusSummary");

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// The current status of the predictions.
  StatusSummaryData? current;

  PredictionStatusSummary();

  /// Fetch the status of the prediction.
  Future<void> fetch(BuildContext context) async {
    hadError = false;

    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final settings = Provider.of<Settings>(context, listen: false);
      final baseUrl = settings.backend.path;
      final statusProviderSubPath = settings.predictionMode.statusProviderSubPath;
      var url = "https://$baseUrl/$statusProviderSubPath/status.json";
      final endpoint = Uri.parse(url);

      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching prediction status from $endpoint: ${response.statusCode}";
        log.e(err);
        ToastMessage.showError(err);
        throw Exception(err);
      }

      final json = jsonDecode(response.body);
      current = StatusSummaryData.fromJson(json);

      isLoading = false;
      hadError = false;
      notifyListeners();
    } catch (e, stack) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      final hint = "Error while fetching prediction status: $e";
      Sentry.captureException(e, stackTrace: stack, hint: hint);
      log.e(hint);
      ToastMessage.showError(hint);
      throw Exception(hint);
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
