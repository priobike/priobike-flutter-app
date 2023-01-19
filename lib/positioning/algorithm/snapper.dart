import 'package:latlong2/latlong.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:priobike/routing/models/navigation.dart';

class Snapper {
  /// The distance model.
  static const vincenty = Distance(roundResult: false);

  /// The position to snap.
  final LatLng position;

  /// The list of navigation nodes to snap.
  final List<NavigationNode> nodes;

  const Snapper({
    required this.position,
    required this.nodes,
  });

  /// Calculate the nearest point on the line between p1 and p2,
  /// with respect to the reference point pos.
  static LatLng calcNearestPoint(LatLng pos, LatLng p1, LatLng p2) {
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

  /// Snap a position to the route.
  Snap snap() {
    assert(nodes.length >= 2);

    // Draw snapping lines to all route segments.
    var shortestDistance = double.infinity;
    var shortestDistanceIndex = 0;
    var shortestDistanceP1 = LatLng(0, 0);
    var shortestDistanceP2 = LatLng(0, 0);
    var shortestDistancePSnapped = LatLng(0, 0);
    for (int i = 0; i < nodes.length - 1; i++) {
      final n1 = nodes[i], n2 = nodes[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      final s = calcNearestPoint(position, p1, p2);
      final d = vincenty.distance(position, s);
      if (d < shortestDistance) {
        shortestDistance = d;
        shortestDistanceIndex = i;
        shortestDistanceP1 = p1;
        shortestDistanceP2 = p2;
        shortestDistancePSnapped = s;
      }
    }

    // The snapped bearing is the bearing of the shortest distance segment.
    final snappedBearing = vincenty.bearing(shortestDistanceP1, shortestDistanceP2); // [-180°, 180°]
    final snappedHeading = snappedBearing > 0 ? snappedBearing : 360 + snappedBearing; // [0°, 360°]
    final snappedPosition = shortestDistancePSnapped;

    // Calculate the progress on the route, i.e. the percentage of the route.
    var distanceOnRoute = 0.0;
    for (int i = 0; i < shortestDistanceIndex; i++) {
      final n1 = nodes[i], n2 = nodes[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      distanceOnRoute += vincenty.distance(p1, p2);
    }
    final distanceToSnapped = vincenty.distance(shortestDistanceP1, shortestDistancePSnapped);
    distanceOnRoute += distanceToSnapped;

    return Snap(
      original: position,
      position: snappedPosition,
      distanceToRoute: shortestDistance,
      distanceOnRoute: distanceOnRoute,
      heading: snappedHeading,
      bearing: snappedBearing,
      metadata: SnapMetadata(
        shortestDistanceIndex: shortestDistanceIndex,
        shortestDistanceP1: shortestDistanceP1,
        shortestDistanceP2: shortestDistanceP2,
      ),
    );
  }
}
