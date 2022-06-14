

import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class PositionExtrapolator {
  /// The refresh rate that is used to update the position.
  static num refreshRateHz = 25;

  /// The last known position.
  Position? lastPosition;

  /// Create a position stream.
  Stream<Position> startEstimating() {
    // Create a new stream, which we will later use to push positions.
    var streamController = StreamController<Position>();

    // Start the stream.
    Timer.periodic(Duration(milliseconds: (1000 / refreshRateHz).round()), (Timer timer) {
      if (lastPosition == null) return;
      var extrapolatedPosition = extrapolate(lastPosition!);
      if (extrapolatedPosition == null) return;
      streamController.add(extrapolatedPosition);
    });

    return streamController.stream;
  } 

  /// Extrapolate the position.
  Position? extrapolate(Position lastPosition) {
    // Calculate the elapsed time since the last position.
    final last = lastPosition.timestamp?.toUtc();
    if (last == null) return null;
    final elapsed = DateTime.now().toUtc().difference(last).inMilliseconds;
    if (elapsed < 0) return null;

    // Offset the position by the traveled distance and bearing
    if (lastPosition.heading < 0 || lastPosition.heading > 360) return null;
    // Unfortunately, if the heading is 0.0, we need to assume that 
    // the device has no support for heading. In the future, we should
    // fallback to calculating the heading ourselves (using last 2 positions).
    if (lastPosition.heading == 0.0) return null;
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
}