import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart';

class MapboxMapProjectionBoundingBox {
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;

  MapboxMapProjectionBoundingBox({
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
  });
}

class MapboxMapProjection {
  /// The Web Mercator (x, y) projection system.
  static final projMercator = Projection.get('EPSG:3857')!;

  /// The WGS84 (latitude, longitude) projection system.
  static final projWGS84 = Projection.get('EPSG:4326')!;

  /// Convert lat and lon to Mercator coordinates (absolute, not in relation to screen).
  static Point convertLatLonToMercator(double lat, double lon) {
    return projWGS84.transform(projMercator, Point(x: lon, y: lat));
  }

  /// Convert Mercator coordinates to lat and lon.
  static LatLng convertMercatorToLatLon(double x, double y) {
    final point = projMercator.transform(projWGS84, Point(x: x, y: y));
    return LatLng(point.y, point.x);
  }

  /// Calculate a square bounding box using the Mapbox tile projection system (Mercator).
  static MapboxMapProjectionBoundingBox? mercatorBoundingBox(List<LatLng> coordinates) {
    double? minLon;
    double? minLat;
    double? maxLon;
    double? maxLat;

    for (final position in coordinates) {
      if (minLon == null || position.longitude < minLon) minLon = position.longitude;
      if (minLat == null || position.latitude < minLat) minLat = position.latitude;
      if (maxLon == null || position.longitude > maxLon) maxLon = position.longitude;
      if (maxLat == null || position.latitude > maxLat) maxLat = position.latitude;
    }

    if (minLon == null || minLat == null || maxLon == null || maxLat == null) return null;
    if (minLon == maxLon || minLat == maxLat) return null;

    const double mapPadding = 0.0025;
    minLon -= mapPadding;
    minLat -= mapPadding;
    maxLon += mapPadding;
    maxLat += mapPadding;

    // Make the bounding box square.
    // This has to happen in the Mercator projection system.
    final minM = convertLatLonToMercator(minLat, minLon);
    final maxM = convertLatLonToMercator(maxLat, maxLon);
    double minMx = minM.x;
    double minMy = minM.y;
    double maxMx = maxM.x;
    double maxMy = maxM.y;
    final dBeta = maxMx - minMx;
    final dAlpha = maxMy - minMy;
    if (dAlpha > dBeta) {
      final d = (dAlpha - dBeta) / 2;
      minMx -= d;
      maxMx += d;
    } else {
      final d = (dBeta - dAlpha) / 2;
      minMy -= d;
      maxMy += d;
    }
    // Convert back to lat/lon.
    final paddedMin = convertMercatorToLatLon(minMx, minMy);
    final paddedMax = convertMercatorToLatLon(maxMx, maxMy);

    return MapboxMapProjectionBoundingBox(
      minLat: paddedMin.latitude,
      minLon: paddedMin.longitude,
      maxLat: paddedMax.latitude,
      maxLon: paddedMax.longitude,
    );
  }
}