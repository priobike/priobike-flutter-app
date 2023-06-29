import 'package:flutter/cupertino.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/routing.dart';

/// The shortcut represents a saved route with a name.
class ShortcutRoute implements Shortcut {
  /// The name of the shortcut.
  @override
  final String name;

  /// The waypoints of the shortcut.
  final List<Waypoint> waypoints;

  ShortcutRoute({required this.name, required this.waypoints});

  factory ShortcutRoute.fromJson(Map<String, dynamic> json) {
    return ShortcutRoute(
      name: json['name'],
      waypoints: (json['waypoints'] as List).map((e) => Waypoint.fromJson(e)).toList(),
    );
  }

  @override
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
  @override
  bool isValid() {
    final boundaryService = getIt<Boundary>();
    for (final waypoint in waypoints) {
      if (boundaryService.checkIfPointIsInBoundary(waypoint.lon, waypoint.lat) == false) {
        return false;
      }
    }
    return true;
  }

  /// Get the linebreaked name of the shortcut route. The name is split into at most 2 lines, by a limit of 15 characters.
  @override
  String get linebreakedName {
    var result = name;
    var insertedLinebreaks = 0;
    for (var i = 0; i < name.length; i++) {
      if (i % 15 == 0 && i != 0) {
        if (insertedLinebreaks == 1) {
          // Truncate the name if it is too long
          result = result.substring(0, i);
          result += '...';
          break;
        }
        result = result.replaceRange(i, i + 1, '${result[i]}\n');
        insertedLinebreaks++;
      }
    }
    return result;
  }

  @override
  bool isUsedInRouting() {
    return getIt<Routing>().selectedWaypoints == waypoints;
  }

  @override
  Future<bool> onClick(BuildContext context) async {
    await getIt<Routing>().selectWaypoints(List.from(waypoints));
    return true;
  }
}
