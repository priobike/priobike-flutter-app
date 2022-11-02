class NominatimAddress {
  /// Reference to the Nominatim internal database id.
  final int placeId;

  /// Reference to the OSM Type.
  final String? osmType;

  /// Reference to the OSM Id.
  final int? osmId;

  /// The bounding box of the place.
  final List<String> boundingBox;

  /// Latitude of the centroid of the object.
  final double lat;

  /// Longitude of the centroid of the object.
  final double lon;

  /// Full comma separated address.
  final String displayName;

  /// Key of the main osm tag.
  final String? mainOSMTagClass;

  /// Value of the main osm tag.
  final String? mainOSMTagValue;

  /// Link to the class icon if available.
  final String? icon;

  /// Dictionary of address details (with addressdetails=1).
  /// See: https://nominatim.org/release-docs/develop/api/Output/#addressdetails
  final Map<String, dynamic>? addressDetails;

  /// Dictionary of extra tags (with extratags=1).
  final Map<String, dynamic>? extraTags;

  /// Dictionary of name details (with namedetails=1).
  final Map<String, dynamic>? nameDetails;

  /// The full geojson geometry of the object (with polygon_geojson=1).
  final Map<String, dynamic>? geoJsonGeometry;

  const NominatimAddress({
    required this.placeId,
    required this.osmType,
    required this.osmId,
    required this.boundingBox,
    required this.lat,
    required this.lon,
    required this.displayName,
    required this.mainOSMTagClass,
    required this.mainOSMTagValue,
    required this.icon,
    required this.addressDetails,
    required this.extraTags,
    required this.nameDetails,
    required this.geoJsonGeometry,
  });

  factory NominatimAddress.fromJson(Map<String, dynamic> json) {
    return NominatimAddress(
      placeId: json['place_id'] as int,
      osmType: json['osm_type'] as String?,
      osmId: json['osm_id'] as int?,
      boundingBox: (json['boundingbox'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
      displayName: json['display_name'] as String,
      mainOSMTagClass: json['class'] as String?,
      mainOSMTagValue: json['type'] as String?,
      icon: json['icon'] as String?,
      addressDetails: json['address'] as Map<String, dynamic>?,
      extraTags: json['extratags'] as Map<String, dynamic>?,
      nameDetails: json['namedetails'] as Map<String, dynamic>?,
      geoJsonGeometry: json['geojson'] as Map<String, dynamic>?,
    );
  }
}
