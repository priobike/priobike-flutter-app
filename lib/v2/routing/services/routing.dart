
import 'package:flutter/material.dart';
import 'package:priobike/v2/common/logger.dart';
import 'package:priobike/v2/routing/models/route.dart' as route;
import 'package:priobike/v2/routing/models/waypoint.dart';

class RoutingService with ChangeNotifier {
  /// The logger for this service.
  final Logger log = Logger("RoutingService");

  /// A boolean indicating if the service is currently loading the route.
  bool isFetchingRoute = true;

  /// The waypoints of the loaded route, if provided.
  List<Waypoint>? fetchedWaypoints;

  /// The waypoints of the selected route, if provided.
  List<Waypoint>? selectedWaypoints;

  /// The currently selected route, if one was fetched.
  route.Route? selectedRoute;

  /// The alternative routes, if they were fetched.
  List<route.Route>? altRoutes;

  RoutingService({
    this.fetchedWaypoints,
    this.selectedWaypoints,
    this.selectedRoute,
    this.altRoutes,
  }) { log.i("RoutingService started."); }

  /// Load the routes from the server.
  /// To execute this method, waypoints must be given beforehand.
  loadRoutes() async {
    // TODO: Load routes from the server.
  }

  /// Select an alternative route.
  selectRoute(route.Route? route) {
    
  }
}