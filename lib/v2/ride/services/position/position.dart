import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:priobike/v2/common/logger.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class PositionExtrapolator {
  /// The refresh rate that is used to update the position.
  static num refreshRateHz = 25;

  /// The last known position.
  Position? lastPosition;

  /// Create a position stream.
  Stream<Position> startEstimating() {
    // Create a new stream, which we will later use to push positions.
    var streamController = StreamController<Position>();

    // Start the stream.
    Timer.periodic(Duration(milliseconds: (1000 / refreshRateHz).round()), (Timer timer) {
      if (lastPosition == null) return;
      var extrapolatedPosition = extrapolate(lastPosition!);
      if (extrapolatedPosition == null) return;
      streamController.add(extrapolatedPosition);
    });

    return streamController.stream;
  } 

  /// Extrapolate the position.
  Position? extrapolate(Position lastPosition) {
    // Calculate the elapsed time since the last position.
    final last = lastPosition.timestamp?.toUtc();
    if (last == null) return null;
    final elapsed = DateTime.now().toUtc().difference(last).inMilliseconds;
    if (elapsed < 0) return null;

    // Offset the position by the traveled distance and bearing
    if (lastPosition.heading < 0 || lastPosition.heading > 360) return null;
    // Unfortunately, if the heading is 0.0, we need to assume that 
    // the device has no support for heading. In the future, we should
    // fallback to calculating the heading ourselves (using last 2 positions).
    if (lastPosition.heading == 0.0) return null;
    final newLatLng = const Distance().offset(
      LatLng(lastPosition.latitude, lastPosition.longitude), 
      lastPosition.speed * (elapsed / 1000), 
      lastPosition.heading
    );
    
    return Position(
      latitude: newLatLng.latitude,
      longitude: newLatLng.longitude,
      altitude: lastPosition.altitude,
      timestamp: DateTime.now().toUtc(),
      accuracy: lastPosition.accuracy,
      speed: lastPosition.speed,
      heading: lastPosition.heading,
      speedAccuracy: lastPosition.speedAccuracy,
    );
  }
}

abstract class PositionSource {
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

class PositionService with ChangeNotifier {
  Logger log = Logger("PositionService");

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The interface to the position source.
  /// See [PositionSource] for more information.
  final PositionSource positionSource;

  /// An extrapolator for the position.
  final positionEstimator = PositionExtrapolator();

  /// A subscription to the estimated position.
  StreamSubscription<Position>? estimatorSubscription;

  /// A subscription to the real position.
  StreamSubscription<Position>? positionSubscription;

  /// The current estimated position (> 1Hz).
  Position? estimatedPosition;

  /// The current measured position (1 Hz).
  Position? lastPosition;

  /// An indicator if geolocation is active.
  bool isGeolocating = false;

  PositionService({required this.positionSource});

  /// Show a dialog if the location provider was denied.
  showLocationAccessDeniedDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("Einstellungen öffnen"),
      onPressed: () => positionSource.openLocationSettings(),
    );
    AlertDialog alert = AlertDialog(
      title: const Text("Zugriff auf Standort verweigert."),
      content: const Text("Bitte erlauben Sie den Zugriff auf Ihren Standort in den Einstellungen."),
      actions: [ okButton ],
    );
    showDialog(context: context, builder: (BuildContext context) => alert);
  }

  Future<bool> requestGeolocatorPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await positionSource.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled - don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await positionSource.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await positionSource.requestPermission();
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

  startGeolocation(BuildContext context) async {
    if (isGeolocating) {
      log.w('Attempted to start geolocation while already geolocating');
      return;
    }
    isGeolocating = true;

    final hasPermission = await requestGeolocatorPermission();
    if (!hasPermission) {
      Navigator.of(context).pop();
      showLocationAccessDeniedDialog(context);
      log.w('Permission to Geolocator denied');
      isGeolocating = false;
      return;
    }

    var positionStream = positionSource.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    );

    // Launch a position estimator, which will get the real 
    // positions and extrapolate the estimated position.
    estimatorSubscription = positionEstimator.startEstimating()
      .listen((Position estimatedPosition) {
        if (!isGeolocating) return;
        this.estimatedPosition = estimatedPosition;
        notifyListeners();
      });

    positionSubscription = positionStream.listen((Position position) {
      if (isGeolocating == true) {
        lastPosition = position;
        // Update the position estimator with the new position.
        positionEstimator.lastPosition = position; 
        notifyListeners();
      }
    });

    log.i('Geolocator started!');
  }

  stopGeolocation() {
    isGeolocating = false;
    positionSubscription?.cancel();
    estimatorSubscription?.cancel();
    log.i('Geolocator stopped!');
    notifyListeners();
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}

class GNSSPositionService extends PositionService {
  GNSSPositionService({required LatLng position}) : super(positionSource: GNSSPositionSource());
}
