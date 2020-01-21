class Point {
  double lon;
  double lat;
  // double ele;

  Point({this.lon, this.lat});

  Point.fromJson(Map<String, dynamic> json) {
    lon = json['lon'];
    lat = json['lat'];
    // lat = json['ele'].toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lon'] = this.lon;
    data['lat'] = this.lat;
    // data['ele'] = this.ele;
    return data;
  }
}
