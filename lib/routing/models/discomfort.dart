import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/routing/messages/graphhopper.dart';

class DiscomfortSegment {
  /// A random unique id for this route.
  late String id;

  /// The segment of this discomfort.
  final GHSegment segment;

  /// The localized description of this discomfort.
  final String description;

  /// The coordinates of the discomfort.
  /// If there are more than 2 coordinates, this will be interpreted as a line.
  /// Otherwise, this will be interpreted as a point.
  final List<LatLng> coordinates;

  DiscomfortSegment({String? id, required this.segment, required this.description, required this.coordinates}) {
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
        'segment': segment.toJson(),
        'description': description,
        'coordinates': coordinates.map((e) => <double>[e.latitude, e.longitude]).toList(),
      };

  factory DiscomfortSegment.fromJson(dynamic json) => DiscomfortSegment(
        id: json['id'],
        segment: GHSegment.fromJson(json['segment']),
        description: json['description'],
        coordinates: (json['coordinates'] as List).map((e) => LatLng(e[0], e[1])).toList(),
      );
}
