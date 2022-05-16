class UserPosition {
  double? lat;
  double? lon;
  double? speed;
  double? accuracy;
  double? heading;
  DateTime? timestamp;

  UserPosition({
    required this.lat,
    required this.lon,
    required this.speed,
    required this.accuracy,
    required this.heading,
    required this.timestamp,
  });

  UserPosition.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
    speed = json['speed'];
    accuracy = json['accuracy'];
    heading = json['heading'];
    timestamp = DateTime.parse(json['timestamp']);
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
