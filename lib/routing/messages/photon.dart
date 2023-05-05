class PhotonAddress {
  /// Reference to the OSM Type. Example: "W"
  final String? osmType;

  /// Reference to the OSM Id. Example: 23290301
  final int? osmId;

  /// Latitude of the centroid of the object. Example: 51.02546065
  final double lat;

  /// Longitude of the centroid of the object. Example: 13.72304
  final double lon;

  /// Name of the place. Example: "Andreas-Pfitzmann-Bau"
  final String? name;

  /// The Street. Example: "Nöthnitzer Straße"
  final String? street;

  /// The House Number. Example: "46"
  final String? houseNumber;

  /// The Suburb. Example: "Räcknitz"
  final String? district;

  /// The City. Example: "Dresden"
  final String? city;

  /// The State. Example: "Sachsen"
  final String? state;

  /// The Postcode. Example: "01187"
  final String? postcode;

  /// The Country. Example: "Deutschland"
  final String? country;

  /// The bounding box of the place.
  final List<double>? boundingBox;

  const PhotonAddress({
    required this.osmType,
    required this.osmId,
    required this.lat,
    required this.lon,
    required this.name,
    required this.street,
    required this.houseNumber,
    required this.district,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.boundingBox,
  });

  // For API Info see: https://github.com/komoot/photon
  factory PhotonAddress.fromJson(Map<String, dynamic> json) {
    return PhotonAddress(
      osmType: json["properties"]['osm_type'] as String?,
      osmId: json["properties"]['osm_id'] as int?,
      boundingBox: (json["properties"]['extent'] as List<dynamic>? ?? []).map((e) => e as double).toList(),
      lon: json["geometry"]["coordinates"][0] as double,
      lat: json["geometry"]["coordinates"][1] as double,
      street: json["properties"]["street"] as String?,
      houseNumber: json["properties"]["housenumber"] as String?,
      district: json["properties"]["district"] as String?,
      city: json["properties"]["city"] as String?,
      state: json["properties"]["state"] as String?,
      postcode: json["properties"]["postcode"] as String?,
      country: json["properties"]["country"] as String?,
      name: json["properties"]["name"] as String?,
    );
  }
}
