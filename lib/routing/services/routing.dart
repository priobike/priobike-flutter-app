import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/messages/sgselector.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

class Routing with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Routing");

  /// The HTTP client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// A boolean indicating if the service is currently loading the route.
  bool isFetchingRoute = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  /// The waypoints of the loaded route, if provided.
  List<Waypoint>? fetchedWaypoints;

  /// The waypoints of the selected route, if provided.
  List<Waypoint>? selectedWaypoints;

  /// The currently selected route, if one wetched.
  r.Route? selectedRoute;

  /// All routes, if they were fetched.
  List<r.Route>? allRoutes;

  Routing({
    this.fetchedWaypoints,
    this.selectedWaypoints,
    this.selectedRoute,
    this.allRoutes,
  }) { log.i("Routing started."); }

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
    notifyListeners();
  }

  // Reset the routing service.
  Future<void> reset() async {
    needsLayout = {};
    hadErrorDuringFetch = false;
    isFetchingRoute = false;
    fetchedWaypoints = null;
    selectedWaypoints = null;
    selectedRoute = null;
    allRoutes = null;
    notifyListeners();
  }

  /// Load a SG-Selector response.
  Future<SGSelectorResponse?> loadSGSelectorResponse(BuildContext context, GHRouteResponsePath path) async {
    try {
      final settings = Provider.of<Settings>(context, listen: false);

      final baseUrl = settings.backend.path;
      final sgSelectorUrl = "https://$baseUrl/sg-selector-backend/routing/select";
      final sgSelectorEndpoint = Uri.parse(sgSelectorUrl);
      log.i("Loading SG-Selector response from $sgSelectorUrl");

      final req = SGSelectorRequest(route: path.points.coordinates.map((e) => SGSelectorPosition(
        lat: e.lat, lon: e.lon, alt: e.elevation ?? 0.0,
      )).toList());
      final response = await httpClient.post(sgSelectorEndpoint, body: json.encode(req.toJson()));
      if (response.statusCode == 200) {
        return SGSelectorResponse.fromJson(json.decode(response.body));
      } else {
        log.e("Failed to load SG-Selector response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      log.e("Failed to load SG-Selector response: $e");
      return null;
    }
  }

  /// Load a GraphHopper response.
  Future<GHRouteResponse?> loadGHRouteResponse(BuildContext context, List<Waypoint> waypoints) async {
    try {
      final settings = Provider.of<Settings>(context, listen: false);

      final baseUrl = settings.backend.path;
      var ghUrl = "https://$baseUrl/graphhopper/route";
      ghUrl += "?type=json";
      ghUrl += "&locale=de";
      ghUrl += "&weighting=fastest";
      ghUrl += "&elevation=true";
      ghUrl += "&points_encoded=false";
      ghUrl += "&vehicle=bike2";
      // Add the supported details. This must be specified in the GraphHopper config.
      ghUrl += "&details=surface";
      ghUrl += "&details=max_speed";
      ghUrl += "&details=smoothness";
      ghUrl += "&details=lanes";
      if (waypoints.length == 2) {
        ghUrl += "&algorithm=alternative_route";
        ghUrl += "&ch.disable=true";
      }
      for (final waypoint in waypoints) {
        ghUrl += "&point=${waypoint.lat},${waypoint.lon}";
      }
      final ghEndpoint = Uri.parse(ghUrl);
      log.i("Loading GraphHopper response from $ghUrl");

      final response = await httpClient.get(ghEndpoint);
      if (response.statusCode == 200) {
        return GHRouteResponse.fromJson(json.decode(response.body));
      } else {
        log.e("Failed to load GraphHopper response: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e, stacktrace) {
      log.e("Failed to load GraphHopper response: $e $stacktrace");
      return null;
    }
  } 

  /// Load the routes from the server.
  /// To execute this method, waypoints must be given beforehand.
  Future<List<r.Route>?> loadRoutes(BuildContext context) async {
    if (isFetchingRoute) return null;

    // Do nothing if the waypoints were already fetched (or both are null).
    if (fetchedWaypoints == selectedWaypoints) return null;
    if (selectedWaypoints == null || selectedWaypoints!.isEmpty) return null;
    if (selectedWaypoints!.length < 2) return null;

    isFetchingRoute = true;
    hadErrorDuringFetch = false;
    notifyListeners();

    // Load the GraphHopper response.
    final ghResponse = await loadGHRouteResponse(context, selectedWaypoints!);
    if (ghResponse == null || ghResponse.paths.isEmpty) {
      hadErrorDuringFetch = true;
      isFetchingRoute = false;
      notifyListeners();
      return null;
    }

    // Load the SG-Selector responses for each path.
    final sgSelectorResponses = await Future.wait(ghResponse.paths.map((path) => loadSGSelectorResponse(context, path)));
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
    final routes = ghResponse.paths.asMap().map((i, path) {
      final sgSelectorResponse = sgSelectorResponses[i]!;
      var route = r.Route(path: path, route: sgSelectorResponse.route, signalGroups: sgSelectorResponse.signalGroups);
      // Connect the route to the start and end points.
      route = route.connected(selectedWaypoints!.first, selectedWaypoints!.last);
      return MapEntry(i, route);
    }).values.toList();

    selectedRoute = routes.first;
    allRoutes = routes;
    fetchedWaypoints = selectedWaypoints;
    isFetchingRoute = false;

    final discomforts = Provider.of<Discomforts>(context, listen: false);
    await discomforts.findDiscomforts(context, routes.first.path);

    final status = Provider.of<PredictionSGStatus>(context, listen: false);
    await status.fetch(context, routes.first.signalGroups.values.toList());

    notifyListeners();
    return routes;
  }

  /// Select a route.
  Future<void> switchToRoute(BuildContext context, r.Route route) async {
    // Can only select an alternative route if there are some, 
    // and if there is a currently selected route.
    selectedRoute = route;

    final discomforts = Provider.of<Discomforts>(context, listen: false);
    await discomforts.findDiscomforts(context, route.path);

    final status = Provider.of<PredictionSGStatus>(context, listen: false);
    await status.fetch(context, route.signalGroups.values.toList());

    notifyListeners();
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}