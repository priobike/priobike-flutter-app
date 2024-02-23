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
  final double screenCoordinateX;

  /// The screen coordinate Y of the label.
  final double screenCoordinateY;

  /// The alignment of the label.
  final RouteLabelAlignment alignment;

  ManagedRouteLabel({
    required this.routeId,
    required this.screenCoordinateX,
    required this.screenCoordinateY,
    required this.alignment,
  });
}

enum RouteLabelAlignment {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class RouteLabelBox {
  final ScreenCoordinate topLeft;
  final ScreenCoordinate topRight;
  final ScreenCoordinate bottomLeft;
  final ScreenCoordinate bottomRight;

  RouteLabelBox({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
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

  /// The mapbox map controller.
  final MapboxMap mapController;

  RouteLabelManager({
    required this.routeLabelMarginLeft,
    required this.routeLabelMarginRight,
    required this.routeLabelMarginTop,
    required this.routeLabelMarginBottom,
    required this.mapController,
  });

  /// Checks whether a possible route label at those coordinates would be completely visible.
  bool _routeLabelCandidateInBounds(ManagedRouteLabelCandidate candidate) {
    final routeLabelBox = candidate.box;
    final maxLeft = routeLabelBox.topLeft.x;
    final maxRight = routeLabelBox.topRight.x;
    final maxTop = routeLabelBox.topLeft.y;
    final maxBottom = routeLabelBox.bottomLeft.y;
    if (maxLeft < routeLabelMarginLeft ||
        maxRight > routeLabelMarginRight ||
        maxTop < routeLabelMarginTop ||
        maxBottom > routeLabelMarginBottom) {
      return false;
    }

    return true;
  }

  /// Calculates all possible route label candidates for a given route independent of other route labels.
  Future<List<ManagedRouteLabelCandidate>> _getPossibleRouteLabelCandidates(Route route) async {
    List<ManagedRouteLabelCandidate> candidates = [];
    Set<ScreenCoordinate> uniqueScreenCoordinates = {};
    List<RouteLabelAlignment> alignments = [
      RouteLabelAlignment.topLeft,
      RouteLabelAlignment.topRight,
      RouteLabelAlignment.bottomLeft,
      RouteLabelAlignment.bottomRight,
    ];

    for (GHCoordinate coordinate in route.path.points.coordinates) {
      ScreenCoordinate screenCoordinate = await mapController.pixelForCoordinate(
        Point(
          coordinates: Position(coordinate.lon, coordinate.lat),
        ).toJson(),
      );

      // Avoid duplicate screen coordinates.
      if (uniqueScreenCoordinates.contains(screenCoordinate)) {
        continue;
      }
      uniqueScreenCoordinates.add(screenCoordinate);
      for (final alignment in alignments) {
        final candidate = ManagedRouteLabelCandidate(screenCoordinate, alignment);
        log.i(_routeLabelCandidateInBounds(candidate));
        if (_routeLabelCandidateInBounds(candidate)) {
          candidates.add(candidate);
        }
      }
    }

    return candidates;
  }

  bool _isValidCombination(
    List<ManagedRouteLabelCandidate> combination,
    List<List<int>> indicesToCheckPerCombination,
  ) {
    for (final indices in indicesToCheckPerCombination) {
      final candidate1 = combination[indices[0]];
      final candidate2 = combination[indices[1]];
      // https://silentmatt.com/rectangle-intersection/
      if (candidate1.box.topLeft.x < candidate2.box.topRight.x &&
          candidate1.box.topRight.x > candidate2.box.topLeft.x &&
          candidate1.box.topLeft.y < candidate2.box.bottomLeft.y &&
          candidate1.box.bottomLeft.y > candidate2.box.topLeft.y) {
        for (final routeCandidate in combination) {
          log.i(
              "Left: ${routeCandidate.box.topLeft.x}, Right: ${routeCandidate.box.topRight.x}, Top: ${routeCandidate.box.topLeft.y}, Bottom: ${routeCandidate.box.bottomLeft.y}");
        }

        return false;
      }
    }

    return true;
  }

  List<ManagedRouteLabelCandidate>? _getValidCombination(
    List<List<ManagedRouteLabelCandidate>> possibleRouteLabelScreenCoordinates,
    List<ManagedRouteLabelCandidate> combination,
    List<List<int>> indicesToCheckPerCombination,
  ) {
    bool last = (possibleRouteLabelScreenCoordinates.length == 1);
    int n = possibleRouteLabelScreenCoordinates[0].length;
    final previousCombination = combination.toList();

    for (int i = 0; i < n; i++) {
      ManagedRouteLabelCandidate candidate = possibleRouteLabelScreenCoordinates[0][i];
      final combinationToCheck = previousCombination.toList();
      combinationToCheck.add(candidate);
      if (last) {
        if (_isValidCombination(combinationToCheck, indicesToCheckPerCombination)) {
          return combinationToCheck;
        } else {
          return null;
        }
      } else {
        final completeCombination = _getValidCombination(
          possibleRouteLabelScreenCoordinates.sublist(1),
          combinationToCheck,
          indicesToCheckPerCombination,
        );
        if (completeCombination != null) {
          return completeCombination;
        }
      }
    }

    return null;
  }

  Future<void> updateRouteLabels() async {
    routeLabelLock.run(() async {
      final routing = getIt<Routing>();

      log.i("Updating route labels");

      managedRouteLabels.clear();

      if (routing.allRoutes == null || routing.allRoutes!.length < 2) {
        notifyListeners();
        return;
      }

      // Possible route label screen coordinates for all routes.
      List<List<ManagedRouteLabelCandidate>> possibleRouteLabelCandidates = [];

      // Preprocess data and calculate candidates for the route labels.
      for (final route in routing.allRoutes!) {
        possibleRouteLabelCandidates.add(await _getPossibleRouteLabelCandidates(route));
      }

      // Choose route label coordinates where all route labels do not intersect with each other (Brut Force).
      // When doing so, we need to check all possible combinations of route label candidates.
      final numberOfCandidatesPerCombination = possibleRouteLabelCandidates.length;
      List<List<int>> indicesToCheckPerCombination = [];
      for (int i = 0; i < numberOfCandidatesPerCombination; i++) {
        for (int j = i + 1; j < numberOfCandidatesPerCombination; j++) {
          if (i >= j) {
            continue;
          }
          indicesToCheckPerCombination.add([i, j]);
        }
      }
      List<ManagedRouteLabelCandidate>? validCombination = _getValidCombination(
        possibleRouteLabelCandidates,
        [],
        indicesToCheckPerCombination,
      );

      if (validCombination != null) {
        for (int i = 0; i < routing.allRoutes!.length; i++) {
          final route = routing.allRoutes![i];
          final candidate = validCombination[i];
          managedRouteLabels.add(ManagedRouteLabel(
            routeId: route.id,
            screenCoordinateX: candidate.screenCoordinate.x,
            screenCoordinateY: candidate.screenCoordinate.y,
            alignment: candidate.alignment,
          ));
        }
      }

      notifyListeners();
    });
  }
}
