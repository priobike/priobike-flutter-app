class UserPosition {
  final double? lat;
  final double? lon;
  final double? speed;
  final double? accuracy;
  final double? heading;
  final DateTime? timestamp;

  const UserPosition({
    required this.lat,
    required this.lon,
    required this.speed,
    required this.accuracy,
    required this.heading,
    required this.timestamp,
  });

  factory UserPosition.fromJson(Map<String, dynamic> json) {
    return UserPosition(
      lat: json['lat'],
      lon: json['lon'],
      speed: json['speed'],
      accuracy: json['accuracy'],
      heading: json['heading'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lon'] = lon;
    data['speed'] = speed;
    data['accuracy'] = accuracy;
    data['heading'] = heading;
    data['timestamp'] = timestamp?.toIso8601String();
    return data;
  }
}
