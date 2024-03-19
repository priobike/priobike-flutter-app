import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/details/route_label.dart';

class ManagedRouteLabel {
  /// The route id.
  final int routeId;

  /// The screen coordinate X of the label.
  double? screenCoordinateX;

  /// The screen coordinate Y of the label.
  double? screenCoordinateY;

  /// The alignment of the label.
  RouteLabelAlignment? alignment;

  /// If the label is ready for display.
  bool ready() => screenCoordinateX != null && screenCoordinateY != null && alignment != null;

  /// The unique coordinates of the route.
  List<GHCoordinate> uniqueRouteCoordinates = [];

  /// Available route label candidates for the route label.
  List<ManagedRouteLabelCandidate>? availableRouteLabelCandidates;

  ManagedRouteLabel({
    required this.routeId,
    required this.uniqueRouteCoordinates,
  });
}

enum RouteLabelAlignment {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class ManagedRouteLabelCandidate {
  /// The screen coordinate where the label is pointing towards.
  final ScreenCoordinate screenCoordinate;

  /// The alignment of the label.
  final RouteLabelAlignment alignment;

  /// The box of the route label.
  late RouteLabelBox box;

  ManagedRouteLabelCandidate(
    this.screenCoordinate,
    this.alignment,
  ) {
    switch (alignment) {
      case RouteLabelAlignment.topLeft:
        box = RouteLabelBox(
          topLeft: screenCoordinate,
          topRight: ScreenCoordinate(x: screenCoordinate.x + RouteLabelState.maxWidth, y: screenCoordinate.y),
          bottomLeft: ScreenCoordinate(x: screenCoordinate.x, y: screenCoordinate.y + RouteLabelState.maxHeight),
          bottomRight: ScreenCoordinate(
              x: screenCoordinate.x + RouteLabelState.maxWidth, y: screenCoordinate.y + RouteLabelState.maxHeight),
        );
      case RouteLabelAlignment.topRight:
        box = RouteLabelBox(
          topLeft: ScreenCoordinate(x: screenCoordinate.x - RouteLabelState.maxWidth, y: screenCoordinate.y),
          topRight: screenCoordinate,
          bottomLeft: ScreenCoordinate(
              x: screenCoordinate.x - RouteLabelState.maxWidth, y: screenCoordinate.y + RouteLabelState.maxHeight),
          bottomRight: ScreenCoordinate(x: screenCoordinate.x, y: screenCoordinate.y + RouteLabelState.maxHeight),
        );
      case RouteLabelAlignment.bottomLeft:
        box = RouteLabelBox(
          topLeft: ScreenCoordinate(x: screenCoordinate.x, y: screenCoordinate.y - RouteLabelState.maxHeight),
          topRight: ScreenCoordinate(
              x: screenCoordinate.x + RouteLabelState.maxWidth, y: screenCoordinate.y - RouteLabelState.maxHeight),
          bottomLeft: screenCoordinate,
          bottomRight: ScreenCoordinate(x: screenCoordinate.x + RouteLabelState.maxWidth, y: screenCoordinate.y),
        );
      case RouteLabelAlignment.bottomRight:
        box = RouteLabelBox(
          topLeft: ScreenCoordinate(
              x: screenCoordinate.x - RouteLabelState.maxWidth, y: screenCoordinate.y - RouteLabelState.maxHeight),
          topRight: ScreenCoordinate(x: screenCoordinate.x, y: screenCoordinate.y - RouteLabelState.maxHeight),
          bottomLeft: ScreenCoordinate(x: screenCoordinate.x - RouteLabelState.maxWidth, y: screenCoordinate.y),
          bottomRight: screenCoordinate,
        );
    }
  }
}

/// The route label box which represents the dimensions of a route label.
class RouteLabelBox {
  /// The top left screen coordinate of the route label box.
  final ScreenCoordinate topLeft;

  /// The top right screen coordinate of the route label box.
  final ScreenCoordinate topRight;

  /// The bottom left screen coordinate of the route label box.
  final ScreenCoordinate bottomLeft;

  /// The bottom right screen coordinate of the route label box.
  final ScreenCoordinate bottomRight;

