class PoisRequest {
  /// The computed route, containing coordinates.
  final List<PoiRoutePoint> route;

  /// The elongation that is applied to the construction sites, in meters.
  final int elongation;

  /// The search radius threshold applied to find construction sites, in meters.
  final int threshold;

  const PoisRequest({
    required this.route,
    this.elongation = 50,
    this.threshold = 10,
  });

  Map<String, dynamic> toJson() => {
        'route': route.map((v) => v.toJson()).toList(),
        'elongation': elongation,
        'threshold': threshold,
      };

  factory PoisRequest.fromJson(Map<String, dynamic> json) {
    return PoisRequest(
      route: (json['route'] as List).map((e) => PoiRoutePoint.fromJson(e)).toList(),
      elongation: json['elongation'],
      threshold: json['threshold'],
    );
  }
}

class PoiRoutePoint {
  /// The latitude of the route point.
  final double lat;

  /// The longitude of the route point.
  final double lon;

  const PoiRoutePoint({required this.lat, required this.lon});

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
      };

  factory PoiRoutePoint.fromJson(Map<String, dynamic> json) {
    return PoiRoutePoint(
      lat: json['lat'],
      lon: json['lon'],
    );
  }
}

class PoisResponse {
  /// List of construction sites (segments along the route).
  final List<PoiSegment> constructions;

  /// List of accident hotspots (segments along the route).
  final List<PoiSegment> accidenthotspots;

  const PoisResponse({required this.constructions, required this.accidenthotspots});

  factory PoisResponse.fromJson(Map<String, dynamic> json) {
    return PoisResponse(
      constructions: (json['constructions'] as List).map((construction) => PoiSegment.fromJson(construction)).toList(),
      accidenthotspots:
          (json['accidenthotspots'] as List).map((accidenthotspot) => PoiSegment.fromJson(accidenthotspot)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constructions': constructions,
      'accidenthotspots': accidenthotspots,
    };
  }
}

class PoiSegment {
  /// List of points that define the poi.
  final List<PoiCoordinate> points;

  const PoiSegment({required this.points});

  factory PoiSegment.fromJson(List<dynamic> json) {
    return PoiSegment(
      points: json.map((point) => PoiCoordinate.fromJson(point)).toList(),
    );
  }

  List<dynamic> toJson() {
    return points.map((point) => point.toJson()).toList();
  }
}

class PoiCoordinate {
  /// Longitude of the poi.
  final double lng;

  /// Latitude of the poi.
  final double lat;

  const PoiCoordinate({required this.lng, required this.lat});

  factory PoiCoordinate.fromJson(List<dynamic> json) {
    return PoiCoordinate(
      lng: json[0],
      lat: json[1],
    );
  }

  List<dynamic> toJson() {
    return [lng, lat];
  }
}
