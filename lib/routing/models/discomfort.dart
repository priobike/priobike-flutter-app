import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DiscomfortSegment {
  /// A random unique id for this route.
  late String id;

  /// The localized description of this discomfort.
  final String description;

  /// The coordinates of the discomfort.
  /// If there are more than 2 coordinates, this will be interpreted as a line.
  /// Otherwise, this will be interpreted as a point.
  final List<LatLng> coordinates;

  /// The distance where the segment is on the route.
  final double distanceOnRoute;

  /// The color for the visualization of this discomfort.
  final Color color;

  /// The weight/trust value of the discomfort.
  final int? weight;

  DiscomfortSegment({
    String? id,
    required this.description,
    required this.coordinates,
    required this.distanceOnRoute,
    required this.color,
    this.weight,
  }) {
    if (id == null) {
      this.id = UniqueKey().toString();
    } else {
      this.id = id;
    }
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is DiscomfortSegment && other.id == id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'coordinates': coordinates.map((e) => <double>[e.latitude, e.longitude]).toList(),
        'distanceOnRoute': distanceOnRoute,
        'color': color.toString(),
        'weight': weight,
      };

  factory DiscomfortSegment.fromJson(dynamic json) => DiscomfortSegment(
        id: json['id'],
        description: json['description'],
        coordinates: (json['coordinates'] as List).map((e) => LatLng(e[0], e[1])).toList(),
        distanceOnRoute: json['distanceOnRoute'],
        color: json['color'],
        weight: json['weight'],
      );
}
