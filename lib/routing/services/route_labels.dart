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

  /// The unique coordinates of the route.
  List<GHCoordinate> uniqueCoordinates = [];

  /// Candidates for the route label.
  List<ScreenCoordinate>? candidates;

  /// Filtered candidates for the route label.
  List<ManagedRouteLabelCandidate>? filteredCandidates;

  ManagedRouteLabel({
    required this.routeId,
    required this.uniqueCoordinates,
    this.screenCoordinateX,
    this.screenCoordinateY,
    this.alignment,
    this.candidates,
  });
}

enum RouteLabelAlignment {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class ManagedRouteLabelCandidate {
  final ScreenCoordinate screenCoordinate;

  final List<RouteLabelBox> possibleBoxes;

  ManagedRouteLabelCandidate(this.screenCoordinate, this.possibleBoxes);
}

class RouteLabelBox {
  final double x;

  final double y;

  final double width;

  final double height;

  final RouteLabelAlignment routeLabelAlignment;

  RouteLabelBox(this.x, this.y, this.width, this.height, this.routeLabelAlignment);
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

  /// Returns a List of lists of unique coordinates for every route.
  /// Could be placed in Route service but since we don't always need this we can leave it here.
  List<List<GHCoordinate>> getUniqueCoordinatesPerRoute(List<Route> routes) {
    List<List<GHCoordinate>> uniqueCoordinatesLists = [];

    // Return a set of unique GHCoordinate lists.
    for (final route in routes) {
      List<GHCoordinate> uniqueCoordinates = [];

      // Go through all coordinates of the route and check for uniqueness.
      for (GHCoordinate coordinate in route.path.points.coordinates) {
        // Loop through all other routes except the current route.
        bool unique = true;
        for (final routeToBeChecked in routes) {
          if (routeToBeChecked.id != route.id) {
            // Compare coordinate to all coordinates in other route.
            for (GHCoordinate coordinateToBeChecked in routeToBeChecked.path.points.coordinates) {
              if (!unique) {
                break;
              }
              if (coordinateToBeChecked.lon == coordinate.lon && coordinateToBeChecked.lat == coordinate.lat) {
                unique = false;
              }
            }
          }
        }

        if (unique) {
          // Check coordinates in screen bounds.
          uniqueCoordinates.add(coordinate);
        }
      }

      if (uniqueCoordinates.isNotEmpty) {
        // Use the middlemost coordinate.
        uniqueCoordinatesLists.add(uniqueCoordinates);
      }
    }

    return uniqueCoordinatesLists;
  }

