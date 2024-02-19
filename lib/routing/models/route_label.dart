import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
  List<ScreenCoordinate>? allScreenCoordinates;

  /// The unique coordinates of the route.
  List<GHCoordinate> uniqueCoordinates;

  /// The unique coordinates of the route.
  List<ScreenCoordinate>? candidates;

  List<RouteLabelCandidate>? filteredCandidates;

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
}

class RouteLabelCandidate {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final ScreenCoordinate screenCoordinate;

  RouteLabelCandidate(this.topLeft, this.topRight, this.bottomLeft, this.bottomRight, this.screenCoordinate);
}
