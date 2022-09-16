import 'dart:math';

import 'package:latlong2/latlong.dart' as latlng;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/waypoint.dart';

class Route {
  /// The GraphHopper route response path.
  final GHRouteResponsePath path;

  /// A list of navigation nodes representing the route.
  /// 
  /// This is set by the SG selector with an interpolated 
  /// route that contains the signal groups.
  final List<NavigationNode> route;

  /// A mapping of signal group ids to signal groups.
  /// 
  /// All signal groups must occur in the route.
  final Map<String, Sg> signalGroups;

  const Route({
    required this.path,
    required this.route,
    required this.signalGroups,
  });

  Map<String, dynamic> toJson() => {
    'path': path.toJson(),
    'route': route.map((e) => e.toJson()).toList(),
    'signalGroups': { for (var e in signalGroups.entries) e.key: e.value.toJson() },
  };

  factory Route.fromJson(dynamic json) => Route(
    path: GHRouteResponsePath.fromJson(json['path']),
    route: (json['route'] as List).map((e) => NavigationNode.fromJson(e)).toList(),
    signalGroups: (json['signalGroups'] as Map).map((key, value) => MapEntry<String, Sg>(key, Sg.fromJson(value))),
  );

  /// The route, connected to the start and end point.
  Route connected(Waypoint startpoint, Waypoint endpoint) {
    const vincenty = latlng.Distance();
    final first = route.isNotEmpty ? route.first : null;
    final distToFirst = first == null ? null : vincenty.distance(
      latlng.LatLng(startpoint.lat, startpoint.lon), 
      latlng.LatLng(first.lat, first.lon)
    );
    final last = route.isNotEmpty ? route.last : null;
    final distToLast = last == null ? null : vincenty.distance(
      latlng.LatLng(last.lat, last.lon), 
      latlng.LatLng(endpoint.lat, endpoint.lon)
    );
    return Route(
      path: path,
      signalGroups: signalGroups,
      route: [
        NavigationNode(
          lon: startpoint.lon, 
          lat: startpoint.lat, 
          alt: first?.alt ?? 0,
          distanceToNextSignal: first == null ? null : (first.distanceToNextSignal! + distToFirst!),
          signalGroupId: first?.signalGroupId,
        ),
        ...route,
        NavigationNode(
          lon: endpoint.lon, 
          lat: endpoint.lat, 
          alt: last?.alt ?? 0,
          distanceToNextSignal: last == null ? null : (last.distanceToNextSignal! + distToLast!),
          signalGroupId: last?.signalGroupId,
        ),
      ],
    );
  }

  /// Calculate the bounds of this route.
  LatLngBounds get bounds {
    assert(route.isNotEmpty);
    var first = route.first;
    var s = first.lat,
        n = first.lat,
        w = first.lon,
        e = first.lon;
    for (var i = 1; i < route.length; i++) {
      var node = route[i];
      s = min(s, node.lat);
      n = max(n, node.lat);
      w = min(w, node.lon);
      e = max(e, node.lon);
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
}