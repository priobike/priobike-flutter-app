import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/routingNew/messages/graphhopper.dart';
import 'package:priobike/routing/messages/sgselector.dart';
import 'package:priobike/routingNew/models/route.dart' as r;
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routingNew/services/discomfort.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum RoutingProfile {
  bikeDefault, // Bike doesn't consider elevation data.
  bikeShortest,
  bikeFastest,
  bike2Default, // Bike2 considers elevation data (avoid uphills).
  bike2Shortest,
  bike2Fastest,
  racingbikeDefault,
  racingbikeShortest,
  racingbikeFastest,
  mtbDefault,
  mtbShortest,
  mtbFastest,
}

extension RoutingProfileExtension on RoutingProfile {
  String get ghConfigName {
    switch (this) {
      case RoutingProfile.bikeDefault:
        return "bike_default";
      case RoutingProfile.bikeShortest:
        return "bike_shortest";
      case RoutingProfile.bikeFastest:
        return "bike_fastest";
      case RoutingProfile.bike2Default:
        return "bike2_default";
      case RoutingProfile.bike2Shortest:
        return "bike2_shortest";
      case RoutingProfile.bike2Fastest:
        return "bike2_fastest";
      case RoutingProfile.racingbikeDefault:
        return "racingbike_default";
      case RoutingProfile.racingbikeShortest:
        return "racingbike_shortest";
      case RoutingProfile.racingbikeFastest:
        return "racingbike_fastest";
      case RoutingProfile.mtbDefault:
        return "mtb_default";
      case RoutingProfile.mtbShortest:
        return "mtb_shortest";
      case RoutingProfile.mtbFastest:
        return "mtb_fastest";
    }
  }

  String get explanation {
    switch (this) {
      case RoutingProfile.bikeDefault:
        return "Standard";
      case RoutingProfile.bikeShortest:
        return "Kürzeste Strecke";
      case RoutingProfile.bikeFastest:
        return "Schnellste Strecke";
      case RoutingProfile.bike2Default:
        return "Anstiege vermeiden";
      case RoutingProfile.bike2Shortest:
        return "Anstiege vermeiden - Kürzeste Strecke";
      case RoutingProfile.bike2Fastest:
        return "Anstiege vermeiden - Schnellste Strecke";
      case RoutingProfile.racingbikeDefault:
        return "Rennrad";
      case RoutingProfile.racingbikeShortest:
        return "Rennrad - Kürzeste Strecke";
      case RoutingProfile.racingbikeFastest:
        return "Rennrad - Schnellste Strecke";
      case RoutingProfile.mtbDefault:
        return "Mountainbike";
      case RoutingProfile.mtbShortest:
        return "Mountainbike - Kürzeste Strecke";
      case RoutingProfile.mtbFastest:
        return "Mountainbike - Schnellste Strecke";
    }
  }
}