  /// Function that Updates the route labels.
  Future<void> updateRouteLabels() async {
    final routing = getIt<Routing>();
    if (routing.allRoutes == null) return;
    if (routing.allRoutes!.length < 2) return;

    // Initialize route label.
    // Init id, time text, secondary text and unique coordinates per route once.
    if (managedRouteLabels.isEmpty) {
      // Init unique waypoints per route.
      List<List<GHCoordinate>> uniqueCoordinatesPerRoute = getUniqueCoordinatesPerRoute(routing.allRoutes!);

      for (final route in routing.allRoutes!) {
        managedRouteLabels.add(ManagedRouteLabel(
          routeId: route.id,
          uniqueCoordinates: uniqueCoordinatesPerRoute[route.id],
        ));
      }
    }

    /// Returns a bool whether the given screen coordinate fits for the route label margins.
    bool _routeLabelInScreenBounds(ScreenCoordinate screenCoordinate) {
      if (screenCoordinate.x > routeLabelMarginLeft &&
          screenCoordinate.x < routeLabelMarginRight &&
          screenCoordinate.y > routeLabelMarginTop &&
          screenCoordinate.y < routeLabelMarginBottom) {
        return true;
      } else {
        return false;
      }
    }

    /// Calculates the screen coordinates for a given route label.
    Future<(List<ScreenCoordinate>?, List<ScreenCoordinate>?)> getScreenCoordinates(
        ManagedRouteLabel routeLabel) async {
      // Store all visible unique coordinates.
      List<ScreenCoordinate> coordinates = [];
      List<ScreenCoordinate> coordinatesUniqueAndVisible = [];

      for (GHCoordinate coordinate in routing.allRoutes![routeLabel.routeId].path.points.coordinates) {
        // Check coordinates in screen bounds.
        ScreenCoordinate screenCoordinate = await mapController!.pixelForCoordinate(
          Point(
            coordinates: Position(coordinate.lon, coordinate.lat),
          ).toJson(),
        );

        // Add the screen coordinate to list.
        coordinates.add(screenCoordinate);

        if (routeLabel.uniqueCoordinates.contains(coordinate) && _routeLabelInScreenBounds(screenCoordinate)) {
          // Add the screen coordinate to list if visible and unique.
          coordinatesUniqueAndVisible.add(screenCoordinate);
        }
      }

      return (coordinates, coordinatesUniqueAndVisible);
    }

    // The new route label list is set at the end of this function.
    List<ManagedRouteLabel> updatedRouteLabels = [];
    // The list of lists with all screen coordinates.
    // Separated in different lists to avoid connecting screen coordinates of different routes to segments.
    List<List<ScreenCoordinate>> allCoordinates = [];

    // Preprocess data and calculate new candidates for the route labels.
    for (final routeLabel in managedRouteLabels) {
      // Get all screen coordinates of the route labels route and all candidates for this route label.
      var (allCoordinatesRouteLabel, candidates) = await getScreenCoordinates(routeLabel);
      if (allCoordinatesRouteLabel != null) {
        // Add to all coordinates.
        allCoordinates.add(allCoordinatesRouteLabel);
      }
      routeLabel.candidates = candidates;
    }

    // Calculate intersections with route segments and screen bounds and filter those candidates out.
    for (final routeLabel in managedRouteLabels) {
      // Filtered candidates in decreasing order.
      List<ManagedRouteLabelCandidate> filteredCandidates = [];

      // Leave filteredCandidates empty if not candidates are in view.
      if (routeLabel.candidates == null || routeLabel.candidates!.isEmpty) {
        routeLabel.filteredCandidates = filteredCandidates;
        continue;
      }

      // Loop through candidates and filter.
      for (ScreenCoordinate candidate in routeLabel.candidates!) {
        // Check intersection with route segments for different orientations and return possible route label boxes.
        List<RouteLabelBox> possibleBoxes = _getPossibleRouteLabelBoxes(candidate, allCoordinates);

        // Skip candidate if no possible box found.
        if (possibleBoxes.isEmpty) continue;
        filteredCandidates.add(ManagedRouteLabelCandidate(candidate, possibleBoxes));
      }

      // Sort the filtered candidates so that the middlemost are the first ones to check compatibility.
      filteredCandidates.sort((a, b) =>
          ((a.screenCoordinate.x - widthMid).abs() + (a.screenCoordinate.y - heightMid).abs()) >
                  ((b.screenCoordinate.x - widthMid).abs() + (b.screenCoordinate.y - heightMid).abs())
              ? 1
              : 0);

      // Finally set filtered candidates for route label.
      routeLabel.filteredCandidates = filteredCandidates;
    }

    // Choose route label boxes that do not intersect with each other.
    // Therefore go through route labels and find the first combination, that do not intersect for all route labels given.

    // Hypothetically order of checks is as follows:
    /*
    x0 y0 z0
    x1 y0 z0
    x0 y1 z0
    x0 y0 z1
    x1 y1 z1
     */
    // The assumption is that a combination can be quickly and therefore can be simplified.

    // Calculate max depth for the algorithm.
    int maxLength = managedRouteLabels.fold(
        0,
        (int max, ManagedRouteLabel routeLabel) => max =
            (routeLabel.filteredCandidates != null && routeLabel.filteredCandidates!.length > max
                ? routeLabel.filteredCandidates!.length
                : max));

    bool combinationFound = false;
    if (maxLength > 0) {
      // Width search through filtered candidates.
      for (int i = 0; i < maxLength; i++) {
        if (combinationFound) break;

        // Iterate every combination plus one for index j.
        // Start at index -1 so that we have number route labels + 1 iterations.
        for (int j = -1; j < managedRouteLabels.length; j++) {
          if (combinationFound) break;

          List<ManagedRouteLabelCandidate?> candidateCombination = [];
          // Fill candidates for iteration.
          // Increment index where k == j.
          for (int k = 0; k < managedRouteLabels.length; k++) {
            if (managedRouteLabels[k].filteredCandidates!.isNotEmpty) {
              // Only increment if filtered candidate length is greater then i + 1.
              // This means increment if there is one more element or use the last element.
              if (managedRouteLabels[k].filteredCandidates!.length > i + 1) {
                candidateCombination.add(managedRouteLabels[k].filteredCandidates![i + (k == j ? 1 : 0)]);
              } else {
                // Add last candidate.
                if (managedRouteLabels[k].filteredCandidates!.isNotEmpty) {
                  candidateCombination.add(
                      managedRouteLabels[k].filteredCandidates![managedRouteLabels[k].filteredCandidates!.length - 1]);
                }
              }
            } else {
              // No candidate found after filter for this route label.
              candidateCombination.add(null);
            }
          }
          // Candidate list complete for this iteration.

          // If candidate list contains only one element, just pick first one.
          // This can happen, when the second route is not visible.
          if (candidateCombination.length < 2) {
            // Has to be not null if only one element is set as candidate combination.
            managedRouteLabels[0].screenCoordinateX = candidateCombination[0]!.screenCoordinate.x;
            managedRouteLabels[0].screenCoordinateY = candidateCombination[0]!.screenCoordinate.y;
            managedRouteLabels[0].alignment = candidateCombination[0]!.possibleBoxes[0].routeLabelAlignment;
            updatedRouteLabels.add(managedRouteLabels[0]);
            combinationFound = true;
          }

          // Test combination with all label options and break when first combination fits.

          // Get working combination or null.
          List<RouteLabelBox?> foundCombination =
              _findCombinationForRouteLabelBoxes(candidateCombination[0], candidateCombination.slice(1), []);

          // Stop searching and update route labels if combination found.
          if (foundCombination.isNotEmpty) {
            // Update route labels.
            for (int i = 0; i < foundCombination.length; i++) {
              managedRouteLabels[i].screenCoordinateX = foundCombination[i]?.x;
              managedRouteLabels[i].screenCoordinateY = foundCombination[i]?.y;
              managedRouteLabels[i].alignment = foundCombination[i]?.routeLabelAlignment;
              updatedRouteLabels.add(managedRouteLabels[i]);
            }
            combinationFound = true;
          }
        }
      }
    }

    // No combination could be found.
    if (!combinationFound) {
      // No filtered route labels left.
      // Update all route labels with null.
      for (final routeLabel in managedRouteLabels) {
        routeLabel.screenCoordinateX = null;
        routeLabel.screenCoordinateY = null;
        routeLabel.alignment = null;
        updatedRouteLabels.add(routeLabel);
      }
    }

    // Update route labels list.
    managedRouteLabels.clear();
    managedRouteLabels.addAll(updatedRouteLabels);
    notifyListeners();
  }

