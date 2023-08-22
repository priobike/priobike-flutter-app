import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/settings.dart';

class BackgroundImage with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("BackgroundImage");

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// If the service has loaded the status.
  bool hasLoaded = false;

  /// The cached images. The key is the sessionId of the route + light/dark mode
  /// and the value is the backgroundimage of the map.
  Map<String, MemoryImage>? cachedImages = {};

  /// Loads the background image for the given route. Tries to load it from the cache first.
  Future<ImageProvider?> loadImage({
    required String sessionId,
    required double minLon,
    required double minLat,
    required double maxLon,
    required double maxLat,
    required int screenWidth,
  }) async {
    if (cachedImages == null || cachedImages!.isEmpty) await loadAllImages();

    final ColorMode colorMode = getIt<Settings>().colorMode;

    // load from cache preferentially
    log.i("Loading image $sessionId+${colorMode.toString()}.");
    if (cachedImages!.containsKey("$sessionId+${colorMode.toString()}")) {
      log.i("Found image $sessionId+${colorMode.toString()} in cache.");
      return cachedImages!["$sessionId+${colorMode.toString()}"];
    }
    return await fetchImage(
      sessionId: sessionId,
      minLon: minLon,
      minLat: minLat,
      maxLon: maxLon,
      maxLat: maxLat,
      screenWidth: screenWidth,
    );
  }

  /// Fetches the background image for the given route from the mapbox api.
  Future<MemoryImage?> fetchImage({
    required String sessionId,
    required double minLon,
    required double minLat,
    required double maxLon,
    required double maxLat,
    required int screenWidth,
  }) async {
    hadError = false;

    if (isLoading) return null;
    isLoading = true;
    hasLoaded = false;

    try {
      // For Styles see: https://docs.mapbox.com/api/maps/styles/
      // TODO: Style von Philipp nutzen
      final ColorMode colorMode = getIt<Settings>().colorMode;
      final String style = colorMode == ColorMode.dark ? "navigation-night-v1" : "navigation-preview-day-v1";
      // use screen size
      final String url =
          "https://api.mapbox.com/styles/v1/mapbox/$style/static/[$minLon,$minLat,$maxLon,$maxLat]/${screenWidth}x$screenWidth?padding=0&@2x&access_token=pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA";
      final endpoint = Uri.parse(url);
      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        isLoading = false;
        final err = "Error while fetching background image status from Mapbox: ${response.statusCode}";
        throw Exception(err);
      }
      final image = MemoryImage(response.bodyBytes);

      isLoading = false;
      hadError = false;
      hasLoaded = true;
      log.i("Fetched background image $sessionId from Mapbox.");
      await saveImage(sessionId, image);
      notifyListeners();
      return image;
    } catch (e) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      log.e("Error while fetching background-image-service: $e");
      return null;
    }
  }

  /// Helper function to get the path to the local storage.
  Future<String> _getPath() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = "${dir.path}/background-images";
    final Directory imagesDir = Directory(path);
    if (!await imagesDir.exists()) await imagesDir.create();
    return path;
  }

  /// Saves the given image to the cache and the local storage.
  Future<void> saveImage(String sessionId, MemoryImage image) async {
    if (cachedImages == null) await loadAllImages();

    final ColorMode colorMode = getIt<Settings>().colorMode;
    cachedImages!["$sessionId+${colorMode.toString()}"] = image;
    final String path = await _getPath();
    final File file = File("$path/$sessionId+${colorMode.toString()}.png");
    await file.writeAsBytes(image.bytes);
    log.i("Saved image $sessionId+${colorMode.toString()}.png to local storage.");
    notifyListeners();
  }

  /// Deletes the given image from the cache and the local storage.
  Future<void> deleteImage(String sessionId) async {
    if (cachedImages == null) return;
    if (cachedImages!.isEmpty) return;

    final ColorMode colorMode = getIt<Settings>().colorMode;
    cachedImages!.remove("$sessionId+${colorMode.toString()}");
    final String path = await _getPath();
    final File file = File("$path/$sessionId+${colorMode.toString()}.png");
    await file.delete();
    log.i("Deleted image from $path/$sessionId+${colorMode.toString()}.png");
    notifyListeners();
  }

  /// Saves all images from the cache to the local storage.
  Future<void> saveAllImages() async {
    if (cachedImages == null) return;

    // SessionId already contains the colorMode
    for (final sessionId in cachedImages!.keys) {
      final MemoryImage image = cachedImages![sessionId]!;
      final String path = await _getPath();
      final File file = File("$path/$sessionId.png");
      await file.writeAsBytes(image.bytes);
    }
    log.i("Saved all images to local storage.");
    notifyListeners();
  }

  /// Loads all images from the local storage to the cache.
  Future<void> loadAllImages() async {
    final String path = await _getPath();
    final Directory imagesDir = Directory(path);
    final List<FileSystemEntity> files = imagesDir.listSync();
    cachedImages = {};
    List<String> sessionIds = [];
    for (final file in files) {
      if (file is File && file.path.endsWith(".png")) {
        // turns "save/data/user/0/de.tudresden.priobike/app_flutter/background-images/[#13a7f]+ColorMode.light.png"
        // into "#13a7f+ColorMode.light"
        final String fileName = file.path.split("/").last;
        final String sessionId = fileName.substring(0, fileName.length - 4);
        final MemoryImage image = MemoryImage(await file.readAsBytes());
        cachedImages![sessionId] = image;
        sessionIds.add(sessionId);
      }
    }
    log.i("Loaded images from local storage: $sessionIds");
    notifyListeners();
  }

  /// Calculates the total size in bytes of all images in the local storage.
  Future<int> calculateStorageSize() async {
    final String path = await _getPath();
    final Directory imagesDir = Directory(path);
    final List<FileSystemEntity> files = imagesDir.listSync();
    int size = 0;
    for (final file in files) {
      if (file is File && file.path.endsWith(".png")) {
        size += await file.length();
      }
    }
    return size;
  }

  /// Deletes all images from the cache and the local storage.
  Future<void> deleteAllImages() async {
    cachedImages = {};
    final String path = await _getPath();
    final Directory imagesDir = Directory(path);
    final List<FileSystemEntity> files = imagesDir.listSync();
    for (final file in files) {
      if (file is File && file.path.endsWith(".png")) {
        await file.delete();
      }
    }
    log.i("Deleted all images from local storage.");
    notifyListeners();
  }
}
