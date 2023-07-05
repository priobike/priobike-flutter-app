import 'package:flutter/material.dart';

/// The shortcut represents a saved route or location with a name.
abstract class Shortcut {
  /// The type of the shortcut.
  final String type;

  /// The name of the shortcut.
  final String name;

  /// Get the linebreaked name of the shortcut.
  String get linebreakedName;

  /// Checks if the shortcut has invalid waypoints.
  bool isValid();

  /// Trim the addresses of the waypoints, if a factor < 1 is given.
  Shortcut trim(double factor);

  /// Copy the shortcut with another name.
  Shortcut copyWith({String? name});

  /// Function which loads the shortcut route.
  Future<bool> loadRoute(BuildContext context);

  /// Returns a String with a short info of the shortcut.
  String getShortInfo();

  /// Returns a Widget with a representation of the shortcut.
  Widget getRepresentation();

  /// Returns the icon of the shortcut type.
  Widget getTypeIcon();

  /// Checks if the shortcut waypoints are used in the selected route.
  bool isUsedInRouting();

  const Shortcut({required this.name, required this.type});

  Map<String, dynamic> toJson();
}
