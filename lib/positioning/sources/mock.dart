import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
// l is an alias to not clash with MapBox's dependency.
// We cannot use MapBox's LatLng since MapBox doesn't import Distance.
import 'package:latlong2/latlong.dart' as l;
import 'package:latlong2/latlong.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/sources/interface.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';

/// Unwrap a double from a json source safely.
double checkDouble(dynamic value) {
  if (value is String) {
    return double.parse(value);
  } else {
    return value.toDouble();
  }
}

/// A mocked position source in which the user never moves.
class StaticMockPositionSource extends PositionSource {
  /// The static position.
  final LatLng position;

  /// The static heading.
  final double heading;

  /// The calculation timer.
  Timer? timer;

  StaticMockPositionSource(this.position, this.heading);

  /// Check if location services are enabled.
  /// With the mock client, this only returns true.
  @override
  Future<bool> isLocationServicesEnabled() async => true;

  /// Check the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  /// Request the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  /// Get the position stream of the device.
  /// With the mock client, this starts a stream of the mocked positions.
  @override
  Future<Stream<Position>> startPositioning({required LocationSettings? locationSettings}) async {
    // Create a new stream, which we will later use to push positions.
    var streamController = StreamController<Position>();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        streamController.add(
          Position(
            latitude: position.latitude,
            longitude: position.longitude,
            altitude: 0,
            speed: 0,
            heading: heading, // Not 0, since 0 indicates an error.
            accuracy: 1,
            speedAccuracy: 1,
            timestamp: DateTime.now().toUtc(),
            headingAccuracy: 0,
            altitudeAccuracy: 0,
          ),
        );
      },
    );

    return streamController.stream;
  }

  /// Get one position of the device.
  /// With the mock client, this returns the mocked position.
  @override
  Future<Position> getPosition({required LocationAccuracy desiredAccuracy}) async {
    return Position(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: 0,
      speed: 0,
      heading: heading, // Not 0, since 0 indicates an error.
      accuracy: 1,
      speedAccuracy: 1,
      timestamp: DateTime.now().toUtc(),
      headingAccuracy: 0,
      altitudeAccuracy: 0,
    );
  }

  /// Open the location settings.
  /// With the mock client, this does nothing and returns true.
  @override
  Future<bool> openLocationSettings() async => true;

  /// Stop the geolocation.
  @override
  Future<void> stopPositioning() async => timer?.cancel();
}

class RecordedMockPositionSource extends PositionSource {
  /// A mock position source for Dresden.
  static var mockDresden = RecordedMockPositionSource("assets/tracks/dresden/philipp.json");

  /// A mock position source for Hamburg.
  static var mockHamburg = RecordedMockPositionSource("assets/tracks/hamburg/thomas.json");

  /// The calculation timer.
  Timer? timer;

  /// The mocked positions from the source.
  List<Position> positions = [];

  /// The index of the current position.
  int index = 0;

  RecordedMockPositionSource(String filepath) {
    load(filepath);
  }

  /// Load the file contents and parse the JSON.
  void load(String filepath) async {
    // Read all positions from the json file, for example 'assets/tracks/hamburg/track.json'.
    String filecontents = await rootBundle.loadString(filepath);
    List<dynamic> json = jsonDecode(filecontents);
    for (int i = 0; i < json.length; i++) {
      positions.add(
        Position(
          latitude: checkDouble(json[i]['positionLat']),
          longitude: checkDouble(json[i]['positionLon']),
          altitude: 0.0,
          speed: checkDouble(json[i]['speed']),
          heading: checkDouble(json[i]['heading']),
          accuracy: checkDouble(json[i]['accuracy']),
          speedAccuracy: 0.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(json[i]['timeUnixMillis']),
          headingAccuracy: 0.0,
          altitudeAccuracy: 0.0,
        ),
      );
    }
  }

  /// Check if location services are enabled.
  /// With the mock client, this only returns true.
  @override
  Future<bool> isLocationServicesEnabled() async => true;