  /// Returns a list of route label box updates or empty list if no combination was found.
  /// Recursive function that tests a list of candidates with a given candidate.
  /// Hypothetically order: x1<->x2, x1<->x3, x2<->x3, done.
  List<RouteLabelBox?> _findCombinationForRouteLabelBoxes(ManagedRouteLabelCandidate? routeLabelCandidate,
      List<ManagedRouteLabelCandidate?> leftCandidates, List<RouteLabelBox?> routeLabelBoxList) {
    // Nothing left to compare.
    if (leftCandidates.isEmpty) {
      if (routeLabelCandidate == null) {
        routeLabelBoxList.add(null);
        // Check if combination intersects.
        if (!_doesOrientationCombinationIntersect(routeLabelBoxList)) {
          // Return route label box list if fits.
          return routeLabelBoxList;
        }
      } else {
        for (RouteLabelBox routeLabelBox in routeLabelCandidate.possibleBoxes) {
          // Add the current orientation.
          routeLabelBoxList.add(routeLabelBox);
          // Check if combination intersects.
          if (!_doesOrientationCombinationIntersect(routeLabelBoxList)) {
            // Return route label box list on first fit.
            return routeLabelBoxList;
          }
        }
      }

      // No combination found, return empty list.
      return [];
    }

    if (routeLabelCandidate == null) {
      routeLabelBoxList.add(null);

      List<RouteLabelBox?> workingRouteLabelBox =
          _findCombinationForRouteLabelBoxes(leftCandidates[0], leftCandidates.slice(1), routeLabelBoxList);

      // Returns the working orientation back to the first call of the function.
      if (workingRouteLabelBox.isNotEmpty) {
        return workingRouteLabelBox;
      }
    } else {
      for (RouteLabelBox routeLabelBox in routeLabelCandidate.possibleBoxes) {
        // Add the current orientation.
        routeLabelBoxList.add(routeLabelBox);
        // Recursive call of this function to go through the possible orientations.
        List<RouteLabelBox?> workingRouteLabelBox =
            _findCombinationForRouteLabelBoxes(leftCandidates[0], leftCandidates.slice(1), routeLabelBoxList);

        // Returns the working orientation back to the first call of the function.
        if (workingRouteLabelBox.isNotEmpty) {
          return workingRouteLabelBox;
        }
      }
    }
    return [];
  }

