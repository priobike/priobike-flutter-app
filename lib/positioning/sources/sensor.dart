import 'dart:async';

import 'package:geolocator/geolocator.dart';
// l is an alias to not clash with MapBox's dependency.
// We cannot use MapBox's LatLng since MapBox doesn't import Distance.
import 'package:latlong2/latlong.dart' as l;
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/sources/interface.dart';

class SpeedSensorPositioningSource extends PositionSource {
  final log = Logger("SpeedSensorPositioningSource");

  /// The path (a list of coordinates) to follow.
  final List<LatLng> positions;

  /// The static speed with which the path should be followed.
  double speed;

  /// The last position.
  Position? lastPosition;

  /// The stream we use to push positions.
  StreamController<Position>? streamController;

  /// The current distance on the path.
  double? distance;

  /// The distances between the positions.
  List<double>? dists;

  /// The mapped positions.
  List<LatLng>? mappedPositions;

  final vincenty = const l.Distance();

  SpeedSensorPositioningSource({required this.positions, this.speed = 0});

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
    if (streamController != null) {
      log.i("Stream already initialized.");
      return streamController!.stream;
    }

    if (positions.length < 2) throw Exception();

    // Create a new stream, which we will later use to push positions.
    streamController = StreamController<Position>();

    // Map the positions so that we can use them for distance calculations.
    mappedPositions = positions.map((e) => l.LatLng(e.latitude, e.longitude)).toList();

    // Sum up the distances between the positions.
    dists = <double>[];
    l.LatLng? prev;
    double? prevDist;
    for (l.LatLng p in mappedPositions!) {
      if (prev == null && prevDist == null) {
        double dist = 0;
        dists!.add(dist);
        prev = p;
        prevDist = dist;
      } else {
        double dist = prevDist! + vincenty.distance(prev!, p);
        dists!.add(dist);
        prev = p;
        prevDist = dist;
      }
    }

    distance = 0;

    return streamController!.stream;
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
        speed: speed,
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

  Future<void> updateSpeed() async {
    if (streamController == null) return;
    if (distance == null) return;
    if (dists == null) return;
    if (mappedPositions == null) return;

    // Find the current segment
    l.LatLng? from;
    l.LatLng? to;
    double? distanceOnSegment;
    for (MapEntry<int, double> e in dists!.asMap().entries.toList()) {
      if (e.value > distance!) {
        // We can assume that e.key > 0 since distance = 0 > 0 at the start
        from = mappedPositions![e.key - 1];
        to = mappedPositions![e.key];
        final segmentLength = e.value - dists![e.key - 1];
        distanceOnSegment = segmentLength - (e.value - distance!);
        break;
      }
    }

    if (from == null || to == null || distanceOnSegment == null) {
      // Finished, restart.
      distance = 0;
      lastPosition = null;
      return;
    }

    final double bearing;
    final LatLng currentLocation;

    // Don't use random values in simulator mode.
    bearing = vincenty.bearing(from, to);
    currentLocation = vincenty.offset(from, distanceOnSegment, bearing);
    final heading = bearing > 0 ? bearing : 360 + bearing;

    lastPosition = Position(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
      altitude: 0,
      speed: speed,
      heading: heading, // Not 0, since 0 indicates an error.
      accuracy: 1,
      speedAccuracy: 1,
      timestamp: DateTime.now().toUtc(),
      headingAccuracy: 0,
      altitudeAccuracy: 0,
    );
    streamController!.add(lastPosition!);

    distance = distance! + 1 * speed;
  }

  /// Stop the geolocation.
  @override
  Future<void> stopPositioning() async {
    streamController?.close();
    streamController = null;
    distance = null;
    dists = null;
    mappedPositions = null;
  }
}
