import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' hide LocationAccuracy;

abstract class PositionSource {
  /// Check if location services are enabled.
  Future<bool> isLocationServicesEnabled();

  /// Check the location permissions.
  Future<LocationPermission> checkPermission();

  /// Request the location permissions.
  Future<LocationPermission> requestPermission();

  /// Get the position stream of the device.
  Future<Stream<Position>> startPositioning({required LocationSettings? locationSettings});

  /// Get one position of the device.
  Future<Position> getPosition({required LocationAccuracy desiredAccuracy});

  /// Stop the geolocation.
  Future<void> stopPositioning();

  /// Open the location settings.
  Future<bool> openLocationSettings();
}
