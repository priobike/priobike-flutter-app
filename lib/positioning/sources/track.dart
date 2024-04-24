import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:priobike/positioning/sources/interface.dart';

/// Unwrap a double from a json source safely.
double checkDouble(dynamic value) {
  if (value is String) {
    return double.parse(value);
  } else {
    return value.toDouble();
  }
}

class TrackPositionSource extends PositionSource {
  /// A mock position source for Hamburg.
  static var mockHamburg = TrackPositionSource("assets/tracks/hamburg/users/track.json");

  /// The calculation timer.
  Timer? timer;

  /// The mocked positions from the source.
  List<Position> positions = [];

  /// The index of the current position.
  int index = 0;

  TrackPositionSource(String filepath) {
    load(filepath);
  }

  /// Load the file contents and parse it.
  void load(String filepath) async {
    String filecontents = await rootBundle.loadString(filepath);
    dynamic json = jsonDecode(filecontents);
    final gpsCSV = json["gpsCSV"];
    final lines = gpsCSV.split("\n");

    double? initTimestamp;

    for (int i = 1; i < lines.length; i++) {
      final columns = lines[i].split(",");
      if (initTimestamp == null) {
        initTimestamp = checkDouble(columns[0]);
        continue;
      }
      // Skip the first 100 seconds.
      if (checkDouble(columns[0]) < initTimestamp + (0 * 1000)) continue;
      final timestamp = columns[0];
      final lon = columns[1];
      final lat = columns[2];
      final speed = columns[3];
      final accuracy = columns[4];
      positions.add(
        Position(
          latitude: checkDouble(lat),
          longitude: checkDouble(lon),
          altitude: 0.0,
          speed: checkDouble(speed),
          heading: 0.0,
          accuracy: checkDouble(accuracy),
          speedAccuracy: 0.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)),
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
