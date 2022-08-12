class Point {
  final double lon;
  final double lat;
  final double? alt;

  const Point({required this.lon, required this.lat, this.alt});

  const Point.withAltitude({required this.lon, required this.lat, required this.alt});

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      lon: json['lon'].toDouble(),
      lat: json['lat'].toDouble(),
      alt: json['alt']?.toDouble(),
    );
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
