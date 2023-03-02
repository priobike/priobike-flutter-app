import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/messages/sgselector.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/route_multi_lane.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_selection_mode.dart';
import 'package:priobike/settings/models/sg_selector.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
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

class RoutingMultiLane with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Routing-Multi-Lane");

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

  /// The list of waypoints for SearchRoutingView.
  List<Waypoint?> routingItems = [];

  /// The index which routingBarItem gets highlighted next.
  int nextItem = -1;

  /// The currently selected route, if one fetched.
  RouteMultiLane? selectedRoute;

  /// All routes, if they were fetched.
  List<RouteMultiLane>? allRoutes;

  /// The route label coords.
  List<GHCoordinate> routeLabelCoords = [];

  /// Variable that holds the state of which the item should be minimized to max 3 items.
  bool minimized = false;

  RoutingMultiLane({
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
      selectedWaypoints!.add(waypoint);
      // Reset the previously generated route(s) and fetched waypoints.
      selectedRoute = null;
      allRoutes = null;
      fetchedWaypoints = null;
    }
    notifyListeners();
  }

  /// Add new route label coords.
  void addRouteLabelCoords(GHCoordinate coordinate) {
    routeLabelCoords.add(coordinate);
    // Use original notifyListeners to prevent setting camera to route bounds.
    super.notifyListeners();
  }

  /// Add new route label coords.
  void resetRouteLabelCoords() {
    routeLabelCoords = [];
    // Use original notifyListeners to prevent setting camera to route bounds.
    super.notifyListeners();
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

  /// Select the remaining waypoints.
  Future<void> selectRemainingWaypoints() async {
    final userPos = getIt<Positioning>().lastPosition;
    if (userPos == null) return;
    final userPosLatLng = LatLng(userPos.latitude, userPos.longitude);
    if (selectedWaypoints == null) return;
    // Find the waypoint segment with the shortest distance to our position.
    var shortestWaypointDistance = double.infinity;
    var shortestWaypointToIdx = 0;
    for (int i = 0; i < (selectedWaypoints!.length - 1); i++) {
      final w1 = selectedWaypoints![i], w2 = selectedWaypoints![i + 1];
      final p1 = LatLng(w1.lat, w1.lon), p2 = LatLng(w2.lat, w2.lon);
      final n = Snapper.calcNearestPoint(userPosLatLng, p1, p2);
      final d = Snapper.vincenty.distance(userPosLatLng, n);
      if (d < shortestWaypointDistance) {
        shortestWaypointDistance = d;
        shortestWaypointToIdx = i + 1;
      }
    }
    List<Waypoint> remaining = [Waypoint(userPos.latitude, userPos.longitude, address: "Aktuelle Position")];
    remaining += selectedWaypoints!.sublist(shortestWaypointToIdx);
    return await selectWaypoints(remaining);
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
    routeLabelCoords = [];
    minimized = false;
    notifyListeners();
  }

  /// Load a SG-Selector response.
  Future<SGSelectorResponse?> loadSGSelectorResponse(GHRouteResponsePath path) async {
    try {
      final settings = getIt<Settings>();

      final baseUrl = settings.backend.path;
      String usedRoutingParameter;
      if (settings.routingEndpoint == RoutingEndpoint.graphhopperDRN) {
        usedRoutingParameter = "drn";
      } else {
        usedRoutingParameter = "osm";
      }
      final sgSelectorUrl =
          "https://$baseUrl/sg-selector-backend/routing/${SGSelectionMode.single.path}?matcher=${settings.sgSelector.servicePathParameter}&routing=$usedRoutingParameter";
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
      final response = await Http.post(sgSelectorEndpoint, body: json.encode(req.toJson()));

      if (response.statusCode == 200) {
        log.i("Loaded SG-Selector response from $sgSelectorUrl");
        return SGSelectorResponse.fromJson(json.decode(response.body));
      } else {
        log.e("Failed to load SG-Selector response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e, stack) {
      final hint = "Failed to load SG-Selector response: $e";
      log.e(hint);

      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stack, hint: hint);
      }
      return null;
    }
  }

  /// Load a SG-Selector response.
  Future<SGSelectorMultiLaneResponse?> loadSGSelectorMultiLaneResponse(GHRouteResponsePath path) async {
    try {
      final settings = getIt<Settings>();

      final baseUrl = settings.backend.path;
      final sgSelectorUrl =
          "http://10.0.2.2:8000/routing/${SGSelectionMode.crossing.path}?bearingDiff=${settings.sgSelectionModeBearingDiff}";
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
      final response = await Http.post(sgSelectorEndpoint, body: json.encode(req.toJson()));

      if (response.statusCode == 200) {
        log.i("Loaded SG-Selector response from $sgSelectorUrl");
        return SGSelectorMultiLaneResponse.fromJson(json.decode(response.body));
      } else {
        log.e("Failed to load SG-Selector response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e, stack) {
      final hint = "Failed to load SG-Selector response: $e";
      log.e(hint);

      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stack, hint: hint);
      }
      return null;
    }
  }

  /// Select the correct profile.
  Future<RoutingProfile> selectProfile() async {
    final profile = getIt<Profile>();

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
    if (profile.activityType == ActivityType.allowIncline) {
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
  Future<GHRouteResponse?> loadGHRouteResponse(List<Waypoint> waypoints) async {
    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.backend.path;
      final servicePath = settings.routingEndpoint.servicePath;
      var ghUrl = "https://$baseUrl/$servicePath/route";
      ghUrl += "?type=json";
      ghUrl += "&locale=de";
      ghUrl += "&elevation=true";
      ghUrl += "&points_encoded=false";
      ghUrl += "&profile=${selectedProfile?.ghConfigName ?? RoutingProfile.bike2Default.ghConfigName}";
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
        return GHRouteResponse.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        log.e("Failed to load GraphHopper response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e, stacktrace) {
      final hint = "Failed to load GraphHopper response: $e";
      log.e(hint);
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stacktrace, hint: hint);
      }
      return null;
    }
  }

  /// Load the routes from the server.
  /// To execute this method, waypoints must be given beforehand.
  Future<List<RouteMultiLane>?> loadRoutes() async {
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
    selectedProfile = await selectProfile();

    // Load the GraphHopper response.
    final ghResponse = await loadGHRouteResponse(selectedWaypoints!);
    if (ghResponse == null || ghResponse.paths.isEmpty) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    List<RouteMultiLane> routes = [];

    // Load the SG-Selector responses for each path.
    final sgSelectorResponses =
        await Future.wait(ghResponse.paths.map((path) => loadSGSelectorMultiLaneResponse(path)));
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
    routes = ghResponse.paths
        .asMap()
        .map((i, path) {
          final sgSelectorResponse = sgSelectorResponses[i]!;
          var route = RouteMultiLane(
            id: i,
            path: path,
            route: path.points.coordinates
                .map((e) => NavigationNodeMultiLane(
                      lat: e.lat,
                      lon: e.lon,
                      alt: e.elevation ?? 0.0,
                    ))
                .toList(),
            signalGroups: sgSelectorResponse.signalGroups,
            crossings: sgSelectorResponse.crossings,
          );
          // Connect the route to the start and end points.
          route = route.connected(selectedWaypoints!.first, selectedWaypoints!.last);
          return MapEntry(i, route);
        })
        .values
        .toList();

    selectedRoute = routes.first;
    allRoutes = routes;
    fetchedWaypoints = selectedWaypoints!;
    isFetchingRoute = false;

    final discomforts = getIt<Discomforts>();
    await discomforts.findDiscomforts(routes.first.path);

    final status = getIt<PredictionSGStatus>();
    await status.fetchMulitLane(routes.first);

    // Force new route label coords.
    routeLabelCoords = [];
    notifyListeners();
    return routes;
  }

  /// Select a route.
  Future<void> switchToRoute(int idx) async {
    if (idx < 0 || idx >= allRoutes!.length) return;

    selectedRoute = allRoutes![idx];

    final discomforts = getIt<Discomforts>();
    await discomforts.findDiscomforts(selectedRoute!.path);

    final status = getIt<PredictionSGStatus>();
    await status.fetchMulitLane(selectedRoute!);

    notifyListeners();
  }

  void switchMinimized() {
    minimized = !minimized;
    // Use original notifyListeners to prevent setting camera to route bounds.
    super.notifyListeners();
  }

  void setMinimized() {
    minimized = false;
    // Use original notifyListeners to prevent setting camera to route bounds.
    super.notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
