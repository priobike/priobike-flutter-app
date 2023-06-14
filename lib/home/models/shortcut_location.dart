import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';

/// The shortcut represents a saved route with a name.
class ShortcutLocation extends Shortcut {
  /// The waypoint of the shortcutLocation.
  final Waypoint waypoint;

  const ShortcutLocation({required name, required this.waypoint}) : super(name: name);

  factory ShortcutLocation.fromJson(Map<String, dynamic> json) {
    return ShortcutLocation(
      name: json['name'],
      waypoint: Waypoint.fromJson(json["waypoint"]),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'waypoint': waypoint.toJSON(),
      };

  /// Shortcuts with waypoints that are outside of the bounding box of the city are not allowed.
  @override
  bool isValid() {
    final boundaryService = getIt<Boundary>();
    if (boundaryService.checkIfPointIsInBoundary(waypoint.lon, waypoint.lat) == false) {
      return false;
    }
    return true;
  }
}
