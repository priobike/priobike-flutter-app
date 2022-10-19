import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart' as mapbox;
import 'package:priobike/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:priobike/positioning/sources/interface.dart';
import 'package:priobike/positioning/sources/gnss.dart';
import 'package:priobike/positioning/sources/mock.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class Positioning with ChangeNotifier {
  final log = Logger("Positioning");

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

  Positioning({this.positionSource});

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
    serviceEnabled = await positionSource!.isLocationServicesEnabled();
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

  /// Ensure that the position source is initialized.
  Future<void> initializePositionSource(BuildContext context) async {
    final settings = Provider.of<Settings>(context, listen: false);
    if (settings.positioningMode == PositioningMode.gnss) {
      positionSource = GNSSPositionSource();
      log.i("Using gnss positioning source.");
    } else if (settings.positioningMode == PositioningMode.follow18kmh) {
      final routing = Provider.of<Routing>(context, listen: false);
      final positions = routing.selectedRoute?.route // Fallback to center location of city.
        .map((e) => mapbox.LatLng(e.lat, e.lon)).toList() ?? [settings.backend.center];
      positionSource = PathMockPositionSource(speed: 18 / 3.6, positions: positions);
      log.i("Using mocked path positioning source (18 km/h).");
    } else if (settings.positioningMode == PositioningMode.follow40kmh) {
      final routing = Provider.of<Routing>(context, listen: false);
      final positions = routing.selectedRoute?.route // Fallback to center location of city.
        .map((e) => mapbox.LatLng(e.lat, e.lon)).toList() ?? [settings.backend.center];
      positionSource = PathMockPositionSource(speed: 40 / 3.6, positions: positions);
      log.i("Using mocked path positioning source (40 km/h).");
    } else if (settings.positioningMode == PositioningMode.recordedDresden) {
      positionSource = RecordedMockPositionSource.mockDresden;
      log.i("Using mocked positioning source for Dresden.");
    } else if (settings.positioningMode == PositioningMode.recordedHamburg) {
      positionSource = RecordedMockPositionSource.mockHamburg;
      log.i("Using mocked positioning source for Hamburg.");
    } else if (settings.positioningMode == PositioningMode.dresdenStatic1) {
      positionSource = StaticMockPositionSource(
        position: const mapbox.LatLng(51.030077, 13.729404), heading: 270
      );
      log.i("Using mocked position source for traffic light 1 in Dresden.");
    } else if (settings.positioningMode == PositioningMode.dresdenStatic2) {
      positionSource = StaticMockPositionSource(
        position: const mapbox.LatLng(51.030241, 13.728205), heading: 1
      );
      log.i("Using mocked position source for traffic light 2 in Dresden.");
    } else {
      throw Exception("Unknown position source.");
    }
  }

  /// Request a single location update. This will not be recorded.
  Future<void> requestSingleLocation(BuildContext context) async {
    await initializePositionSource(context);

    final hasPermission = await requestGeolocatorPermission();
    if (!hasPermission) {
      Navigator.of(context).pop();
      showLocationAccessDeniedDialog(context);
      log.w('Permission to Geolocator denied');
      isGeolocating = false;
      return;
    }

    lastPosition = await positionSource!.getPosition(desiredAccuracy: LocationAccuracy.high);
    notifyListeners();
  }

  Future<void> startGeolocation({
    required BuildContext context, 
    required void Function(Position pos) onNewPosition,
  }) async {
    if (isGeolocating) return;
    isGeolocating = true;

    await initializePositionSource(context);

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
    positionSource = null;
    log.i('Geolocator stopped!');
    isGeolocating = false;
  }

  /// Set the current speed to a selected value.
  /// This is a debug feature and only applies to positioning 
  /// sources that support the setting of the current speed.
  Future<void> setDebugSpeed(double speed) async {
    if (speed < 0) return;
    // Currently, this is only supported by the PathMockPositionSource.
    if (positionSource is PathMockPositionSource) {
      (positionSource as PathMockPositionSource).speed = speed;
    }
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
