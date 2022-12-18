import 'package:flutter/material.dart' hide Route;
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/messages/recommendation.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/sg.dart';

abstract class Ride with ChangeNotifier {
  /// The threshold used for showing traffic light colors and speedometer colors
  static const qualityThreshold = 0.5;

  /// An optional callback that is called when a new recommendation is received.
  void Function(Sg?)? onSelectNextSignalGroup;

  /// The currently selected route.
  Route? route;

  /// The current predicted phases.
  List<Phase>? calcPhasesFromNow;

  /// The prediction qualities from now in [0.0, 1.0], calculated periodically.
  List<double>? calcQualitiesFromNow;

  /// The current predicted time of the next phase change, calculated periodically.
  DateTime? calcCurrentPhaseChangeTime;

  /// The predicted current signal phase, calculated periodically.
  Phase? calcCurrentSignalPhase;

  /// The prediction quality in [0.0, 1.0], calculated periodically.
  double? calcPredictionQuality;

  /// The current signal group, calculated periodically.
  Sg? calcCurrentSG;

  /// The calculated distance to the next signal group.
  double? calcDistanceToNextSG;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The recorded recommendations of the ride.
  final recommendations = List<Recommendation>.empty(growable: true);

  /// Select a new route.
  Future<void> selectRoute(BuildContext context, Route selectedRoute);

  /// Start the navigation.
  Future<void> startNavigation(BuildContext context);

  /// Update the position.
  Future<void> updatePosition(BuildContext context);

  /// Stop the navigation.
  Future<void> stopNavigation(BuildContext context);

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    calcPhasesFromNow = null;
    calcQualitiesFromNow = null;
    calcCurrentPhaseChangeTime = null;
    calcCurrentSignalPhase = null;
    calcPredictionQuality = null;
    calcCurrentSG = null;
    calcDistanceToNextSG = null;
    needsLayout = {};
  }

  /// Check if everything is calculated.
  bool get everythingCalculated =>
      calcPhasesFromNow != null &&
      calcQualitiesFromNow != null &&
      calcCurrentPhaseChangeTime != null &&
      calcCurrentSignalPhase != null &&
      calcPredictionQuality != null &&
      calcCurrentSG != null &&
      calcDistanceToNextSG != null;

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
