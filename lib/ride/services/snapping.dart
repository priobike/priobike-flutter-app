import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A node in the snapping graph.
class Node {
  /// The coordinates of the node.
  final LatLng position;

  /// The index of the node in the route.
  final int idx;

  const Node(this.position, this.idx);
}

class SnappingService with ChangeNotifier {
  /// The logger for this service.
  final Logger log = Logger("SnappingService");

  /// The current distance to the route.
  double? distance;

  /// The current snapped position.
  LatLng? snappedPosition;

  /// The current snapped heading.
  double? snappedHeading;

  /// A boolean indicating if the service is updating.
  bool isUpdating = false;

  /// The remaining waypoints.
  List<Waypoint>? remainingWaypoints;

  SnappingService() { log.i("SnappingService started."); }

  /// Snap the current position to the route and calculate the remaining waypoints.
  Future<void> updatePosition(BuildContext context) async {
    if (isUpdating) return;
    isUpdating = true;

    final position = Provider.of<PositionService>(context, listen: false);
    final routing = Provider.of<RoutingService>(context, listen: false);

    if (position.lastPosition == null) return;
    if (routing.selectedRoute == null || routing.selectedWaypoints == null) return;
    if (routing.selectedRoute!.route.length < 2 || routing.selectedWaypoints!.length < 2) return;

    // Find the shortest path to the route. To do this, we perform two steps:
    // 1. Find the 2 closest points to the current location.
    // 2. Find the nearest point on the finite line between, to the current location.
    final p = LatLng(position.lastPosition!.latitude, position.lastPosition!.longitude);
    const vincenty = Distance();
    double dist(n) => vincenty.distance(n, p);
    // Keep the index of the nodes to reconstruct the order.
    final nodes = routing.selectedRoute!.route.asMap().entries
      .map((e) => Node(LatLng(e.value.lat, e.value.lon), e.key));
    final nodesAsc = nodes.toList(); nodesAsc
      .sort(((a, b) => dist(a.position).compareTo(dist(b.position))));
    final p1 = nodesAsc[0]; final p2 = nodesAsc[1];
    // Find the nearest point on the finite line between p1 and p2.
    snappedPosition = snap(p, p1.position, p2.position);
    // Calculate the shortest distance to the route.
    distance = vincenty.distance(snappedPosition!, p);
    // Make sure that we calculate the heading into the right 
    // direction, since p1 and p2 can be in any order.
    final bearing = p1.idx < p2.idx 
      ? vincenty.bearing(p1.position, p2.position) 
      : vincenty.bearing(p2.position, p1.position);
    // Map the bearing from [-180, 180] to a heading in [0, 360].
    snappedHeading = bearing > 0 ? bearing : 360 + bearing;

    // Find the waypoint segment with the shortest distance to our position.
    double? shortestDistance; 
    int? shortestToIdx;
    for (int i = 0; i < (routing.selectedWaypoints!.length - 1); i++) {
      final from = routing.selectedWaypoints![i], to = routing.selectedWaypoints![i + 1];
      final fromCoord = LatLng(from.lat, from.lon), toCoord = LatLng(to.lat, to.lon);
      final snappedCoord = snap(p, fromCoord, toCoord);
      final distance = vincenty.distance(p, snappedCoord);
      if (shortestDistance == null || shortestDistance > distance) {
        shortestDistance = distance; 
        shortestToIdx = i + 1;
      }
    }

    remainingWaypoints = [
      Waypoint(p.latitude, p.longitude, address: "Aktuelle Position")
    ] + routing.selectedWaypoints!.sublist(shortestToIdx!);

    isUpdating = false;
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
    notifyListeners();
  }
}