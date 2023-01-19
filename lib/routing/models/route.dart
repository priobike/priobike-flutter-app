import 'dart:math';

import 'package:latlong2/latlong.dart' as latlng;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/crossing.dart';
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

  /// A list of signal groups in the order of the route.
  final List<Sg> signalGroups;

  /// A list of sg distances on the route, in the order of `signalGroups`.
  final List<double> signalGroupsDistancesOnRoute;

  /// A list of crossings.
  final List<Crossing> crossings;

  /// A list of crossing distances on the route, in the order of `crossings`.
  final List<double> crossingsDistancesOnRoute;

  const Route({
    required this.path,
    required this.route,
    required this.signalGroups,
    required this.signalGroupsDistancesOnRoute,
    required this.crossings,
    required this.crossingsDistancesOnRoute,
  });

  Map<String, dynamic> toJson() => {
        'path': path.toJson(),
        'route': route.map((e) => e.toJson()).toList(),
        'signalGroups': signalGroups.map((e) => e.toJson()).toList(),
        'signalGroupsDistancesOnRoute': signalGroupsDistancesOnRoute,
        'crossings': crossings.map((e) => e.toJson()).toList(),
        'crossingsDistancesOnRoute': crossingsDistancesOnRoute,
      };

  factory Route.fromJson(dynamic json) => Route(
        path: GHRouteResponsePath.fromJson(json['path']),
        route: (json['route'] as List).map((e) => NavigationNode.fromJson(e)).toList(),
        signalGroups: (json['signalGroups'] as List).map((e) => Sg.fromJson(e)).toList(),
        signalGroupsDistancesOnRoute: (json['signalGroupsDistancesOnRoute'] as List).map((e) => e as double).toList(),
        crossings: (json['crossings'] as List).map((e) => Crossing.fromJson(e)).toList(),
        crossingsDistancesOnRoute: (json['crossingsDistancesOnRoute'] as List).map((e) => e as double).toList(),
      );

  /// The route, connected to the start and end point.
  Route connected(Waypoint startpoint, Waypoint endpoint) {
    const vincenty = latlng.Distance();
    final first = route.isNotEmpty ? route.first : null;
    final distToFirst = first == null
        ? null
        : vincenty.distance(latlng.LatLng(startpoint.lat, startpoint.lon), latlng.LatLng(first.lat, first.lon));
    final last = route.isNotEmpty ? route.last : null;
    final distToLast = last == null
        ? null
        : vincenty.distance(latlng.LatLng(last.lat, last.lon), latlng.LatLng(endpoint.lat, endpoint.lon));
    return Route(
      path: path,
      signalGroups: signalGroups,
      signalGroupsDistancesOnRoute: signalGroupsDistancesOnRoute,
      route: [
        NavigationNode(
          lon: startpoint.lon,
          lat: startpoint.lat,
          alt: first?.alt ?? 0,
          distanceToNextSignal:
              first?.distanceToNextSignal == null ? null : (first!.distanceToNextSignal! + distToFirst!),
          signalGroupId: first?.signalGroupId,
        ),
        ...route,
        NavigationNode(
          lon: endpoint.lon,
          lat: endpoint.lat,
          alt: last?.alt ?? 0,
          distanceToNextSignal: last?.distanceToNextSignal == null ? null : (last!.distanceToNextSignal! + distToLast!),
          signalGroupId: last?.signalGroupId,
        ),
      ],
      crossings: crossings,
      crossingsDistancesOnRoute: crossingsDistancesOnRoute,
    );
  }

  /// Calculate the bounds of this route.
  LatLngBounds get bounds {
    assert(route.isNotEmpty);
    var first = route.first;
    var s = first.lat, n = first.lat, w = first.lon, e = first.lon;
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

  /// Calculate a camera position for this route.
  CameraPosition get cameraPosition {
    final bounds = this.bounds;
    // Calculate the center.
    final center = latlng.LatLng((bounds.southwest.latitude + bounds.northeast.latitude) / 2,
        (bounds.southwest.longitude + bounds.northeast.longitude) / 2);
    return CameraPosition(
      target: LatLng(center.latitude, center.longitude),
      zoom: 12.0,
      bearing: 0.0,
      tilt: 0.0,
    );
  }
}
