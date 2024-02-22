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

  /// The unique coordinates of the route that are in screen sight.
  List<ScreenCoordinate>? candidates;

  /// The filtered candidates not intersecting route segments for the new route label.
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
  final ScreenCoordinate screenCoordinate;

  final List<RouteLabelBox> possibleBoxes;

  RouteLabelCandidate(this.screenCoordinate, this.possibleBoxes);
}

class RouteLabelBox {
  final double x;

  final double y;

  final double width;

  final double height;

  final RouteLabelOrientationVertical routeLabelOrientationVertical;

  final RouteLabelOrientationHorizontal routeLabelOrientationHorizontal;

  RouteLabelBox(this.x, this.y, this.width, this.height, this.routeLabelOrientationVertical,
      this.routeLabelOrientationHorizontal);
}
