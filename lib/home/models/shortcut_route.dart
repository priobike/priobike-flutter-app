import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:uuid/v4.dart';

/// The shortcut represents a saved route with a name.
class ShortcutRoute implements Shortcut {
  /// The unique id of the shortcut.
  @override
  final String id;

  /// The type of the shortcut.
  @override
  final String type = "ShortcutRoute";

  /// The name of the shortcut.
  @override
  String name;

  /// The waypoints of the shortcut.
  final List<Waypoint> waypoints;

  /// The length text of the route.
  String? routeLengthText;

  /// The time text of the route.
  String? routeTimeText;

  ShortcutRoute({
    required this.name,
    required this.waypoints,
    required this.id,
    this.routeLengthText,
    this.routeTimeText,
  });

  factory ShortcutRoute.fromJson(Map<String, dynamic> json) {
    return ShortcutRoute(
      id: json.keys.contains('id') ? json['id'] : const UuidV4().generate(),
      name: json['name'],
      waypoints: (json['waypoints'] as List).map((e) => Waypoint.fromJson(e)).toList(),
      routeLengthText: json['routeLengthText'],
      routeTimeText: json['routeTimeText'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
        'waypoints': waypoints.map((e) => e.toJSON()).toList(),
        'routeLengthText': routeLengthText,
        'routeTimeText': routeTimeText,
      };

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

  /// Trim the addresses of the waypoints, if a factor < 1 is given.
  @override
  ShortcutRoute trim(double factor) => ShortcutRoute(
        id: id,
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

  /// Methods which returns a list of waypoints.
  @override
  List<Waypoint> getWaypoints() {
    return waypoints;
  }

  /// Returns a String with a short info of the shortcut.
  @override
  String getShortInfo() {
    return "${waypoints.length} Wegpunkte";
  }

  /// Returns the icon of the shortcut type.
  @override
  Widget getIcon() {
    return const Icon(Icons.route);
  }

  /// Create sharing link of shortcut.
  @override
  String getLongLink() {
    final Map<String, dynamic> shortcutJson = toJson();
    final str = json.encode(shortcutJson);
    final bytes = utf8.encode(str);
    final base64Str = base64.encode(bytes);
    const scheme = 'https';
    const host = 'priobike.vkw.tu-dresden.de';
    const route = 'import';
    return '$scheme://$host/$route/$base64Str';
  }

  String? getFirstAddress() {
    if (waypoints.length >= 2) {
      return waypoints[0].address;
    }
    return null;
  }

  String? getLastAddress() {
    if (waypoints.length >= 2) {
      return waypoints[waypoints.length - 1].address;
    }
    return null;
  }
}
