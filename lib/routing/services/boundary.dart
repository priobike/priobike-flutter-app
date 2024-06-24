import 'dart:convert';

import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/algorithms/ray_casting_algo.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// The Boundary is used to make sure we only use waypoints within the supported city limits.
class Boundary {
  /// The logger for this service.
  final log = Logger("Boundary");

  /// The exact coordiantes of the boundries of the city.
  List<Point> boundaryCoords = List.empty(growable: true);

  /// The boundary geoJson String.
  String? boundaryGeoJson;

  Boundary();

  /// Load the coordinates of the bounding box from the assets.
  Future<void> loadBoundaryCoordinates() async {
    final city = getIt<Settings>().city;
    var coords = List.empty(growable: true);
    boundaryCoords = List.empty(growable: true);
    boundaryGeoJson = await city.boundaryGeoJson;
    final geojsonDecoded = jsonDecode(boundaryGeoJson!);
    coords = geojsonDecoded["features"][0]["geometry"]["coordinates"][1];

    for (final coord in coords) {
      boundaryCoords.add(Point(x: coord[0], y: coord[1]));
    }
  }

  /// Check if a point is inside the exact bounding box given via saved assets.
  bool checkIfPointIsInBoundary(double lon, double lat) {
    if (boundaryCoords.isEmpty) {
      log.w("Boundary coordinates are empty, can't check if point is in boundary.");
      return false;
    }

    final point = Point(x: lon, y: lat);
    return Poly.isPointInPolygon(point, boundaryCoords);
  }
}
