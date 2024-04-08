class ConstructionSitesRequest {
  /// The computed route, containing coordinates.
  final List<ConstructionSiteRoutePoint> route;

  /// The elongation that is applied to the construction sites, in meters.
  final int elongation;

  /// The search radius threshold applied to find construction sites, in meters.
  final int threshold;

  const ConstructionSitesRequest({
    required this.route,
    this.elongation = 50,
    this.threshold = 10,
  });

  Map<String, dynamic> toJson() => {
        'route': route.map((v) => v.toJson()).toList(),
        'elongation': elongation,
        'threshold': threshold,
      };

  factory ConstructionSitesRequest.fromJson(Map<String, dynamic> json) {
    return ConstructionSitesRequest(
      route: (json['route'] as List).map((e) => ConstructionSiteRoutePoint.fromJson(e)).toList(),
      elongation: json['elongation'],
      threshold: json['threshold'],
    );
  }
}

class ConstructionSiteRoutePoint {
  /// The latitude of the route point.
  final double lat;

  /// The longitude of the route point.
  final double lon;

  const ConstructionSiteRoutePoint({required this.lat, required this.lon});

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
      };

  factory ConstructionSiteRoutePoint.fromJson(Map<String, dynamic> json) {
    return ConstructionSiteRoutePoint(
      lat: json['lat'],
      lon: json['lon'],
    );
  }
}

class ConstructionSitesResponse {
  /// List of construction sites (segments along the route).
  final List<ConstructionSegment> constructions;

  const ConstructionSitesResponse({required this.constructions});

  factory ConstructionSitesResponse.fromJson(Map<String, dynamic> json) {
    return ConstructionSitesResponse(
      constructions:
          (json['constructions'] as List).map((construction) => ConstructionSegment.fromJson(construction)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constructions': constructions,
    };
  }
}

class ConstructionSegment {
  /// List of points that define the construction site.
  final List<ConstructionCoordinate> points;

  const ConstructionSegment({required this.points});

  factory ConstructionSegment.fromJson(List<dynamic> json) {
    return ConstructionSegment(
      points: json.map((point) => ConstructionCoordinate.fromJson(point)).toList(),
    );
  }

  List<dynamic> toJson() {
    return points.map((point) => point.toJson()).toList();
  }
}

class ConstructionCoordinate {
  /// Longitude of the construction site point.
  final double lng;

  /// Latitude of the construction site point.
  final double lat;

  const ConstructionCoordinate({required this.lng, required this.lat});

  factory ConstructionCoordinate.fromJson(List<dynamic> json) {
    return ConstructionCoordinate(
      lng: json[0],
      lat: json[1],
    );
  }

  List<dynamic> toJson() {
    return [lng, lat];
  }
}