  /// Check the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  /// Request the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  /// Get the position stream of the device.
  /// With the mock client, this starts a stream of the mocked positions.
  @override
  Future<Stream<Position>> startPositioning({required LocationSettings? locationSettings}) async {
    // Create a new stream, which we will later use to push positions.
    var streamController = StreamController<Position>();

    DateTime? startPositionTime;
    DateTime? startRealTime;

    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (t) {
        // If we have finished, reset the index.
        if (index >= positions.length) {
          index = 0;
          return;
        }

        // If the index is 0, we need to set the reference times.
        if (index == 0 || startPositionTime == null || startRealTime == null) {
          startPositionTime = positions[index].timestamp;
          startRealTime = DateTime.now();
        }

        // Compute the milliseconds between the current position and the reference position time.
        final elapsedPositionTime = positions[index].timestamp.difference(startPositionTime!).inMilliseconds;
        // Compute the milliseconds between the current real time and the reference real time.
        final elapsedRealTime = DateTime.now().difference(startRealTime!).inMilliseconds;

        // Dispatch the position if the elapsed time is greater than or equal to the position time.
        if (elapsedRealTime >= elapsedPositionTime) {
          var p = positions[index];
          // Map the position to the current time.
          var pNow = Position(
            latitude: p.latitude,
            longitude: p.longitude,
            altitude: p.altitude,
            speed: p.speed,
            heading: p.heading,
            accuracy: p.accuracy,
            speedAccuracy: p.speedAccuracy,
            timestamp: DateTime.now().toUtc(),
            headingAccuracy: 0,
            altitudeAccuracy: 0,
          );
          streamController.add(pNow);
          index++;
        }
      },
    );

    return streamController.stream;
  }

  /// Get one position of the device.
  /// With the mock client, this returns the mocked position.
  @override
  Future<Position> getPosition({required LocationAccuracy desiredAccuracy}) async {
    if (index >= positions.length) {
      index = 0;
    }
    return positions[index];
  }

  /// Open the location settings.
  /// With the mock client, this does nothing and returns true.
  @override
  Future<bool> openLocationSettings() async => true;

  /// Stop the geolocation.
  @override
  Future<void> stopPositioning() async => timer?.cancel();
}

/// A mock position service that simply follows the route path with a static speed.
class PathMockPositionSource extends PositionSource {
  /// The path (a list of coordinates) to follow.
  final List<LatLng> positions;

  /// The ideal speed with which the path should be followed.
  double idealSpeed;

  /// If the position source should pick the optimal speed automatically.
  bool autoSpeed;

  /// The calculation timer.
  Timer? timer;

  /// The last position.
  Position? lastPosition;

  PathMockPositionSource({required this.positions, this.idealSpeed = 18 / 3.6, this.autoSpeed = false});

  /// Check if location services are enabled.
  /// With the mock client, this only returns true.
  @override
  Future<bool> isLocationServicesEnabled() async => true;

  /// Check the location permissions.
  /// With the mock client, this still has to check for permission to display the custom puck.
  @override
  Future<LocationPermission> checkPermission() async => Geolocator.checkPermission();

  /// Request the location permissions.
  /// With the mock client, this still has to request for permission to display the custom puck.
  @override
  Future<LocationPermission> requestPermission() async => Geolocator.requestPermission();

