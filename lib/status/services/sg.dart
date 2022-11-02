import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class PredictionSGStatus with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("PredictionSGStatus");

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

  PredictionSGStatus();

  /// Populate the sg status cache with the current route and
  /// Recalculate the status for this route.
  Future<void> fetch(
      BuildContext context, List<Sg> sgs, List<Crossing> crossings) async {
    if (isLoading) return;

    log.i(
        "Fetching sg status for ${sgs.length} sgs and ${crossings.length} crossings.");

    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    isLoading = true;
    notifyListeners();

    final pending = List<Future>.empty(growable: true);
    for (final sg in sgs) {
      if (cache.containsKey(sg.id)) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final lastFetched = cache[sg.id]!.statusUpdateTime;
        if (now - lastFetched < 5 * 60) continue;
      }

      try {
        var url =
            "https://$baseUrl/prediction-monitor-nginx/${sg.id}/status.json";
        log.i("Fetching $url");
        final endpoint = Uri.parse(url);

        final future = Http.get(endpoint).then((response) {
          if (response.statusCode == 200) {
            final data = SGStatusData.fromJson(jsonDecode(response.body));
            cache[sg.id] = data;
          } else {
            log.e("Failed to fetch $url: ${response.statusCode}");
          }
        }).catchError((error) {
          log.e("Failed to fetch $url: $error");
        });
        pending.add(future);
      } catch (e, stack) {
        final hint = "Error while fetching prediction status: $e";
        log.w(hint);
        Sentry.captureException(e, stackTrace: stack, hint: hint);
      }
    }

    // Wait for all requests to finish.
    await Future.wait(pending);

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
        case SGPredictionState.ok:
          ok++;
          break;
        case SGPredictionState.offline:
          offline++;
          break;
        case SGPredictionState.bad:
          bad++;
          break;
      }
    }

    disconnected = crossings.where((c) => !c.connected).length;

    log.i(
        "Fetched sg status for ${sgs.length} sgs and ${crossings.length} crossings.");
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
