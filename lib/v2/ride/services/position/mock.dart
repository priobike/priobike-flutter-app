import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/ride/services/position/position.dart';

/// Unwrap a double from a json source safely.
double checkDouble(dynamic value) {
  if (value is String) {
    return double.parse(value);
  } else {
    return value.toDouble();
  }
}

const examplePosition = LatLng(53.564292, 9.902202);

const exampleHeading = 140.0;

/// A mocked position source in which the user never moves.
class StaticMockPositionSource extends PositionSource {
  /// The static position.
  final LatLng position;

  /// The static heading.
  final double heading;

  StaticMockPositionSource({this.position = examplePosition, this.heading = exampleHeading});

  /// Check if location services are enabled.
  /// With the mock client, this only returns true.
  @override Future<bool> isLocationServiceEnabled() async => true;

  /// Check the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override Future<LocationPermission> checkPermission() async => LocationPermission.always;

  /// Request the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override Future<LocationPermission> requestPermission() async => LocationPermission.always;

  /// Get the position stream of the device.
  /// With the mock client, this starts a stream of the mocked positions.
  @override Stream<Position> getPositionStream({ required LocationSettings? locationSettings }) {
    // Create a new stream, which we will later use to push positions.
    var streamController = StreamController<Position>();

    Timer.periodic(const Duration(seconds: 1), (t) {
      streamController.add(Position(
        latitude: position.latitude, 
        longitude: position.longitude, 
        altitude: 0,
        speed: 4, 
        heading: heading, // Not 0, since 0 indicates an error. 
        accuracy: 1, 
        speedAccuracy: 1, 
        timestamp: DateTime.now().toUtc(),
      ));
    });

    return streamController.stream;
  }

  /// Open the location settings.
  /// With the mock client, this does nothing and returns true.
  @override Future<bool> openLocationSettings() async => true;
}

class StaticMockPositionService extends PositionService {
  StaticMockPositionService({LatLng position = examplePosition, double heading = exampleHeading}) : super(
    positionSource: StaticMockPositionSource(position: position, heading: heading),
  );
}

class RecordedMockPositionSource extends PositionSource {
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
      positions.add(Position(
        latitude: checkDouble(json[i]['positionLat']),
        longitude: checkDouble(json[i]['positionLon']),
        altitude: 0.0,
        speed: checkDouble(json[i]['speed']),
        heading: checkDouble(json[i]['heading']),
        accuracy: checkDouble(json[i]['accuracy']), 
        speedAccuracy: 0.0, 
        timestamp: DateTime.fromMillisecondsSinceEpoch(json[i]['timeUnixMillis']),
      ));
    }
  }

  /// Check if location services are enabled.
  /// With the mock client, this only returns true.
  @override Future<bool> isLocationServiceEnabled() async => true;

  /// Check the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override Future<LocationPermission> checkPermission() async => LocationPermission.always;

  /// Request the location permissions.
  /// With the mock client, this does nothing and returns "always allowed".
  @override Future<LocationPermission> requestPermission() async => LocationPermission.always;

  /// Get the position stream of the device.
  /// With the mock client, this starts a stream of the mocked positions.
  @override Stream<Position> getPositionStream({ required LocationSettings? locationSettings }) {
    // Create a new stream, which we will later use to push positions.
    var streamController = StreamController<Position>();

    late DateTime startPositionTime;
    late DateTime startRealTime;

    Timer.periodic(const Duration(milliseconds: 100), (t) {
      // If we have finished, reset the index.
      if (index >= positions.length) {
        index = 0;
        return;
      }

      // If the index is 0, we need to set the reference times.
      if (index == 0) {
        startPositionTime = positions[index].timestamp!;
        startRealTime = DateTime.now();
      }

      // Compute the milliseconds between the current position and the reference position time.
      final elapsedPositionTime = positions[index].timestamp!.difference(startPositionTime).inMilliseconds;
      // Compute the milliseconds between the current real time and the reference real time.
      final elapsedRealTime = DateTime.now().difference(startRealTime).inMilliseconds;

      // Dispatch the position if the elapsed time is greater than or equal to the position time.
      if (elapsedRealTime >= elapsedPositionTime) {
        var p = positions[index];
        // Map the position to the current time.
        var pNow = Position(
          latitude: p.latitude, longitude: p.longitude, altitude: p.altitude,
          speed: p.speed, heading: p.heading, accuracy: p.accuracy, speedAccuracy: p.speedAccuracy, 
          timestamp: DateTime.now().toUtc(),
        );
        streamController.add(pNow);
        index++;
      }
    });

    return streamController.stream;
  }

  /// Open the location settings.
  /// With the mock client, this does nothing and returns true.
  @override Future<bool> openLocationSettings() async => true;
}

class RecordedMockPositionService extends PositionService {
  /// A mock position source for Dresden.
  static var mockDresden = RecordedMockPositionService("assets/tracks/dresden/philipp.json");

  /// A mock position source for Hamburg.
  static var mockHamburg = RecordedMockPositionService("assets/tracks/hamburg/thomas.json");

  RecordedMockPositionService(String path) : super(
    positionSource: RecordedMockPositionSource(path),
  );
}