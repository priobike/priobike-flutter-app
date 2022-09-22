import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/common/models/point.dart';
import 'package:priobike/routingNew/messages/routing.dart';
import 'package:priobike/routingNew/models/route.dart' as r;
import 'package:priobike/routingNew/models/waypoint.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routingNew/services/discomfort.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
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
  }) {
    log.i("Routing started.");
  }

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

  /// Load the routes from the server.
  /// To execute this method, waypoints must be given beforehand.
  Future<RoutesResponse?> loadRoutes(BuildContext context) async {
    if (isFetchingRoute) return null;

    // Do nothing if the waypoints were already fetched (or both are null).
    if (fetchedWaypoints == selectedWaypoints) return null;
    if (selectedWaypoints == null || selectedWaypoints!.isEmpty) return null;
    if (selectedWaypoints!.length < 2) return null;

    isFetchingRoute = true;
    notifyListeners();

    hadErrorDuringFetch = false;

    try {
      final settings = Provider.of<Settings>(context, listen: false);

      final baseUrl = settings.backend.path;
      final routeUrl = "https://$baseUrl/backend-service/routes";
      final routeEndpoint = Uri.parse(routeUrl);
      final routeRequest = RouteRequest(
        waypoints: selectedWaypoints!.map((e) => Point(lat: e.lat, lon: e.lon)).toList(),
      );
      final response = await httpClient.post(routeEndpoint, body: json.encode(routeRequest.toJson()));
      if (response.statusCode != 200) {
        isFetchingRoute = false;
        notifyListeners();
        final err = "Route could not be fetched from endpoint $routeEndpoint: ${response.body}";
        log.e(err); ToastMessage.showError(err); throw Exception(err);
      }

      final decoded = json.decode(response.body);
      final routeResponse = RoutesResponse
        .fromJson(decoded)
        .connected(selectedWaypoints!.first, selectedWaypoints!.last);
      if (routeResponse.routes.isEmpty) return null;
      selectedRoute = routeResponse.routes.first;
      allRoutes = routeResponse.routes;
      fetchedWaypoints = selectedWaypoints;
      isFetchingRoute = false;

      final discomforts = Provider.of<Discomforts>(context, listen: false);
      await discomforts.findDiscomforts(context, routeResponse.routes.first.path);

      notifyListeners();
      return routeResponse;
    } catch (error, stacktrace) {
      log.e("Error during load routes: $error $stacktrace");
      isFetchingRoute = false;
      hadErrorDuringFetch = true;
      notifyListeners();
      return null;
    }
  }

  /// Select a route.
  Future<void> switchToRoute(BuildContext context, r.Route route) async {
    // Can only select an alternative route if there are some,
    // and if there is a currently selected route.
    selectedRoute = route;

    final discomforts = Provider.of<Discomforts>(context, listen: false);
    await discomforts.findDiscomforts(context, route.path);

    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
