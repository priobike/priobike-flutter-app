/// A dangerous location reported by the user.
class Danger {
  /// A unique identifier for the danger.
  final int? pk;

  /// The GPS latitude of the location.
  final double lat;

  /// The GPS longitude of the location.
  final double lon;

  /// The category of danger. In the past we had multiple categories.
  /// To maintain backwards compatibility, we keep this field, but set it with a const value.
  static const category = "dangerspot";

  /// The icon of the danger.
  static const icon = "assets/images/dangerspot.png";

  /// The translation of the category.
  static const description = "Gefahrenstelle";

  const Danger({
    required this.pk,
    required this.lat,
    required this.lon,
  });

  /// Create a new danger from a json object.
  factory Danger.fromJson(Map<String, dynamic> json) => Danger(
        pk: json['pk'] as int?,
        lat: json['lat'] as double,
        lon: json['lon'] as double,
      );

  /// Convert this danger to a json object.
  Map<String, dynamic> toJson() => {
        if (pk != null) 'pk': pk,
        'lat': lat,
        'lon': lon,
        'category': category,
      };
}
