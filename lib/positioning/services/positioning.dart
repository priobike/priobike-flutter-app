import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_gl/mapbox_gl.dart' as mapbox;
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/logging/logger.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:priobike/positioning/algorithm/snapper.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:priobike/positioning/sources/interface.dart';
import 'package:priobike/positioning/sources/gnss.dart';
import 'package:priobike/positioning/sources/mock.dart';
import 'package:priobike/routing/models/route.dart';
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

  /// The current route, for snapping.
  Route? route;

  /// The current position snapped to the route.
  Snap? snap;

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
    route = null;
    snap = null;
  }

  /// Notify the positioning that a new route was loaded.
  Future<void> selectRoute(Route? route) async {
    this.route = route;
    snap = null;
    notifyListeners();
  }

  /// Show a dialog if the location provider was denied.
  void showLocationAccessDeniedDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("Einstellungen öffnen"),
      onPressed: () => positionSource?.openLocationSettings(),
    );
    AlertDialog alert = AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      title: SubHeader(
        text: "Zugriff auf Standort verweigert.",
        context: context,
      ),
      content: Content(
        text: "Bitte erlauben Sie den Zugriff auf Ihren Standort in den Einstellungen.",
        context: context,
      ),
      actions: [okButton],
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
              .map((e) => mapbox.LatLng(e.lat, e.lon))
              .toList() ??
          [settings.backend.center];
      positionSource = PathMockPositionSource(speed: 18 / 3.6, positions: positions);
      log.i("Using mocked path positioning source (18 km/h).");
    } else if (settings.positioningMode == PositioningMode.follow40kmh) {
      final routing = Provider.of<Routing>(context, listen: false);
      final positions = routing.selectedRoute?.route // Fallback to center location of city.
              .map((e) => mapbox.LatLng(e.lat, e.lon))
              .toList() ??
          [settings.backend.center];
      positionSource = PathMockPositionSource(speed: 40 / 3.6, positions: positions);
      log.i("Using mocked path positioning source (40 km/h).");
    } else if (settings.positioningMode == PositioningMode.recordedDresden) {
      positionSource = RecordedMockPositionSource.mockDresden;
      log.i("Using mocked positioning source for Dresden.");
    } else if (settings.positioningMode == PositioningMode.recordedHamburg) {
      positionSource = RecordedMockPositionSource.mockHamburg;
      log.i("Using mocked positioning source for Hamburg.");
    } else if (settings.positioningMode == PositioningMode.hamburgStatic1) {
      positionSource = StaticMockPositionSource(position: const mapbox.LatLng(53.5529283, 10.004511), heading: 270);
      log.i("Using mocked position source for Hamburg main station.");
    } else if (settings.positioningMode == PositioningMode.dresdenStatic1) {
      positionSource = StaticMockPositionSource(position: const mapbox.LatLng(51.030077, 13.729404), heading: 270);
      log.i("Using mocked position source for traffic light 1 in Dresden.");
    } else if (settings.positioningMode == PositioningMode.dresdenStatic2) {
      positionSource = StaticMockPositionSource(position: const mapbox.LatLng(51.030241, 13.728205), heading: 1);
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
    required void Function() onNewPosition,
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
      (positionSource as PathMockPositionSource).speed = speed;
    }
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
