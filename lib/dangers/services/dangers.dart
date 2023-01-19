import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:priobike/dangers/models/danger.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
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

  /// The submitted votes for the dangers, by the pk of the danger.
  Map<String, bool> votes = {};

  /// Load dangers along a route.
  Future<void> fetch(Route route, BuildContext context) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/dangers-service/dangers/match/');
    final request = {
      "route": route.path.points.coordinates.map((e) => {"lat": e.lat, "lon": e.lon}).toList(),
    };
    try {
      final response = await Http.post(endpoint, body: json.encode(request)).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        log.e("Error fetching dangers from $endpoint: ${response.body}");
      } else {
        log.i("Fetched dangers from $endpoint");
        final decoded = json.decode(response.body);
        dangers = (decoded["dangers"] as List).map<Danger>((e) => Danger.fromJson(e)).toList();
        // Compute the distances of the dangers along the route.
        dangersDistancesOnRoute = dangers
            .map(
              (d) => Snapper(
                position: LatLng(d.lat, d.lon),
                nodes: route.route,
              ).snap().distanceOnRoute,
            )
            .toList();
        notifyListeners();
      }
    } catch (error) {
      log.e("Error fetching dangers from $endpoint: $error");
    }
  }

  /// Report a new danger.
  Future<void> submitNew(BuildContext context, Snap? snap, String category) async {
    if (snap == null) {
      log.w("Cannot report a danger without a position.");
      return;
    }
    log.i("Reporting a new danger.");
    // Create the danger.
    final danger = Danger(
      pk: null, // The server will assign a pk.
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

  /// Update the position.
  Future<void> updatePosition(BuildContext context) async {
    final snap = Provider.of<Positioning>(context, listen: false).snap;
    final route = Provider.of<Routing>(context, listen: false).selectedRoute;
    if (snap == null || route == null) return;
  }

  /// The list of reported dangers during the ride.
  Future<void> clearDangers() async {
    dangers.clear();
    dangersDistancesOnRoute.clear();
    notifyListeners();
  }

  /// Reset the list of reported dangers.
  Future<void> reset() async {
    dangers = List.empty(growable: true);
    dangersDistancesOnRoute = List.empty(growable: true);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
