import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart' as mapbox;
import 'package:priobike/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:priobike/ride/services/position/mock.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

abstract class PositionSource {
  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled();

  /// Check the location permissions.
  Future<LocationPermission> checkPermission();

  /// Request the location permissions.
  Future<LocationPermission> requestPermission();

  /// Get the position stream of the device.
  Future<Stream<Position>> startPositioning({ required LocationSettings? locationSettings });

  /// Stop the geolocation.
  Future<void> stopPositioning();

  /// Open the location settings.
  Future<bool> openLocationSettings();
}

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
  @override Future<Stream<Position>> startPositioning({ required LocationSettings? locationSettings }) async 
    => Geolocator.getPositionStream(locationSettings: locationSettings);

  /// Stop the geolocation.
  @override Future<void> stopPositioning() async 
    => { /* Not supported by flutter geolocator? */ };

  /// Open the location settings.
  @override Future<bool> openLocationSettings() async
    => Geolocator.openLocationSettings();
}

class PositionService with ChangeNotifier {
  Logger log = Logger("PositionService");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The interface to the position source.
  /// See [PositionSource] for more information.
  PositionSource? positionSource;

  /// A subscription to the real position.
  StreamSubscription<Position>? positionSubscription;

  /// The recorded positions of the user.
  final positions = List<Position>.empty(growable: true);

  /// The current measured position (1 Hz).
  Position? lastPosition;

  /// An indicator if geolocation is active.
  bool isGeolocating = false;

  PositionService({this.positionSource});

  /// Reset the position service.
  Future<void> reset() async {
    await stopGeolocation();
    needsLayout = {};
    positionSource = null;
    positionSubscription = null;
    positions.clear();
    lastPosition = null;
  }

  /// Show a dialog if the location provider was denied.
  showLocationAccessDeniedDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("Einstellungen öffnen"),
      onPressed: () => positionSource?.openLocationSettings(),
    );
    AlertDialog alert = AlertDialog(
      title: const Text("Zugriff auf Standort verweigert."),
      content: const Text("Bitte erlauben Sie den Zugriff auf Ihren Standort in den Einstellungen."),
      actions: [ okButton ],
    );
    showDialog(context: context, builder: (BuildContext context) => alert);
  }

  Future<bool> requestGeolocatorPermission() async {
    if (positionSource == null) return false;

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await positionSource!.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled - don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await positionSource!.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await positionSource!.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again - this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  Future<void> startGeolocation({
    required BuildContext context, 
    required void Function(Position pos) onNewPosition,
  }) async {
    if (isGeolocating) return;
    isGeolocating = true;

    if (positionSource == null) {
      final settings = Provider.of<SettingsService>(context, listen: false);
      if (settings.positioning == Positioning.gnss) {
        positionSource = GNSSPositionSource();
        log.i("Using gnss positioning source.");
      } else if (settings.positioning == Positioning.follow18kmh) {
        final routing = Provider.of<RoutingService>(context, listen: false);
        positionSource = PathMockPositionSource(
          speed: 18 / 3.6,
          positions: routing.selectedRoute!.route.map((e) => mapbox.LatLng(e.lat, e.lon)).toList()
        );
        log.i("Using mocked path positioning source (18 km/h).");
      } else if (settings.positioning == Positioning.follow40kmh) {
        final routing = Provider.of<RoutingService>(context, listen: false);
        positionSource = PathMockPositionSource(
          speed: 40 / 3.6,
          positions: routing.selectedRoute!.route.map((e) => mapbox.LatLng(e.lat, e.lon)).toList()
        );
        log.i("Using mocked path positioning source (40 km/h).");
      } else if (settings.positioning == Positioning.recordedDresden) {
        positionSource = RecordedMockPositionSource.mockDresden;
        log.i("Using mocked positioning source for Dresden.");
      } else if (settings.positioning == Positioning.recordedHamburg) {
        positionSource = RecordedMockPositionSource.mockHamburg;
        log.i("Using mocked positioning source for Hamburg.");
      } else if (settings.positioning == Positioning.dresdenStatic1) {
        positionSource = StaticMockPositionSource(
          position: const mapbox.LatLng(51.030077, 13.729404), heading: 270
        );
        log.i("Using mocked position source for traffic light 1 in Dresden.");
      } else if (settings.positioning == Positioning.dresdenStatic2) {
        positionSource = StaticMockPositionSource(
          position: const mapbox.LatLng(51.030241, 13.728205), heading: 1
        );
        log.i("Using mocked position source for traffic light 2 in Dresden.");
      } else {
        throw Exception("Unknown position source.");
      }
    }

    final hasPermission = await requestGeolocatorPermission();
    if (!hasPermission) {
      Navigator.of(context).pop();
      showLocationAccessDeniedDialog(context);
      log.w('Permission to Geolocator denied');
      isGeolocating = false;
      return;
    }

    // Only use kCLLocationAccuracyBestForNavigation if the device is charging.
    // See: https://developer.apple.com/documentation/corelocation/kcllocationaccuracybestfornavigation
    final desiredAccuracy = await Battery().batteryState == BatteryState.charging
      ? LocationAccuracy.bestForNavigation // Requires additional energy for sensor fusion.
      : LocationAccuracy.best;
    
    var positionStream = await positionSource!.startPositioning(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy,
        distanceFilter: 0,
      ),
    );

    positionSubscription = positionStream.listen((Position position) {
      if (!isGeolocating) return;
      lastPosition = position;
      positions.add(position);
      onNewPosition(position);
      notifyListeners();
    });

    log.i('Geolocator started!');
  }

  Future<void> stopGeolocation() async {
    await positionSource?.stopPositioning();
    await positionSubscription?.cancel();
    log.i('Geolocator stopped!');
    isGeolocating = false;
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
