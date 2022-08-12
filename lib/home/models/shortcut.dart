

import 'package:flutter/material.dart';
import 'package:priobike/routing/models/waypoint.dart';

class Shortcut {
  /// The name of the shortcut.
  final String name;

  /// The icon of the shortcut.
  final IconData icon;

  /// The waypoints of the shortcut.
  final List<Waypoint> waypoints;

  const Shortcut({required this.name, required this.icon, required this.waypoints});
}
