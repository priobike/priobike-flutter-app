

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:provider/provider.dart';

class PositionEstimator with ChangeNotifier {
  /// The refresh rate that is used to update the position.
  /// Note that this rate should not be too high, to save energy.
  static int refreshRateHz = 5;

  /// The distance in meters at which the position will be clamped to the route.
  static double clampDistance = 25;

  /// A log for this service.
  final log = Logger("PositionEstimator");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The estimator timer.
  Timer? timer;

  /// The current estimated position (> 1Hz).
  Position? estimatedPosition;

  PositionEstimator() { log.i("PositionEstimator started."); }

  /// Start estimating the position.
  Future<void> startEstimating(BuildContext context) async {
    // Start the estimator.
    timer = Timer.periodic(Duration(milliseconds: (1000 / refreshRateHz).round()), (Timer timer) {
      final positioning = Provider.of<Positioning>(context, listen: false);
      final snapping = Provider.of<Snapping>(context, listen: false);
      if (positioning.lastPosition == null) return;

      // Use the snapped position and heading if it is less than <x>m away from the route.
      final useSnappedPosition = 
        snapping.snappedPosition != null && 
        snapping.snappedHeading != null &&
        snapping.distance != null && 
        snapping.distance! < clampDistance;
      
      estimatedPosition = extrapolate(Position(
        latitude: useSnappedPosition 
          ? snapping.snappedPosition!.latitude 
          : positioning.lastPosition!.latitude,
        longitude: useSnappedPosition 
          ? snapping.snappedPosition!.longitude 
          : positioning.lastPosition!.longitude,
        heading: useSnappedPosition 
          ? snapping.snappedHeading! 
          : positioning.lastPosition!.heading,
        altitude: positioning.lastPosition!.altitude,
        timestamp: positioning.lastPosition!.timestamp,
        accuracy: positioning.lastPosition!.accuracy,
        speed: positioning.lastPosition!.speed,
        speedAccuracy: positioning.lastPosition!.speedAccuracy,
      ));
      notifyListeners();
    });
  }

  /// Extrapolate the position.
  Position extrapolate(Position lastPosition) {
    // Calculate the elapsed time since the last position.
    final last = lastPosition.timestamp?.toUtc();
    if (last == null) return lastPosition;
    final elapsed = DateTime.now().toUtc().difference(last).inMilliseconds;
    if (elapsed < 0) return lastPosition;

    // Offset the position by the traveled distance and bearing
    if (lastPosition.heading < 0 || lastPosition.heading > 360) return lastPosition;
    final newLatLng = const Distance().offset(
      LatLng(lastPosition.latitude, lastPosition.longitude), 
      lastPosition.speed * (elapsed / 1000), 
      lastPosition.heading
    );
    
    return Position(
      latitude: newLatLng.latitude,
      longitude: newLatLng.longitude,
      altitude: lastPosition.altitude,
      timestamp: DateTime.now().toUtc(),
      accuracy: lastPosition.accuracy,
      speed: lastPosition.speed,
      heading: lastPosition.heading,
      speedAccuracy: lastPosition.speedAccuracy,
    );
  }

  /// Stop estimating the position.
  Future<void> stopEstimating() async {
    timer?.cancel();
  }

  /// Reset the position estimator.
  Future<void> reset() async {
    await stopEstimating();
    needsLayout = {};
    timer = null;
    estimatedPosition = null;
    notifyListeners();
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}