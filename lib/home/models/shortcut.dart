import 'package:priobike/routing/models/waypoint.dart';

class Shortcut {
  /// The name of the shortcut.
  final String name;

  /// The waypoints of the shortcut.
  final List<Waypoint> waypoints;

  const Shortcut({required this.name, required this.waypoints});

  factory Shortcut.fromJson(Map<String, dynamic> json) {
    return Shortcut(
      name: json['name'],
      waypoints: (json['waypoints'] as List).map((e) => Waypoint.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['name'] = name;
    data['waypoints'] = waypoints.map((e) => e.toJSON()).toList();
    return data;
  }
}
