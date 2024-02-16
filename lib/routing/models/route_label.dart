import 'package:priobike/routing/messages/graphhopper.dart';

enum RouteLabelOrientationHorizontal { left, right }

enum RouteLabelOrientationVertical { bottom, top }

/// Route label class that represents the state of a route label.
class RouteLabel {
  /// The id of the route.
  int id;

  /// The selected state of the route label.
  bool selected;

  /// The time text of the route label.
  String timeText;

  /// The secondary text of the route label.
  String? secondaryText;

  /// The GHCoordinate of the waypoint.
  GHCoordinate? coordinate;

  /// The screen coordinate X of the label.
  double? screenCoordinateX;

  /// The screen coordinate Y of the label.
  double? screenCoordinateY;

  /// The vertical orientation of the route label.
  RouteLabelOrientationVertical? routeLabelOrientationVertical;

  /// The horizontal orientation of the route label.
  RouteLabelOrientationHorizontal? routeLabelOrientationHorizontal;

  /// The unique coordinates of the route.
  List<GHCoordinate> uniqueCoordinates;

  RouteLabel(
      {required this.id,
      required this.selected,
      required this.timeText,
      required this.uniqueCoordinates,
      this.secondaryText});

  void updateScreenPosition(double? x, double? y) {
    screenCoordinateX = x;
    screenCoordinateY = y;
  }

  void updateCoordinate(GHCoordinate? coordinate) {
    // Calculate more vertical or horizontal.
    this.coordinate = coordinate;

    // Update route label orientation.
    if (uniqueCoordinates.length < 2 || coordinate == null) return;
    GHCoordinate start = uniqueCoordinates[0];
    GHCoordinate end = uniqueCoordinates[uniqueCoordinates.length - 1];

    // Note: this code has to be adjusted for different regions in the world.
    // For region hamburg the following works.
    // To reduce complexity and use of costly functions this is not considered currently.

    // Switch start and end if start is above end.
    if (start.lat > end.lat) {
      var tmp = start;
      start = end;
      end = tmp;
    }

    // Calculate right or left from viewpoint north.
    double vector1X = end.lon - start.lon;
    double vector1Y = end.lat - start.lat;
    double vector2X = coordinate.lon - start.lon;
    double vector2Y = coordinate.lat - start.lat;
    double crossProduct = vector1X * vector2Y - vector1Y * vector2X;

    // Setting route label orientation due to cross product and start end relation.
    if (crossProduct > 0) {
      // Coordinate is on the left.
      // Therefore place the corner right.
      routeLabelOrientationHorizontal = RouteLabelOrientationHorizontal.right;
      if (start.lon > end.lon) {
        // Start is more right and therefore place the label top.
        routeLabelOrientationVertical = RouteLabelOrientationVertical.top;
      } else {
        // Start is more left and therefore place the label bottom.
        routeLabelOrientationVertical = RouteLabelOrientationVertical.bottom;
      }
    } else if (crossProduct < 0) {
      // Coordinate is on the right.
      // Therefore place the corner left
      routeLabelOrientationHorizontal = RouteLabelOrientationHorizontal.left;
      if (start.lon > end.lon) {
        // Start is more right and therefore place the label bottom.
        routeLabelOrientationVertical = RouteLabelOrientationVertical.bottom;
      } else {
        // Start is more left and therefore place the label top.
        routeLabelOrientationVertical = RouteLabelOrientationVertical.top;
      }
    } else {
      // Default value.
      routeLabelOrientationVertical = RouteLabelOrientationVertical.bottom;
      routeLabelOrientationHorizontal = RouteLabelOrientationHorizontal.left;
    }
  }
}
