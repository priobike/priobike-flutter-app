import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/hybrid_predictor.dart';
import 'package:priobike/ride/services/prediction_service.dart';
import 'package:priobike/ride/services/predictor.dart';
import 'package:priobike/ride/services/ride.dart';
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

  /// The size of the sliding window for the accelerometer data.
  int accWindowSize = 10;

  /// The size of the sliding window for the accelerometer data.
  int gyrWindowSize = 10;

  /// The size of the sliding window for the accelerometer data.
  int magWindowSize = 10;

  /// The sliding window for the accelerometer data.
  Queue<(double, double, double)> accWindow = Queue<(double, double, double)>();

  /// The sliding window for the gyroscope data.
  Queue<(double, double, double)> gyrWindow = Queue<(double, double, double)>();

  /// The sliding window for the magnetometer data.
  Queue<(double, double, double)> magWindow = Queue<(double, double, double)>();

  /// The moving average of the accelerometer data.
  (double, double, double) accAvg = (0.0, 0.0, 0.0);

  /// The moving average of the gyroscope data.
  (double, double, double) gyrAvg = (0.0, 0.0, 0.0);

  /// The moving average of the magnetometer data.
  (double, double, double) magAvg = (0.0, 0.0, 0.0);

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
      await startCollectingAccData();
      await startCollectingGyrData();
      await startCollectingMagData();
      if (sensorSamplingTimer == null || !sensorSamplingTimer!.isActive) {
        sensorSamplingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async => await sampleSensorData());
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
      accWindow.addLast((latestAccEvent!.x, latestAccEvent!.y, latestAccEvent!.z));
      if (accWindow.length > accWindowSize) {
        accWindow.removeFirst();
      }
      double sumX = 0.0, sumY = 0.0, sumZ= 0.0;
      for (var tup in accWindow) {
        sumX += tup.$1;
        sumY += tup.$2;
        sumZ += tup.$3;
      }
      accAvg = (sumX / accWindow.length, sumY / accWindow.length, sumZ / accWindow.length);
      await accCache?.add("$latestAccEventTimestamp,${accAvg.$1},${accAvg.$2},${accAvg.$3}");
    }
    if (latestGyroEvent != null && latestGyroEventTimestamp != null) {
      gyrWindow.addLast((latestGyroEvent!.x, latestGyroEvent!.y, latestGyroEvent!.z));
      if (gyrWindow.length > gyrWindowSize) {
        gyrWindow.removeFirst();
      }
      double sumX = 0.0, sumY = 0.0, sumZ= 0.0;
      for (var tup in gyrWindow) {
        sumX += tup.$1;
        sumY += tup.$2;
        sumZ += tup.$3;
      }
      gyrAvg = (sumX / gyrWindow.length, sumY / gyrWindow.length, sumZ / gyrWindow.length);
      await gyrCache?.add("$latestGyroEventTimestamp,${gyrAvg.$1},${gyrAvg.$2},${gyrAvg.$3}");
    }
    if (latestMagEvent != null && latestMagEventTimestamp != null) {
      magWindow.addLast((latestMagEvent!.x, latestMagEvent!.y, latestMagEvent!.z));
      if (magWindow.length > magWindowSize) {
        magWindow.removeFirst();
      }
      double sumX = 0.0, sumY = 0.0, sumZ= 0.0;
      for (var tup in magWindow) {
        sumX += tup.$1;
        sumY += tup.$2;
        sumZ += tup.$3;
      }
      magAvg = (sumX / magWindow.length, sumY / magWindow.length, sumZ / magWindow.length);
      await magCache?.add("$latestMagEventTimestamp,${magAvg.$1},${magAvg.$2},${magAvg.$3}");
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
  Future<void> startCollectingAccData() async {
    // Note: The sampling period is a recommendation and can diverge from the actual period.
    const samplingPeriod = Duration(milliseconds: 20);
    final stream = accelerometerEventStream(samplingPeriod: samplingPeriod);
    accCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track!.accelerometerCSVFile,
      maxLines: 5, // Flush after 5 lines of data (~5s).
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
  Future<void> startCollectingGyrData() async {
    // Note: The sampling period is a recommendation and can diverge from the actual period.
    const samplingPeriod = Duration(milliseconds: 20);
    final stream = gyroscopeEventStream(samplingPeriod: samplingPeriod);
    gyrCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track!.gyroscopeCSVFile,
      maxLines: 5, // Flush after 5 lines of data (~5s).
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
  Future<void> startCollectingMagData() async {
    // Note: The sampling period is a recommendation and can diverge from the actual period.
    const samplingPeriod = Duration(milliseconds: 20);
    final stream = magnetometerEventStream(samplingPeriod: samplingPeriod);
    magCache = CSVCache(
      header: "timestamp,x,y,z",
      file: await track!.magnetometerCSVFile,
      maxLines: 5, // Flush after 5 lines of data (~5s).
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

    // Open sensor data CSV files and convert them to a usable format.
    if (gpsCache != null && accCache != null && gyrCache != null && magCache != null) {
      // gps
      final gpsCsvList = await gpsCache!.file.openRead()
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(fieldDelimiter: ',', eol: '\n'))
          .toList();
      gpsCsvList.removeAt(0); // remove header: timestamp, x, y, z
      List<(int, double, double, double)> gpsList = [];
      for (final line in gpsCsvList) {
        int timestamp = line[0];
        double x = line[1];
        double y = line[2];
        double z = line[3];
        gpsList.add((timestamp, x, y, z));
      }

      // accelerometer
      final accCsvList = await accCache!.file.openRead()
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(fieldDelimiter: ',', eol: '\n'))
          .toList();
      List<(int, double, double, double)> accList = [];
      for (final line in accCsvList) {
        try {
          int timestamp = line[0];
          double x = line[1];
          double y = line[2];
          double z = line[3];
          accList.add((timestamp, x, y, z));
        } catch (_, __) {
          continue;
        }
      }

      // Kalman
      int currentGpsIndex = 1;
      int currentAccIndex = 1;
      double v = 0.0; // v0
      double b = 9.809; // b0
      const double qV = 1.0;
      const double qA = 0.01;
      const double Q00 = qV;
      const double Q01 = 0.0;
      const double Q10 = 0.0;
      const double Q11 = qA;
      double P00_ = Q00;
      double P01_ = Q01;
      double P10_ = Q10;
      double P11_ = Q11;
      double v_ = 0.0;
      // double b_ = 0.0;
      double deltaT;
      List<(int, double)> vs = [];
      while (currentGpsIndex < gpsList.length && currentAccIndex < accList.length) {
        int accTimestamp = accList[currentAccIndex].$1;
        try {
          int newGpsTimestamp = gpsList[currentGpsIndex + 1].$1;
          if (newGpsTimestamp <= accTimestamp) {
            currentGpsIndex++;
          }
        } catch(_, __) {}

        deltaT = (accList[currentAccIndex].$1 - accList[currentAccIndex - 1].$1) / 1000.0;
        const double A00 = 1.0;
        final double A01 = -deltaT;
        const double A10 = 0.0;
        const double A11 = 1.0;
        final double a = sqrt(pow(accList[currentAccIndex].$2, 2) + pow(accList[currentAccIndex].$3, 2) + pow(accList[currentAccIndex].$4, 2)); // root-mean-square of accelerometer
        // X(k|k-1) = A * X (k-1|k-1) + B * U
        v_ = v + (a - b) * deltaT;
        // b is regarded as constant
        // P(k|k-1) = A * P * A^t + Q
        double P00 = A00 * (A00 * P00_ + A01 * P10_) + A01 * (A00 * P01_ + A01 * P11_) + Q00;
        double P01 = A10 * (A00 * P00_ + A01 * P10_) + A11 * (A00 * P01_ + A01 * P11_) + Q01;
        double P10 = A00 * (A10 * P00_ + A11 * P10_) + A01 * (A10 * P01_ + A11 * P11_) + Q10;
        double P11 = A10 * (A10 * P00_ + A11 * P10_) + A11 * (A10 * P01_ + A11 * P11_) + Q11;

        // G = P(k|k-1) * H^t / (H * P(k|k-1) * H^t + Q)
        double G0 = 1 / (P00 + qV) * P00;
        // double G1 = 1 / (P00 + qV) * P10;

        // X(k|k) = X(k|k-1) + G * (gpsSpeed - H * X(k|k-1))
        v = v_ + G0 * (gpsList[currentGpsIndex].$4 - v_);
        vs.add((accTimestamp, v));
        // b is regarded as constant

        // P(k|k) = (I - G * H) * P(k|k-1)
        double denominator = P00 + qV;
        P00_ = P00 - P00 * P00 / denominator;
        P01_ = P01 - P00 * P01 / denominator;
        P10_ = P10 - P00 * P10 / denominator;
        P11_ = P11 - P01 * P10 / denominator;

        currentAccIndex++;
      }
      // TODO analyse user behaviour
      // TODO overwrite speed in GPS_CSV with Kalman result

      // sub-sample accelerometer data
      int subSamplingIndex = 0;
      int subSamplingModulus = 50;
      accCache!.file.writeAsString('timestamp,x,y,z\n'); // clear file and write header
      for (final line in accList) {
        if (subSamplingIndex == 0) await accCache!.file.writeAsString('${line.$1},${line.$2},${line.$3},${line.$4}\n', mode: FileMode.append, flush: true);
        subSamplingIndex = (subSamplingIndex + 1) % subSamplingModulus;
      }

      // gyroscope
      final gyrCsvList = await gyrCache!.file.openRead()
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(fieldDelimiter: ',', eol: '\n'))
          .toList();
      List<(int, double, double, double)> gyrList = [];
      for (final line in gyrCsvList) {
        try {
          int timestamp = line[0];
          double x = line[1];
          double y = line[2];
          double z = line[3];
          gyrList.add((timestamp, x, y, z));
        } catch (_, __) {}
      }

      // sub-sample gyroscope data
      subSamplingIndex = 0;
      gyrCache!.file.writeAsString('timestamp,x,y,z\n'); // clear file and write header
      for (final line in gyrList) {
        if (subSamplingIndex == 0) await gyrCache!.file.writeAsString('${line.$1},${line.$2},${line.$3},${line.$4}\n', mode: FileMode.append, flush: true);
        subSamplingIndex = (subSamplingIndex + 1) % subSamplingModulus;
      }

      // magnetometer
      final magCsvList = await magCache!.file.openRead()
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(fieldDelimiter: ',', eol: '\n'))
          .toList();
      magCsvList.removeAt(0); // remove header: timestamp, x, y, z
      List<(int, double, double, double)> magList = [];
      for (final line in magCsvList) {
        try {
          int timestamp = line[0];
          double x = line[1];
          double y = line[2];
          double z = line[3];
          magList.add((timestamp, x, y, z));
        } catch (_, __) {}
      }

      // sub-sample magnetometer data
      subSamplingIndex = 0;
      magCache!.file.writeAsString('timestamp,x,y,z\n'); // clear file and write header
      for (final line in magList) {
        if (subSamplingIndex == 0) await magCache!.file.writeAsString('${line.$1},${line.$2},${line.$3},${line.$4}\n', mode: FileMode.append, flush: true);
        subSamplingIndex = (subSamplingIndex + 1) % subSamplingModulus;
      }
    }

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
