import 'package:geolocator/geolocator.dart';
import 'package:priobike/positioning/sources/interface.dart';

class GNSSPositionSource extends PositionSource {
  /// Check if location services are enabled.
  @override Future<bool> isLocationServicesEnabled() async
    => Geolocator.isLocationServiceEnabled();

  /// Check the location permissions.
  @override Future<LocationPermission> checkPermission() async 
    => Geolocator.checkPermission();

  /// Request the location permissions.
  @override Future<LocationPermission> requestPermission() async 
    => Geolocator.requestPermission();

  /// Get the position stream of the device.
  @override Future<Stream<Position>> startPositioning({ required LocationSettings? locationSettings }) async 
    => Geolocator.getPositionStream(locationSettings: locationSettings);

  /// Get one position of the device.
  @override Future<Position> getPosition({ required LocationAccuracy desiredAccuracy }) async 
    => Geolocator.getCurrentPosition(desiredAccuracy: desiredAccuracy);

  /// Stop the geolocation.
  @override Future<void> stopPositioning() async 
    => { /* Not supported by flutter geolocator? */ };

  /// Open the location settings.
  @override Future<bool> openLocationSettings() async
    => Geolocator.openLocationSettings();
}