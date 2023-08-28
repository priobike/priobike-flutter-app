import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/hybrid_predictor.dart';
import 'package:priobike/ride/services/prediction_service.dart';
import 'package:priobike/ride/services/predictor.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/tracking.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/user.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CSVCache {
  /// The currently pending lines.
  List<String> lines;

  /// The file reference.
  File file;

  /// The maximum number of lines to cache.
  int maxLines;

  CSVCache({
    required String header,
    required this.file,
    required this.maxLines,
  }) : lines = [header];

  /// Add a line to the cache.
  Future<void> add(String line) async {
    lines.add(line);
    if (lines.length >= maxLines) await flush();
  }

  /// Flush the cache.
  Future<void> flush() async {
    if (lines.isEmpty) return;
    // Create the file if it does not exist.
    var fileIsNew = false;
    if (!await file.exists()) {
      await file.create(recursive: true);
      fileIsNew = true;
    }
    // Flush the cache and write the data to the file.
    final csv = lines.join("\n");
    lines.clear();
    // If the file is not new, append a newline.
    if (!fileIsNew) await file.writeAsString("\n", mode: FileMode.append, flush: true);
    await file.writeAsString(csv, mode: FileMode.append, flush: true);
  }
}

/// A track of a bicycle ride.
class Tracking with ChangeNotifier {
  final log = Logger("Tracking");

  /// The current tracking submission policy.
  TrackingSubmissionPolicy? submissionPolicy;

  /// The current track.
  Track? track;

  /// The previous tracks.
  List<Track>? previousTracks;

  /// The csv writer for the gps data.
  CSVCache? gpsCache;

  /// The csv writer for the accelerometer data.
  CSVCache? accCache;

  /// The current accelerometer stream subscription.
  StreamSubscription? accSub;

  /// The csv writer for the magnetometer data.
  CSVCache? magCache;

  /// The current magnetometer stream subscription.
  StreamSubscription? magSub;

  /// The csv writer for the gyroscope data.
  CSVCache? gyrCache;

  /// The current gyroscope stream subscription.
  StreamSubscription? gyrSub;

  /// If a track by the session id is currently being uploaded.
  Map<String, bool> uploadingTracks = {};

  /// A timer that checks if tracks need to be uploaded.
  Timer? uploadTimer;

  /// Latest accelerometer data.
  AccelerometerEvent? latestAccEvent;

  /// The timestamp of the last accelerometer event.
  int? latestAccEventTimestamp;

  /// Latest magnetometer data.
  MagnetometerEvent? latestMagEvent;

  /// The timestamp of the last magnetometer event.
  int? latestMagEventTimestamp;

  /// Latest gyroscope data.
  GyroscopeEvent? latestGyroEvent;

  /// The timestamp of the last gyroscope event.
  int? latestGyroEventTimestamp;

  /// The timer used to sample the sensor data.
  Timer? sensorSamplingTimer;

  /// The key for the tracks in the shared preferences.
  static const tracksKey = "priobike.tracking.tracks";

  Tracking();

  /// Set the current tracking submission policy.
  Future<void> setSubmissionPolicy(TrackingSubmissionPolicy policy) async {
    submissionPolicy = policy;
  }

