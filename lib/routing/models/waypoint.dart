class Waypoint {
  /// The latitude of the waypoint.
  final double lat;

  /// The longitude of the waypoint.
  final double lon;

  /// The address of this location.
  final String address;

  @override
  bool operator ==(other) => other is Waypoint && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  const Waypoint(this.lat, this.lon, {required this.address});  

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
    json['lat'], json['lon'], address: json['address']
  );

  /// Convert the waypoint to a json map.
  Map<String, dynamic> toJSON() => {
    "lat": lat, 
    "lon": lon, 
    "address": address,
  };
}