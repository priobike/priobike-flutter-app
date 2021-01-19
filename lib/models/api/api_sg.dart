class ApiSg {
  int index;
  double lat;
  double lon;
  String mqtt;

  ApiSg({this.index, this.lat, this.lon, this.mqtt});

  ApiSg.fromJson(Map<String, dynamic> json) {
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
