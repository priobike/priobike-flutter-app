import 'package:priobike/common/models/point.dart';

class CrossingMultiLane {
  /// The name of this crossing.
  final String name;

  /// The position of this crossing.
  final Point position;

  /// The distance on the route to this crossing (in meter).
  final double distanceOnRoute;

  /// If the crossing is connected to a SG.
  final bool connected;

  const CrossingMultiLane({
    required this.name,
    required this.position,
    required this.distanceOnRoute,
    required this.connected,
  });

  factory CrossingMultiLane.fromJson(Map<String, dynamic> json) => CrossingMultiLane(
        name: json['name'],
        position: Point.fromJson(json['position']),
        distanceOnRoute: json['distanceOnRoute'],
        connected: json['connected'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'position': position.toJson(),
        'distanceOnRoute': distanceOnRoute,
        'connected': connected,
      };
}