  RouteLabelBox({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
}

class RouteLabelManager extends ChangeNotifier {
  /// The logger for this service.
  final log = Logger("RouteLabelManager");

  /// A lock that avoids rapid relocating of route labels.
  final routeLabelLock = Lock(milliseconds: 250);

  /// The currently managed route labels.
  final List<ManagedRouteLabel> managedRouteLabels = [];

  /// The relative horizontal margin in pixel for the route label to be displayed.
  final double routeLabelMarginLeft;

  /// The relative horizontal margin in pixel for the route label to be displayed.
  final double routeLabelMarginRight;

  /// The relative vertical margin in pixel for the route label to be displayed.
  final double routeLabelMarginTop;

  /// The relative vertical margin in pixel for the route label to be displayed.
  final double routeLabelMarginBottom;

  /// The relative vertical margin in pixel for the route label to be displayed.
  final double widthMid;

  /// The relative vertical margin in pixel for the route label to be displayed.
  final double heightMid;

  /// The mapbox map controller.
  final MapboxMap mapController;

  RouteLabelManager({
    required this.routeLabelMarginLeft,
    required this.routeLabelMarginRight,
    required this.routeLabelMarginTop,
    required this.routeLabelMarginBottom,
    required this.widthMid,
    required this.heightMid,
    required this.mapController,
  });

  /// Function that resets the route labels.
  void resetService() {
    managedRouteLabels.clear();
    notifyListeners();
  }

  /// Resets outdated managed route labels.
  void _resetOutdatedRouteLabels() {
    for (int i = 0; i < managedRouteLabels.length; i++) {
      managedRouteLabels[i].screenCoordinateX = null;
      managedRouteLabels[i].screenCoordinateY = null;
      managedRouteLabels[i].alignment = null;
      managedRouteLabels[i].availableRouteLabelCandidates?.clear();
    }
  }

  /// Function that Updates the route labels.
  Future<void> updateRouteLabels() async {
    final routing = getIt<Routing>();
    if (routing.allRoutes == null || routing.allRoutes!.length < 2) {
      resetService();
      return;
    }

    // Initialize route label.
    if (managedRouteLabels.isEmpty) {
      List<List<GHCoordinate>> uniqueCoordinatesPerRoute = getUniqueCoordinatesPerRoute(routing.allRoutes!);

      for (final route in routing.allRoutes!) {
        managedRouteLabels.add(ManagedRouteLabel(
          routeId: route.id,
          uniqueRouteCoordinates: uniqueCoordinatesPerRoute[route.id].toList(),
        ));
      }
    } else {
      _resetOutdatedRouteLabels();
    }

    // Check zoom level and return if to small.
    final camera = await mapController.getCameraState();
    if (camera.zoom < 9) return;

    // Visible screen coordinates per route.
    List<List<ScreenCoordinate>> visibleScreenCoordinates = [];

    // Preprocess data and calculate new candidates for the route labels.
    for (final routeLabel in managedRouteLabels) {
      final screenCoordinates = await _getVisibleScreenCoordinates(routeLabel.uniqueRouteCoordinates);
      visibleScreenCoordinates.add(screenCoordinates);
    }

    // Check intersections with route segments. Filter intersecting route label candidates out.
    for (int i = 0; i < managedRouteLabels.length; i++) {
      if (visibleScreenCoordinates[i].isEmpty) {
        managedRouteLabels[i].availableRouteLabelCandidates = [];
        continue;
      }

      List<ManagedRouteLabelCandidate> filteredCandidates = [];

      for (final screenCoordinate in visibleScreenCoordinates[i]) {
        List<ManagedRouteLabelCandidate> possibleCandidates =
            _getPossibleRouteLabelCandidates(screenCoordinate, visibleScreenCoordinates);

        filteredCandidates.addAll(possibleCandidates);
      }

      // Order the candidates of each route label, that the middlemost in relation to the route is checked first.
      ScreenCoordinate first = visibleScreenCoordinates[i].first;
      ScreenCoordinate last = visibleScreenCoordinates[i].last;

      filteredCandidates.sort((a, b) {
        final aDistToFirst = sqrt(pow(a.screenCoordinate.x - first.x, 2) + pow(a.screenCoordinate.y - first.y, 2));
        final aDistToLast = sqrt(pow(a.screenCoordinate.x - last.x, 2) + pow(a.screenCoordinate.y - last.y, 2));
        final bDistToFirst = sqrt(pow(b.screenCoordinate.x - first.x, 2) + pow(b.screenCoordinate.y - first.y, 2));
        final bDistToLast = sqrt(pow(b.screenCoordinate.x - last.x, 2) + pow(b.screenCoordinate.y - last.y, 2));

        if (max(aDistToFirst, aDistToLast) > max(bDistToFirst, bDistToLast)) {
          return 1;
        } else {
          return 0;
        }
      });

      managedRouteLabels[i].availableRouteLabelCandidates = filteredCandidates;
    }

    List<List<ManagedRouteLabelCandidate>> possibleCandidates = [];
    for (final routeLabel in managedRouteLabels) {
      if (routeLabel.availableRouteLabelCandidates != null) {
        possibleCandidates.add(routeLabel.availableRouteLabelCandidates!);
      } else {
        possibleCandidates.add([]);
      }
    }

    // Searching a valid combination where all route labels do not intersect each other.
    List<ManagedRouteLabelCandidate?>? combination = _getValidCombination(possibleCandidates, []);

    if (combination == null) {
      for (int i = 0; i < managedRouteLabels.length; i++) {
        managedRouteLabels[i].screenCoordinateX = null;
        managedRouteLabels[i].screenCoordinateY = null;
        managedRouteLabels[i].alignment = null;
      }
    } else {
      for (int i = 0; i < managedRouteLabels.length; i++) {
        managedRouteLabels[i].screenCoordinateX = combination[i]?.screenCoordinate.x;
        managedRouteLabels[i].screenCoordinateY = combination[i]?.screenCoordinate.y;
        managedRouteLabels[i].alignment = combination[i]?.alignment;
      }
    }

    notifyListeners();
  }

  /// Returns a List of lists of unique coordinates for every route.
  List<List<GHCoordinate>> getUniqueCoordinatesPerRoute(List<Route> routes) {
    List<HashSet<GHCoordinate>> coordinatesPerRoute = [];

    // Use hashsets to reduce the complexity for the contains function in the next part.
    for (final route in routes) {
      HashSet<GHCoordinate> coordinates = HashSet();

      for (GHCoordinate coordinate in route.path.points.coordinates) {
        coordinates.add(coordinate);
      }
      coordinatesPerRoute.add(coordinates);
    }

    List<HashSet<GHCoordinate>> uniqueCoordinatesPerRoute = [];

    for (final coordinates in coordinatesPerRoute) {
      HashSet<GHCoordinate> uniqueCoordinates = HashSet();
      for (final coordinate in coordinates) {
        bool unique = true;
        for (final coordinatesToBeChecked in coordinatesPerRoute) {
          if (coordinatesToBeChecked != coordinates) {
            if (coordinatesToBeChecked.contains(coordinate)) {
              unique = false;
              break;
            }
          }
        }
        if (unique) {
          uniqueCoordinates.add(coordinate);
        }
      }
      uniqueCoordinatesPerRoute.add(uniqueCoordinates);
    }

    List<List<GHCoordinate>> uniqueCoordinatesPerRouteList = [];
    // Map the unique coordinates to the original order of the route due to the hashset use.
    for (int i = 0; i < routes.length; i++) {
      List<GHCoordinate> uniqueCoordinatesList = [];
      for (GHCoordinate coordinate in routes[i].path.points.coordinates) {
        if (uniqueCoordinatesPerRoute[i].contains(coordinate)) {
          uniqueCoordinatesList.add(coordinate);
        }
      }
      uniqueCoordinatesPerRouteList.add(uniqueCoordinatesList);
    }

    return uniqueCoordinatesPerRouteList;
  }

  /// Returns a bool whether the given screen coordinate fits for the route label margins.
  bool _inScreenBounds(ScreenCoordinate screenCoordinate) {
    if (screenCoordinate.x > routeLabelMarginLeft &&
        screenCoordinate.x < routeLabelMarginRight &&
        screenCoordinate.y > routeLabelMarginTop &&
        screenCoordinate.y < routeLabelMarginBottom) {
      return true;
    } else {
      return false;
    }
  }

  /// Calculates the visible screen coordinates for a given list of route coordinates.
  Future<List<ScreenCoordinate>> _getVisibleScreenCoordinates(List<GHCoordinate> coordinates) async {
    List<ScreenCoordinate> screenCoordinates = [];
    for (final coordinate in coordinates) {
      final screenCoordinate = await mapController.pixelForCoordinate(
        Point(
          coordinates: Position(coordinate.lon, coordinate.lat),
        ).toJson(),
      );

      if (_inScreenBounds(screenCoordinate)) {
        screenCoordinates.add(screenCoordinate);
      }
    }

    return screenCoordinates;
  }

  /// Recursive implementation of a depth search through all possible combinations
  /// of route label candidates until a valid combination is found.
  /// Also considers cases where no route label candidate is available for a route.
  List<ManagedRouteLabelCandidate?>? _getValidCombination(
    List<List<ManagedRouteLabelCandidate>> possibleRouteLabelCandidates,
    List<ManagedRouteLabelCandidate?> combination,
  ) {
    bool last = (possibleRouteLabelCandidates.length == 1);
    int n = possibleRouteLabelCandidates[0].length;

    final previousCombination = combination.toList();

    // Edge Case, no candidates.
    if (n == 0) {
      final combinationToCheck = previousCombination.toList();
      combinationToCheck.add(null);
      if (last) {
        if (!_doesRouteLabelCombinationIntersect(combinationToCheck)) {
          return combinationToCheck;
        } else {
          return null;
        }
      } else {
        final completeCombination = _getValidCombination(
          possibleRouteLabelCandidates.sublist(1),
          combinationToCheck,
        );
        if (completeCombination != null) {
          return completeCombination;
        }
      }
    } else {
      for (int i = 0; i < n; i++) {
        ManagedRouteLabelCandidate candidate = possibleRouteLabelCandidates[0][i];
        final combinationToCheck = previousCombination.toList();
        combinationToCheck.add(candidate);
        if (last) {
          if (!_doesRouteLabelCombinationIntersect(combinationToCheck)) {
            return combinationToCheck;
          } else {
            return null;
          }
        } else {
          final completeCombination = _getValidCombination(
            possibleRouteLabelCandidates.sublist(1),
            combinationToCheck,
          );
          if (completeCombination != null) {
            return completeCombination;
          }
        }
      }
    }

    return null;
  }

  /// Checks for a given list of route label candidates if they do intersect geometrically.
  bool _doesRouteLabelCombinationIntersect(List<ManagedRouteLabelCandidate?> routeLabelCandidateCombination) {
    if (routeLabelCandidateCombination.length < 2) return false;

    ManagedRouteLabelCandidate? currentRouteLabelCandidate = routeLabelCandidateCombination[0];
    List<ManagedRouteLabelCandidate?> leftRouteLabelCandidates = routeLabelCandidateCombination.slice(1);

    for (ManagedRouteLabelCandidate? routeLabelCandidate in leftRouteLabelCandidates) {
      if (_doRouteLabelBoxesIntersect(currentRouteLabelCandidate?.box, routeLabelCandidate?.box)) return true;
    }

    return _doesRouteLabelCombinationIntersect(leftRouteLabelCandidates);
  }

  /// Checks if two given route label boxes intersect.
  _doRouteLabelBoxesIntersect(RouteLabelBox? routeLabelBox1, RouteLabelBox? routeLabelBox2) {
    if (routeLabelBox1 == null || routeLabelBox2 == null) return false;

    // https://silentmatt.com/rectangle-intersection/
    if (routeLabelBox1.topLeft.x < routeLabelBox2.topRight.x &&
        routeLabelBox1.topRight.x > routeLabelBox2.topLeft.x &&
        routeLabelBox1.topLeft.y < routeLabelBox2.bottomLeft.y &&
        routeLabelBox1.bottomLeft.y > routeLabelBox2.topLeft.y) {
      return true;
    }

    return false;
  }

  /// Returns possible route label boxes that do not intersect with any route segment.
  List<ManagedRouteLabelCandidate> _getPossibleRouteLabelCandidates(
      ScreenCoordinate candidate, List<List<ScreenCoordinate>> allCoordinates) {
    bool topLeftIntersects = false;
    bool topRightIntersects = false;
    bool bottomLeftIntersects = false;
    bool bottomRightIntersects = false;

    // Check if route label would be out of screen for each position.
    if (candidate.x + RouteLabelState.maxWidth > widthMid * 2) {
      topLeftIntersects = true;
      bottomLeftIntersects = true;
    }
    if (candidate.x - RouteLabelState.maxWidth < 0) {
      topRightIntersects = true;
      bottomRightIntersects = true;
    }
    if (candidate.y + RouteLabelState.maxHeight > heightMid * 2) {
      topRightIntersects = true;
      topLeftIntersects = true;
    }
    if (candidate.y - RouteLabelState.maxHeight < 0) {
      bottomLeftIntersects = true;
      bottomRightIntersects = true;
    }

    // Add a small offset accordingly to prevent filtering good candidates.
    double pointOffset = RouteLabelState.cornerIconMargin * 0.05;

    // Top left box.
    ScreenCoordinate topLeft = ScreenCoordinate(x: candidate.x + pointOffset, y: candidate.y + pointOffset);
    ManagedRouteLabelCandidate topLeftCandidate = ManagedRouteLabelCandidate(topLeft, RouteLabelAlignment.topLeft);

    // Top right box.
    ScreenCoordinate topRight = ScreenCoordinate(x: candidate.x - pointOffset, y: candidate.y + pointOffset);
    ManagedRouteLabelCandidate topRightCandidate = ManagedRouteLabelCandidate(topRight, RouteLabelAlignment.topRight);

    // Bottom left box.
    ScreenCoordinate bottomLeft = ScreenCoordinate(x: candidate.x + pointOffset, y: candidate.y - pointOffset);
    ManagedRouteLabelCandidate bottomLeftCandidate =
        ManagedRouteLabelCandidate(bottomLeft, RouteLabelAlignment.bottomLeft);

    // Bottom right box.
    ScreenCoordinate bottomRight = ScreenCoordinate(x: candidate.x - pointOffset, y: candidate.y - pointOffset);
    ManagedRouteLabelCandidate bottomRightCandidate =
        ManagedRouteLabelCandidate(bottomRight, RouteLabelAlignment.bottomRight);

    // The first and second coordinate of a segment.
    ScreenCoordinate? first;
    ScreenCoordinate? second;

    // Check all screen coordinates of each route.
    for (List<ScreenCoordinate> screenCoordinateRoute in allCoordinates) {
      // Go through screen coordinates of route.
      for (ScreenCoordinate screenCoordinate in screenCoordinateRoute) {
        // If all position intersect, we skip the candidate.
        if (topLeftIntersects && topRightIntersects && bottomLeftIntersects && bottomRightIntersects) break;

        // Set second to the next coordinate.
        second = screenCoordinate;

        if (first != null) {
          // Top left.
          // Check top left if we haven't found one yet.
          if (!topLeftIntersects) {
            topLeftIntersects = _checkLineIntersectsRect(
              topLeftCandidate.box.topLeft,
              topLeftCandidate.box.topRight,
              topLeftCandidate.box.bottomLeft,
              topLeftCandidate.box.bottomRight,
              first,
              second,
            );
          }

          // Top right.
          // Check top right if we haven't found one yet.
          if (!topRightIntersects) {
            topRightIntersects = _checkLineIntersectsRect(
              topRightCandidate.box.topLeft,
              topRightCandidate.box.topRight,
              topRightCandidate.box.bottomLeft,
              topRightCandidate.box.bottomRight,
              first,
              second,
            );
          }

          // Bottom left.
          // Check bottom left if we haven't found one yet.
          if (!bottomLeftIntersects) {
            // If screen coordinate intersects with bounding box.
            bottomLeftIntersects = _checkLineIntersectsRect(
              bottomLeftCandidate.box.topLeft,
              bottomLeftCandidate.box.topRight,
              bottomLeftCandidate.box.bottomLeft,
              bottomLeftCandidate.box.bottomRight,
              first,
              second,
            );
          }

          // Bottom right.
          // Check bottom right if we haven't found one yet.
          if (!bottomRightIntersects) {
            // If screen coordinate intersects with bounding box.
            bottomRightIntersects = _checkLineIntersectsRect(
              bottomRightCandidate.box.topLeft,
              bottomRightCandidate.box.topRight,
              bottomRightCandidate.box.bottomLeft,
              bottomRightCandidate.box.bottomRight,
              first,
              second,
            );
          }
        }

        // Set first to the last coordinate.
        first = screenCoordinate;
      }
    }

    List<ManagedRouteLabelCandidate> possibleCandidates = [];

    if (!topLeftIntersects) {
      possibleCandidates.add(topLeftCandidate);
    }
    if (!topRightIntersects) {
      possibleCandidates.add(topRightCandidate);
    }
    if (!bottomLeftIntersects) {
      possibleCandidates.add(bottomLeftCandidate);
    }
    if (!bottomRightIntersects) {
      possibleCandidates.add(bottomRightCandidate);
    }

    return possibleCandidates;
  }

  /// Returns a bool if a route segment intersects with a rect.
  bool _checkLineIntersectsRect(
      ScreenCoordinate topLeftRect,
      ScreenCoordinate topRightRect,
      ScreenCoordinate bottomLeftRect,
      ScreenCoordinate bottomRightRect,
      ScreenCoordinate startLine,
      ScreenCoordinate endLine) {
    // Check if line intersects with one side of the rect.
    // Side 1 (topLeft - topRight).
    if (_doLinesIntersect(topLeftRect, topRightRect, startLine, endLine)) {
      return true;
    }
    // Side 2 (topRight - bottomRight).
    if (_doLinesIntersect(topRightRect, bottomRightRect, startLine, endLine)) {
      return true;
    }
    // Side 3 (bottomRight - bottomLeft).
    if (_doLinesIntersect(bottomRightRect, bottomLeftRect, startLine, endLine)) {
      return true;
    }
    // Side 4 (bottomLeft - topLeft).
    if (_doLinesIntersect(bottomLeftRect, topLeftRect, startLine, endLine)) {
      return true;
    }

    return false;
  }

  /// Returns a bool on whether two lines intersect each other.
  bool _doLinesIntersect(
      ScreenCoordinate startLine1, ScreenCoordinate endLine1, ScreenCoordinate startLine2, ScreenCoordinate endLine2) {
    // Calculate orientations for the line of 1 to 2 with the points 3 and 4.
    double orientation1 = _orientation(startLine1, endLine1, startLine2);
    double orientation2 = _orientation(startLine1, endLine1, endLine2);

    // Calculate orientations for the line 3 to 4 with points 1 and 2.
    double orientation3 = _orientation(startLine2, endLine2, startLine1);
    double orientation4 = _orientation(startLine2, endLine2, endLine1);

    // Orientation 1 and 2 have to be different (clockwise and anti clockwise). This makes sure that point 3 and 4 are on different side.
    // Orientation 3 and 4 have to be different (clockwise and anti clockwise). This makes sure that point 1 and 2 are on different side.
    // If these conditions are true the lines have to intersect.
    // We leave out collinear lines to simplify this step. It's an edge case we can skip.
    if ((orientation1 * orientation2 < 0) && (orientation3 * orientation4 < 0)) {
      return true;
    }
    return false;
  }

  /// Helper function that calculates the orientation of three points.
  /// Means if they are collinear, clockwise or anti clockwise oriented.
  /// 0 means collinear, <0 means anti clockwise and >0 means clockwise.
  /// Formula from:
  /// https://math.stackexchange.com/questions/405966/if-i-have-three-points-is-there-an-easy-way-to-tell-if-they-are-collinear
  double _orientation(ScreenCoordinate startLine, ScreenCoordinate endLine, ScreenCoordinate point) {
    return (endLine.y - startLine.y) * (point.x - endLine.x) - (point.y - endLine.y) * (endLine.x - startLine.x);
  }
}
