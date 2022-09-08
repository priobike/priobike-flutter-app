

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/snapping.dart';
import 'package:provider/provider.dart';

class PositionEstimatorService with ChangeNotifier {
  /// The refresh rate that is used to update the position.
  static int refreshRateHz = 5;

  /// The distance in meters at which the position will be clamped to the route.
  static double clampDistance = 25;

  /// A log for this service.
  final Logger log = Logger("PositionEstimatorService");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The estimator timer.
  Timer? timer;

  /// The current estimated position (> 1Hz).
  Position? estimatedPosition;

  PositionEstimatorService() { log.i("PositionEstimatorService started."); }

  /// Start estimating the position.
  Future<void> startEstimating(BuildContext context) async {
    // Start the estimator.
    timer = Timer.periodic(Duration(milliseconds: (1000 / refreshRateHz).round()), (Timer timer) {
      final positionService = Provider.of<PositionService>(context, listen: false);
      final snappingService = Provider.of<SnappingService>(context, listen: false);
      if (positionService.lastPosition == null) return;

      // Use the snapped position and heading if it is less than <x>m away from the route.
      final useSnappedPosition = 
        snappingService.snappedPosition != null && 
        snappingService.snappedHeading != null &&
        snappingService.distance != null && 
        snappingService.distance! < clampDistance;
      
      estimatedPosition = extrapolate(Position(
        latitude: useSnappedPosition 
          ? snappingService.snappedPosition!.latitude 
          : positionService.lastPosition!.latitude,
        longitude: useSnappedPosition 
          ? snappingService.snappedPosition!.longitude 
          : positionService.lastPosition!.longitude,
        heading: useSnappedPosition 
          ? snappingService.snappedHeading! 
          : positionService.lastPosition!.heading,
        altitude: positionService.lastPosition!.altitude,
        timestamp: positionService.lastPosition!.timestamp,
        accuracy: positionService.lastPosition!.accuracy,
        speed: positionService.lastPosition!.speed,
        speedAccuracy: positionService.lastPosition!.speedAccuracy,
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

    // If we have an active route and we are less than <x> meters from the route,
    // we can snap the estimated position to the route.
    
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