  /// Get the position stream of the device.
  /// With the mock client, this starts a stream of the mocked positions.
  @override
  Future<Stream<Position>> startPositioning({required LocationSettings? locationSettings}) async {
    if (positions.length < 2) throw Exception();

    // Create a new stream, which we will later use to push positions.
    var streamController = StreamController<Position>();

    // Map the positions so that we can use them for distance calculations.
    final mappedPositions = positions.map((e) => l.LatLng(e.latitude, e.longitude)).toList();

    const vincenty = l.Distance();

    // Sum up the distances between the positions.
    final dists = <double>[];
    l.LatLng? prev;
    double? prevDist;
    for (l.LatLng p in mappedPositions) {
      if (prev == null && prevDist == null) {
        double dist = 0;
        dists.add(dist);
        prev = p;
        prevDist = dist;
      } else {
        double dist = prevDist! + vincenty.distance(prev!, p);
        dists.add(dist);
        prev = p;
        prevDist = dist;
      }
    }

    double distance = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      // Find the current segment
      l.LatLng? from;
      l.LatLng? to;
      double? distanceOnSegment;
      for (MapEntry<int, double> e in dists.asMap().entries.toList()) {
        if (e.value > distance) {
          // We can assume that e.key > 0 since distance = 0 > 0 at the start
          from = mappedPositions[e.key - 1];
          to = mappedPositions[e.key];
          final segmentLength = e.value - dists[e.key - 1];
          distanceOnSegment = segmentLength - (e.value - distance);
          break;
        }
      }

      if (from == null || to == null || distanceOnSegment == null) {
        // Finished, restart.
        distance = 0;
        lastPosition = null;
        return;
      }

      var chosenSpeedOrAutoSpeed = idealSpeed;
      if (autoSpeed) chosenSpeedOrAutoSpeed = calcAutoSpeed(lastPosition?.speed) ?? idealSpeed;

      final random = Random(); // Simulate GPS inaccuracy.
      final bearing = vincenty.bearing(from, to) - 2.5 + 5 * random.nextDouble(); // [-180°, 180°]
      final currentLocation = vincenty.offset(from, distanceOnSegment - 1 + 2 * random.nextDouble(), bearing);
      final heading = bearing > 0 ? bearing : 360 + bearing;

      lastPosition = Position(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        altitude: 0,
        speed: chosenSpeedOrAutoSpeed,
        heading: heading, // Not 0, since 0 indicates an error.
        accuracy: 1,
        speedAccuracy: 1,
        timestamp: DateTime.now().toUtc(),
        headingAccuracy: 0,
        altitudeAccuracy: 0,
      );
      streamController.add(lastPosition!);

      distance += 1 * chosenSpeedOrAutoSpeed;
    });

    return streamController.stream;
  }

  /// Simulate a cyclist that selects an optimal speed based on the traffic light phases.
  double? calcAutoSpeed(double? prevSpeed) {
    final ride = getIt<Ride>();
    final dist = ride.calcDistanceToNextSG;
    if (dist == null) return null;
    final phasesFromNow = ride.predictionProvider?.recommendation?.calcPhasesFromNow;
    if (phasesFromNow == null || phasesFromNow.isEmpty) return null;

    var minSpeedAdjustment = double.infinity;
    var bestSpeed = idealSpeed;

    // Find the centers of the phases.
    var phaseStarts = List<int>.from([]);
    var phaseEnds = List<int>.from([]);
    var inGreen = false;
    for (int i = 0; i < phasesFromNow.length; i++) {
      final phase = phasesFromNow[i];
      if (phase == Phase.green && !inGreen) {
        phaseStarts.add(i);
        inGreen = true;
      } else if (phase != Phase.green && inGreen) {
        phaseEnds.add(i);
        inGreen = false;
      }
    }
    if (inGreen) phaseEnds.add(phasesFromNow.length);

    if (phaseStarts.length != phaseEnds.length) return null;
    if (phaseStarts.isEmpty || phaseEnds.isEmpty) return null;
    for (int i = 0; i < phaseStarts.length; i++) {
      var phaseStart = phaseStarts[i];
      final phaseCenter = (phaseStarts[i] + phaseEnds[i]) ~/ 2;
      var phaseEnd = phaseEnds[i];
      // Add a safety margin to the start and end.
      phaseStart = min(phaseStart + 2, phaseCenter);
      phaseEnd = max(phaseEnd - 2, phaseCenter);
      // Check if the ideal speed is inside this phase.
      final secondOfArrivalWithIdealSpeed = dist / idealSpeed;
      if (secondOfArrivalWithIdealSpeed >= phaseStart && secondOfArrivalWithIdealSpeed <= phaseEnd) {
        // The ideal speed is inside this phase.
        bestSpeed = idealSpeed;
        break;
      }
      for (int t in [phaseStart, phaseCenter, phaseEnd]) {
        if (t == 0) continue;
        final targetSpeed = dist / t;
        final speedAdjustment = (targetSpeed - idealSpeed).abs();
        if (speedAdjustment < minSpeedAdjustment && targetSpeed > 0) {
          minSpeedAdjustment = speedAdjustment;
          bestSpeed = targetSpeed;
        }
      }
    }

    // Bilinear interpolation between the previous speed and the best speed.
    if (prevSpeed != null) {
      const alpha = 0.25;
      bestSpeed = alpha * bestSpeed + (1 - alpha) * prevSpeed;
    }
    return bestSpeed;
  }

  /// Get one position of the device.
  /// With the mock client, this returns the mocked position.
  @override
  Future<Position> getPosition({required LocationAccuracy desiredAccuracy}) async {
    if (lastPosition == null) {
      // Get the first position.
      final firstPosition = positions.first;
      return Position(
        latitude: firstPosition.latitude,
        longitude: firstPosition.longitude,
        altitude: 0,
        speed: 0,
        heading: 0,
        accuracy: 1,
        speedAccuracy: 1,
        timestamp: DateTime.now().toUtc(),
        headingAccuracy: 0,
        altitudeAccuracy: 0,
      );
    }
    return lastPosition!;
  }

  /// Open the location settings.
  /// With the mock client, this does nothing and returns true.
  @override
  Future<bool> openLocationSettings() async => true;

  /// Stop the geolocation.
  @override
  Future<void> stopPositioning() async => timer?.cancel();
}

