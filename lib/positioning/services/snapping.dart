import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

class Snapping with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Snapping");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The distance model.
  final vincenty = const Distance();

  /// The current distance to the route.
  double? distance;

  /// The current snapped position.
  LatLng? snappedPosition;

  /// The current snapped heading.
  double? snappedHeading;

  /// The distance to the next turn.
  double? distanceToNextTurn;

  /// The distance to the next signal group.
  double? distanceToNextSG;

  /// The remaining waypoints.
  List<Waypoint>? remainingWaypoints;

  Snapping() { log.i("Snapping started."); }

  /// Snap the current position to the route and calculate the remaining waypoints.
  Future<void> updatePosition(BuildContext context) async {
    final positioning = Provider.of<Positioning>(context, listen: false);
    final routing = Provider.of<Routing>(context, listen: false);

    if (positioning.lastPosition == null) return;
    if (routing.selectedRoute == null || routing.selectedWaypoints == null) return;
    if (routing.selectedRoute!.route.length < 2 || routing.selectedWaypoints!.length < 2) return;

    final p = LatLng(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude);
    final nodes = routing.selectedRoute!.route;
    
    // Draw snapping lines to all route segments.
    var shortestDistance = double.infinity;
    var shortestDistanceIndex = 0;
    var shortestDistanceP1 = LatLng(0, 0);
    var shortestDistanceP2 = LatLng(0, 0);
    var shortestDistancePSnapped = LatLng(0, 0);
    for (int i = 0; i < routing.selectedRoute!.route.length - 1; i++) {
      final n1 = nodes[i], n2 = nodes[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      final s = snap(p, p1, p2);
      final d = vincenty.distance(p, s);
      if (d < shortestDistance) {
        shortestDistance = d;
        shortestDistanceIndex = i;
        shortestDistanceP1 = p1;
        shortestDistanceP2 = p2;
        shortestDistancePSnapped = s;
      }
    }

    distance = shortestDistance;
    snappedPosition = shortestDistancePSnapped;
    final bearing = vincenty.bearing(shortestDistanceP1, shortestDistanceP2); // [-180°, 180°]
    snappedHeading = bearing > 0 ? bearing : 360 + bearing; // [0°, 360°]

    // Traverse the segments and find the next turn, i.e. where the bearing changes > <x>°.
    const bearingThreshold = 15;
    var distanceToNextTurn = 0.0;
    for (int i = shortestDistanceIndex; i < routing.selectedRoute!.route.length - 1; i++) {
      final n1 = nodes[i], n2 = nodes[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      final b = vincenty.bearing(p1, p2); // [-180°, 180°]
      distanceToNextTurn += vincenty.distance(p1, p2);
      if ((b - bearing).abs() > bearingThreshold) break;
    }
    this.distanceToNextTurn = distanceToNextTurn;

    // Calculate the shortest distance to the signal groups.
    var distanceToNextSG = double.infinity;
    for (final sg in routing.selectedRoute!.signalGroups.values) {
      final d = vincenty.distance(p, LatLng(sg.position.lat, sg.position.lon));
      if (d < distanceToNextSG) distanceToNextSG = d;
    }
    this.distanceToNextSG = distanceToNextSG;

    // Find the waypoint segment with the shortest distance to our position.
    final waypoints = routing.selectedWaypoints!;

    var shortestWaypointDistance = double.infinity;
    var shortestWaypointToIdx = 0;
    for (int i = 0; i < (waypoints.length - 1); i++) {
      final w1 = waypoints[i], w2 = waypoints[i + 1];
      final p1 = LatLng(w1.lat, w1.lon), p2 = LatLng(w2.lat, w2.lon);
      final s = snap(p, p1, p2);
      final d = vincenty.distance(p, s);
      if (d < shortestWaypointDistance) {
        shortestWaypointDistance = d; 
        shortestWaypointToIdx = i + 1;
      }
    }

    remainingWaypoints = [
      Waypoint(p.latitude, p.longitude, address: "Aktuelle Position")
    ] + routing.selectedWaypoints!.sublist(shortestWaypointToIdx);

    notifyListeners();
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
    snappedPosition = null;
    distance = null;
    snappedHeading = null;
    distanceToNextTurn = null;
    distanceToNextSG = null;
    remainingWaypoints = null;
    needsLayout = {};
    notifyListeners();
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}