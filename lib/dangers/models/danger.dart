/// A dangerous location reported by the user.
class Danger {
  /// The GPS latitude of the location.
  final double lat;

  /// The GPS longitude of the location.
  final double lon;

  /// The category of danger.
  final String category;

  const Danger({
    required this.lat,
    required this.lon,
    required this.category,
  });

  /// Create a new danger from a json object.
  factory Danger.fromJson(Map<String, dynamic> json) => Danger(
        lat: json['lat'] as double,
        lon: json['lon'] as double,
        category: json['category'] as String,
      );

  /// Convert this danger to a json object.
  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'category': category,
      };
}
