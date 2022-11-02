/// Acceleration data, used to calculate features such as the DCI.
/// See: https://doi.org/10.1016/j.trc.2015.05.007
class Acceleration {
  /// The GPS latitude of the location.
  final double lat;

  /// The GPS longitude of the location.
  final double lng;

  /// The latitude of the location, snapped to the route/road network.
  final double sLat;

  /// The longitude of the location, snapped to the route/road network.
  final double sLng;

  /// The current estimated GPS speed in m/s.
  final double speed;

  /// The current estimated GPS location accuracy in m.
  final double acc;

  /// The start time in milliseconds since the epoch when the location was reported.
  final int sTime;

  /// The end time in milliseconds since the epoch when the location was reported.
  final int eTime;

  /// The number of measurements.
  final int n;

  /// The average acceleration in m/s².
  final double a;

  const Acceleration({
    required this.lat,
    required this.lng,
    required this.sLat,
    required this.sLng,
    required this.speed,
    required this.acc,
    required this.sTime,
    required this.eTime,
    required this.n,
    required this.a,
  });

  /// Create a new acceleration from a json object.
  factory Acceleration.fromJson(Map<String, dynamic> json) => Acceleration(
        lat: json['lat'] as double,
        lng: json['lng'] as double,
        sLat: json['sLat'] as double,
        sLng: json['sLng'] as double,
        speed: json['speed'] as double,
        acc: json['acc'] as double,
        sTime: json['sTime'] as int,
        eTime: json['eTime'] as int,
        n: json['n'] as int,
        a: json['a'] as double,
      );

  /// Convert this acceleration to a json object.
  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'sLat': sLat,
        'sLng': sLng,
        'speed': speed,
        'acc': acc,
        'sTime': sTime,
        'eTime': eTime,
        'n': n,
        'a': a,
      };
}
