class UserPosition {
  double lat;
  double lon;
  int speed;
  String id;

  UserPosition({this.lat, this.lon, this.speed, this.id});

  UserPosition.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
    speed = json['speed'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    data['speed'] = this.speed;
    data['id'] = this.id;
    return data;
  }
}
