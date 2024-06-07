import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/node_workload.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

// TODO maybe send these values from the load service.
// Unknown thresholds. Lets leave it at 80% for now.
const ingressLoadThreshold = 80.0;
// Should increase with increase of users.
// Note: in the release system this will be one node. If it is separated into multiple nodes, this should be adjusted.
const workerLoadThreshold = 85.0;
// Should be on a relatively stable rate. Current rate is 60% in release backend.
const statefulLoadThreshold = 70.0;

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

      // If one of the workloads is above 80%, we show a warning.
      if (nodeWorkload.stateful > statefulLoadThreshold ||
          nodeWorkload.worker > workerLoadThreshold ||
          nodeWorkload.ingress > ingressLoadThreshold) {
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

  /// Fetches the status data from the priobike-load-service for release and production and decides whether the failover (production) should be used.
  Future<bool> shouldUseFailover() async {
    NodeWorkload? nodeWorkloadRelease;
    NodeWorkload? nodeWorkloadProduction;

    // Try fetching status for release.
    try {
      // final baseUrlRelease = Backend.staging.path;
      final baseUrlRelease = Backend.release.path;

      final urlRelease = "https://$baseUrlRelease/load-service/load.json";
      final endpointRelease = Uri.parse(urlRelease);

      final responseRelease = await Http.get(endpointRelease).timeout(const Duration(seconds: 4));

      if (responseRelease.statusCode != 200) {
        final err = "Error while fetching load status from $endpointRelease: ${responseRelease.statusCode}";
        throw Exception(err);
      }

      final jsonRelease = jsonDecode(responseRelease.body);

      // jsonRelease['worker'] = jsonRelease['worker'] + 88.0;
      // print("jsonRelease" + jsonRelease.toString());

      nodeWorkloadRelease = NodeWorkload.fromJson(jsonRelease);
    } catch (e, stacktrace) {
      final hint = "Error while fetching load status: $e $stacktrace";
      log.e(hint);
    }

    // Try fetching status for production.
    try {
      final baseUrlProduction = Backend.production.path;

      final urlProduction = "https://$baseUrlProduction/load-service/load.json";
      final endpointProduction = Uri.parse(urlProduction);

      final responseProduction = await Http.get(endpointProduction).timeout(const Duration(seconds: 4));

      if (responseProduction.statusCode != 200) {
        final err = "Error while fetching load status from $endpointProduction: ${responseProduction.statusCode}";
        throw Exception(err);
      }

      final jsonProduction = jsonDecode(responseProduction.body);

      // print("jsonProduction" + jsonProduction.toString());

      nodeWorkloadProduction = NodeWorkload.fromJson(jsonProduction);
    } catch (e, stacktrace) {
      final hint = "Error while fetching load status: $e $stacktrace";
      log.e(hint);
    }

    // If production has no status, we should not use it.
    if (nodeWorkloadProduction == null) return false;

    // If release has no status, we should use the failover.
    if (nodeWorkloadRelease == null) return true;

    // Load status is updated every minute.
    // If the timestamp of the release status is older than 5 minutes, we should use the failover.
    if (DateTime.now().difference(nodeWorkloadRelease.timestamp).inMinutes > 5) {
      return true;
    }

    // If the timestamp of the production status is older than 5 minutes, we should not use the failover.
    if (DateTime.now().difference(nodeWorkloadProduction.timestamp).inMinutes > 5) {
      return false;
    }

    // Concept:
    // 1. Use the release backend as default.
    // 2. Depending on the load of the release backend, increase the chance of using the failover (prevent flooding).
    // 3. If the release backend is down, we have to use the failover and vice versa. (Already handled above)

    double chanceOfUsingFailover = 0.0;

    final diffStatefulNode = nodeWorkloadRelease.stateful - nodeWorkloadProduction.stateful;
    final diffWorkerNode = nodeWorkloadRelease.worker - nodeWorkloadProduction.worker;
    final diffIngressNode = nodeWorkloadRelease.ingress - nodeWorkloadProduction.ingress;

    // print("diffStatefulNode" + diffStatefulNode.toString());
    // print("diffWorkerNode" + diffWorkerNode.toString());
    // print("diffIngressNode" + diffIngressNode.toString());

    // if the production backend is more loaded than the release backend. We do not use the failover.
    if (diffStatefulNode + diffWorkerNode + diffIngressNode < 0) return false;

    // Increase the chance of using failover for all nodes.
    if (nodeWorkloadRelease.stateful > statefulLoadThreshold) {
      final diff = nodeWorkloadRelease.stateful - statefulLoadThreshold;
      final diffPercentage = diff / (100 - statefulLoadThreshold);
      chanceOfUsingFailover += diffPercentage;
    }

    // print("chanceOfUsingFailover" + chanceOfUsingFailover.toString());

    if (nodeWorkloadRelease.worker > workerLoadThreshold) {
      final diff = nodeWorkloadRelease.worker - workerLoadThreshold;
      final diffPercentage = diff / (100 - workerLoadThreshold);
      chanceOfUsingFailover += diffPercentage;
    }

    // print("chanceOfUsingFailover" + chanceOfUsingFailover.toString());

    if (nodeWorkloadRelease.ingress > ingressLoadThreshold) {
      final diff = nodeWorkloadRelease.ingress - ingressLoadThreshold;
      final diffPercentage = diff / (100 - ingressLoadThreshold);
      chanceOfUsingFailover += diffPercentage;
    }

    // print("chanceOfUsingFailover" + chanceOfUsingFailover.toString());

    // Note: if multiple nodes are above the threshold, the chance of using the failover can be greater then 1.
    // A switch should be executed definitely in this case.

    final random = Random();
    if (random.nextDouble() < chanceOfUsingFailover) return true;

    return false;
  }

  /// Reset the status.
  Future<void> reset() async {
    hasWarning = false;
    isLoading = false;
    notifyListeners();
  }
}
