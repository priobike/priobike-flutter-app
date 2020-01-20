class Sg {
  int index;
  double lat;
  double lon;
  String mqtt;

  Sg({this.index, this.lat, this.lon, this.mqtt});

  Sg.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    lat = json['lat'];
    lon = json['lon'];
    mqtt = json['mqtt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['index'] = this.index;
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    data['mqtt'] = this.mqtt;
    return data;
  }
}
