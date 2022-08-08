import 'dart:math';

import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/routing/models/discomfort.dart';
import 'package:uuid/uuid.dart';

class Route {
  /// A random unique id for this route.
  final Uuid id = const Uuid();

  /// The coordinates of the route, as calculated by the routing service.
  final List<LatLng> coordinates;

  /// The duration of this route in seconds.
  final double duration;

  /// The length of this route in meters.
  final double distance;

  /// The (optional) list of traffic lights along the route.
  final List<LatLng>? trafficLights;

  /// The (optional) list of discomforts along the route.
  final List<Discomfort>? discomforts;

  /// Calculate the bounds of this route.
  LatLngBounds get bounds {
    assert(coordinates.isNotEmpty);
    var firstLatLng = coordinates.first;
    var s = firstLatLng.latitude,
        n = firstLatLng.latitude,
        w = firstLatLng.longitude,
        e = firstLatLng.longitude;
    for (var i = 1; i < coordinates.length; i++) {
      var latlng = coordinates[i];
      s = min(s, latlng.latitude);
      n = max(n, latlng.latitude);
      w = min(w, latlng.longitude);
      e = max(e, latlng.longitude);
    }
    return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
  }

  /// Calculate the padded bounds of this route.
  LatLngBounds get paddedBounds {
    final bounds = this.bounds;
    // Padding is approximately 111m (Approximately 0.001 degrees).
    // See: https://www.usna.edu/Users/oceano/pguth/md_help/html/approx_equivalents.htm
    const pad = 0.001;
    return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude - pad, bounds.southwest.longitude - pad), 
      northeast: LatLng(bounds.northeast.latitude + pad, bounds.northeast.longitude + pad),
    );
  }

  const Route({
    required this.coordinates, 
    required this.duration, 
    required this.distance,
    this.trafficLights,
    this.discomforts,
  });
}