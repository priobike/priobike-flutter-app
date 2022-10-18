/// A dangerous location reported by the user.
class Danger {
   /// The GPS latitude of the location.
  final double lat;

  /// The GPS longitude of the location.
  final double lng;

  /// The latitude of the location, snapped to the route/road network.
  final double sLat;

  /// The longitude of the location, snapped to the route/road network.
  final double sLng;

  /// The current estimated GPS location accuracy in m.
  final double acc;

  /// The time in milliseconds since the epoch when the location was reported.
  final int time;

  const Danger({
    required this.lat,
    required this.lng,
    required this.sLat,
    required this.sLng,
    required this.acc,
    required this.time,
  });

  /// Create a new danger from a json object.
  factory Danger.fromJson(Map<String, dynamic> json) => Danger(
    lat: json['lat'] as double,
    lng: json['lng'] as double,
    sLat: json['sLat'] as double,
    sLng: json['sLng'] as double,
    acc: json['acc'] as double,
    time: json['time'] as int,
  );

  /// Convert this danger to a json object.
  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'sLat': sLat,
    'sLng': sLng,
    'acc': acc,
    'time': time,
  };
}