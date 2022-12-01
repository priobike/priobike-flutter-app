import 'package:priobike/routing/models/waypoint.dart';

class Place {
  /// The name of the place.
  final String name;

  /// The waypoint of the place.
  final Waypoint waypoint;

  const Place({required this.name, required this.waypoint});

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'],
      waypoint: (Waypoint.fromJson(json['waypoint'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'waypoint': waypoint.toJSON(),
      };
}