class Routing with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Routing");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// A boolean indicating if the service is currently loading the route.
  bool isFetchingRoute = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  /// The waypoints of the loaded route, if provided.
  List<Waypoint>? fetchedWaypoints;

  /// The selected graphhopper routing profile.
  RoutingProfile? selectedProfile;

  /// The waypoints of the selected route, if provided.
  List<Waypoint>? selectedWaypoints;

  /// The list of waypoints for SearchRoutingView
  List<Waypoint?> routingItems = [];

  /// The index which routingBarItem gets filled next
  int nextItem = -1;

  /// The currently selected route, if one fetched.
  r.Route? selectedRoute;

  /// All routes, if they were fetched.
  List<r.Route>? allRoutes;

  /// The routeType.
  String routeType = "Schnell";

  Routing({
    this.fetchedWaypoints,
    this.selectedWaypoints,
    this.selectedRoute,
    this.allRoutes,
  });

  /// Add a new waypoint.
  Future<void> addWaypoint(Waypoint waypoint) async {
    if (selectedWaypoints == null) {
      selectedWaypoints = [waypoint];
    } else {
      selectedWaypoints = selectedWaypoints! + [waypoint];
    }
    notifyListeners();
  }

  /// Select new waypoints.
  Future<void> selectWaypoints(List<Waypoint>? waypoints) async {
    selectedWaypoints = waypoints;
    if ((waypoints?.length ?? 0) < 2) {
      selectedRoute = null;
      allRoutes = null;
      fetchedWaypoints = null;
    }
    notifyListeners();
  }

  /// Select new waypoints.
  Future<void> selectRoutingItems(List<Waypoint?> waypoints) async {
    routingItems = waypoints;
    notifyListeners();
  }

  // Reset the routing service.
  Future<void> reset() async {
    needsLayout = {};
    hadErrorDuringFetch = false;
    isFetchingRoute = false;
    fetchedWaypoints = null;
    selectedWaypoints = null;
    routingItems = [];
    nextItem = -1;
    selectedRoute = null;
    allRoutes = null;
    notifyListeners();
  }

  /// Load a SG-Selector response.
  Future<SGSelectorResponse?> loadSGSelectorResponse(
      BuildContext context, GHRouteResponsePath path) async {
    try {
      final settings = Provider.of<Settings>(context, listen: false);

      final baseUrl = settings.backend.path;
      final sgSelectorUrl =
          "https://$baseUrl/sg-selector-backend/routing/select";
      final sgSelectorEndpoint = Uri.parse(sgSelectorUrl);
      log.i("Loading SG-Selector response from $sgSelectorUrl");

      final req = SGSelectorRequest(
          route: path.points.coordinates
              .map((e) => SGSelectorPosition(
                    lat: e.lat,
                    lon: e.lon,
                    alt: e.elevation ?? 0.0,
                  ))
              .toList());
      final response =
          await Http.post(sgSelectorEndpoint, body: json.encode(req.toJson()));

      if (response.statusCode == 200) {
        log.i("Loaded SG-Selector response from $sgSelectorUrl");
        return SGSelectorResponse.fromJson(json.decode(response.body));
      } else {
        log.e(
            "Failed to load SG-Selector response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e, stack) {
      final hint = "Failed to load SG-Selector response: $e";
      log.e(hint);

      if (!kDebugMode) {
        await Sentry.captureException(e, stackTrace: stack, hint: hint);
      }
      return null;
    }
  }

  /// Select the correct profile.
  Future<RoutingProfile> selectProfile(BuildContext context) async {
    final profile = Provider.of<Profile>(context, listen: false);

    // Look for specific bike types first.
    if (profile.bikeType == BikeType.mountainbike) {
      if (profile.preferenceType == PreferenceType.fast) {
        return RoutingProfile.mtbFastest;
      } else if (profile.preferenceType == PreferenceType.short) {
        return RoutingProfile.mtbShortest;
      } else {
        return RoutingProfile.mtbDefault;
      }
    }
    if (profile.bikeType == BikeType.racingbike) {
      if (profile.preferenceType == PreferenceType.fast) {
        return RoutingProfile.racingbikeFastest;
      } else if (profile.preferenceType == PreferenceType.short) {
        return RoutingProfile.racingbikeShortest;
      } else {
        return RoutingProfile.racingbikeDefault;
      }
    }

    // Check if the user wants to do sport - if so, ignore elevation.
    if (profile.activityType == ActivityType.sport) {
      if (profile.preferenceType == PreferenceType.fast) {
        return RoutingProfile.bikeFastest;
      } else if (profile.preferenceType == PreferenceType.short) {
        return RoutingProfile.bikeShortest;
      } else {
        return RoutingProfile.bikeDefault;
      }
    }

    if (profile.preferenceType == PreferenceType.fast) {
      return RoutingProfile.bike2Fastest;
    } else if (profile.preferenceType == PreferenceType.short) {
      return RoutingProfile.bike2Shortest;
    } else {
      return RoutingProfile.bike2Default;
    }
  }

  /// Load a GraphHopper response.
  Future<GHRouteResponse?> loadGHRouteResponse(
      BuildContext context, List<Waypoint> waypoints) async {
    try {
      final settings = Provider.of<Settings>(context, listen: false);
      final baseUrl = settings.backend.path;
      final servicePath = settings.routingEndpoint.servicePath;
      var ghUrl = "https://$baseUrl/$servicePath/route";
      ghUrl += "?type=json";
      ghUrl += "&locale=de";
      ghUrl += "&elevation=true";
      ghUrl += "&points_encoded=false";
      ghUrl +=
          "&profile=${selectedProfile?.ghConfigName ?? RoutingProfile.bike2Default.ghConfigName}";
      // Add the supported details. This must be specified in the GraphHopper config.
      ghUrl += "&details=surface";
      ghUrl += "&details=max_speed";
      ghUrl += "&details=smoothness";
      ghUrl += "&details=lanes";
      ghUrl += "&details=road_class";
      if (waypoints.length == 2) {
        ghUrl += "&algorithm=alternative_route";
        ghUrl += "&ch.disable=true";
      }
      for (final waypoint in waypoints) {
        ghUrl += "&point=${waypoint.lat},${waypoint.lon}";
      }
      final ghEndpoint = Uri.parse(ghUrl);
      log.i("Loading GraphHopper response from $ghUrl");

      final response = await Http.get(ghEndpoint);
      if (response.statusCode == 200) {
        log.i("Loaded GraphHopper response from $ghUrl");
        return GHRouteResponse.fromJson(
            json.decode(utf8.decode(response.bodyBytes)));
      } else {
        log.e(
            "Failed to load GraphHopper response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e, stacktrace) {
      final hint = "Failed to load GraphHopper response: $e";
      log.e(hint);
      if (!kDebugMode) {
        await Sentry.captureException(e, stackTrace: stacktrace, hint: hint);
      }
      return null;
    }
  }

  /// Load the routes from the server.
  /// To execute this method, waypoints must be given beforehand.
  Future<List<r.Route>?> loadRoutes(BuildContext context) async {
    if (isFetchingRoute) return null;

    // Do nothing if the waypoints were already fetched (or both are null).
    if (fetchedWaypoints == selectedWaypoints) return null;
    if (selectedWaypoints == null || selectedWaypoints!.isEmpty || selectedWaypoints!.length < 2) {
      hadErrorDuringFetch = false;
      notifyListeners();
      return null;
    }

    isFetchingRoute = true;
    hadErrorDuringFetch = false;
    notifyListeners();

    // Select the correct profile.
    selectedProfile = await selectProfile(context);

    // Load the GraphHopper response.
    final ghResponse = await loadGHRouteResponse(context, selectedWaypoints!);
    if (ghResponse == null || ghResponse.paths.isEmpty) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    // Load the SG-Selector responses for each path.
    final sgSelectorResponses =
        await Future.wait(ghResponse.paths.map((path) => loadSGSelectorResponse(context, path)));
    if (sgSelectorResponses.contains(null)) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    if (ghResponse.paths.length != sgSelectorResponses.length) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    // Create the routes.
    final routes = ghResponse.paths
        .asMap()
        .map(
          (i, path) {
            final sgSelectorResponse = sgSelectorResponses[i]!;
            final sgsInOrderOfRoute = List<Sg>.empty(growable: true);
            for (final waypoint in sgSelectorResponse.route) {
              if (waypoint.signalGroupId == null) continue;
              final sg = sgSelectorResponse.signalGroups[waypoint.signalGroupId];
              if (sg == null) continue;
              if (sgsInOrderOfRoute.contains(sg)) continue;
              sgsInOrderOfRoute.add(sg);
            }
            var route = r.Route(
              id: i,
              path: path,
              route: sgSelectorResponse.route,
              signalGroups: sgsInOrderOfRoute,
              crossings: sgSelectorResponse.crossings,
            );
            // Connect the route to the start and end points.
            route = route.connected(selectedWaypoints!.first, selectedWaypoints!.last);
            return MapEntry(i, route);
          },
        )
        .values
        .toList();

    selectedRoute = routes.first;
    allRoutes = routes;
    fetchedWaypoints = selectedWaypoints;
    isFetchingRoute = false;
    routeType = "Schnell";

    final discomforts = Provider.of<Discomforts>(context, listen: false);
    await discomforts.findDiscomforts(context, routes.first.path);

    final status = Provider.of<PredictionSGStatus>(context, listen: false);
    await status.fetch(
        context, routes.first.signalGroups, routes.first.crossings);

    notifyListeners();
    return routes;
  }

  /// Select a route.
  Future<void> switchToRoute(BuildContext context, int idx) async {
    if (idx < 0 || idx >= allRoutes!.length) return;

    routeType = selectedRoute!.id == 0 ? "Bequem" : "Schnell";

    selectedRoute = allRoutes![idx];

    final discomforts = Provider.of<Discomforts>(context, listen: false);
    await discomforts.findDiscomforts(context, selectedRoute!.path);

    final status = Provider.of<PredictionSGStatus>(context, listen: false);
    await status.fetch(context, selectedRoute!.signalGroups, selectedRoute!.crossings);

    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
