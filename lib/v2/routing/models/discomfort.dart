import 'package:mapbox_gl/mapbox_gl.dart';

class Discomfort {
  /// The localized description of this discomfort.
  final String description;

  /// The coordinates of the discomfort.
  /// If there are more than 2 coordinates, this will be interpreted as a line.
  /// Otherwise, this will be interpreted as a point.
  final List<LatLng> coordinates;

  const Discomfort({required this.description, required this.coordinates});
}