import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';

import '../../home/services/profile.dart';
import '../../main.dart';
import '../../routing/messages/graphhopper.dart';
import '../../routing/models/navigation.dart';
import '../../routing/models/waypoint.dart';
import '../../settings/services/features.dart';
import '../../settings/services/settings.dart';
import '../../status/services/summary.dart';
import '../../user.dart';
import 'package:priobike/routing/models/route.dart' as r;

/// This service generates mock tracks
class TrackGenerationService with ChangeNotifier {
  TrackGenerationService();


  Future<void> generate(double deviceWidth, double deviceHeight) async {
    // Get some session- and device-specific data.
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceType;

    if (Platform.isIOS) {
      // UTSName/Machine is e.g. "iPhone12,1" for iPhone 11 Pro and version is e.g. "13.3".
      final info = (await deviceInfoPlugin.iosInfo);
      deviceType = "${info.utsname.machine} (iOS ${info.systemVersion})";
    } else if (Platform.isAndroid) {
      // Model is e.g. "Pixel 2" and version.release is e.g. "8.1.0".
      final info = (await deviceInfoPlugin.androidInfo);
      deviceType = "${info.model} (Android ${info.version.release})";
    } else {
      throw Exception("Unsupported platform");
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, now.hour, now.minute - 5).millisecondsSinceEpoch;
    final settings = getIt<Settings>();
    final status = getIt<PredictionStatusSummary>();
    final profile = getIt<Profile>();
    final feature = getIt<Feature>();

    // TODO calculate distance
    double distance = 10;
    // TODO calculate time
    int time = 300000; // 5min in milliseconds
    // TODO calculate ascend
    double ascend = 0; // 0m
    // TODO calculate descend
    double descend = 0; // 0m
    // TODO generate points
    List<GHCoordinate> coordinates = [];
    GHLineString points = GHLineString(
        type: "LineString",
        coordinates: coordinates
    );
    // TODO calculate bbox
    double minLon = 90;
    double minLat = 90;
    double maxLon = -90;
    double maxLat = -90;
    GHBoundingBox bbox = GHBoundingBox(
        minLon: minLon,
        minLat: minLat,
        maxLon: maxLon,
        maxLat: maxLat
    );
    // TODO generate path
    GHRouteResponsePath path = GHRouteResponsePath(
      distance: distance,
      time: time,
      ascend: ascend,
      descend: descend,
      points: points,
      snappedWaypoints: points,
      pointsEncoded: true,
      bbox: bbox,
      instructions: [],
      details: const GHDetails(surface: [], maxSpeed: [], smoothness: [], lanes: [], roadClass: []),
      pointsOrder: null
    );
    // TODO generate waypoints
    List<Waypoint> selectedWaypoints = [];
    // TODO generate navigation Nodes
    List<NavigationNode> navigationNodes = [];
    // generate route
    r.Route selectedRoute = r.Route(
        id: 1,
        path: path,
        route: navigationNodes,
        signalGroups: [],
        signalGroupsDistancesOnRoute: [],
        crossings: [],
        crossingsDistancesOnRoute: []
    );

    Track track = Track(
      uploaded: false,
      hasFileData: true,
      startTime: startTime,
      endTime: null,
      debug: kDebugMode,
      backend: settings.backend,
      positioningMode: settings.positioningMode,
      userId: await User.getOrCreateId(),
      sessionId: UniqueKey().toString(),
      deviceType: deviceType,
      deviceWidth: deviceWidth,
      deviceHeight: deviceHeight,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      statusSummary: status.current!,
      taps: [],
      predictionServicePredictions: [],
      predictorPredictions: [],
      selectedWaypoints: selectedWaypoints,
      bikeType: profile.bikeType,
      preferenceType: profile.preferenceType,
      activityType: profile.activityType,
      routes: {startTime: selectedRoute},
      subVersion: feature.gitHead.replaceAll("ref: refs/heads/", ""),
    );

    Tracking tracking = Tracking();
    tracking.accCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track.accelerometerCSVFile,
      maxLines: 500, // Flush after 500 lines of data (~5s on most devices).
    );
    tracking.gpsCache = CSVCache(
      header: "timestamp,longitude,latitude,speed,accuracy",
      file: await track.gpsCSVFile,
      maxLines: 5, // Flush after 5 seconds of data.
    );
    tracking.gyrCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track.gyroscopeCSVFile,
      maxLines: 500, // Flush after 500 lines of data (~5s on most devices).
    );
    tracking.magCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track.magnetometerCSVFile,
      maxLines: 500, // Flush after 500 lines of data (~5s on most devices).
    );
    await tracking.accCache!.flush();
    await tracking.gpsCache!.flush();
    await tracking.gyrCache!.flush();
    await tracking.magCache!.flush();
    await tracking.loadPreviousTracks();
    tracking.previousTracks!.add(track);
    await tracking.savePreviousTracks();
    tracking.send(track);
    notifyListeners();
  }
}
