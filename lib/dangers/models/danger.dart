/// A dangerous location reported by the user.
class Danger {
  /// A unique identifier for the danger.
  final int? pk;

  /// The GPS latitude of the location.
  final double lat;

  /// The GPS longitude of the location.
  final double lon;

  /// The category of danger.
  final String category;

  /// The icon of the danger.
  String get icon {
    switch (category) {
      case "potholes":
        return "assets/images/potholes.png";
      case "obstacle":
        return "assets/images/obstacle.png";
      case "dangerspot":
        return "assets/images/dangerspot.png";
      default:
        return "assets/images/dangerspot.png";
    }
  }

  /// The translation of the category.
  String get description {
    switch (category) {
      case "potholes":
        return "Schlechte Straße";
      case "obstacle":
        return "Hindernis";
      case "dangerspot":
        return "Gefahrenstelle";
      default:
        return "Gefahrenstelle";
    }
  }

  const Danger({
    required this.pk,
    required this.lat,
    required this.lon,
    required this.category,
  });

  /// Create a new danger from a json object.
  factory Danger.fromJson(Map<String, dynamic> json) => Danger(
        pk: json['pk'] as int?,
        lat: json['lat'] as double,
        lon: json['lon'] as double,
        category: json['category'] as String,
      );

  /// Convert this danger to a json object.
  Map<String, dynamic> toJson() => {
        if (pk != null) 'pk': pk,
        'lat': lat,
        'lon': lon,
        'category': category,
      };
}
