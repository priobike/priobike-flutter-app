/// The shortcut represents a saved route or location with a name.
abstract class Shortcut {
  /// The name of the shortcut.
  final String name;

  /// Get the linebreaked name of the shortcut. The name is split into at most 2 lines, by a limit of 15 characters.
  String get linebreakedName;

  /// Checks if the route or location has invalid waypoints.
  bool isValid();

  const Shortcut({required this.name});

  Map<String, dynamic> toJson();
}
