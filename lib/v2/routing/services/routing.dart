
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/logger.dart';
import 'package:priobike/v2/common/models/point.dart';
import 'package:priobike/v2/routing/messages/routing.dart';
import 'package:priobike/v2/routing/models/route.dart' as r;
import 'package:priobike/v2/routing/models/waypoint.dart';
import 'package:priobike/v2/session/services/session.dart';
import 'package:priobike/v2/session/views/toast.dart';
import 'package:provider/provider.dart';

class RoutingService with ChangeNotifier {
  /// The logger for this service.
  final Logger log = Logger("RoutingService");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// A boolean indicating if the service is currently loading the route.
  bool isFetchingRoute = true;

  /// The waypoints of the loaded route, if provided.
  List<Waypoint>? fetchedWaypoints;

  /// The waypoints of the selected route, if provided.
  List<Waypoint>? selectedWaypoints;

  /// The currently selected route, if one was fetched.
  r.Route? selectedRoute;

  /// The alternative routes, if they were fetched.
  List<r.Route>? altRoutes;

  RoutingService({
    this.fetchedWaypoints,
    this.selectedWaypoints,
    this.selectedRoute,
    this.altRoutes,
  }) { log.i("RoutingService started."); }

  /// Load the routes from the server.
  /// To execute this method, waypoints must be given beforehand.
  Future<void> loadRoutes(BuildContext context) async {
    // Do nothing if the waypoints were already fetched (or both are null).
    if (fetchedWaypoints == selectedWaypoints) return;
    if (selectedWaypoints == null || selectedWaypoints!.isEmpty) return;

    // Get the session from the context and open it.
    final session = Provider.of<SessionService>(context, listen: false);
    try { 
      final sessionId = await session.openSession();

      // Session must be open to send the route request.
      final routeEndpoint = Uri.parse(session.routeUrl);
      final routeRequest = RouteRequest(
        sessionId: sessionId,
        waypoints: selectedWaypoints!.map((e) => Point(lat: e.lat, lon: e.lon)).toList(),
      );
      final response = await session.httpClient.post(routeEndpoint, body: json.encode(routeRequest.toJson()));
      if (response.statusCode != 200) {
        final err = "Route could not be fetched from endpoint $routeEndpoint: $response.body";
        log.e(err); ToastMessage.showError(err); throw Exception(err);
      }
      
      final routeResponse = RouteResponse.fromJson(json.decode(response.body));
      // Map the route response to our model.
      selectedRoute = r.Route(
        nodes: routeResponse.route,
        ascend: routeResponse.ascend,
        descend: routeResponse.descend,
        duration: routeResponse.estimatedDuration,
        distance: routeResponse.distance,
        sgs: routeResponse.signalgroups.values.toList(),
        discomforts: [], // TODO: Support discomforts.
      );
      altRoutes = []; // TODO: Support alternative routes.
      fetchedWaypoints = selectedWaypoints;
      notifyListeners();
    } catch (error) { 
      // Show error, navigate up in view hierarchy or try again.
      await session.closeSession();
    }
  }

  /// Select an alternative route.
  switchToAltRoute(r.Route route) {
    // Can only select an alternative route if there are some, 
    // and if there is a currently selected route.
    if (altRoutes == null || selectedRoute == null) return;
    // Can only select the alternative route if it is valid.
    if (!altRoutes!.contains(route)) return;
    altRoutes!.remove(route);
    altRoutes!.add(selectedRoute!);
    selectedRoute = route;
    notifyListeners();
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}