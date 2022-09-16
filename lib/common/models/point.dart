class Point {
  /// The longitude of the point.
  final double lon;

  /// The latitude of the point.
  final double lat;

  /// The optional altitude of the point.
  final double? alt;

  const Point({required this.lon, required this.lat, this.alt});

  factory Point.fromJson(Map<String, dynamic> json) => Point(
    lon: json['lon'].toDouble(),
    lat: json['lat'].toDouble(),
    alt: json['alt']?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'lon': lon,
    'lat': lat,
    if (alt != null) 'alt': alt,
  };
}
