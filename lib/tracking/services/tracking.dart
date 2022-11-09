import 'dart:convert';
import 'dart:io';
import 'package:priobike/accelerometer/models/acceleration.dart';
import 'package:priobike/accelerometer/services/accelerometer.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/http.dart';
import 'package:priobike/settings/models/backend.dart';
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
import 'package:priobike/dangers/models/danger.dart';
import 'package:priobike/tracking/models/tap_tracking.dart';
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

  /// The list of reported dangers after the ride.
  List<Danger>? dangers;

  /// The list of accelerometer data points after the ride.
  List<Acceleration>? accelerations;

  /// The positions after the ride.
  List<Position>? positions;

  /// The recommendation after the ride.
  List<Recommendation>? recommendations;

  /// The logs after the ride.
  List<String>? logs;

  /// The final json string of this track, after it was ended
  String? json;

  /// If the user will send the track.
  bool willSendTrack = true;

  /// If the track is currently being sent.
  bool isSendingTrack = false;

  /// If the track can be sent.
  bool get canSendTrack => json != null;

  /// The positions where the user tapped during a ride.
  List<ScreenTrack> tapsTracked = [];

  /// The devices frame size used to analyse on taps in ride view.
  Size? deviceSize;

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
    // Get the current dangers.
    dangers = Provider.of<Dangers>(context, listen: false).dangers;
    // Get the current accelerations.
    accelerations = Provider.of<Accelerometer>(context, listen: false).accelerations;
    // Get the current positions.
    positions = Provider.of<Positioning>(context, listen: false).positions;
    // Get the current recommendations.
    recommendations = Provider.of<Ride>(context, listen: false).recommendations;
    // Get the current logs.
    logs = Logger.db;
    json = jsonEncode(toJson());
    notifyListeners();
  }

  /// Set the willSend flag.
  void setWillSendTrack(bool willSendTrack) {
    this.willSendTrack = willSendTrack;
    notifyListeners();
  }

  /// Send the track to the server.
  Future<bool> send(BuildContext context) async {
    if (json == null) {
      log.w("Cannot send track, because it is not ready.");
      return false;
    }
    if (isSendingTrack) {
      log.w("Cannot send track, because it is already being sent.");
      return false;
    }
    if (!willSendTrack) {
      log.w("Cannot send track, because the user does not want to send it.");
      return false;
    }
    log.i("Sending track to the server.");

    isSendingTrack = true;
    notifyListeners();

    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/tracking-service/tracks/post/');
    final response = await Http.post(endpoint, body: json!);
    if (response.statusCode != 200) {
      log.e("Error sending track to $endpoint: ${response.body}"); // If the track gets lost here, it's not a big deal.
    } else {
      log.i("Successfully sent track to $endpoint");
    }

    isSendingTrack = false;
    notifyListeners();

    return true;
  }

  /// Reset the current track.
  Future<void> reset() async {
    startTime = null;
    route = null;
    selectedWaypoints = null;
    settings = null;
    statusSummary = null;
    endTime = null;
    dangers = null;
    accelerations = null;
    positions = null;
    recommendations = null;
    logs = null;
    tapsTracked = [];
    deviceSize = null;
    isSendingTrack = false;
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
        'dangers': dangers?.map((d) => d.toJson()).toList(),
        'accelerations': accelerations?.map((d) => d.toJson()).toList(),
        'settings': settings?.toJson(),
        'statusSummary': statusSummary?.toJsonCamelCase(),
        'deviceInfo': deviceInfo?.toMap(),
        'deviceWidth': deviceSize?.width.round(),
        'deviceHeight': deviceSize?.height.round(),
        'screenTracks': tapsTracked.map((p) => p.toJson()).toList(),
        'packageInfo': {
          'appName': packageInfo?.appName,
          'packageName': packageInfo?.packageName,
          'version': packageInfo?.version,
          'buildNumber': packageInfo?.buildNumber,
        }
      };
}
