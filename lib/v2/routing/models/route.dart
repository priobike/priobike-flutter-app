import 'dart:math';

import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/routing/models/discomfort.dart';
import 'package:uuid/uuid.dart';

class Route {
  /// A random unique id for this route.
  late String id;

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'coordinates': coordinates.map((e) => <double>[e.latitude, e.longitude]).toList(),
    'duration': duration,
    'distance': distance,
    'trafficLights': trafficLights?.map((e) => <double>[e.latitude, e.longitude]).toList(),
    'discomforts': discomforts?.map((e) => e.toJson()).toList(),
  };

  factory Route.fromJson(dynamic json) {
    return Route(
      id: json['id'],
      coordinates: (json['coordinates'] as List).map((e) => LatLng(e[0], e[1])).toList(),
      duration: json['duration'],
      distance: json['distance'],
      trafficLights: (json['trafficLights'] as List?)?.map((e) => LatLng(e[0], e[1])).toList(),
      discomforts: (json['discomforts'] as List?)?.map((e) => Discomfort.fromJson(e)).toList(),
    );
  }

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

  Route({
    String? id,
    required this.coordinates, 
    required this.duration, 
    required this.distance,
    this.trafficLights,
    this.discomforts,
  }) {
    if (id == null) {
      this.id = const Uuid().v4();
    } else {
      this.id = id;
    }
  }
}