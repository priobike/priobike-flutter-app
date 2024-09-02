import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:priobike/common/csv.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/tracking.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/v7.dart';

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

  /// If a track by the session id is currently being uploaded.
  Map<String, bool> uploadingTracks = {};

  /// A timer that checks if tracks need to be uploaded.
  Timer? uploadTimer;

  /// The timer used to sample the battery state.
  Timer? batterySamplingTimer;

  /// The class used to get the battery state.
  Battery? battery;

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
    final prefs = await SharedPreferences.getInstance();
    final json = previousTracks!.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("priobike.tracking.tracks", json);
  }

  /// Start a new track.
  Future<void> start(
    double deviceWidth,
    double deviceHeight,
    bool saveBatteryModeEnabled,
    bool? isDarkMode, {
    bool freeRide = false,
  }) async {
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
    final profile = getIt<Profile>();

    final sessionId = const UuidV7().generate(); 

    try {
      Feature feature = getIt<Feature>();
      track = Track(
        uploaded: false,
        hasFileData: true,
        startTime: startTime,
        endTime: null,
        debug: kDebugMode,
        freeRide: freeRide,
        city: settings.city,
        backend: settings.city.selectedBackend(true),
        positioningMode: settings.positioningMode,
        userId: await User.getOrCreateId(),
        sessionId: sessionId,
        deviceType: deviceType,
        deviceWidth: deviceWidth,
        deviceHeight: deviceHeight,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        statusSummary: status.current!,
        taps: [],
        // Predictions will be empty using the free ride mode.
        predictionServicePredictions: [],
        // Can be empty if the free ride mode is selected.
        selectedWaypoints: routing.selectedWaypoints ?? [],
        bikeType: profile.bikeType,
        // Can be null if the free ride mode is selected.
        routes: routing.selectedRoute == null ? {} : {startTime: routing.selectedRoute!},
        subVersion: feature.buildTrigger,
        batteryStates: [],
        saveBatteryModeEnabled: saveBatteryModeEnabled,
        isDarkMode: isDarkMode,
      );
      // Add the track to the list of previous tracks and save it.
      previousTracks!.add(track!);
      await savePreviousTracks();
      // Start collecting data to the files of the track.
      await startCollectingGPSData();
      await sampleBatteryState();
      if (batterySamplingTimer == null || !batterySamplingTimer!.isActive) {
        batterySamplingTimer = Timer.periodic(const Duration(seconds: 60), (timer) async => await sampleBatteryState());
      }
    } catch (e, stacktrace) {
      final hint = "Could not start a new track: $e $stacktrace";
      log.e(hint);
      return end();
    }

    notifyListeners();
  }

  Future<void> sampleBatteryState() async {
    if (track == null) return;
    try {
      battery ??= Battery();
      final level = await battery!.batteryLevel;
      final batteryState = await battery!.batteryState;
      // When battery is full and charging, battery is full is returned.
      final isInBatterySaveMode = await battery!.isInBatterySaveMode;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      track!.batteryStates.add(
        BatteryHistory(
            level: level,
            timestamp: timestamp,
            batteryState: batteryState.toString(),
            isInBatterySaveMode: isInBatterySaveMode),
      );
    } catch (e, stacktrace) {
      log.e("Could not sample battery state: $e $stacktrace");
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
    track?.predictionServicePredictions = ride.predictionProvider?.predictionServicePredictions ?? [];

    batterySamplingTimer?.cancel();
    batterySamplingTimer = null;
    // Add the last battery state.
    await sampleBatteryState();
    battery = null;

    // Stop collecting data.
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
      if (!connectivityResult.contains(ConnectivityResult.wifi)) {
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

      if (track.endTime != null) {
        final trackDurationMinutes = (track.endTime! - track.startTime) / 1000 / 60;
        log.i("Track duration: ${trackDurationMinutes.round()} minutes.");
      } else {
        log.i("Track duration: unknown (app was terminated before ride finished).");
      }
      log.i("Sending ${(metadataBytes.length / 1000).round()} KB of gzipped track metadata.");
      log.i("Sending ${(gpsBytes.length / 1000).round()} KB of compressed GPS data.");

      // Skip tracks that are >50 MB, but mark them as sent so that they are not sent again.
      final totalSize = metadataBytes.length + gpsBytes.length;
      if (totalSize < 50 * 1000 * 1000) {
        final response = await Http.multipartPost(
          endpoint,
          fields: {},
          files: [metadataMF, gpsMF],
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
    if (await directory.exists()) await directory.delete(recursive: true);
    previousTracks?.removeWhere((t) => t.sessionId == track.sessionId);
    await savePreviousTracks();
    notifyListeners();
  }

  /// Delete all tracks.
  Future<void> deleteAllTracks() async {
    if (previousTracks != null || previousTracks!.isNotEmpty) {
      log.i("Deleting all tracks.");
      for (final Track track in previousTracks!) {
        final directory = await track.trackDirectory;
        if (await directory.exists()) await directory.delete(recursive: true);
      }
      previousTracks?.clear();
    }
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
