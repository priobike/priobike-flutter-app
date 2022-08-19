class GHGeocodeResponse {
  /// The list of hits.
  final List<GHGeocodingLocation> hits;

  /// How long the request tool.
  final int took;

  const GHGeocodeResponse({required this.hits, required this.took});

  factory GHGeocodeResponse.fromJson(Map<String, dynamic> json) {
    return GHGeocodeResponse(
      hits: (json['hits'] as List).map((e) => GHGeocodingLocation.fromJson(e)).toList(),
      took: json['took'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['hits'] = hits.map((e) => e.toJson()).toList();
    data['took'] = took;
    return data;
  }
}

class GHGeocodingLocation {
  /// The point.
  final GHGeocodingPoint point;

  /// The OSM ID of the entity.
  final String osmId;

  /// N = node, R = relation, W = way.
  final String osmType;

  /// The OSM key of the entity.
  final String osmKey;

  /// The name of the entity. Can be a boundary, POI, address, etc.
  final String name;

  /// The country of the address.
  final String country;

  /// The city of the address.
  final String city;

  /// The state of the address.
  final String state;

  /// The street of the address.
  final String street;

  /// The housenumber of the address.
  final String housenumber;

  /// The postcode of the address.
  final String postcode;

  const GHGeocodingLocation({
    required this.point,
    required this.osmId,
    required this.osmType,
    required this.osmKey,
    required this.name,
    required this.country,
    required this.city,
    required this.state,
    required this.street,
    required this.housenumber,
    required this.postcode,
  });

  factory GHGeocodingLocation.fromJson(Map<String, dynamic> json) {
    return GHGeocodingLocation(
      point: GHGeocodingPoint.fromJson(json['point']), 
      osmId: json['osm_id'], 
      osmType: json['osm_type'], 
      osmKey: json['osm_key'], 
      name: json['name'], 
      country: json['country'], 
      city: json['city'], 
      state: json['state'], 
      street: json['street'], 
      housenumber: json['housenumber'], 
      postcode: json['postcode'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['point'] = point.toJson();
    data['osm_id'] = osmId;
    data['osm_type'] = osmType;
    data['osm_key'] = osmKey;
    data['name'] = name;
    data['country'] = country;
    data['city'] = city;
    data['state'] = state;
    data['street'] = street;
    data['housenumber'] = housenumber;
    data['postcode'] = postcode;
    return data;
  }
}

class GHGeocodingPoint {
  final double lat;
  final double lng;

  const GHGeocodingPoint({
    required this.lat, 
    required this.lng,
  });

  factory GHGeocodingPoint.fromJson(Map<String, dynamic> json) {
    return GHGeocodingPoint(lat: json['lat'], lng: json['lng']);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}

class GHRouteResponse {
  /// The list of paths.
  final List<GHRouteResponsePath> paths;

  /// Additional information for your request.
  final GHResponseInfo info;

  const GHRouteResponse({required this.paths, required this.info});

  factory GHRouteResponse.fromJson(Map<String, dynamic> json) {
    return GHRouteResponse(
      paths: (json['paths'] as List).map((e) => GHRouteResponsePath.fromJson(e)).toList(),
      info: GHResponseInfo.fromJson(json['info']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['paths'] = paths.map((e) => e.toJson()).toList();
    data['info'] = info.toJson();
    return data;
  }
}

class GHResponseInfo {
  /// Attribution according to our documentation is necessary if no white-label option included.
  final List<String> copyrights;

  /// The time in milliseconds it took to perform the request.
  final double took;

  const GHResponseInfo({required this.copyrights, required this.took});

  factory GHResponseInfo.fromJson(Map<String, dynamic> json) {
    return GHResponseInfo(
      copyrights: json['paths'],
      took: json['took'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['copyrights'] = copyrights;
    data['took'] = took;
    return data;
  }
}

class GHRouteResponsePath {
  /// The total distance, in meters. 
  final double distance;

  /// The total travel time, in milliseconds.
  final int time;

  /// The total ascent, in meters.
  final double ascend;

  /// The total descent, in meters.
  final double descend;

  /// The geometry of the route. The format depends on the value of points_encoded. (We use non-encoded)
  final GHLineString points;

  /// The snapped input points. The format depends on the value of points_encoded. (We use non-encoded)
  final GHLineString snappedWaypoints;

  /// Whether the points and snapped_waypoints fields are polyline-encoded strings rather 
  /// than JSON arrays of coordinates. See the field description for more information on the two formats.
  final bool pointsEncoded;

  /// The bounding box of the route geometry. Format: [minLon, minLat, maxLon, maxLat].
  final GHBoundingBox bbox;

  /// The instructions for this route. This feature is under active development, and our instructions can 
  /// sometimes be misleading, so be mindful when using them for navigation.
  final List<GHInstruction> instructions;

  /// Details, as requested with the details parameter. Consider the value {"street_name": 
  /// [[0,2,"Frankfurter Straße"],[2,6,"Zollweg"]]}. In this example, the route uses two 
  /// streets: The first, Frankfurter Straße, is used between points[0] and points[2], 
  /// and the second, Zollweg, between points[2] and points[6]. 
  /// 
  /// Read more about the usage of path details here: https://discuss.graphhopper.com/t/2539
  final GHDetails details;

  /// An array of indices (zero-based), specifiying the order in which the input points are visited. 
  /// Only present if the optimize parameter was used.
  final List<int>? pointsOrder;

  const GHRouteResponsePath({
    required this.distance,
    required this.time,
    required this.ascend,
    required this.descend,
    required this.points,
    required this.snappedWaypoints,
    required this.pointsEncoded,
    required this.bbox,
    required this.instructions,
    required this.details,
    required this.pointsOrder,
  });

  factory GHRouteResponsePath.fromJson(Map<String, dynamic> json) {
    return GHRouteResponsePath(
      distance: json['distance'],
      time: json['time'],
      ascend: json['ascend'],
      descend: json['descend'],
      points: GHLineString.fromJson(json['points']),
      snappedWaypoints: GHLineString.fromJson(json['snapped_waypoints']),
      pointsEncoded: json['points_encoded'],
      bbox: GHBoundingBox.fromJson(json['bbox']),
      instructions: (json['instructions'] as List).map((e) => GHInstruction.fromJson(e)).toList(),
      details: GHDetails.fromJson(json['details']),
      pointsOrder: (json['points_order'] as List?)?.map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['distance'] = distance;
    data['time'] = time;
    data['ascend'] = ascend;
    data['descend'] = descend;
    data['points'] = points.toJson();
    data['snapped_waypoints'] = snappedWaypoints.toJson();
    data['points_encoded'] = pointsEncoded;
    data['bbox'] = bbox.toJson();
    data['instructions'] = instructions.map((e) => e.toJson()).toList();
    data['details'] = details.toJson();
    if (pointsOrder != null) data['points_order'] = pointsOrder;
    return data;
  }
}

class GHLineString {
  /// The type of the geometry, always "LineString" for a line string.
  final String type;

  /// The coordinates of the geometry.
  final List<GHCoordinate> coordinates;

  const GHLineString({required this.type, required this.coordinates});

  factory GHLineString.fromJson(Map<String, dynamic> json) {
    return GHLineString(
      type: json['type'],
      coordinates: (json['coordinates'] as List).map((e) => GHCoordinate.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['type'] = type;
    data['coordinates'] = coordinates.map((e) => e.toJson()).toList();
    return data;
  }
}

class GHCoordinate {
  final double lon;
  final double lat;
  final double? elevation;

  const GHCoordinate({required this.lon, required this.lat, this.elevation});

  factory GHCoordinate.fromJson(List<dynamic> json) {
    return GHCoordinate(
      lon: json[0], 
      lat: json[1], 
      elevation: json.length > 2 ? json[2] : null
    );
  }

  List<double> toJson() {
    return [
      lon,
      lat, 
      if (elevation != null) elevation!,
    ];
  }
}

class GHBoundingBox {
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  const GHBoundingBox({
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
  });

  factory GHBoundingBox.fromJson(List<dynamic> json) {
    return GHBoundingBox(
      minLon: json[0], 
      minLat: json[1], 
      maxLon: json[2],
      maxLat: json[3],
    );
  }

  List<double> toJson() {
    return [minLon, minLat, maxLon, maxLat];
  }
}

class GHInstruction {
  /// A description what the user has to do in order to follow the route. 
  /// The language depends on the locale parameter.
  final String text;

  /// The name of the street to turn onto in order to follow the route.
  final String streetName;

  /// The distance for this instruction, in meters.
  final double distance;

  /// The duration for this instruction, in milliseconds.
  final int time;

  /// Two indices into points, referring to the beginning and the end of the segment of the route this instruction refers to.
  final List<int> interval;

  /// A number which specifies the sign to show.
  final int sign;

  /// Only available for roundabout instructions (sign is 6). The count 
  /// of exits at which the route leaves the roundabout.
  final int? exitNumber;

  /// Only available for roundabout instructions (sign is 6). The radian of the route within 
  /// the roundabout 0 < r < 2*PI for clockwise and -2*PI < r < 0 for counterclockwise turns.
  final String? turnAngle;

  const GHInstruction({
    required this.text,
    required this.streetName,
    required this.distance,
    required this.time,
    required this.interval,
    required this.sign,
    required this.exitNumber,
    required this.turnAngle,
  });

  factory GHInstruction.fromJson(Map<String, dynamic> json) {
    return GHInstruction(
      text: json['text'],
      streetName: json['street_name'],
      distance: json['distance'],
      time: json['time'],
      interval: (json['interval'] as List).map((e) => e as int).toList(),
      sign: json['sign'],
      exitNumber: json['exit_number'],
      turnAngle: json['turn_angle'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['text'] = text;
    data['street_name'] = streetName;
    data['distance'] = distance;
    data['time'] = time;
    data['interval'] = interval;
    data['sign'] = sign;
    if (exitNumber != null) data['exit_number'] = exitNumber;
    if (turnAngle != null) data['turn_angle'] = turnAngle;
    return data;
  }
}

class GHDetails {
  /// The surface of the line segments.
  final List<GHSegment<String>> surface;

  /// The max speed of the line segments.
  final List<GHSegment<double>> maxSpeed;

  /// The smoothness of the line segments.
  final List<GHSegment<String>> smoothness;

  /// The lanes of the line segments.
  final List<GHSegment<int>> lanes;

  const GHDetails({
    required this.surface,
    required this.maxSpeed,
    required this.smoothness,
    required this.lanes,
  });

  factory GHDetails.fromJson(Map<String, dynamic> json) {
    return GHDetails(
      surface: (json['surface'] as List).map((e) => GHSegment<String>.fromJson(e)).toList(),
      maxSpeed: (json['max_speed'] as List).map((e) => GHSegment<double>.fromJson(e)).toList(),
      smoothness: (json['smoothness'] as List).map((e) => GHSegment<String>.fromJson(e)).toList(),
      lanes: (json['lanes'] as List).map((e) => GHSegment<int>.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['surface'] = surface.map((e) => e.toJson()).toList();
    data['max_speed'] = maxSpeed.map((e) => e.toJson()).toList();
    data['smoothness'] = smoothness.map((e) => e.toJson()).toList();
    data['lanes'] = lanes.map((e) => e.toJson()).toList();
    return data;
  }
}

class GHSegment<T> {
  /// The from coordinate number.
  final int from;

  /// The to coordinate number.
  final int to;

  /// The value.
  final T? value;

  const GHSegment({
    required this.from,
    required this.to,
    required this.value,
  });

  factory GHSegment.fromJson(List<dynamic> json) {
    return GHSegment(
      from: json[0], 
      to: json[1], 
      value: json.length > 2 ? json[2] : null,
    );
  }

  List<dynamic> toJson() {
    return [
      from,
      to, 
      if (value != null) value!,
    ];
  }
}