/// A mock position source that drives in a straight line.
/// The speed is a sine wave between 0 and 50 km/h.
class StraightLineMockPositionSource extends PositionSource {
  static const vincenty = Distance(roundResult: false);

  // The calculation timer.
  Timer? timer;

  StraightLineMockPositionSource();

  /// Check if location services are enabled.
  /// With the mock client, this only returns true.
  @override
  Future<bool> isLocationServicesEnabled() async => true;

  /// Check the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  /// Request the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  /// Get the position stream of the device.
  /// With the mock client, this starts a stream of the mocked positions.
  @override
  Future<Stream<Position>> startPositioning({required LocationSettings? locationSettings}) async {
    // Create a new stream, which we will later use to push positions.
    final streamController = StreamController<Position>();

    var currLatLng = const l.LatLng(53.550518, 9.971212);
    const heading = 90.0;

    timer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      // Speed is set based on a sine wave between 0 and 50 km/h.
      final speed = 50 * sin(DateTime.now().millisecondsSinceEpoch / 1000 / 10) + 50;
      final dist = speed / 3.6;
      final newLatLng = vincenty.offset(currLatLng, dist, heading);
      currLatLng = newLatLng;

      streamController.add(
        Position(
          latitude: currLatLng.latitude,
          longitude: currLatLng.longitude,
          altitude: 0,
          speed: speed,
          heading: heading, // Not 0, since 0 indicates an error.
          accuracy: 1,
          speedAccuracy: 1,
          timestamp: DateTime.now().toUtc(),
          headingAccuracy: 1,
          altitudeAccuracy: 1,
        ),
      );
    });

    return streamController.stream;
  }

  /// Get one position of the device.
  /// With the mock client, this returns the mocked position.
  @override
  Future<Position> getPosition({required LocationAccuracy desiredAccuracy}) async {
    return Position(
      latitude: 51.0,
      longitude: 13.0,
      altitude: 0,
      speed: 0,
      heading: 0, // Not 0, since 0 indicates an error.
      accuracy: 1,
      speedAccuracy: 1,
      timestamp: DateTime.now().toUtc(),
      headingAccuracy: 0,
      altitudeAccuracy: 0,
    );
  }

  /// Open the location settings.
  /// With the mock client, this does nothing and returns true.
  @override
  Future<bool> openLocationSettings() async => true;

  /// Stop the geolocation.
  @override
  Future<void> stopPositioning() async => timer?.cancel();
}
