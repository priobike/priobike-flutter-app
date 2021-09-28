class Point {
  double? lon;
  double? lat;
  double? alt;

  Point({required this.lon, required this.lat});

  Point.withAltitude({required this.lon, required this.lat, this.alt});

  Point.fromJson(Map<String, dynamic> json) {
    lon = json['lon'].toDouble();
    lat = json['lat'].toDouble();
    alt = json['alt'].toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lon'] = lon;
    data['lat'] = lat;
    if (alt != null) {
      data['alt'] = alt;
    }
    return data;
  }
}
