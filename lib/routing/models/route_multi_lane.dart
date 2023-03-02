import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/crossing_multi_lane.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/sg_multi_lane.dart';
import 'package:priobike/routing/models/waypoint.dart';

class RouteMultiLane {
  /// The route id.
  final int id;

  /// The GraphHopper route response path.
  final GHRouteResponsePath path;

  /// A list of navigation nodes representing the route.
  ///
  /// This is set by the SG selector with an interpolated
  /// route that contains the signal groups.
  final List<NavigationNodeMultiLane> route;

  /// A list of signal groups in the order of the route.
  final List<SgMultiLane> signalGroups;

  /// A list of crossings.
  final List<CrossingMultiLane> crossings;

  const RouteMultiLane({
    required this.id,
    required this.path,
    required this.route,
    required this.signalGroups,
    required this.crossings,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path.toJson(),
        'route': route.map((e) => e.toJson()).toList(),
        'signalGroups': signalGroups.map((e) => e.toJson()).toList(),
        'crossings': crossings.map((e) => e.toJson()).toList(),
      };

  factory RouteMultiLane.fromJson(dynamic json) => RouteMultiLane(
        id: json["id"],
        path: GHRouteResponsePath.fromJson(json['path']),
        route: (json['route'] as List).map((e) => NavigationNodeMultiLane.fromJson(e)).toList(),
        signalGroups: (json['signalGroups'] as List).map((e) => SgMultiLane.fromJson(e)).toList(),
        crossings: (json['crossings'] as List).map((e) => CrossingMultiLane.fromJson(e)).toList(),
      );

  /// The route, connected to the start and end point.
  RouteMultiLane connected(Waypoint startpoint, Waypoint endpoint) {
    final first = route.isNotEmpty ? route.first : null;
    final last = route.isNotEmpty ? route.last : null;
    return RouteMultiLane(
      id: id,
      path: path,
      signalGroups: signalGroups,
      route: [
        NavigationNodeMultiLane(
          lon: startpoint.lon,
          lat: startpoint.lat,
          alt: first?.alt ?? 0,
        ),
        ...route,
        NavigationNodeMultiLane(
          lon: endpoint.lon,
          lat: endpoint.lat,
          alt: last?.alt ?? 0,
        ),
      ],
      crossings: crossings,
    );
  }

  /// Calculate the bounds of this route.
  CoordinateBounds get bounds {
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
    return CoordinateBounds(
        southwest: Point(
            coordinates: Position(
          s,
          w,
        )).toJson(),
        northeast: Point(
            coordinates: Position(
          n,
          e,
        )).toJson(),
        infiniteBounds: false);
  }

  /// Calculate the padded bounds of this route.
  CoordinateBounds get paddedBounds {
    final bounds = this.bounds;
    const pad = 0.003;
    final coordinatesSouthwest = bounds.southwest["coordinates"] as List;
    final s = coordinatesSouthwest[1] as double;
    final w = coordinatesSouthwest[0] as double;
    final coordinatesNortheast = bounds.northeast["coordinates"] as List;
    final n = coordinatesNortheast[1] as double;
    final e = coordinatesNortheast[0] as double;
    return CoordinateBounds(
        southwest: Point(
            coordinates: Position(
          s - pad,
          w - pad,
        )).toJson(),
        northeast: Point(
            coordinates: Position(
          n + pad,
          e + pad,
        )).toJson(),
        infiniteBounds: false);
  }

  /// Calculate a camera position for this route.
  CameraOptions get cameraOptions {
    final bounds = this.bounds;
    final geometrySouthwest = bounds.southwest["geometry"] as Map;
    final coordinatesSouthwest = geometrySouthwest["coordinates"] as List;
    final s = coordinatesSouthwest[0] as double;
    final w = coordinatesSouthwest[1] as double;
    final geometryNortheast = bounds.northeast["geometry"] as Map;
    final coordinatesNortheast = geometryNortheast["coordinates"] as List;
    final n = coordinatesNortheast[0] as double;
    final e = coordinatesNortheast[1] as double;
    // Calculate the center.
    final center = LatLng((s + n) / 2, (w + e) / 2);
    return CameraOptions(
      center: Point(
          coordinates: Position(
        center.longitude,
        center.latitude,
      )).toJson(),
      zoom: 12.0,
      bearing: 0.0,
      pitch: 0.0,
    );
  }
}
