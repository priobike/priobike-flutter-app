import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/logging/logger.dart';
import 'package:http/http.dart' as http;
import 'package:priobike/logging/toast.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class PredictionSGStatus with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("PredictionSGStatus");

  /// The http client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// The cached sg status, by the sg name.
  Map<String, SGStatusData> cache = {};

  /// The number of sgs that are ok.
  int ok = 0;

  /// The number of sgs that are offline.
  int offline = 0;

  /// The number of sgs that have a bad quality.
  int bad = 0;

  /// The number of disconnected sgs.
  int disconnected = 0;

  PredictionSGStatus() {
    log.i("PredictionSGStatus started.");
  }

  /// Populate the sg status cache with the current route and
  /// Recalculate the status for this route. 
  Future<void> fetch(BuildContext context, List<Sg> sgs, List<Crossing> crossings) async {
    if (isLoading) return;

    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    isLoading = true;
    notifyListeners();

    for (final sg in sgs) {
      if (cache.containsKey(sg.id)) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final lastFetched = cache[sg.id]!.statusUpdateTime;
        if (now - lastFetched < 5 * 60) continue;
      }

      try {
        var url = "https://$baseUrl/prediction-monitor-nginx/${sg.id}/status.json";
        log.i("Fetching $url");
        final endpoint = Uri.parse(url);

        final response = await httpClient.get(endpoint);
        if (response.statusCode != 200) {
          isLoading = false;
          notifyListeners();
          final err = "Error while fetching prediction status: ${response.statusCode}";
          log.e(err); ToastMessage.showError(err); throw Exception(err);
        }

        final data = SGStatusData.fromJson(jsonDecode(response.body));
        cache[sg.id] = data;
      } catch (e) {
        log.w("Error while fetching prediction status: $e");
      }
    }

    ok = 0; 
    offline = 0; 
    bad = 0;
    for (final sg in sgs) {
      if (!cache.containsKey(sg.id)) {
        offline++;
        continue;
      }
      final status = cache[sg.id]!;
      switch (status.predictionState) {
        case SGPredictionState.ok: ok++; break;
        case SGPredictionState.offline: offline++; break;
        case SGPredictionState.bad: bad++; break;
      }
    }

    disconnected = crossings.where((c) => !c.connected).length;

    isLoading = false;
    notifyListeners();
  }

  /// Reset the status.
  Future<void> reset() async {
    cache = {};
    isLoading = false;
    notifyListeners();
  }
}