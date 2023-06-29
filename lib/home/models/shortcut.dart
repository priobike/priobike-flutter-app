import 'package:flutter/cupertino.dart';

/// The shortcut represents a saved route or location with a name.
abstract class Shortcut {
  /// The name of the shortcut.
  final String name;

  /// Get the linebreaked name of the shortcut.
  String get linebreakedName;

  /// Checks if the shortcut has invalid waypoints.
  bool isValid();

  /// Function which is executed on Shortcut Clicked.
  Future<bool> onClick(BuildContext context);

  /// Checks if the shortcut waypoints are used in the selected route.
  bool isUsedInRouting();

  const Shortcut({required this.name});

  Map<String, dynamic> toJson();
}
