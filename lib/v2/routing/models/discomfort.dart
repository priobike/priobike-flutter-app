import 'package:mapbox_gl/mapbox_gl.dart';

class Discomfort {
  /// The localized description of this discomfort.
  final String description;

  /// The coordinates of the discomfort.
  /// If there are more than 2 coordinates, this will be interpreted as a line.
  /// Otherwise, this will be interpreted as a point.
  final List<LatLng> coordinates;

  const Discomfort({required this.description, required this.coordinates});

  Map<String, dynamic> toJson() => {
    'description': description,
    'coordinates': coordinates.map((e) => <double>[e.latitude, e.longitude]).toList(),
  };

  factory Discomfort.fromJson(dynamic json) {
    return Discomfort(
      description: json['description'],
      coordinates: (json['coordinates'] as List).map((e) => LatLng(e[0], e[1])).toList(),
    );
  }
}