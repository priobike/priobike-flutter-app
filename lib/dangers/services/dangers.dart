import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/dangers/models/danger.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class Dangers with ChangeNotifier {
  final log = Logger("Dangers");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The list of dangers along the route.
  List<Danger> dangers = List.empty(growable: true);

  /// The distances of dangers along the route.
  List<double> dangersDistancesOnRoute = List.empty(growable: true);

  /// Report a new danger.
  Future<void> submitNew(BuildContext context, Snap? snap, String category) async {
    if (snap == null) {
      log.w("Cannot report a danger without a position.");
      return;
    }
    log.i("Reporting a new danger.");
    // Create the danger.
    final danger = Danger(
      lat: snap.position.latitude,
      lon: snap.position.longitude,
      category: category,
    );
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/dangers-service/dangers/post/');
    try {
      final response =
          await Http.post(endpoint, body: json.encode(danger.toJson())).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        log.e(
            "Error sending danger to $endpoint: ${response.body}"); // If feedback gets lost here, it's not a big deal.
      } else {
        log.i("Sent danger to $endpoint");
      }
    } on TimeoutException catch (error) {
      log.w("Timeout sending danger to $endpoint: $error");
    } on SocketException catch (error) {
      log.w("Error sending danger to $endpoint: $error");
    }
    // Add the danger to the list.
    dangers.add(danger);
    dangersDistancesOnRoute.add(snap.distanceOnRoute);
    notifyListeners();
  }

  /// The list of reported dangers during the ride.
  Future<void> clearDangers() async {
    dangers.clear();
    notifyListeners();
  }

  /// Reset the list of reported dangers.
  Future<void> reset() async {
    dangers = List.empty(growable: true);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
