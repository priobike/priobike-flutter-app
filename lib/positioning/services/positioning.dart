import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:priobike/positioning/sources/gnss.dart';
import 'package:priobike/positioning/sources/interface.dart';
import 'package:priobike/positioning/sources/mock.dart';
import 'package:priobike/positioning/sources/sensor.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart' hide Simulator;
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/services/settings.dart';

class Positioning with ChangeNotifier {
  final log = Logger("Positioning");

  /// The interface to the position source.
  /// See [PositionSource] for more information.
  PositionSource? positionSource;

  /// A subscription to the real position.
  StreamSubscription<Position>? positionSubscription;

  /// The recorded positions of the user.
  final positions = List<Position>.empty(growable: true);

  /// The current measured position (1 Hz).
  Position? lastPosition;

  /// The current route, for snapping.
  Route? route;

  /// The recorded snapped positions of the user.
  final snaps = List<Snap>.empty(growable: true);

  /// The current position snapped to the route.
  Snap? snap;

  /// An indicator if geolocation is active.
  bool isGeolocating = false;

  /// An indicator whether we already have shown the system dialog for location permission.
  bool _locationPermissionDialogShown = false;

  Positioning({this.positionSource});

  /// Reset the position service.
  Future<void> reset() async {
    await stopGeolocation();
    positionSource = null;
    positionSubscription = null;
    positions.clear();
    snaps.clear();
    lastPosition = null;
    route = null;
    snap = null;
  }

  /// Notify the positioning that a new route was loaded.
  Future<void> selectRoute(Route? route) async {
    this.route = route;
    snap = null;
    notifyListeners();
  }

  /// Set whether the location permission dialog was shown.
  void setLocationPermissionDialogShown() {
    _locationPermissionDialogShown = true;
  }

  /// Check whether the geolocator permission is granted.
  Future<LocationPermission?> checkGeolocatorPermission() async {
    if (positionSource == null) return null;

    bool serviceEnabled;

    // Test if location services are enabled.
    serviceEnabled = await positionSource!.isLocationServicesEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled - don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return null;
    }

