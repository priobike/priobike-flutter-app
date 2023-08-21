import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:flutter/material.dart';

class BackgroundImage with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("BackgroundImage");

  /// If the service is currently loading the status.
  bool isLoading = false;

  /// If the service had an error during the last request.
  bool hadError = false;

  /// If the service has loaded the status.
  bool hasLoaded = false;

  /// The cached images. The key is the sessionId of the route and the value is the backgroundimage of the map.
  Map<String, ImageProvider>? cachedImages = {};

  /// Loads the background image for the given route. Tries to load it from the cache first.
  Future<ImageProvider?> loadImage({
    required String sessionId,
    required double minLon,
    required double minLat,
    required double maxLon,
    required double maxLat,
    required int screenWidth,
    required Brightness brightness,
  }) async {
    if (cachedImages == null) {
      await loadAllImages();
    }
    if (cachedImages!.containsKey(sessionId)) {
      return cachedImages![sessionId];
    }
    return await fetchImage(
      sessionId: sessionId,
      minLon: minLon,
      minLat: minLat,
      maxLon: maxLon,
      maxLat: maxLat,
      screenWidth: screenWidth,
      brightness: brightness,
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
    required Brightness brightness,
  }) async {
    hadError = false;

    if (isLoading) return null;
    isLoading = true;
    hasLoaded = false;

    try {
      // For Styles see: https://docs.mapbox.com/api/maps/styles/
      // TODO: Style von Philipp nutzen
      final String style = brightness == Brightness.dark ? "navigation-night-v1" : "navigation-preview-day-v1";
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

      if (cachedImages == null) {
        await loadAllImages();
      }
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

  Future<void> saveImage(String sessionId, MemoryImage image) async {
    cachedImages![sessionId] = image;

    //TODO: save to local storage
  }

  Future<void> deleteImage() async {
    //TODO:
  }

  Future<void> saveAllImages() async {
    // TODO:
  }

  Future<void> loadAllImages() async {
    if (cachedImages != null) return;
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = "${dir.path}/background-images";
    final Directory imagesDir = Directory(path);
    if (!await imagesDir.exists()) {
      await imagesDir.create();
    }
    final List<FileSystemEntity> files = imagesDir.listSync();
    cachedImages = {};
    for (final file in files) {
      final String sessionId = file.path.split("/").last;
      // final bytes = await file.readAsBytes();
      // final image = MemoryImage(bytes);
      // cachedImages![sessionId] = image;
      //TODO: finish
    }
  }
}
