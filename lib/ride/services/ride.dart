import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/prediction_service.dart';
import 'package:priobike/ride/services/predictor.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:provider/provider.dart';

/// The distance model.
const vincenty = Distance(roundResult: false);

class Ride with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("Ride");

  /// The threshold used for showing traffic light colors and speedometer colors
  static const qualityThreshold = 0.5;

  /// An optional callback that is called when a new recommendation is received.
  void Function(Sg?)? onSelectNextSignalGroup;

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The currently selected route.
  Route? route;

  /// The current prediction mode.
  PredictionMode? predictionMode;

  /// The current signal group, calculated periodically.
  Sg? calcCurrentSG;

  /// The signal group that the user wants to see.
  Sg? userSelectedSG;

  /// The current signal group index, calculated periodically.
  int? calcCurrentSGIndex;

  /// The current signal group index, selected by the user.
  int? userSelectedSGIndex;

  /// The calculated distance to the next signal group.
  double? calcDistanceToNextSG;

  /// The calculated distance to the next turn.
  double? calcDistanceToNextTurn;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The session id, set randomly by `startNavigation`.
  String? sessionId;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  void Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// The wrapper-service for the prediction service MQTT client.
  PredictionService? predictionService;

  /// The wrapper-service for the predictor MQTT client.
  Predictor? predictor;

  /// The currently used client used for the hybrid mode (predictionService or predictor) based on the current
  /// predictions of both.
  PredictionMode hybridModePredictionMode = PredictionMode.usePredictionService;

  /// The predicted current signal phase, calculated periodically.
  Phase? get calcCurrentSignalPhase {
    if (predictionMode == PredictionMode.usePredictionService) {
      return predictionService?.calcCurrentSignalPhase;
    } else if (predictionMode == PredictionMode.usePredictor) {
      return predictor?.calcCurrentSignalPhase;
    } else {
      if (hybridModePredictionMode == PredictionMode.usePredictionService) {
        return predictionService?.calcCurrentSignalPhase;
      } else if (hybridModePredictionMode == PredictionMode.usePredictor) {
        return predictor?.calcCurrentSignalPhase;
      } else {
        return null;
      }
    }
  }

  /// The current predicted time of the next phase change, calculated periodically.
  DateTime? get calcCurrentPhaseChangeTime {
    if (predictionMode == PredictionMode.usePredictionService) {
      return predictionService?.calcCurrentPhaseChangeTime;
    } else if (predictionMode == PredictionMode.usePredictor) {
      return predictor?.calcCurrentPhaseChangeTime;
    } else {
      if (hybridModePredictionMode == PredictionMode.usePredictionService) {
        return predictionService?.calcCurrentPhaseChangeTime;
      } else if (hybridModePredictionMode == PredictionMode.usePredictor) {
        return predictor?.calcCurrentPhaseChangeTime;
      } else {
        return null;
      }
    }
  }

  /// The prediction quality in [0.0, 1.0], calculated periodically.
  double? get calcPredictionQuality {
    if (predictionMode == PredictionMode.usePredictionService) {
      return predictionService?.calcPredictionQuality;
    } else if (predictionMode == PredictionMode.usePredictor) {
      return predictor?.calcPredictionQuality;
    } else {
      if (hybridModePredictionMode == PredictionMode.usePredictionService) {
        return predictionService?.calcPredictionQuality;
      } else if (hybridModePredictionMode == PredictionMode.usePredictor) {
        return predictor?.calcPredictionQuality;
      } else {
        return null;
      }
    }
  }

  /// The current predicted phases.
  List<Phase>? get calcPhasesFromNow {
    if (predictionMode == PredictionMode.usePredictionService) {
      return predictionService?.calcPhasesFromNow;
    } else if (predictionMode == PredictionMode.usePredictor) {
      return predictor?.calcPhasesFromNow;
    } else {
      if (hybridModePredictionMode == PredictionMode.usePredictionService) {
        return predictionService?.calcPhasesFromNow;
      } else if (hybridModePredictionMode == PredictionMode.usePredictor) {
        return predictor?.calcPhasesFromNow;
      } else {
        return null;
      }
    }
  }

  /// The prediction qualities from now in [0.0, 1.0], calculated periodically.
  List<double>? get calcQualitiesFromNow {
    if (predictionMode == PredictionMode.usePredictionService) {
      return predictionService?.calcQualitiesFromNow;
    } else if (predictionMode == PredictionMode.usePredictor) {
      return predictor?.calcQualitiesFromNow;
    } else {
      if (hybridModePredictionMode == PredictionMode.usePredictionService) {
        return predictionService?.calcQualitiesFromNow;
      } else if (hybridModePredictionMode == PredictionMode.usePredictor) {
        return predictor?.calcQualitiesFromNow;
      } else {
        return null;
      }
    }
  }

  /// The predictions received during the ride, from the prediction service.
  List<PredictionServicePrediction> get predictionServicePredictions {
    if (predictionMode == PredictionMode.usePredictor) return [];
    if (predictionService == null) return [];
    return predictionService!.predictionServicePredictions;
  }

  /// The predictions received during the ride, from the predictor.
  List<PredictorPrediction> get predictorPredictions {
    if (predictionMode == PredictionMode.usePredictionService) return [];
    if (predictor == null) return [];
    return predictor!.predictorPredictions;
  }

  /// The current prediction received during the ride.
  dynamic get prediction {
    if (predictionMode == PredictionMode.usePredictionService) {
      if (predictionService?.client == null) return null;
      return predictionService!.prediction;
    } else {
      if (predictor?.client == null) return null;
      return predictor!.prediction;
    }
  }

  /// The current calculated recommendation during the ride.
  Recommendation? get recommendation {
    if (predictionMode == PredictionMode.usePredictionService) {
      if (predictionService?.client == null) return null;
      return predictionService!.recommendation;
    } else {
      if (predictor?.client == null) return null;
      return predictor!.recommendation;
    }
  }

  /// Subscribe to the signal group.
  void selectSG(Sg? sg) {
    if (!navigationIsActive) return;
    if (predictionMode == PredictionMode.usePredictionService) {
      if (predictionService == null) return;
      predictionService!.selectSG(sg);
    } else if (predictionMode == PredictionMode.usePredictor) {
      if (predictor == null) return;
      predictor!.selectSG(sg);
    } else {
      if (predictionService != null) predictionService!.selectSG(sg);
      if (predictor != null) predictor!.selectSG(sg);
    }

    onSelectNextSignalGroup?.call(calcCurrentSG);
  }

  /// Callback that gets called when the prediction service MQTT client established a connection.
  void onPredictionServiceClientConnected() {
    if (predictionService?.client == null) return;
    predictionService!.selectSG(userSelectedSG ?? calcCurrentSG);
  }

  /// Callback that gets called when the predictor MQTT client established a connection.
  void onPredictorClientConnected() {
    if (predictor?.client == null) return;
    predictor!.selectSG(userSelectedSG ?? calcCurrentSG);
  }

  /// A wrapper for the notifyListeners() method used in case of the hybrid prediction mode.
  void predictionServiceUpdate() {
    if (predictionMode == PredictionMode.hybrid) {
      updateHybridMode();
    }
    notifyListeners();
  }

  /// A wrapper for the notifyListeners() method used in case of the hybrid prediction mode.
  void predictorUpdate() {
    if (predictionMode == PredictionMode.hybrid) {
      updateHybridMode();
    }
    notifyListeners();
  }

  /// Update the hybrid mode based on some factors (decide what predictions to use (predictionService-predictions or
  /// predictor-predictions)).
  void updateHybridMode() {
    // Basic availability checks.
    if (predictionService == null || predictor == null) return;
    if (predictionService?.client == null || predictor?.client == null) return;
    // If one is currently not connected use the other one.
    if (predictionService?.client == null || predictionService!.subscribedSG == null) {
      if (hybridModePredictionMode != PredictionMode.usePredictor) {
        hybridModePredictionMode = PredictionMode.usePredictor;
        log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Prediction service is not ${predictionService?.client == null ? "connected." : "subscribed."}""");
      }
      return;
    }
    if (predictor?.client == null || predictor!.subscribedSG == null) {
      if (hybridModePredictionMode != PredictionMode.usePredictionService) {
        hybridModePredictionMode = PredictionMode.usePredictionService;
        log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Predictor is not ${predictor?.client == null ? "connected." : "subscribed."}""");
      }
      return;
    }
    // If one is currently subscribed to the wrong signal group use the other one.
    if (predictionService!.subscribedSG != predictor!.subscribedSG) {
      Sg? currentSG = userSelectedSG ?? calcCurrentSG;
      if (currentSG == null) return;
      if (predictionService!.subscribedSG!.id != currentSG.id && predictor!.subscribedSG!.id == currentSG.id) {
        if (hybridModePredictionMode != PredictionMode.usePredictor) {
          hybridModePredictionMode = PredictionMode.usePredictor;
          log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Prediction service currently subscribes to the wrong SG.""");
        }
        return;
      }
      if (predictionService!.subscribedSG!.id == currentSG.id && predictor!.subscribedSG!.id != currentSG.id) {
        if (hybridModePredictionMode != PredictionMode.usePredictionService) {
          hybridModePredictionMode = PredictionMode.usePredictionService;
          log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Predictor currently subscribes to the wrong SG.""");
        }
        return;
      }
    }
    // If based on the previous checks everything is fine with both prediction clients use the prediction service as
    // default.
    if (hybridModePredictionMode != PredictionMode.usePredictionService) {
      log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Fallback to default.""");
      hybridModePredictionMode = PredictionMode.usePredictionService;
    }
  }

  /// Select the next signal group.
  /// Forward is step = 1, backward is step = -1.
  void jumpToSG({required int step}) {
    if (route == null) return;
    if (route!.signalGroups.isEmpty) return;
    if (userSelectedSGIndex == null && calcCurrentSGIndex == null) {
      // If there is no next signal group, select the first one if moving forward.
      // If moving backward, select the last one.
      userSelectedSGIndex = step > 0 ? 0 : route!.signalGroups.length - 1;
    } else if (userSelectedSGIndex == null) {
      // User did not manually select a signal group yet.
      userSelectedSGIndex = (calcCurrentSGIndex! + step) % route!.signalGroups.length;
    } else {
      // User manually selected a signal group.
      userSelectedSGIndex = (userSelectedSGIndex! + step) % route!.signalGroups.length;
    }
    userSelectedSG = route!.signalGroups[userSelectedSGIndex!];
    selectSG(userSelectedSG);
    notifyListeners();
  }

  /// Unselect the current signal group.
  void unselectSG() {
    if (userSelectedSG == null) return;
    if (userSelectedSGIndex == null) return;
    userSelectedSG = null;
    userSelectedSGIndex = null;
    onSelectNextSignalGroup?.call(calcCurrentSG);
    selectSG(calcCurrentSG);
    notifyListeners();
  }

  /// Select a new route.
  Future<void> selectRoute(BuildContext context, Route route) async {
    this.route = route;
    notifyListeners();
  }

  /// Start the navigation and connect the MQTT client.
  Future<void> startNavigation(BuildContext context, Function(SGStatusData)? onNewPredictionStatusDuringRide) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;

    final settings = Provider.of<Settings>(context, listen: false);
    predictionMode = settings.predictionMode;
    if (predictionMode == PredictionMode.usePredictionService) {
      // Connect the prediction service MQTT client.
      predictionService = PredictionService(
        onConnected: onPredictionServiceClientConnected,
        notifyListeners: predictionServiceUpdate,
        onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide,
      );
      predictionService!.connectMQTTClient(context);
      predictionService!.navigationIsActive = true;
    } else if (predictionMode == PredictionMode.usePredictor) {
      // Connect the predictor MQTT client.
      predictor = Predictor(
        onConnected: onPredictorClientConnected,
        notifyListeners: predictorUpdate,
        onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide,
      );
      predictor!.connectMQTTClient(context);
      predictor!.navigationIsActive = true;
    } else {
      // Hybrid mode -> connect both clients.
      predictionService = PredictionService(
        onConnected: onPredictionServiceClientConnected,
        notifyListeners: predictionServiceUpdate,
        onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide,
      );
      predictionService!.connectMQTTClient(context);
      predictionService!.navigationIsActive = true;
      predictor = Predictor(
        onConnected: onPredictorClientConnected,
        notifyListeners: predictorUpdate,
        onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide,
      );
      predictor!.connectMQTTClient(context);
      predictor!.navigationIsActive = true;
    }

    // Mark that navigation is now active.
    sessionId = UniqueKey().toString();
    navigationIsActive = true;
    // Notify listeners of a new sg status update.
    this.onNewPredictionStatusDuringRide = onNewPredictionStatusDuringRide;
  }

  /// Update the position.
  Future<void> updatePosition(BuildContext context) async {
    if (!navigationIsActive) return;

    final snap = Provider.of<Positioning>(context, listen: false).snap;
    if (snap == null || route == null) return;

    // Calculate the distance to the next turn.
    // Traverse the segments and find the next turn, i.e. where the bearing changes > <x>°.
    const bearingThreshold = 15;
    var calcDistanceToNextTurn = 0.0;
    for (int i = snap.metadata.shortestDistanceIndex; i < route!.route.length - 1; i++) {
      final n1 = route!.route[i], n2 = route!.route[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      final b = vincenty.bearing(p1, p2); // [-180°, 180°]
      calcDistanceToNextTurn += vincenty.distance(p1, p2);
      if ((b - snap.bearing).abs() > bearingThreshold) break;
    }
    this.calcDistanceToNextTurn = calcDistanceToNextTurn;

    // Find the next signal group.
    Sg? nextSg;
    int? nextSgIndex;
    double routeDistanceOfNextSg = double.infinity;
    for (int i = 0; i < route!.signalGroups.length; i++) {
      if (route!.signalGroupsDistancesOnRoute[i] > snap.distanceOnRoute) {
        nextSg = route!.signalGroups[i];
        nextSgIndex = i;
        routeDistanceOfNextSg = route!.signalGroupsDistancesOnRoute[i];
        break;
      }
    }

    // Find the next crossing that is not connected on the route.
    double routeDistanceOfDisconnectedCrossing = double.infinity;
    for (int i = 0; i < route!.crossings.length; i++) {
      if (route!.crossingsDistancesOnRoute[i] > snap.distanceOnRoute) {
        if (route!.crossings[i].connected) continue;
        // The crossing is not connected, so we can use it.
        routeDistanceOfDisconnectedCrossing = route!.crossingsDistancesOnRoute[i];
        break;
      }
    }
    // If the next disconnected crossing is closer, don't select the next sg just yet.
    if (routeDistanceOfDisconnectedCrossing < routeDistanceOfNextSg) {
      nextSg = null;
      nextSgIndex = null;
    }

    if (calcCurrentSG != nextSg) {
      calcCurrentSG = nextSg;
      calcCurrentSGIndex = nextSgIndex;
      // If the user didn't override the current sg, select it.
      if (userSelectedSG == null) selectSG(nextSg);
    }
    // Calculate the distance to the next signal group.
    if (calcCurrentSGIndex != null) {
      calcDistanceToNextSG = route!.signalGroupsDistancesOnRoute[calcCurrentSGIndex!] - snap.distanceOnRoute;
    } else {
      calcDistanceToNextSG = null;
    }

    notifyListeners();
  }

  /// Stop the navigation.
  Future<void> stopNavigation(BuildContext context) async {
    if (predictionService != null) predictionService!.stopNavigation();
    if (predictor != null) predictor!.stopNavigation();
    navigationIsActive = false;
    onNewPredictionStatusDuringRide = null; // Don't call the callback anymore.
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    if (predictionService != null) predictionService!.reset();
    if (predictor != null) predictor!.reset();
    calcCurrentSG = null;
    calcCurrentSGIndex = null;
    calcDistanceToNextSG = null;
    needsLayout = {};
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
