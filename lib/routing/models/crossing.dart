import 'package:priobike/common/models/point.dart';

class Crossing {
  /// The name of this crossing.
  final String name;

  /// The position of this crossing.
  final Point position;

  /// If the crossing is connected to a SG.
  final bool connected;

  const Crossing({
    required this.name,
    required this.position,
    required this.connected,
  });

  factory Crossing.fromJson(Map<String, dynamic> json) => Crossing(
    name: json['name'],
    position: Point.fromJson(json['position']),
    connected: json['connected'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'position': position.toJson(),
    'connected': connected,
  };
}