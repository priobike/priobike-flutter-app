import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/summary.dart';

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
  Future<void> fetch() async {
    hadError = false;

    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.backend.path;
      final statusProviderSubPath = settings.predictionMode.statusProviderSubPath;
      var url = "https://$baseUrl/$statusProviderSubPath/status.json";
      final endpoint = Uri.parse(url);

      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching prediction status from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }

      final json = jsonDecode(response.body);
      current = StatusSummaryData.fromJson(json);

      isLoading = false;
      hadError = false;
      notifyListeners();
    } catch (e, stacktrace) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      final hint = "Error while fetching prediction status: $e $stacktrace";
      log.e(hint);
    }
  }

  /// Get the problem text if problems are detected.
  String? getProblem() {
    if (current == null) return null;

    String? problem;
    if (current!.mostRecentPredictionTime != null &&
        current!.mostRecentPredictionTime! <
            current!.statusUpdateTime && // Sometimes we may have a prediction "from the future".
        (current!.mostRecentPredictionTime! - current!.statusUpdateTime).abs() > const Duration(minutes: 5).inSeconds) {
      // Render the most recent prediction time as hh:mm.
      final time = DateTime.fromMillisecondsSinceEpoch(current!.mostRecentPredictionTime! * 1000);
      final formattedTime = "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
      problem =
          "Seit $formattedTime Uhr senden Ampeln keine oder nur noch wenige Daten. Klicke hier für eine Störungskarte.";
    } else if (current!.numThings != 0 &&
        (current!.numPredictions - current!.numBadPredictions) / current!.numThings < 0.5) {
      problem = "Gerade senden weniger Ampeln als gewöhnlich Daten. Klicke hier für eine Störungskarte.";
    } else if (current!.numPredictions != 0 && current!.numBadPredictions / current!.numPredictions > 0.5) {
      problem = "Viele Ampeln senden gerade lückenhafte Daten. Klicke hier für eine Störungskarte.";
    } else if (current!.averagePredictionQuality != null && current!.averagePredictionQuality! < 0.5) {
      problem =
          "Im Moment kann die Qualität der Geschwindigkeitsempfehlungen für Ampeln niedriger als gewohnt sein. Klicke hier für eine Störungskarte.";
    }

    return problem;
  }

  /// Get a text for the current status.
  String getStatusText() {
    if (current == null) return "";

    var info = "";

    var ratio = 0.0;
    if (current!.numThings != 0) {
      ratio = (current!.numPredictions - current!.numBadPredictions) / current!.numThings;
    }

    if (ratio > 0.95) {
      info += "Sieht sehr gut aus!";
    } else if (ratio > 0.9) {
      info += "Sieht gut aus.";
    } else if (ratio > 0.85) {
      info += "Sieht weitestgehend gut aus.";
    } else if (ratio > 0.8) {
      info += "Mit kleinen Ausnahmen sieht es gut aus.";
    } else if (ratio > 0.75) {
      info += "Es kommt zurzeit zu kleineren Einschränkungen.";
    } else {
      info += "Es kommt zurzeit zu größeren Einschränkungen.";
    }

    info += " Klicke hier für eine Störungskarte.";

    return info;
  }

  /// Loads the percentage of good predictions.
  double loadGood() {
    if (current == null) return 0.0;
    if (current!.mostRecentPredictionTime == null) return 0.0;

    if (current!.mostRecentPredictionTime! - current!.statusUpdateTime > const Duration(minutes: 5).inSeconds) {
      // Sometimes we may have a prediction "from the future".
      if (current!.mostRecentPredictionTime! < current!.statusUpdateTime) return 0.0;
    }
    if (current!.numPredictions == 0) return 0.0;
    if (current!.numThings == 0) return 0.0;

    return (current!.numPredictions - current!.numBadPredictions) / current!.numThings;
  }

  /// Reset the status.
  Future<void> reset() async {
    current = null;
    isLoading = false;
    hadError = false;
    notifyListeners();
  }
}
