import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:priobike/positioning/sources/interface.dart';

class GNSSPositionSource extends PositionSource {
  /// Check if location services are enabled.
  @override
  Future<bool> isLocationServicesEnabled() async =>
      Geolocator.isLocationServiceEnabled();

  /// Check the location permissions.
  @override
  Future<LocationPermission> checkPermission() async =>
      Geolocator.checkPermission();

  /// Request the location permissions.
  @override
  Future<LocationPermission> requestPermission() async =>
      Geolocator.requestPermission();

  /// Get the position stream of the device.
  @override
  Future<Stream<Position>> startPositioning(
      {required LocationSettings? locationSettings}) async {
    Location location = Location();
    // Set time interval to 1000.
    location.changeSettings(interval: 1000);

    return location.onLocationChanged.map((currentLocation) {
      return Position(
          longitude: currentLocation.longitude ?? -1,
          latitude: currentLocation.latitude ?? -1,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              (currentLocation.time ?? 0).toInt()),
          accuracy: currentLocation.accuracy ?? -1,
          altitude: currentLocation.altitude ?? -1,
          heading: currentLocation.heading ?? -1,
          speed: currentLocation.speed ?? -1,
          speedAccuracy: currentLocation.speedAccuracy ?? -1);
    });
  }

  /// Get one position of the device.
  @override
  Future<Position> getPosition(
          {required LocationAccuracy desiredAccuracy}) async =>
      Geolocator.getCurrentPosition(desiredAccuracy: desiredAccuracy);

  /// Stop the geolocation.
  @override
  Future<void> stopPositioning() async => {
        /* Not supported by flutter geolocator? */
      };

  /// Open the location settings.
  @override
  Future<bool> openLocationSettings() async =>
      Geolocator.openLocationSettings();
}
