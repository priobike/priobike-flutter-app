import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/accelerometer/models/acceleration.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

class Accelerometer with ChangeNotifier {
  final log = Logger("Accelerometer");

  /// The list of acceleration data points during the ride.
  List<Acceleration> accelerations = List.empty(growable: true);

  /// The current window of raw acceleration values.
  List<UserAccelerometerEvent> window = List.empty(growable: true);

  /// The time when the window was opened.
  int? windowStart;

  /// The current accelerometer stream subscription.
  StreamSubscription? sub;

  /// Start getting accelerometer data.
  Future<void> start() async {
    log.i("Starting accelerometer updates");
    // User accelerometer events come without the gravity component.
    sub = userAccelerometerEvents.listen(
      (event) {
        windowStart ??= DateTime.now().millisecondsSinceEpoch;
        window.add(event);
        notifyListeners();
      },
    );
  }

  /// Aggregate the raw acceleration values into a single acceleration data point.
  /// This method should be called when a new GPS location is received.
  /// May be used for DCI or other indices. See: https://doi.org/10.1016/j.trc.2015.05.007
  Future<void> updatePosition(BuildContext context) async {
    // First, clear the accelerometer window.
    final aXYZ = window.toList();
    window.clear();
    // Clear and cache the window start time.
    final windowStart = this.windowStart;
    this.windowStart = null;

    // Get the necessary data.
    final positioning = Provider.of<Positioning>(context, listen: false);
    if (positioning.lastPosition == null || positioning.snap == null) {
      log.w("Cannot calculate without a current position.");
      return;
    }
    if (aXYZ.length < 2) {
      log.w("Cannot calculate without at least two accelerometer values.");
      return;
    }
    if (aXYZ.length > 200) {
      // This may happen if the GPS is not updating fast enough.
      log.w("Cannot calculate with more than 200 accelerometer values.");
      return;
    }
    if (windowStart == null) {
      log.w("Cannot calculate without a window start time.");
      return;
    }
    // Compute the magnitude of the acceleration in m/s².
    final aMag = aXYZ.map((e) => e.x * e.x + e.y * e.y + e.z * e.z).map((e) => sqrt(e));
    // Compute the average acceleration in m/s².
    final n = aMag.length;
    final aAvg = aMag.reduce((a, b) => a + b) / n;
    // Create a new acceleration data point.
    final acceleration = Acceleration(
      lat: positioning.lastPosition!.latitude,
      lng: positioning.lastPosition!.longitude,
      sLat: positioning.snap!.position.latitude,
      sLng: positioning.snap!.position.longitude,
      acc: positioning.lastPosition!.accuracy,
      speed: positioning.lastPosition!.speed,
      sTime: windowStart,
      eTime: DateTime.now().millisecondsSinceEpoch,
      n: n,
      a: aAvg,
    );
    accelerations.add(acceleration);
    notifyListeners();
  }

  /// Stop getting accelerometer data.
  Future<void> stop() async {
    log.i("Stopping accelerometer updates");
    sub?.cancel();
    sub = null;
  }

  /// Reset the service.
  Future<void> reset() async {
    accelerations.clear();
    window.clear();
    sub?.cancel();
    sub = null;
    notifyListeners();
  }
}
