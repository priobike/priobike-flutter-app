import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:uuid/v4.dart';

/// The shortcut represents a saved location with a name.
class ShortcutLocation implements Shortcut {
  /// The unique id of the shortcut.
  @override
  final String id;

  /// The type of the shortcut.
  @override
  final String type = "ShortcutLocation";

  /// The name of the shortcut.
  @override
  String name;

  /// The waypoint of the shortcut location.
  final Waypoint waypoint;

  ShortcutLocation({
    required this.name,
    required this.waypoint,
    required this.id,
  });

  factory ShortcutLocation.fromJson(Map<String, dynamic> json) {
    return ShortcutLocation(
      id: json.keys.contains('id') ? json['id'] : const UuidV4().generate(),
      name: json['name'],
      waypoint: Waypoint.fromJson(json["waypoint"]),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ShortcutLocation',
        'id': id,
        'name': name,
        'waypoint': waypoint.toJSON(),
      };

  /// Get the linebreaked name of the shortcut location. The name is split into at most 2 lines, by a limit of 15 characters.
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

  /// Locations with a waypoint outside of the bounding box of the city are not allowed.
  @override
  bool isValid() {
    final boundaryService = getIt<Boundary>();
    if (boundaryService.checkIfPointIsInBoundary(waypoint.lon, waypoint.lat) == false) {
      return false;
    }
    return true;
  }

  /// Trim the addresses of the waypoints, if a factor < 1 is given.
  @override
  ShortcutLocation trim(double factor) {
    String? newAddress;
    if (waypoint.address == null) {
      newAddress = null;
    } else {
      final int newLength = (waypoint.address!.length * factor).round();
      if (factor >= 1) {
        newAddress = waypoint.address;
      } else {
        newAddress = "${waypoint.address?.substring(0, newLength)}...";
      }
    }

    return ShortcutLocation(
      id: id,
      name: name,
      waypoint: Waypoint(
        waypoint.lat,
        waypoint.lon,
        address: newAddress,
      ),
    );
  }

  @override

  /// Methods which returns a list of waypoints.
  List<Waypoint> getWaypoints() {
    return [waypoint];
  }

  /// Returns a String with a short info of the shortcut.
  @override
  String getShortInfo() {
    return waypoint.address ?? "";
  }

  /// Returns the icon of the shortcut type.
  @override
  Widget getIcon() {
    return const Icon(Icons.location_on);
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
}
