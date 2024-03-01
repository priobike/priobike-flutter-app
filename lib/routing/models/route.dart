import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';

import 'instruction.dart';

class Route {
  /// The route id.
  final int id;

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

  /// A list of instructions.
  final List<Instruction> instructions;

  const Route({
    required this.id,
    required this.path,
    required this.route,
    required this.signalGroups,
    required this.signalGroupsDistancesOnRoute,
    required this.crossings,
    required this.crossingsDistancesOnRoute,
    required this.instructions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path.toJson(),
        'route': route.map((e) => e.toJson()).toList(),
        'signalGroups': signalGroups.map((e) => e.toJson()).toList(),
        'signalGroupsDistancesOnRoute': signalGroupsDistancesOnRoute,
        'crossings': crossings.map((e) => e.toJson()).toList(),
        'crossingsDistancesOnRoute': crossingsDistancesOnRoute,
      };

  factory Route.fromJson(dynamic json) => Route(
        id: json["id"],
        path: GHRouteResponsePath.fromJson(json['path']),
        route: (json['route'] as List).map((e) => NavigationNode.fromJson(e)).toList(),
        signalGroups: (json['signalGroups'] as List).map((e) => Sg.fromJson(e)).toList(),
        signalGroupsDistancesOnRoute: (json['signalGroupsDistancesOnRoute'] as List).map((e) => e as double).toList(),
        crossings: (json['crossings'] as List).map((e) => Crossing.fromJson(e)).toList(),
        crossingsDistancesOnRoute: (json['crossingsDistancesOnRoute'] as List).map((e) => e as double).toList(),
        instructions: [],
      );

  /// The route, connected to the start and end point.
  Route connected(Waypoint startpoint, Waypoint endpoint) {
    const vincenty = Distance();
    final first = route.isNotEmpty ? route.first : null;
    final distToFirst =
        first == null ? null : vincenty.distance(LatLng(startpoint.lat, startpoint.lon), LatLng(first.lat, first.lon));
    final last = route.isNotEmpty ? route.last : null;
    final distToLast =
        last == null ? null : vincenty.distance(LatLng(last.lat, last.lon), LatLng(endpoint.lat, endpoint.lon));
    return Route(
      id: id,
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
      instructions: instructions,
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

  /// Calculate a length text for this route.
  String get lengthText {
    return path.distance.round() >= 1000
        ? "${((path.distance) / 1000).toStringAsFixed(1)} km"
        : "${path.distance.toStringAsFixed(0)} m";
  }

  /// Calculate a time text for this route.
  String get timeText {
    final seconds = path.time / 1000;
    // Get the full hours needed to cover the route.
    final hours = seconds ~/ 3600;
    // Get the remaining minutes.
    final minutes = (seconds - hours * 3600) ~/ 60;

    return "${hours == 0 ? '' : '$hours Std. '}$minutes Min.";
  }

  /// Calculate a arrival time text for this route.
  String get arrivalTimeText {
    final seconds = path.time / 1000;
    // Get the full hours needed to cover the route.

    final arrivalTime = DateTime.now().add(Duration(seconds: seconds.toInt()));
    return "Ankunft ca. ${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, "0")} Uhr";
  }
}
