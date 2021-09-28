class UserPosition {
  double? lat;
  double? lon;
  int? speed;

  UserPosition({required this.lat, required this.lon, required this.speed});

  UserPosition.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
    speed = json['speed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lon'] = lon;
    data['speed'] = speed;
    return data;
  }
}