  /// Checks for a given list of route label boxes if they do not intersect geometrically.
  bool _doesOrientationCombinationIntersect(List<RouteLabelBox?> routeLabelBoxCombination) {
    // Does not intersect since only one element.
    if (routeLabelBoxCombination.length < 2) return false;

    RouteLabelBox? currentRouteLabelBox = routeLabelBoxCombination[0];
    List<RouteLabelBox?> leftRouteLabelBoxes = routeLabelBoxCombination.slice(1);

    // Compare each route label box.
    for (RouteLabelBox? routeLabelBox in leftRouteLabelBoxes) {
      // Compare and return true if intersect.
      // Return nothing if not intersect.

      if (_doRouteLabelBoxesIntersect(currentRouteLabelBox, routeLabelBox)) {
        return true;
      }
    }

    return _doesOrientationCombinationIntersect(leftRouteLabelBoxes);
  }

  /// Checks if two given route label boxes intersect.
  _doRouteLabelBoxesIntersect(RouteLabelBox? routeLabelBox1, RouteLabelBox? routeLabelBox2) {
    // Return false if one box is null since no route label will be shown.
    if (routeLabelBox1 == null || routeLabelBox2 == null) return false;

    // Check if one of the four corners of box 2 is inside box1.
    late double xMin;
    late double xMax;
    late double yMin;
    late double yMax;

    if (routeLabelBox1.width > 0) {
      xMin = routeLabelBox1.x;
      xMax = routeLabelBox1.x + routeLabelBox1.width;
    } else {
      xMin = routeLabelBox1.x + routeLabelBox1.width;
      xMax = routeLabelBox1.x;
    }

    if (routeLabelBox1.height > 0) {
      yMin = routeLabelBox1.y;
      yMax = routeLabelBox1.y + routeLabelBox1.width;
    } else {
      yMin = routeLabelBox1.y + routeLabelBox1.width;
      yMax = routeLabelBox1.y;
    }

    // Test if one of the four corners of the route label box 2 is inside route label box 1.
    // corner 1.
    if (routeLabelBox2.x > xMin && routeLabelBox2.x < xMax && routeLabelBox2.y > yMin && routeLabelBox2.y < yMax) {
      return true;
    }
    // corner 2.
    if (routeLabelBox2.x + routeLabelBox2.width > xMin &&
        routeLabelBox2.x + routeLabelBox2.width < xMax &&
        routeLabelBox2.y > yMin &&
        routeLabelBox2.y < yMax) {
      return true;
    }
    // corner 3.
    if (routeLabelBox2.x > xMin &&
        routeLabelBox2.x < xMax &&
        routeLabelBox2.y + routeLabelBox2.height > yMin &&
        routeLabelBox2.y + routeLabelBox2.height < yMax) {
      return true;
    }
    // corner 4.
    if (routeLabelBox2.x + routeLabelBox2.width > xMin &&
        routeLabelBox2.x + routeLabelBox2.width < xMax &&
        routeLabelBox2.y + routeLabelBox2.height > yMin &&
        routeLabelBox2.y + routeLabelBox2.height < yMax) {
      return true;
    }

    // Do not intersect.
    return false;
  }

