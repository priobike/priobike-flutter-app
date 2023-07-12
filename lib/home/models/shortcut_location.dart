import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
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
  String name;

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
      name: name,
      waypoint: Waypoint(
        waypoint.lat,
        waypoint.lon,
        address: newAddress,
      ),
    );
  }

  /// Copy the shortcut with another name.
  @override
  ShortcutLocation copyWith({String? name}) => ShortcutLocation(name: name ?? this.name, waypoint: waypoint);

  /// Function which loads the shortcut route.
  @override
  Future<bool> loadRoute(BuildContext context) async {
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

  /// Returns a String with a short info of the shortcut.
  @override
  String getShortInfo() {
    return waypoint.address ?? "";
  }

  /// Returns a Widget with a representation of the shortcut.
  @override
  Widget getRepresentation() {
    return const Icon(
      Icons.location_on,
      color: CI.blue,
      size: 64,
    );
  }

  /// Returns the icon of the shortcut type.
  @override
  Widget getTypeIcon() {
    return const Icon(Icons.location_on);
  }

  /// Checks if the shortcut waypoint is used in the selected route.
  @override
  bool isUsedInRouting() {
    bool isUsed = false;
    getIt<Routing>().selectedWaypoints?.forEach((waypoint) {
      if (waypoint == this.waypoint) isUsed = true;
    });
    return isUsed;
  }
}
