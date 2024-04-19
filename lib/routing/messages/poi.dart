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
  final List<PoiPoints> constructions;

  /// List of accident hotspots (segments along the route).
  final List<PoiPoints> accidenthotspots;

  /// List of green waves (segments along the route).
  final List<PoiPoints> greenwaves;

  /// List of velo routes (segments along the route).
  final List<PoiPoints> veloroutes;

  const PoisResponse({
    required this.constructions,
    required this.accidenthotspots,
    required this.greenwaves,
    required this.veloroutes,
  });

  factory PoisResponse.fromJson(Map<String, dynamic> json) {
    return PoisResponse(
      constructions: (json['constructions'] as List) //
          .map((construction) => PoiPoints.fromJson(construction))
          .toList(),
      accidenthotspots: (json['accidenthotspots'] as List) //
          .map((accidenthotspot) => PoiPoints.fromJson(accidenthotspot))
          .toList(),
      greenwaves: (json['greenwaves'] as List) //
          .map((greenwave) => PoiPoints.fromJson(greenwave))
          .toList(),
      veloroutes: (json['veloroutes'] as List) //
          .map((veloroute) => PoiPoints.fromJson(veloroute))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constructions': constructions,
      'accidenthotspots': accidenthotspots,
      'greenwaves': greenwaves,
      'veloroutes': veloroutes,
    };
  }
}

class PoiPoints {
  /// List of points that define the poi.
  final List<PoiCoordinate> points;

  const PoiPoints({required this.points});

  factory PoiPoints.fromJson(List<dynamic> json) {
    return PoiPoints(
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
