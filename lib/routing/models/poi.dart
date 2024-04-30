import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum POIType {
  // Positive
  greenWave,
  veloroute,
  // Negative
  dismount,
  accidentHotspot,
  construction,
  pedestrians,
  carSpeed,
  decline,
  incline,
  surface,
  // Aggregated
  aggregated,
}

extension POITypeMapboxIcon on POIType {
  String get mapboxIcon {
    switch (this) {
      case POIType.greenWave:
        return "";
      case POIType.veloroute:
        return "";
      case POIType.dismount:
        return "dismount";
      case POIType.accidentHotspot:
        return "accidenthotspot";
      case POIType.construction:
        return "construction";
      case POIType.pedestrians:
        return "pedestrians";
      case POIType.carSpeed:
        return "carspeed";
      case POIType.decline:
        return "decline";
      case POIType.incline:
        return "incline";
      case POIType.surface:
        return "surface";
      case POIType.aggregated:
        return "aggregated";
    }
  }
}

class PoiSegment {
  /// A random unique id for this route.
  late String id;

  /// The localized description of this poi.
  final String description;

  /// An identifier of the type of poi.
  final POIType type;

  /// The coordinates of the poi.
  /// If there are more than 2 coordinates, this will be interpreted as a line.
  /// Otherwise, this will be interpreted as a point.
  final List<LatLng> coordinates;

  /// The distance where the segment is on the route.
  final double distanceOnRoute;

  /// The color for the visualization of this poi.
  final Color color;

  /// Whether the segment should appear as a warning on the route.
  final bool isWarning;

  /// The number of POIs in this segment.
  final int poiCount;

  PoiSegment({
    String? id,
    required this.description,
    required this.type,
    required this.coordinates,
    required this.distanceOnRoute,
    required this.color,
    required this.isWarning,
    required this.poiCount,
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
  bool operator ==(Object other) => other is PoiSegment && other.id == id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'type': type,
        'coordinates': coordinates.map((e) => <double>[e.latitude, e.longitude]).toList(),
        'distanceOnRoute': distanceOnRoute,
        'color': color.toString(),
        'isWarning': isWarning,
        'poiCount': poiCount,
      };

  factory PoiSegment.fromJson(dynamic json) => PoiSegment(
        id: json['id'],
        description: json['description'],
        type: json['type'],
        coordinates: (json['coordinates'] as List).map((e) => LatLng(e[0], e[1])).toList(),
        distanceOnRoute: json['distanceOnRoute'],
        color: json['color'],
        isWarning: json['isWarning'],
        poiCount: json['poiCount'],
      );
}
