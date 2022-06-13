import 'package:geolocator/geolocator.dart';

import 'interface.dart';

class GNSSPositionSource extends PositionSource {
  /// Check if location services are enabled.
  @override Future<bool> isLocationServiceEnabled() async
    => Geolocator.isLocationServiceEnabled();

  /// Check the location permissions.
  @override Future<LocationPermission> checkPermission() async 
    => Geolocator.checkPermission();

  /// Request the location permissions.
  @override Future<LocationPermission> requestPermission() async 
    => Geolocator.requestPermission();

  /// Get the position stream of the device.
  @override Stream<Position> getPositionStream({ required LocationSettings? locationSettings }) 
    => Geolocator.getPositionStream(locationSettings: locationSettings);

  /// Open the location settings.
  @override Future<bool> openLocationSettings() async
    => Geolocator.openLocationSettings();
}