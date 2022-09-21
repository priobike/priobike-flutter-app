import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/recommendation.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/summary.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:provider/provider.dart';

/// A track of a bicycle ride.
class Tracking with ChangeNotifier {
  final log = Logger("Tracking");

  /// If the track was recorded in the debug mode.
  bool debug = kDebugMode;

  /// The device info.
  BaseDeviceInfo? deviceInfo;

  /// The package info.
  PackageInfo? packageInfo;

  /// The start time of this track, in milliseconds since the epoch.
  int? startTime;

  /// The route of this track before the ride.
  Route? route;

  /// The selected waypoints of the route.
  List<Waypoint>? selectedWaypoints;

  /// The settings before the ride.
  Settings? settings;

  /// The status summary before the ride.
  StatusSummaryData? statusSummary;

  /// The end time of this track, in milliseconds since the epoch.
  int? endTime;

  /// The positions after the ride.
  List<Position>? positions;

  /// The recommendation after the ride.
  List<Recommendation>? recommendations;

  /// The logs after the ride.
  List<String>? logs;

  /// The final json string of this track, after it was ended
  String? json;

  /// The final gzipped and base64 encoded json string
  /// of this track, after it was ended
  String? jsonEncoded;

  /// If the user will send the track.
  bool willSendTrack = true;

  /// If the track is currently being sent.
  bool isSendingTrack = false;

  Tracking();

  /// Start a new track.
  Future<void> start(BuildContext context) async {
    log.i("Starting a new track.");
    // Get some session- and device-specific data.
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      deviceInfo = await deviceInfoPlugin.iosInfo;
    } else if (Platform.isAndroid) {
      deviceInfo = await deviceInfoPlugin.androidInfo;
    } else {
      throw Exception("Unsupported platform");
    }
    packageInfo = await PackageInfo.fromPlatform();
    // Get the current time.
    startTime = DateTime.now().millisecondsSinceEpoch;
    // Get the currently selected route.
    final routing = Provider.of<Routing>(context, listen: false);
    route = routing.selectedRoute;
    selectedWaypoints = routing.selectedWaypoints;
    // Get the current settings.
    settings = Provider.of<Settings>(context, listen: false);
    // Get the current status summary.
    statusSummary = Provider.of<PredictionStatusSummary>(context, listen: false).current;
    notifyListeners();
  }

  /// End the current track.
  Future<void> end(BuildContext context) async {
    log.i("Ending the current track.");
    // Get the current time.
    endTime = DateTime.now().millisecondsSinceEpoch;
    // Get the current positions.
    positions = Provider.of<Positioning>(context, listen: false).positions;
    // Get the current recommendations.
    recommendations = Provider.of<Ride>(context, listen: false).recommendations;
    // Get the current logs.
    logs = Logger.db;
    json = jsonEncode(toJson());
    // Compress the json with gzip.
    final encoded = gzip.encode(utf8.encode(json!));
    jsonEncoded = base64.encode(encoded);
    notifyListeners();
  }

  /// Set the willSend flag.
  void setWillSendTrack(bool willSendTrack) {
    this.willSendTrack = willSendTrack;
    notifyListeners();
  }

  /// Send the track to the server.
  Future<void> send(BuildContext context) async {
    isSendingTrack = true;
    notifyListeners();

    log.i("Sending the track to the server.");
    log.i(json); // TODO: Actually send the track to the server.

    isSendingTrack = false;
    notifyListeners();
  }

  /// Reset the current track.
  Future<void> reset() async {
    startTime = null;
    route = null;
    selectedWaypoints = null;
    settings = null;
    statusSummary = null;
    endTime = null;
    positions = null;
    recommendations = null;
    logs = null;
    notifyListeners();
  }

  /// Convert the track to a JSON object.
  Map<String, dynamic> toJson() => {
    'startTime': startTime,
    'endTime': endTime,
    'debug': debug,
    'route': route?.toJson(),
    'positions': positions?.map((p) => p.toJson()).toList(),
    'recommendations': recommendations?.map((r) => r.toJson()).toList(),
    'logs': logs,
    'settings': settings?.toJson(),
    'statusSummary': statusSummary?.toJsonCamelCase(),
    'deviceInfo': deviceInfo?.toMap(),
    'packageInfo': {
      'appName': packageInfo?.appName,
      'packageName': packageInfo?.packageName,
      'version': packageInfo?.version,
      'buildNumber': packageInfo?.buildNumber,
    }
  };
}