    return await positionSource!.checkPermission();
  }

  /// Request the geolocator permission
  /// (only if it did not get denied permanently and if it did not get requested before).
  Future<bool> requestGeolocatorPermission() async {
    LocationPermission? permission = await checkGeolocatorPermission();
    if (permission == null) {
      return false;
    }

    if (permission == LocationPermission.denied) {
      // Only show the dialog once per session. If the user wants to update it during a session, they can do so in the settings.
      // We also provide hints for that. But since we have to show an extra explanation dialog before the system dialog,
      // we only show the system dialog once, to make sure that we don't show too many dialogs.
      if (_locationPermissionDialogShown) {
        return false;
      }
      permission = await positionSource!.requestPermission();
      _locationPermissionDialogShown = true;
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  /// Ensure that the position source is initialized.
  Future<void> initializePositionSource() async {
    final settings = getIt<Settings>();
    if (settings.positioningMode == PositioningMode.gnss) {
      positionSource = GNSSPositionSource();
      log.i("Using gnss positioning source.");
    } else if (settings.positioningMode == PositioningMode.follow18kmh) {
      final routing = getIt<Routing>();
      final positions = routing.selectedRoute?.route // Fallback to center location of city.
              .map((e) => LatLng(e.lat, e.lon))
              .toList() ??
          [settings.backend.center];
      positionSource = PathMockPositionSource(idealSpeed: 18 / 3.6, positions: positions);
      log.i("Using mocked path positioning source (18 km/h).");
    } else if (settings.positioningMode == PositioningMode.follow40kmh) {
      final routing = getIt<Routing>();
      final positions = routing.selectedRoute?.route // Fallback to center location of city.
              .map((e) => LatLng(e.lat, e.lon))
              .toList() ??
          [settings.backend.center];
      positionSource = PathMockPositionSource(idealSpeed: 40 / 3.6, positions: positions);
      log.i("Using mocked path positioning source (40 km/h).");
    } else if (settings.positioningMode == PositioningMode.autospeed) {
      final routing = getIt<Routing>();
      final positions = routing.selectedRoute?.route // Fallback to center location of city.
              .map((e) => LatLng(e.lat, e.lon))
              .toList() ??
          [settings.backend.center];
      positionSource = PathMockPositionSource(idealSpeed: 18 / 3.6, positions: positions, autoSpeed: true);
      log.i("Using mocked auto speed positioning source.");
    } else if (settings.positioningMode == PositioningMode.sensor) {
      final routing = getIt<Routing>();
      final positions = routing.selectedRoute?.route // Fallback to center location of city.
              .map((e) => LatLng(e.lat, e.lon))
              .toList() ??
          [settings.backend.center];
      positionSource = SpeedSensorPositioningSource(positions: positions);
      log.i("Using speed sensor positioning source.");
    } else if (settings.positioningMode == PositioningMode.recordedDresden) {
      positionSource = RecordedMockPositionSource.mockDresden;
      log.i("Using mocked positioning source for Dresden.");
    } else if (settings.positioningMode == PositioningMode.recordedHamburg) {
      positionSource = RecordedMockPositionSource.mockHamburg;
      log.i("Using mocked positioning source for Hamburg.");
    } else if (settings.positioningMode == PositioningMode.hamburgStatic1) {
      positionSource = StaticMockPositionSource(const LatLng(53.5529283, 10.004511), 270);
      log.i("Using mocked position source for Hamburg main station.");
    } else if (settings.positioningMode == PositioningMode.dresdenStatic1) {
      positionSource = StaticMockPositionSource(const LatLng(51.030077, 13.729404), 270);
      log.i("Using mocked position source for traffic light 1 in Dresden.");
    } else if (settings.positioningMode == PositioningMode.dresdenStatic2) {
      positionSource = StaticMockPositionSource(const LatLng(51.030241, 13.728205), 1);
      log.i("Using mocked position source for traffic light 2 in Dresden.");
    } else if (settings.positioningMode == PositioningMode.straightLine) {
      positionSource = StraightLineMockPositionSource();
      log.i("Using mocked straight line position source.");
    } else {
      throw Exception("Unknown position source.");
    }
  }

  /// Request a single location update. This will not be recorded.
  Future<void> requestSingleLocation({required void Function() onNoPermission}) async {
    await initializePositionSource();

    final hasPermission = await checkGeolocatorPermission();
    if (hasPermission == null ||
        hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      onNoPermission();
      log.w('Permission to Geolocator denied');
      isGeolocating = false;
      return;
    }

    lastPosition = await positionSource!.getPosition(desiredAccuracy: LocationAccuracy.high);
    notifyListeners();
  }

  Future<void> startGeolocation({
    required void Function() onNoPermission,
    required void Function() onNewPosition,
  }) async {
    if (isGeolocating) return;
    isGeolocating = true;

    await initializePositionSource();

    final hasPermission = await checkGeolocatorPermission();
    if (hasPermission == null ||
        hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      onNoPermission();
      log.w('Permission to Geolocator denied');
      isGeolocating = false;
      return;
    }

    // Only use kCLLocationAccuracyBestForNavigation if the device is charging.
    // See: https://developer.apple.com/documentation/corelocation/kcllocationaccuracybestfornavigation
    final desiredAccuracy = await Battery().batteryState == BatteryState.charging
        ? LocationAccuracy.bestForNavigation // Requires additional energy for sensor fusion.
        : LocationAccuracy.best;

    // Set the time interval for android.
    final locationSettings = Platform.isAndroid
        ? AndroidSettings(
            intervalDuration: const Duration(seconds: 1),
            accuracy: desiredAccuracy,
            distanceFilter: 0,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
              notificationText: "Die Navigation läuft.",
              notificationTitle: "Navigation",
              setOngoing: true,
              enableWakeLock: true,
            ),
          )
        : AppleSettings(
            accuracy: desiredAccuracy,
            distanceFilter: 0,
            allowBackgroundLocationUpdates: true,
            activityType: ActivityType.fitness,
            showBackgroundLocationIndicator: true,
          );

    var positionStream = await positionSource!.startPositioning(
      locationSettings: locationSettings,
    );

    positionSubscription = positionStream.listen(
      (Position position) {
        if (!isGeolocating) return;
        lastPosition = position;

        positions.add(position);
        // Snap the position to the route.
        if (route != null && route!.route.length > 2) {
          snap = Snapper(
            position: LatLng(position.latitude, position.longitude),
            nodes: route!.route,
          ).snap();
          snaps.add(snap!);
        }
        onNewPosition();
        notifyListeners();
      },
    );

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
      (positionSource as PathMockPositionSource).idealSpeed = speed;
    }
  }
}
