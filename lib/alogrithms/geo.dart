import 'dart:math';

class Geo {
  static var deg2rad = (deg) => deg * (pi / 180);
  static var rad2deg = (rad) => rad * (180 / pi);

  /// Calculates the distance between two locations in meter
  static double distanceBetween(
      double lat1, double lon1, double lat2, double lon2) {
    const int EARTH_RADIUS = 6371;
    double dLat = deg2rad(lat2 - lat1);
    double dLon = deg2rad(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double d = EARTH_RADIUS * c * 1000;

    return d;
  }
}
