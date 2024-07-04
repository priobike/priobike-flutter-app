import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/status/messages/summary.dart';
import 'package:priobike/tracking/models/tap_tracking.dart';

class BatteryHistory {
  /// The battery level, in percent.
  int? level;

  /// The timestamp of the battery state.
  int? timestamp;

  /// The state of the battery.
  String? batteryState;

  /// If the system is in battery save mode.
  bool? isInBatterySaveMode;

  BatteryHistory(
      {required this.level, required this.timestamp, required this.batteryState, required this.isInBatterySaveMode});

  /// Convert the battery state to a json object.
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'timestamp': timestamp,
      'batteryState': batteryState,
      'isInBatterySaveMode': isInBatterySaveMode,
    };
  }

  /// Create a battery state from a json object.
  factory BatteryHistory.fromJson(Map<String, dynamic> json) {
    return BatteryHistory(
      level: json.containsKey('level') ? json['level'] : null,
      timestamp: json.containsKey('timestamp') ? json['timestamp'] : null,
      batteryState: json.containsKey('batteryState') ? json['batteryState'] : null,
      isInBatterySaveMode: json.containsKey('isInBatterySaveMode') ? json['isInBatterySaveMode'] : null,
    );
  }
}

class Track {
  /// The start time of this track, in milliseconds since the epoch.
  int startTime;

  /// The end time of this track, in milliseconds since the epoch.
  int? endTime;

  /// If the track was completed.
  get wasCompleted => endTime != null;

  /// If the track was uploaded to the backend.
  bool uploaded;

  /// If the track contains file data.
  bool hasFileData;

  /// If the track was recorded in the debug mode.
  /// This important when filtering out tracks in the backend.
  /// With this field we can determine tracks in debug mode.
  bool debug;

  /// If the track was recorded using the free ride mode.
  bool freeRide;

  /// The city of the ride.
  City city;

  /// The backend of the ride.
  /// This important when filtering out tracks in the backend.
  /// With this field we can determine tracks in production.
  Backend backend;

  /// The positioning mode of the ride.
  /// This important when filtering out tracks in the backend.
  /// With this field we can determine tracks with GPS.
  PositioningMode positioningMode;

  /// The user id.
  /// This is randomly generated when the user first opens the app,
  /// and can be used to identify the user's tracks over time.
  String userId;

  /// The session id.
  /// This is randomly generated when the user starts a ride.
  /// The session id identifies the track.
  String sessionId;

  /// An identifier for the device type (not the device id)
  /// For example "iPhone 11,2" for iPhone 11 Pro Max.
  String deviceType;

  /// The devices width used to analyse on taps in ride view.
  double deviceWidth;

  /// The devices height used to analyse on taps in ride view.
  double deviceHeight;

  /// The version of the app.
  String appVersion;

  /// The build number of the app.
  String buildNumber;

  /// The branch of the current version app.
  String subVersion;

  /// The prediction status summary before the ride.
  /// This can be used to determine tracks with bad prediction quality
  /// and tracks with good prediction quality.
  StatusSummaryData statusSummary;

  /// The positions where the user tapped during a ride.
  List<ScreenTrack> taps;

  /// The prediction service predictions received during the ride.
  List<PredictionServicePrediction> predictionServicePredictions;

  /// The predictor predictions received during the ride.
  List<PredictorPrediction> predictorPredictions;

  /// The *initially* selected waypoints of the route.
  /// This may be used to re-visit the route if the user wishes to do so.
  /// Please note that the waypoints may change if the user deviates from the route.
  /// Therefore we only store the initial waypoints.
  List<Waypoint?> selectedWaypoints;

  /// The bike type used to calculate the route.
  BikeType? bikeType;

  /// The routes of this track by their generation time: (time, route).
  /// This may only contain one route, if the user did not deviate from the route.
  /// Otherwise we can identify the time when the route was recalculated.
  Map<int, Route> routes;

  /// Until the new gamification concept is implemented, this value should remain hardcoded to false.
  /// This flag can be used to find out whether the original gamification concept was used in the corresponding track.
  /// (If the flag doesn't exist it means that it was still active during the ride)
  /// After the gamification concept is implemented the flag has to be set to true.
  bool canUseGamification;

  /// The battery states sampled during the ride.
  List<BatteryHistory> batteryStates = [];

  /// The lightning mode.
  bool? isDarkMode;

  /// The battery save mode.
  bool? saveBatteryModeEnabled;

