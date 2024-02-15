import 'package:priobike/routing/messages/graphhopper.dart';

/// Route label class that represents the state of a route label.
class RouteLabel {
  /// The id of the route.
  int id;

  /// The selected state of the route label.
  bool selected;

  /// The text of the route label.
  String text;

  /// The GHCoordinate of the waypoint.
  GHCoordinate? coordinate;

  /// The screen coordinate X of the label.
  double? screenCoordinateX;

  /// The screen coordinate Y of the label.
  double? screenCoordinateY;

  /// The unique coordinates of the route.
  List<GHCoordinate> uniqueCoordinates;

  RouteLabel({
    required this.id,
    required this.selected,
    required this.text,
    required this.uniqueCoordinates,
  });

  void updateCoordinate(GHCoordinate ghCoordinate) {
    coordinate = ghCoordinate;
  }

  void updateScreenPosition(double? x, double? y) {
    screenCoordinateX = x;
    screenCoordinateY = y;
  }
}
