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
    final backend = getIt<Settings>().backend;
    var coords = List.empty(growable: true);
    boundaryCoords = List.empty(growable: true);
    boundaryGeoJson = await backend.boundaryGeoJson;
    final geojsonDecoded = jsonDecode(boundaryGeoJson!);
    coords = geojsonDecoded["features"][0]["geometry"]["coordinates"][1];

    for (final coord in coords) {
      boundaryCoords.add(Point(x: coord[0], y: coord[1]));
    }
  }

  /// The BoundingBox is used to limit the geosearch-results to a certain area, i.e. Hamburg or Dresden.
  /// It doesn't exactly match the borders of the city, but uses a rectangle as an approximation.
  Map<String, double> getRoughBoundingBox() {
    final backend = getIt<Settings>().backend;

    if (backend == Backend.production) {
      // See: http://bboxfinder.com/#53.350000,9.650000,53.750000,10.400000
      return {
        "minLon": 9.65,
        "maxLon": 10.4,
        "minLat": 53.35,
        "maxLat": 53.75,
      };
    } else if (backend == Backend.staging) {
      // See: http://bboxfinder.com/#50.900000,13.500000,51.200000,14.000000
      return {
        "minLon": 13.5,
        "maxLon": 14.0,
        "minLat": 50.9,
        "maxLat": 51.2,
      };
    } else {
      log.e("Unknown backend used for trying to access BoundingBox: $backend");
      return {};
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