  /// Get the directory under which the track files are stored.
  Future<Directory> get trackDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/tracks/$sessionId');
  }

  /// Get the csv file that stores the GPS data.
  Future<File> get gpsCSVFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tracks/$sessionId/gps.csv');
  }

  Track({
    required this.uploaded,
    required this.hasFileData,
    required this.startTime,
    this.endTime,
    required this.debug,
    required this.freeRide,
    required this.city,
    required this.backend,
    required this.positioningMode,
    required this.userId,
    required this.sessionId,
    required this.deviceType,
    required this.deviceWidth,
    required this.deviceHeight,
    required this.appVersion,
    required this.buildNumber,
    required this.statusSummary,
    required this.taps,
    required this.predictionServicePredictions,
    required this.predictorPredictions,
    required this.selectedWaypoints,
    required this.bikeType,
    required this.routes,
    required this.subVersion,
    required this.batteryStates,
    this.canUseGamification = false,
    required this.isDarkMode,
    required this.saveBatteryModeEnabled,
  });

  /// Convert the track to a json object.
  Map<String, dynamic> toJson() {
    return {
      'uploaded': uploaded,
      'hasFileData': hasFileData,
      'startTime': startTime,
      'endTime': endTime,
      'debug': debug,
      'city': city.name,
      'backend': backend.name,
      'positioningMode': positioningMode.name,
      'userId': userId,
      'sessionId': sessionId,
      'deviceType': deviceType,
      'deviceWidth': deviceWidth,
      'deviceHeight': deviceHeight,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'subVersion': subVersion,
      'canUseGamification': canUseGamification,
      'statusSummary': statusSummary.toJsonCamelCase(),
      'taps': taps.map((e) => e.toJson()).toList(),
      'predictionServicePredictions': predictionServicePredictions.map((e) => e.toJson()).toList(),
      'predictorPredictions': predictorPredictions.map((e) => e.toJson()).toList(),
      'selectedWaypoints': selectedWaypoints.map((e) => e!.toJSON()).toList(),
      'bikeType': bikeType?.name,
      'routes': routes.entries
          .map((e) => {
                'time': e.key,
                'route': e.value.toJson(),
              })
          .toList(),
      'batteryStates': batteryStates.map((e) => e.toJson()).toList(),
      'isDarkMode': isDarkMode,
      'saveBatteryModeEnabled': saveBatteryModeEnabled,
    };
  }

  /// Create a track from a json object.
  factory Track.fromJson(Map<String, dynamic> json) {
    // Assuring backwards compatibility.
    // Battery states were added later, so we need to check if they exist.
    List<BatteryHistory> batteryStates = [];
    if (json.containsKey("batteryStates")) {
      batteryStates = (json['batteryStates'] as List<dynamic>).map((e) => BatteryHistory.fromJson(e)).toList();
    }
    return Track(
      uploaded: json['uploaded'],
      // If the track was stored before we added the hasFileData field,
      // we assume that the track has file data to clean it up.
      hasFileData: json['hasFileData'] ?? true,
      startTime: json['startTime'],
      endTime: json['endTime'],
      debug: json['debug'],
      freeRide: json['freeRide'] ?? false,
      city: City.values.byName(json['city']),
      backend: Backend.values.byName(json['backend']),
      positioningMode: PositioningMode.values.byName(json['positioningMode']),
      userId: json['userId'],
      sessionId: json['sessionId'],
      deviceType: json['deviceType'],
      deviceWidth: json['deviceWidth'],
      deviceHeight: json['deviceHeight'],
      appVersion: json['appVersion'],
      buildNumber: json['buildNumber'],
      statusSummary: StatusSummaryData.fromJsonCamelCase(json['statusSummary']),
      taps: (json['taps'] as List<dynamic>).map((e) => ScreenTrack.fromJson(e)).toList(),
      predictionServicePredictions: (json['predictionServicePredictions'] as List<dynamic>)
          .map((e) => PredictionServicePrediction.fromJson(e))
          .toList(),
      predictorPredictions:
          (json['predictorPredictions'] as List<dynamic>).map((e) => PredictorPrediction.fromJson(e)).toList(),
      selectedWaypoints: (json['selectedWaypoints'] as List<dynamic>).map((e) => Waypoint.fromJson(e)).toList(),
      bikeType: json['bikeType'] == null ? null : BikeType.values.byName(json['bikeType']),
      routes: Map.fromEntries(
          (json['routes'] as List<dynamic>).map((e) => MapEntry(e['time'], Route.fromJson(e['route'])))),
      subVersion: json['subVersion'],
      canUseGamification: json['canUseGamification'],
      batteryStates: batteryStates,
      isDarkMode: json.containsKey("isDarkMode") ? json["isDarkMode"] : null,
      saveBatteryModeEnabled: json.containsKey("saveBatteryModeEnabled") ? json["saveBatteryModeEnabled"] : null,
    );
  }
}
