import 'package:priobike/routing/models/waypoint.dart';

/// The shortcut represents a saved route with a name.
class Shortcut {
  /// The name of the shortcut.
  final String name;

  /// The waypoints of the shortcut.
  final List<Waypoint> waypoints;

  /// Get the linebreaked name of the shortcut. The name is split into at most 3 lines, by a limit of 15 characters.
  String get linebreakedName {
    var result = name;
    var insertedLinebreaks = 0;
    for (var i = 0; i < name.length; i++) {
      if (i % 15 == 0 && i != 0) {
        if (insertedLinebreaks == 2) {
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

  const Shortcut({required this.name, required this.waypoints});

  factory Shortcut.fromJson(Map<String, dynamic> json) {
    return Shortcut(
      name: json['name'],
      waypoints: (json['waypoints'] as List).map((e) => Waypoint.fromJson(e)).toList(),
    );
  }

  Shortcut trim() => Shortcut(
        name: name,
        waypoints: waypoints.map((e) {
          String? address;
          if (e.address == null) {
            address = null;
          } else if (e.address!.length <= 10) {
            address = e.address;
          } else {
            address = "${e.address?.substring(0, 10)}...";
          }
          return Waypoint(
            e.lat,
            e.lon,
            address: address,
          );
        }).toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'waypoints': waypoints.map((e) => e.toJSON()).toList(),
      };
}
