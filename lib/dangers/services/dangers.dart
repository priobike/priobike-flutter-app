import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/dangers/models/danger.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class Dangers with ChangeNotifier {
  final log = Logger("Dangers");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The list of dangers along the route.
  List<Danger> dangers = List.empty(growable: true);

  /// The distances of dangers along the route.
  List<double> dangersDistancesOnRoute = List.empty(growable: true);

  /// The upcoming danger, that should be shown to the user.
  Danger? upcomingDangerToDisplay;

  /// The distance to the upcoming danger, that should be shown to the user.
  double? distanceToUpcomingDangerToDisplay;

  /// The previous danger to vote for.
  Danger? previousDangerToVoteFor;

  /// The distance to the previous danger, that should be shown to the user.
  double? distanceToPreviousDangerToVoteFor;

  /// The distance threshold for computations.
  static const distanceThreshold = 100.0;

  /// The submitted votes for the dangers, by the pk of the danger.
  Map<int, int> votes = {};

  /// Load dangers along a route.
  Future<void> fetch(Route route) async {
    final settings = getIt<Settings>();
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
      final hint = "Error fetching dangers from $endpoint: $error";
      log.e(hint);
    }
  }

  /// Report a new danger.
  Future<void> submitNew(Snap? snap, String category) async {
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
    final settings = getIt<Settings>();
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
    } catch (error) {
      final hint = "Error sending danger to $endpoint: $error";
      log.e(hint);
    }
    // Add the danger to the list.
    dangers.add(danger);
    dangersDistancesOnRoute.add(snap.distanceOnRoute);
    notifyListeners();
  }

  /// Update the position.
  Future<void> calculateUpcomingAndPreviousDangers() async {
    final snap = getIt<Positioning>().snap;
    final route = getIt<Routing>().selectedRoute;
    if (snap == null || route == null) return;
    // First, go backwards and find a danger that the user should vote for.
    previousDangerToVoteFor = null;
    distanceToPreviousDangerToVoteFor = null;
    for (var i = dangers.length - 1; i >= 0; i--) {
      // Don't vote for dangers that were just reported.
      if (dangers[i].pk == null) continue;
      final danger = dangers[i];
      final distance = dangersDistancesOnRoute[i];
      // If we passed this danger, check if we already voted for it, and if not, show it to the user.
      if (distance < snap.distanceOnRoute && !votes.containsKey(danger.pk!)) {
        // Check if the danger is < 100m away.
        final dDist = (distance - snap.distanceOnRoute).abs();
        if (dDist < distanceThreshold) {
          previousDangerToVoteFor = danger;
          distanceToPreviousDangerToVoteFor = dDist;
          break;
        }
      }
    }
    // Now, go forwards and find a danger that we should show to the user.
    upcomingDangerToDisplay = null;
    distanceToUpcomingDangerToDisplay = null;
    for (var i = 0; i < dangers.length; i++) {
      final danger = dangers[i];
      final distance = dangersDistancesOnRoute[i];
      // If we did not pass this danger yet, show it to the user.
      if (distance > snap.distanceOnRoute) {
        // Check if the danger is < 100m away.
        final dDist = (distance - snap.distanceOnRoute).abs();
        if (dDist < distanceThreshold) {
          upcomingDangerToDisplay = danger;
          distanceToUpcomingDangerToDisplay = dDist;
          break;
        }
      }
    }
    notifyListeners();
  }

  /// Vote for a danger.
  Future<void> vote(Danger danger, int vote) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/dangers-service/dangers/vote/');
    final request = {
      "pk": danger.pk,
      "value": vote,
    };
    try {
      final response = await Http.post(endpoint, body: json.encode(request)).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        log.e("Error voting for danger $danger: ${response.body}");
      } else {
        log.i("Voted for danger $danger");
      }
    } catch (error) {
      final hint = "Error voting for danger $danger: $error";
      log.e(hint);
    }
    if (vote == 1) {
      ToastMessage.showSuccess("Gefahr bestätigt!");
    } else {
      ToastMessage.showSuccess("Meldung gespeichert!");
    }
    // Add the vote to the list.
    votes[danger.pk!] = vote;
    await calculateUpcomingAndPreviousDangers();
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
