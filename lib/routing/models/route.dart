import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/poi.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';

/// Adopted from https://github.com/priobike/priobike-graphhopper-drn/blob/main/converter/mapping.py
/// Note: This is not exactly the same mapping. In the DRN data,
/// there are many redundant / transport engineering related
/// way types that the regular user won't understand. These are
/// simplified here.
const drnOSMMapping = {
  "Busfahrstreifen mit Radverkehr": {
    "cycleway": "share_busway",
    "highway": "service",
  },
  "Fähre": {
    "route": "ferry",
    "bicycle": "yes",
  },
  "Fahrradstraße": {
    "bicycle_road": "yes",
    "bicycle": "designated",
    "maxspeed": "30",
    "source:maxspeed": "DE:bicycle_road",
    "traffic_sign": "DE:244.1",
    "highway": "residential",
  },
  "Fußgängerüberweg/-furt": {
    "highway": "pedestrian",
  },
  "Befahrbare Fußgängerzone": {
    "highway": "pedestrian",
    "bicycle": "yes",
  },
  "Fußgängerzone": {
    "highway": "pedestrian",
  },
  "Befahrbarer Fußweg": {
    "highway": "footway",
    "foot": "designated",
    "bicycle": "yes",
    "traffic_sign": "DE:239,1022-10",
  },
  "Fußweg": {
    "highway": "footway",
  },
  "Gemeinsamer Geh-/Radweg": {
    "highway": "path",
    "bicycle": "designated",
    "foot": "designated",
    "segregated": "no",
  },
  "Getrennter Geh-/Radweg": {
    "highway": "path",
    "bicycle": "designated",
    "foot": "designated",
    "segregated": "yes",
  },
  "Durch Fahrräder, Busse, und Taxen befahrbar": {
    "cycleway": "share_busway",
    "highway": "tertiary",
  },
  "Kopenhagener Radweg": {
    "highway": "cycleway",
    "bicycle": "designated",
  },
  "Radfahrstreifen auf Straße": {
    "highway": "tertiary",
    "cycleway:right": "lane",
    "cycleway:right:bicycle": "designated",
  },
  "Baulich getrennter Radweg": {
    "highway": "path",
    "bicycle": "designated",
    "foot": "designated",
    "segregated": "yes",
  },
  "Schutzstreifen": {
    "highway": "tertiary",
    "cycleway:right": "lane",
    "cycleway:lane": "advisory",
    "cycleway:protection:right": "dashed_line",
  },
  "Straße": {
    "highway": "tertiary",
  },
  "Wohnstraße": {
    "highway": "residential",
  },
  "Verkehrsberuhigter Bereich": {
    "highway": "living_street",
  },
  "Weg in Grünflächen": {
    "highway": "path",
    "bicycle": "designated",
    "foot": "designated",
    "segregated": "no",
  },
  "Wirtschaftsweg": {
    "highway": "track",
  },
};

/// Uses [drnOSMMapping] to find the DRN name for the given OSM tags.
String? drnNameFromOSMTags(Map<String, String> givenOSMTags) {
  int bestNMatches = 0;
  String? bestMatch;
  for (var drnName in drnOSMMapping.keys) {
    final osmTags = drnOSMMapping[drnName]!;
    int nMatches = 0;
    for (var key in osmTags.keys) {
      if (givenOSMTags.containsKey(key) && givenOSMTags[key] == osmTags[key]) {
        nMatches++;
      }
    }
    if (nMatches == osmTags.length) {
      if (nMatches > bestNMatches) {
        bestNMatches = nMatches;
        bestMatch = drnName;
      }
    }
  }
  if (bestNMatches == 0) {
    return null;
  }
  return bestMatch;
}

class Route {
  /// The route idx.
  final int idx;

  /// The GraphHopper route response path.
  final GHRouteResponsePath path;

  /// A list of navigation nodes representing the route.
  ///
  /// This is set by the SG selector with an interpolated
  /// route that contains the signal groups.
  final List<NavigationNode> route;

  /// A map from the OSM way IDs to their resolved OSM tags.
  final Map<int, Map<String, String>> osmTags;

