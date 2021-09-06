class ApiPoint {
  double lon;
  double lat;
  double alt;

  ApiPoint({this.lon, this.lat});

  ApiPoint.fromJson(Map<String, dynamic> json) {
    lon = json['lon'];
    lat = json['lat'];
    alt = json['alt'].toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lon'] = this.lon;
    data['lat'] = this.lat;
    data['alt'] = this.alt;
    return data;
  }
}
