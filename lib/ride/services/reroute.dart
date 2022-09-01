import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class RerouteService with ChangeNotifier {
  /// The logger for this service.
  final Logger log = Logger("RerouteService");

  /// A boolean indicating if the service is currently checking.
  var isChecking = false;

  /// The scheduler timer.
  Timer? timer;

  RerouteService() { log.i("RerouteService started."); }

  /// Run a scheduler that checks periodically for reroutes.
  Future<void> runRerouteScheduler(BuildContext context) async {
    final settings = Provider.of<SettingsService>(context, listen: false);
    if (settings.rerouting == Rerouting.disabled) return;

    if (timer != null) return; // Already running.
    timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) async {
      if (isChecking) return; // Skip this check.
      isChecking = true;
      try {
        await check(context);
      } catch (e) {
        // Context was invalidated somehow, stop the scheduler.
        await stopRerouteScheduler();
      }
      isChecking = false;
    });
  }

  /// Execute a scheduled checking for reroutes.
  Future<void> check(BuildContext context) async {
    final position = Provider.of<PositionService>(context, listen: false);
    final routing = Provider.of<RoutingService>(context, listen: false);
    final ride = Provider.of<RideService>(context, listen: false);

    if (position.lastPosition == null) return;
    if (routing.selectedRoute == null || routing.selectedWaypoints == null) return;
    if (routing.selectedRoute!.route.length < 2 || routing.selectedWaypoints!.length < 2) return;

    // Find the shortest path to the route. To do this, we perform two steps:
    // 1. Find the 2 closest points to the current location.
    // 2. Find the nearest point on the finite line between, to the current location.
    final p = LatLng(position.lastPosition!.latitude, position.lastPosition!.longitude);
    const vincenty = Distance();
    double dist(n) => vincenty.distance(n, p);
    final nodes = routing.selectedRoute!.route.map((n) => LatLng(n.lat, n.lon)).toList();
    final nodesAsc = nodes.toList(); nodesAsc.sort(((a, b) => dist(a).compareTo(dist(b))));
    final p1 = nodesAsc[0]; final p2 = nodesAsc[1];
    final closest = snap(p, p1, p2);

    if (vincenty.distance(p, closest) < 50) return; // No need to reroute.

    // Find the waypoint segment with the shortest distance to our position.
    final pCoord = LatLng(position.lastPosition!.latitude, position.lastPosition!.longitude);
    double? shortestDistance; 
    int? shortestToIdx;
    for (int i = 0; i < (routing.selectedWaypoints!.length - 1); i++) {
      final from = routing.selectedWaypoints![i], to = routing.selectedWaypoints![i + 1];
      final fromCoord = LatLng(from.lat, from.lon), toCoord = LatLng(to.lat, to.lon);
      final snappedCoord = snap(pCoord, fromCoord, toCoord);
      final distance = vincenty.distance(pCoord, snappedCoord);
      if (shortestDistance == null || shortestDistance > distance) {
        shortestDistance = distance; 
        shortestToIdx = i + 1;
      }
    }

    final remainingWaypoints = [
      Waypoint(p.latitude, p.longitude, address: "Aktuelle Position")
    ] + routing.selectedWaypoints!.sublist(shortestToIdx!);

    log.i("Requesting reroute with new waypoints: ${remainingWaypoints.map((e) => e.address)}");
    await routing.selectWaypoints(remainingWaypoints);
    final response = await routing.loadRoutes(context);
    if (response == null || response.routes.isEmpty) return;
    await ride.selectRide(context, response.routes.first);
  }

  /// Calculate the nearest point on the line between p1 and p2,
  /// with respect to the reference point pos.
  LatLng snap(LatLng pos, LatLng p1, LatLng p2) {
    final x = pos.latitude, y = pos.longitude;
    final x1 = p1.latitude, y1 = p1.longitude;
    final x2 = p2.latitude, y2 = p2.longitude;

    final A = x - x1, B = y - y1, C = x2 - x1, D = y2 - y1;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    var param = -1.0;
    if (lenSq != 0) param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      // Snap to point 1.
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      // Snap to point 2.
      xx = x2;
      yy = y2;
    } else {
      // Snap to shortest point inbetween.
      xx = x1 + param * C;
      yy = y1 + param * D;
    }
    return LatLng(xx, yy);
  }

  Future<void> reset() async {
    await stopRerouteScheduler();
    isChecking = false;
    timer = null;
  }

  /// Stop the scheduled checking for reroutes.
  Future<void> stopRerouteScheduler() async {
    timer?.cancel();
  }
}