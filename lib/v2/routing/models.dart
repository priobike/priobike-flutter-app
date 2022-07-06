class Waypoint {
  /// The latitude of the waypoint.
  double lat;

  /// The longitude of the waypoint.
  double lon;

  /// The address of this location.
  String address;

  Waypoint(this.lat, this.lon, {required this.address});  

  /// Convert the waypoint to a json map.
  Map<String, dynamic> toJSON() {
    return {
      "lat": lat, 
      "lon": lon, 
      "address": address,
    };
  }
}