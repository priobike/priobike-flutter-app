import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'gnss.dart';
import 'mock.dart';

abstract class PositionSource {
  /// The position source that is used by the app.
  static var main = mockDresden;

  /// The actual implementation of the source.
  static var real = GNSSPositionSource();

  /// A mock position source for Dresden.
  static var mockDresden = MockPositionSource("assets/tracks/dresden/philipp.json");

  /// A mock position source for Hamburg.
  static var mockHamburg = MockPositionSource("assets/tracks/hamburg/thomas.json");

  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled();

  /// Check the location permissions.
  Future<LocationPermission> checkPermission();

  /// Request the location permissions.
  Future<LocationPermission> requestPermission();

  /// Get the position stream of the device.
  Stream<Position> getPositionStream({ required LocationSettings? locationSettings });

  /// Open the location settings.
  Future<bool> openLocationSettings();
}