  /// A map from the OSM way IDs to our mapping and translation of way types.
  late final Map<int, String?> osmWayNames;

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

  /// The most unique attribute of the route within a set of routes.
  String? mostUniqueAttribute;

  /// The number of sgs that are ok.
  int ok = 0;

  /// The number of sgs that are offline.
  int offline = 0;

  /// The number of sgs that have a bad quality.
  int bad = 0;

  /// The number of disconnected sgs.
  int disconnected = 0;

  /// The found pois.
  List<PoiSegment>? foundPois;

  /// The found warning pois (aggregated - if, for example, some POIs share the same location).
  List<PoiSegment>? foundWarningPoisAggregated;

  Route({
    required this.idx,
    required this.path,
    required this.route,
    required this.signalGroups,
    required this.signalGroupsDistancesOnRoute,
    required this.crossings,
    required this.crossingsDistancesOnRoute,
    required this.instructions,
    required this.osmTags,
  }) {
    osmWayNames = {};
    for (var wayId in osmTags.keys) {
      final name = drnNameFromOSMTags(osmTags[wayId]!);
      if (name != null) {
        osmWayNames[wayId] = name;
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'idx': idx,
        'path': path.toJson(),
        'route': route.map((e) => e.toJson()).toList(),
        'signalGroups': signalGroups.map((e) => e.toJson()).toList(),
        'signalGroupsDistancesOnRoute': signalGroupsDistancesOnRoute,
        'crossings': crossings.map((e) => e.toJson()).toList(),
        'crossingsDistancesOnRoute': crossingsDistancesOnRoute,
        'osmTags': (osmTags.map((key, value) => MapEntry(key.toString(), value))),
      };

  factory Route.fromJson(dynamic json) => Route(
        idx: json["idx"],
        path: GHRouteResponsePath.fromJson(json['path']),
        route: (json['route'] as List).map((e) => NavigationNode.fromJson(e)).toList(),
        signalGroups: (json['signalGroups'] as List).map((e) => Sg.fromJson(e)).toList(),
        signalGroupsDistancesOnRoute: (json['signalGroupsDistancesOnRoute'] as List).map((e) => e as double).toList(),
        crossings: (json['crossings'] as List).map((e) => Crossing.fromJson(e)).toList(),
        crossingsDistancesOnRoute: (json['crossingsDistancesOnRoute'] as List).map((e) => e as double).toList(),
        instructions: [],
        osmTags:
            (json['osmTags'] as Map).map((key, value) => MapEntry(int.parse(key), Map<String, String>.from(value))),
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
      idx: idx,
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
      osmTags: osmTags,
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
            w,
            s,
          ),
        ),
        northeast: Point(
          coordinates: Position(
            e,
            n,
          ),
        ),
        infiniteBounds: false);
  }

  /// Calculate the padded bounds of this route.
  CoordinateBounds get paddedBounds {
    final bounds = this.bounds;
    const pad = 0.003;
    final coordinatesSouthwest = bounds.southwest.coordinates;
    final s = coordinatesSouthwest[0] as double;
    final w = coordinatesSouthwest[1] as double;
    final coordinatesNortheast = bounds.northeast.coordinates;
    final n = coordinatesNortheast[0] as double;
    final e = coordinatesNortheast[1] as double;
    return CoordinateBounds(
        southwest: Point(
          coordinates: Position(
            s - pad,
            w - pad,
          ),
        ),
        northeast: Point(
          coordinates: Position(
            n + pad,
            e + pad,
          ),
        ),
        infiniteBounds: false);
  }

  /// Calculate a camera position for this route.
  CameraOptions get cameraOptions {
    final bounds = this.bounds;
    final coordinatesSouthwest = bounds.southwest.coordinates;
    final s = coordinatesSouthwest[0] as double;
    final w = coordinatesSouthwest[1] as double;
    final coordinatesNortheast = bounds.northeast.coordinates;
    final n = coordinatesNortheast[0] as double;
    final e = coordinatesNortheast[1] as double;
    // Calculate the center.
    final center = LatLng((s + n) / 2, (w + e) / 2);
    return CameraOptions(
      center: Point(
        coordinates: Position(
          center.longitude,
          center.latitude,
        ),
      ),
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
