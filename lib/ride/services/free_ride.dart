import 'dart:async';

import 'package:flutter/material.dart' hide Route, Shortcuts;
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/messages/prediction.dart';

/// The distance model.
const vincenty = Distance(roundResult: false);

class FreeRide with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("FreeRide");

  /// The timer which triggers updates to all SGs that should receive predictions.
  Timer? sgUpdateTimer;

  /// The SGs that should receive predictions.
  final Set<String> onScreenSGs = {};

  /// The received predictions
  final Map<String, PredictionServicePrediction> predictions = {};

  /// Start the ride.
  Future<void> startRide() async {
    sgUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {});
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    sgUpdateTimer?.cancel();
    sgUpdateTimer = null;
    notifyListeners();
  }
}
