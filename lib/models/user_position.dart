class UserPosition {
  double lat;
  double lon;
  int speed;

  UserPosition({this.lat, this.lon, this.speed});

  UserPosition.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
    speed = json['speed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    data['speed'] = this.speed;
    return data;
  }
}