  /// Returns possible route label boxes that do not intersect with any route segment.
  List<RouteLabelBox> _getPossibleRouteLabelBoxes(
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
    if (candidate.y + RouteLabelState.maxHeight > heightMid * 2) {}
    if (candidate.y - RouteLabelState.maxHeight < 0) {
      bottomLeftIntersects = true;
      bottomRightIntersects = true;
    }

    // Add a small offset accordingly to prevent filtering good candidates.
    double pointOffset = RouteLabelState.cornerIconMargin * 0.05;

    // Top left box.
    RouteLabelBox topLeftBox = RouteLabelBox(candidate.x + pointOffset, candidate.y + pointOffset,
        RouteLabelState.maxWidth, RouteLabelState.maxHeight, RouteLabelAlignment.topLeft);

    // Top right box.
    RouteLabelBox topRightBox = RouteLabelBox(candidate.x - pointOffset, candidate.y + pointOffset,
        -RouteLabelState.maxWidth, RouteLabelState.maxHeight, RouteLabelAlignment.topRight);

    // Bottom left box.
    RouteLabelBox bottomLeftBox = RouteLabelBox(candidate.x + pointOffset, candidate.y - pointOffset,
        RouteLabelState.maxWidth, -RouteLabelState.maxHeight, RouteLabelAlignment.bottomLeft);

    // Bottom right box.
    RouteLabelBox bottomRightBox = RouteLabelBox(candidate.x - pointOffset, candidate.y - pointOffset,
        -RouteLabelState.maxWidth, -RouteLabelState.maxHeight, RouteLabelAlignment.bottomRight);

    // The first end second coordinate of a segment.
    ScreenCoordinate? first;
    ScreenCoordinate? second;

    // Check all Coordinates of each route.
    for (List<ScreenCoordinate> screenCoordinateRoute in allCoordinates) {
      // Go through screen coordinates of route.
      for (ScreenCoordinate screenCoordinate in screenCoordinateRoute) {
        // All position intersect remove skip candidate.
        if (topLeftIntersects && topRightIntersects && bottomLeftIntersects && bottomRightIntersects) break;

        // Set second to the next coordinate.
        second = screenCoordinate;

        if (first != null) {
          // Top left.
          // Check top left if we haven't found one yet.
          if (!topLeftIntersects) {
            topLeftIntersects = _checkLineIntersectsRect(
                topLeftBox.x, topLeftBox.y, topLeftBox.width, topLeftBox.height, first.x, first.y, second.x, second.y);
          }

          // Top right.
          // Check top right if we haven't found one yet.
          if (!topRightIntersects) {
            topRightIntersects = _checkLineIntersectsRect(topRightBox.x, topRightBox.y, topRightBox.width,
                topRightBox.height, first.x, first.y, second.x, second.y);
          }

          // Bottom left.
          // Check bottom left if we haven't found one yet.
          if (!bottomLeftIntersects) {
            // If screen coordinate intersects with bounding box.
            bottomLeftIntersects = _checkLineIntersectsRect(bottomLeftBox.x, bottomLeftBox.y, bottomLeftBox.width,
                bottomLeftBox.height, first.x, first.y, second.x, second.y);
          }

          // Bottom right.
          // Check bottom right if we haven't found one yet.
          if (!bottomRightIntersects) {
            // If screen coordinate intersects with bounding box.
            bottomRightIntersects = _checkLineIntersectsRect(bottomRightBox.x, bottomRightBox.y, bottomRightBox.width,
                bottomRightBox.height, first.x, first.y, second.x, second.y);
          }
        }

        // Set first to the last coordinate.
        first = screenCoordinate;
      }
    }

    List<RouteLabelBox> possibleBoxes = [];

    if (!topLeftIntersects) {
      possibleBoxes.add(topLeftBox);
    }
    if (!topRightIntersects) {
      possibleBoxes.add(topRightBox);
    }
    if (!bottomLeftIntersects) {
      possibleBoxes.add(bottomLeftBox);
    }
    if (!bottomRightIntersects) {
      possibleBoxes.add(bottomRightBox);
    }

    return possibleBoxes;
  }

  /// Returns a bool if a route segment intersects with a rect.
  bool _checkLineIntersectsRect(
      startXRect, startYRect, rectWidth, rectHeight, startXLine, startYLine, endXLine, endYLine) {
    // Check if line intersects with one side of the rect.
    // Side 1 (start and width).
    if (_doLinesIntersect(
        startXRect, startYRect, startXRect + rectWidth, startYRect, startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }
    // Side 2 (start and height).
    if (_doLinesIntersect(
        startXRect, startYRect, startXRect, startYRect + rectHeight, startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }
    // Side 3 (start + height and width).
    if (_doLinesIntersect(startXRect, startYRect + rectHeight, startXRect + rectWidth, startYRect + rectHeight,
        startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }
    // Side 4 (start + width and height).
    if (_doLinesIntersect(startXRect + rectWidth, startYRect, startXRect + rectWidth, startYRect + rectHeight,
        startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }

    return false;
  }

  /// Returns a bool on whether two lines intersect each other.
  bool _doLinesIntersect(x1, y1, x2, y2, x3, y3, x4, y4) {
    // Calculate orientations for the line of 1 to 2 with the points 3 and 4.
    double orientation1 = _orientation(x1, y1, x2, y2, x3, y3);
    double orientation2 = _orientation(x1, y1, x2, y2, x4, y4);

    // Calculate orientations for the line 3 to 4 with points 1 and 2.
    double orientation3 = _orientation(x3, y3, x4, y4, x1, y1);
    double orientation4 = _orientation(x3, y3, x4, y4, x2, y2);

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
  double _orientation(x1, y1, x2, y2, x3, y3) {
    return (y2 - y1) * (x3 - x2) - (y3 - y2) * (x2 - x1);
  }
}
