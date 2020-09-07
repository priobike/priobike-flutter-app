class UserPosition {
  double lat;
  double lon;
  int speed;
  String id;
  int timestamp;

  UserPosition({this.lat, this.lon, this.speed, this.id, this.timestamp});

  UserPosition.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
    speed = json['speed'];
    id = json['id'];
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    data['speed'] = this.speed;
    data['id'] = this.id;
    data['timestamp'] = this.timestamp;
    return data;
  }
}