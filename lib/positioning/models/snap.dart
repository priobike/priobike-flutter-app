import 'package:latlong2/latlong.dart';

class Snap {
  /// The original position.
  final LatLng original;

  /// The snapped position.
  final LatLng position;

  /// The snapped altitude.
  final double altitude;

  /// The snapped heading in [0°, 360°].
  final double heading;

  /// The snapped bearing in [-180°, 180°].
  final double bearing;

  /// The distance to the route.
  final double distanceToRoute;

  /// The distance on the route (in m).
  final double distanceOnRoute;

  /// The snap metadata.
  final SnapMetadata metadata;

  const Snap({
    required this.original,
    required this.position,
    required this.altitude,
    required this.heading,
    required this.bearing,
    required this.distanceToRoute,
    required this.distanceOnRoute,
    required this.metadata,
  });
}

class SnapMetadata {
  /// The node index of the starting point of the nearest segment.
  final int shortestDistanceIndex;

  /// The starting point of the nearest segment.
  final LatLng shortestDistanceP1;

  /// The ending point of the nearest segment.
  final LatLng shortestDistanceP2;

  const SnapMetadata({
    required this.shortestDistanceIndex,
    required this.shortestDistanceP1,
    required this.shortestDistanceP2,
  });
}