  /// Load previous tracks from the shared preferences.
  Future<void> loadPreviousTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(tracksKey);
    if (json == null) {
      previousTracks = [];
    } else {
      previousTracks = json
          .map((e) {
            try {
              return Track.fromJson(jsonDecode(e));
            } catch (e) {
              return null; // Ignore invalid tracks.
            }
          })
          .whereType<Track>()
          .toList();
    }
    log.i("Loaded ${previousTracks!.length} previous tracks.");
    notifyListeners();
  }

  /// Save the previous tracks to the shared preferences.
  Future<void> savePreviousTracks() async {
    if (previousTracks == null) return;
    if (previousTracks!.isEmpty) return; // Avoid deleting all tracks.
    final prefs = await SharedPreferences.getInstance();
    final json = previousTracks!.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("priobike.tracking.tracks", json);
  }

  /// Start a new track.
  Future<void> start(double deviceWidth, double deviceHeight) async {
    log.i("Starting a new track.");

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
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final routing = getIt<Routing>();
    final settings = getIt<Settings>();
    final status = getIt<PredictionStatusSummary>();
    final ride = getIt<Ride>();
    final profile = getIt<Profile>();

    try {
      Feature feature = getIt<Feature>();
      track = Track(
        uploaded: false,
        hasFileData: true,
        startTime: startTime,
        endTime: null,
        debug: kDebugMode,
        backend: settings.backend,
        positioningMode: settings.positioningMode,
        userId: await User.getOrCreateId(),
        sessionId: ride.sessionId!,
        deviceType: deviceType,
        deviceWidth: deviceWidth,
        deviceHeight: deviceHeight,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        statusSummary: status.current!,
        taps: [],
        predictionServicePredictions: [],
        predictorPredictions: [],
        selectedWaypoints: routing.selectedWaypoints!,
        bikeType: profile.bikeType,
        preferenceType: profile.preferenceType,
        activityType: profile.activityType,
        routes: {startTime: routing.selectedRoute!},
        subVersion: feature.gitHead.replaceAll("ref: refs/heads/", ""),
      );
      // Add the track to the list of previous tracks and save it.
      previousTracks!.add(track!);
      await savePreviousTracks();
      // Start collecting data to the files of the track.
      await startCollectingGPSData();
      await startCollectingAccData(accelerometerEvents);
      await startCollectingGyrData(gyroscopeEvents);
      await startCollectingMagData(magnetometerEvents);
      if (sensorSamplingTimer == null || !sensorSamplingTimer!.isActive) {
        sensorSamplingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async => await sampleSensorData());
      }
    } catch (e, stacktrace) {
      final hint = "Could not start a new track: $e $stacktrace";
      log.e(hint);
      return end();
    }

    notifyListeners();
  }

  /// Start sampling the sensor data.
  Future<void> sampleSensorData() async {
    if (latestAccEvent != null && latestAccEventTimestamp != null) {
      await accCache?.add("$latestAccEventTimestamp,${latestAccEvent?.x},${latestAccEvent?.y},${latestAccEvent?.z}");
    }
    if (latestGyroEvent != null && latestGyroEventTimestamp != null) {
      await gyrCache
          ?.add("$latestGyroEventTimestamp,${latestGyroEvent?.x},${latestGyroEvent?.y},${latestGyroEvent?.z}");
    }
    if (latestMagEvent != null && latestMagEventTimestamp != null) {
      await magCache?.add("$latestMagEventTimestamp,${latestMagEvent?.x},${latestMagEvent?.y},${latestMagEvent?.z}");
    }
  }

  /// Start collecting GPS data.
  Future<void> startCollectingGPSData() async {
    gpsCache = CSVCache(
      header: "timestamp,longitude,latitude,speed,accuracy",
      file: await track!.gpsCSVFile,
      maxLines: 5, // Flush after 5 seconds of data.
    );
    log.i("Started collecting gps data.");
  }

  /// Notify the track that a new GPS position is available.
  Future<void> updatePosition() async {
    final position = getIt<Positioning>().lastPosition;
    if (position == null) return;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await gpsCache?.add("$timestamp,${position.longitude},${position.latitude},${position.speed},${position.accuracy}");
  }

  /// Stop collecting GPS data.
  Future<void> stopCollectingGpsData() async {
    await gpsCache?.flush();
    log.i("Stopped collecting gps data.");
  }

  /// Start collecting accelerometer data.
  Future<void> startCollectingAccData(Stream<AccelerometerEvent> stream) async {
    accCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track!.accelerometerCSVFile,
      maxLines: 500, // Flush after 500 lines of data (~5s on most devices).
    );
    accSub = stream.listen((event) {
      latestAccEventTimestamp = DateTime.now().millisecondsSinceEpoch;
      latestAccEvent = event;
    });
    log.i("Started collecting accelerometer data.");
  }

  /// Stop collecting accelerometer data.
  Future<void> stopCollectingAccData() async {
    await accSub?.cancel();
    accSub = null;
    await accCache?.flush();
    log.i("Stopped collecting accelerometer data.");
  }

  /// Start collecting gyroscope data.
  Future<void> startCollectingGyrData(Stream<GyroscopeEvent> stream) async {
    gyrCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track!.gyroscopeCSVFile,
      maxLines: 500, // Flush after 500 lines of data (~5s on most devices).
    );
    gyrSub = stream.listen((event) {
      latestGyroEventTimestamp = DateTime.now().millisecondsSinceEpoch;
      latestGyroEvent = event;
    });
    log.i("Started collecting gyroscope data.");
  }

  /// Stop collecting gyroscope data.
  Future<void> stopCollectingGyrData() async {
    await gyrSub?.cancel();
    gyrSub = null;
    await gyrCache?.flush();
    log.i("Stopped collecting gyroscope data.");
  }

  /// Start collecting magnetometer data.
  Future<void> startCollectingMagData(Stream<MagnetometerEvent> stream) async {
    magCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track!.magnetometerCSVFile,
      maxLines: 500, // Flush after 500 lines of data (~5s on most devices).
    );
    magSub = stream.listen((event) {
      latestMagEventTimestamp = DateTime.now().millisecondsSinceEpoch;
      latestMagEvent = event;
    });
    log.i("Started collecting magnetometer data.");
  }

  /// Stop collecting magnetometer data.
  Future<void> stopCollectingMagData() async {
    await magSub?.cancel();
    magSub = null;
    await magCache?.flush();
    log.i("Stopped collecting magnetometer data.");
  }

  /// Notify the tracking service that a rerouting has happened.
  Future<void> selectRoute(Route newRoute) async {
    log.i("New route selected.");
    track?.routes[DateTime.now().millisecondsSinceEpoch] = newRoute;
    // Save the change to the shared preferences, in case the app is killed.
    previousTracks?.removeWhere((t) => t.sessionId == track?.sessionId);
    previousTracks?.add(track!);
    await savePreviousTracks();
    notifyListeners();
  }

  /// End the current track.
  Future<void> end() async {
    log.i("Ending the current track.");
    track?.endTime = DateTime.now().millisecondsSinceEpoch;

    final ride = getIt<Ride>();
    if (ride.predictionComponent is PredictionService) {
      track?.predictionServicePredictions =
          (ride.predictionComponent! as PredictionService).predictionServicePredictions;
      track?.predictorPredictions = [];
    } else if (ride.predictionComponent is Predictor) {
      track?.predictorPredictions = (ride.predictionComponent! as Predictor).predictorPredictions;
      track?.predictionServicePredictions = [];
    } else if (ride.predictionComponent is HybridPredictor) {
      track?.predictorPredictions = (ride.predictionComponent! as HybridPredictor).predictorPredictions;
      track?.predictionServicePredictions = (ride.predictionComponent! as HybridPredictor).predictionServicePredictions;
    }

    sensorSamplingTimer?.cancel();
    sensorSamplingTimer = null;

    // Stop collecting data.
    await stopCollectingMagData();
    await stopCollectingGyrData();
    await stopCollectingAccData();
    await stopCollectingGpsData();

    // Update the track in the list of previous tracks and save it.
    previousTracks?.removeWhere((t) => t.sessionId == track?.sessionId);
    previousTracks?.add(track!);
    await savePreviousTracks();

    // Reset the current track.
    final trackToSend = track;
    track = null;
    // Try to immediately send the track to the server, but don't wait for it.
    if (trackToSend != null) send(trackToSend);

    notifyListeners();
  }

  /// Send the track to the server.
  Future<bool> send(Track track) async {
    if (track.uploaded) {
      log.w("Cannot send track, already uploaded.");
      return false;
    }
    if (uploadingTracks.containsKey(track.sessionId)) {
      log.w("Cannot send track, already sending.");
      return false;
    }
    // Check if the user only wants to send data when connected to WiFi.
    if (submissionPolicy == TrackingSubmissionPolicy.onlyOnWifi) {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.wifi) {
        log.i("Not sending track ${track.sessionId} (no connection to WiFi).");
        return false;
      }
    }
    log.i("Sending track ${track.sessionId} to the server.");

    uploadingTracks[track.sessionId] = true;
    notifyListeners();

    final baseUrl = track.backend.path;
    final endpoint = Uri.parse('https://$baseUrl/tracking-service/tracks/post/');

    log.i("Sending track with id ${track.sessionId} to $endpoint ...");
    try {
      // Send a multipart request to the server, with the track json and the gzipped csv files.
      final metadataBytes = gzip.encode(utf8.encode(jsonEncode(track.toJson())));
      final metadataMF = MultipartFile.fromBytes('metadata.json.gz', metadataBytes, filename: 'metadata.json.gz');

      // Data statistics: 10 minutes ~ 20 KB (gzipped), 50 KB (uncompressed).
      final gpsBytes = gzip.encode(await (await track.gpsCSVFile).readAsBytes());
      final gpsMF = MultipartFile.fromBytes('gps.csv.gz', gpsBytes, filename: 'gps.csv.gz');

      // Data statistics: 10 minutes ~ 500-1000 KB (gzipped), 5 MB (uncompressed).
      final accBytes = gzip.encode(await (await track.accelerometerCSVFile).readAsBytes());
      final accMF = MultipartFile.fromBytes('accelerometer.csv.gz', accBytes, filename: 'accelerometer.csv.gz');

      // Data statistics: 10 minutes ~ 1000-2000 KB (gzipped), 5 MB (uncompressed).
      final gyrBytes = gzip.encode(await (await track.gyroscopeCSVFile).readAsBytes());
      final gyrMF = MultipartFile.fromBytes('gyroscope.csv.gz', gyrBytes, filename: 'gyroscope.csv.gz');

      // Data statistics: 10 minutes ~ 1000-2000 KB (gzipped), 5 MB (uncompressed).
      final magBytes = gzip.encode(await (await track.magnetometerCSVFile).readAsBytes());
      final magMF = MultipartFile.fromBytes('magnetometer.csv.gz', magBytes, filename: 'magnetometer.csv.gz');

      if (track.endTime != null) {
        final trackDurationMinutes = (track.endTime! - track.startTime) / 1000 / 60;
        log.i("Track duration: ${trackDurationMinutes.round()} minutes.");
      } else {
        log.i("Track duration: unknown (app was terminated before ride finished).");
      }
      log.i("Sending ${(metadataBytes.length / 1000).round()} KB of gzipped track metadata.");
      log.i("Sending ${(gpsBytes.length / 1000).round()} KB of compressed GPS data.");
      log.i("Sending ${(accBytes.length / 1000).round()} KB of compressed accelerometer data.");
      log.i("Sending ${(gyrBytes.length / 1000).round()} KB of compressed gyroscope data.");
      log.i("Sending ${(magBytes.length / 1000).round()} KB of compressed magnetometer data.");

      // Skip tracks that are >50 MB, but mark them as sent so that they are not sent again.
      final totalSize = metadataBytes.length + gpsBytes.length + accBytes.length + gyrBytes.length + magBytes.length;
      if (totalSize < 50 * 1000 * 1000) {
        final response = await Http.multipartPost(
          endpoint,
          fields: {},
          files: [metadataMF, gpsMF, accMF, gyrMF, magMF],
        );
        if (response.statusCode != 200) {
          throw Exception("Tracking service responded with ${response.statusCode}: ${response.body}.");
        }
        log.i("Sent track with id ${track.sessionId}.");
      } else {
        log.w("Track with id ${track.sessionId} is too large (${totalSize / 1000 / 1000} MB), skipping.");
      }
    } catch (e, stack) {
      final hint = "Failed to send track with id ${track.sessionId}: $e $stack.";
      log.e(hint);
      // If a track file is missing and thus can't be uploaded,
      // we want to continue as it got sent such that it does not try to send it again.
      if (e is! PathNotFoundException) {
        uploadingTracks.remove(track.sessionId);
        notifyListeners();
        return false;
      }
      log.w("Track with id ${track.sessionId} is missing files, skipping.");
    }

    uploadingTracks.remove(track.sessionId);
    notifyListeners();

    // Update the track in the list of previous tracks and save it.
    track.uploaded = true;
    previousTracks?.removeWhere((t) => t.sessionId == track.sessionId);
    previousTracks?.add(track);
    await savePreviousTracks();
    notifyListeners();

    return true;
  }

  /// Cleanup the track files.
  Future<bool> cleanup(Track track) async {
    if (!track.hasFileData || !track.uploaded) return false;
    log.i("Cleaning up track with id ${track.sessionId}.");
    // Delete the track files.
    final directory = await track.trackDirectory;
    if (await directory.exists()) {
      final contents = await directory.list().toList();
      for (final content in contents) {
        // Delete everything but the GPS file.
        if (content is! File) {
          await content.delete(recursive: true);
        } else if (!content.path.contains("gps")) {
          await content.delete();
        }
      }
    }
    log.i("Cleaned uploaded files for track with id ${track.sessionId}.");
    track.hasFileData = false;
    previousTracks?.removeWhere((t) => t.sessionId == track.sessionId);
    previousTracks?.add(track);
    await savePreviousTracks();
    notifyListeners();
    return true;
  }

  /// Delete a specific track.
  Future<void> deleteTrack(Track track) async {
    log.i("Deleting track with id ${track.sessionId}.");
    // Delete the track files.
    final directory = await track.trackDirectory;
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    previousTracks?.removeWhere((t) => t.sessionId == track.sessionId);

    // Delete the associated background image. Needs to first get the bounding box of the track.
    List<LatLng> coordinates = [];
    for (final Route route in track.routes.values) {
      for (final NavigationNode node in route.route) {
        final latLng = LatLng(node.lat, node.lon);
        coordinates.add(latLng);
      }
    }
    final bbox = MapboxMapProjection.mercatorBoundingBox(coordinates);
    if (bbox != null) await MapboxTileImageCache.deleteImage(bbox);

    await savePreviousTracks();
    notifyListeners();
  }

  /// Run a timer that periodically sends tracks to the server.
  Future<void> runUploadRoutine() async {
    log.i("Starting to send tracks to the server.");
    callback() async {
      // Don't send tracks if the user is currently driving.
      if (track != null) return;
      if (previousTracks == null) {
        log.w("Cannot send tracks, previous tracks not loaded.");
        return;
      }
      var sent = 0;
      final tracksToSend = previousTracks?.where((t) => !t.uploaded).toList() ?? [];
      // Send tracks in a random order, if some track fails to send all the time.
      tracksToSend.shuffle();
      for (final track in tracksToSend) {
        if (await send(track)) sent++;
      }
      if (sent > 0) {
        log.i("Sent tracks to server - $sent/${tracksToSend.length} (${previousTracks?.length ?? 0} total).");
      }
      // Delete the track files if they were sent to the server.
      var cleaned = 0;
      final tracksToClean = previousTracks?.where((t) => t.uploaded && t.hasFileData).toList() ?? [];
      for (final track in tracksToClean) {
        if (await cleanup(track)) cleaned++;
      }
      if (cleaned > 0) {
        log.i("Cleaned tracks - $cleaned/${tracksToClean.length} (${previousTracks?.length ?? 0} total).");
      }
    }

    callback(); // Send tracks immediately.
    uploadTimer = Timer.periodic(const Duration(seconds: 30), (_) async => await callback());
  }
}
