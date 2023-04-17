import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';

class PredictionSGStatus with ChangeNotifier {
  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

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
  Future<void> fetch(Route? route) async {
    if (isLoading) return;

    log.i("Fetching sg status for ${route?.signalGroups.length} sgs and ${route?.crossings.length} crossings.");

    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final statusProviderSubPath = settings.predictionMode.statusProviderSubPath;

    isLoading = true;
    notifyListeners();

    final pending = List<Future>.empty(growable: true);
    for (final sg in route?.signalGroups ?? []) {
      if (cache.containsKey(sg.id)) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final lastFetched = cache[sg.id]!.statusUpdateTime;
        if (now - lastFetched < 5 * 60) continue;
      }

      try {
        var url = "https://$baseUrl/$statusProviderSubPath/${sg.id}/status.json";
        log.i("Fetching $url");
        final endpoint = Uri.parse(url);

        final future = Http.get(endpoint).then(
          (response) {
            if (response.statusCode == 200) {
              final data = SGStatusData.fromJson(jsonDecode(response.body));
              cache[sg.id] = data;
              log.i("Fetched status for ${sg.id}.");
            } else {
              log.e("Failed to fetch $url: ${response.statusCode}");
            }
          },
        ).catchError(
          (error) {
            log.e("Failed to fetch $url: $error");
          },
        );
        pending.add(future);
      } catch (e) {
        final hint = "Error while fetching prediction status: $e";
        log.e(hint);
      }
    }

    // Wait for all requests to finish.
    await Future.wait(pending);

    ok = 0;
    offline = 0;
    bad = 0;
    for (final sg in route?.signalGroups ?? []) {
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

    disconnected = route?.crossings.where((c) => !c.connected).length ?? 0;

    log.i("Fetched sg status for ${route?.signalGroups.length} sgs and ${route?.crossings.length} crossings.");
    isLoading = false;
    notifyListeners();
  }

  /// During the ride we receive predictions from a MQTT service.
  /// When we receive a new prediction, we want to update the status.
  /// In this way the UI can adapt to the new prediction.
  onNewPredictionStatusDuringRide(SGStatusData status) {
    log.i("Received new prediction status for ${status.thingName}.");
    cache[status.thingName] = status;
    // Note: We don't need to update the statistics here,
    // because we are in the ride and the statistics are not shown.
    notifyListeners();
  }

  /// Reset the status.
  Future<void> reset() async {
    cache = {};
    offline = 0;
    bad = 0;
    disconnected = 0;
    ok = 0;
    isLoading = false;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
