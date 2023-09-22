import 'package:flutter/material.dart';
import 'package:priobike/routing/models/waypoint.dart';

/// The shortcut represents a saved route or location with a name.
abstract class Shortcut {
  /// The unique id of the shortcut.
  final String id;

  /// The type of the shortcut.
  final ShortcutType type;

  /// The name of the shortcut.
  String name;

  /// Get the linebreaked name of the shortcut.
  String get linebreakedName;

  /// Checks if the shortcut has invalid waypoints.
  bool isValid();

  /// Trim the addresses of the waypoints, if a factor < 1 is given.
  Shortcut trim(double factor);

  /// Methods which returns a list of waypoints.
  List<Waypoint> getWaypoints();

  /// Returns a String with a short info of the shortcut.
  String getShortInfo();

  /// Returns the icon of the shortcut type.
  Widget getIcon();

  Shortcut({required this.type, required this.name, required this.id});

  Map<String, dynamic> toJson();
}

enum ShortcutType {
  route,
  location,
}

extension ShortcutTypeDescription on ShortcutType {
  String description() {
    switch (this) {
      case ShortcutType.route:
        return "ShortcutRoute";
      case ShortcutType.location:
        return "ShortcutLocation";
    }
  }
}
