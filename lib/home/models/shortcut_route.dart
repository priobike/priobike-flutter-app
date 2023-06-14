import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';

/// The shortcut represents a saved route with a name.
class ShortcutRoute extends Shortcut {
    /// The waypoints of the shortcut.
  final List<Waypoint> waypoints;

  const ShortcutRoute({required name, required this.waypoints}) : super(name: name);

  factory ShortcutRoute.fromJson(Map<String, dynamic> json) {
    return ShortcutRoute(
      name: json['name'],
      waypoints: (json['waypoints'] as List).map((e) => Waypoint.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'waypoints': waypoints.map((e) => e.toJSON()).toList(),
  };

  /// Trim the addresses of the waypoints, if a factor < 1 is given.
  ShortcutRoute trim(double factor) => ShortcutRoute(
        name: name,
        waypoints: waypoints.map(
          (e) {
            String? address;
            if (e.address == null) {
              address = null;
            } else {
              final int newLength = (e.address!.length * factor).round();
              if (factor >= 1) {
                address = e.address;
              } else {
                address = "${e.address?.substring(0, newLength)}...";
              }
            }
            return Waypoint(
              e.lat,
              e.lon,
              address: address,
            );
          },
        ).toList(),
      );

  /// Copy the shortcut with another name.
  ShortcutRoute copyWith({String? name}) => ShortcutRoute(name: name ?? this.name, waypoints: waypoints);

  /// Shortcuts with waypoints that are outside of the bounding box of the city are not allowed.
  bool isValid() {
    final boundaryService = getIt<Boundary>();
    for (final waypoint in waypoints) {
      if (boundaryService.checkIfPointIsInBoundary(waypoint.lon, waypoint.lat) == false) {
        return false;
      }
    }
    return true;
  }
}
