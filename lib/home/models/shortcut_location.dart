import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/routing.dart';

/// The shortcut represents a saved location with a name.
class ShortcutLocation implements Shortcut {
  /// The type of the shortcut.
  @override
  final String type = "ShortcutLocation";

  /// The name of the shortcut.
  @override
  final String name;

  /// The waypoint of the shortcut location.
  final Waypoint waypoint;

  ShortcutLocation({required this.name, required this.waypoint});

  factory ShortcutLocation.fromJson(Map<String, dynamic> json) {
    return ShortcutLocation(
      name: json['name'],
      waypoint: Waypoint.fromJson(json["waypoint"]),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ShortcutLocation',
        'name': name,
        'waypoint': waypoint.toJSON(),
      };

  /// Locations with a waypoint outside of the bounding box of the city are not allowed.
  @override
  bool isValid() {
    final boundaryService = getIt<Boundary>();
    if (boundaryService.checkIfPointIsInBoundary(waypoint.lon, waypoint.lat) == false) {
      return false;
    }
    return true;
  }

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

  @override
  bool isUsedInRouting() {
    bool isUsed = false;
    getIt<Routing>().selectedWaypoints?.forEach((waypoint) {
      if (waypoint == this.waypoint) isUsed = true;
    });
    return isUsed;
  }

  @override
  Future<bool> onClick(BuildContext context) async {
    Positioning positioning = getIt<Positioning>();
    await positioning.requestSingleLocation(onNoPermission: () {
      showLocationAccessDeniedDialog(context, positioning.positionSource);
    });
    if (positioning.lastPosition != null) {
      await getIt<Routing>().selectWaypoints(
          [Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude), waypoint]);
      return true;
    } else {
      ToastMessage.showError("Route konnte nicht geladen werden.");
      return false;
    }
  }
}
