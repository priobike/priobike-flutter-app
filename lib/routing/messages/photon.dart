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

  /// Returns the formatted display name of the address.
  /// Example: "Andreas-Pfitzmann-Bau, Nöthnitzer Straße 46, Räcknitz, 01187, Dresden, Sachsen, Deutschland"
  String getDisplayName() {
    var displayName = "";
    if (name != null) displayName += "$name, ";
    // only show house number if street is also present
    if (street != null && houseNumber != null) {
      displayName += "$street $houseNumber, ";
    } else if (street != null) {
      displayName += "$street, ";
    }
    if (district != null) displayName += "$district, ";
    if (postcode != null) displayName += "$postcode, ";
    if (city != null) displayName += "$city, ";
    if (state != null) displayName += "$state, ";
    if (country != null) displayName += "$country";
    return displayName;
  }
}
