import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapboxTileImageCache {
  /// The logger for this service.
  static final log = Logger("MapboxTileImageCache");

  /// Current ongoing fetches of tiles, keys are the bounding boxes as strings.
  static Map<String, Future<MemoryImage?>> ongoingFetches = {};

  /// Requests the tile.
  static Future<MemoryImage?> requestTile({
    required List<LatLng> coords,
    required Brightness brightness,
    String? styleUri,
    double heightRatio = 1,
    double widthRatio = 1,
  }) async {
    final bbox = MapboxMapProjection.mercatorBoundingBox(coords);
    if (bbox == null) return null;
    final imageName = _getImageName(bbox, brightness, styleUri);

    // Check if we are currently already fetching the image.
    if (MapboxTileImageCache.ongoingFetches.containsKey(imageName)) {
      return MapboxTileImageCache.ongoingFetches[imageName];
    } else {
      // Fetch the image.
      final Future<MemoryImage?> fetch = MapboxTileImageCache._fetchTile(
          bbox: bbox, brightness: brightness, styleUri: styleUri, heightRatio: heightRatio, widthRatio: widthRatio);
      MapboxTileImageCache.ongoingFetches[imageName] = fetch;
      final MemoryImage? image = await fetch;
      MapboxTileImageCache.ongoingFetches.remove(imageName);
      return image;
    }
  }

  /// Fetches the background image for the given route from the mapbox api (or if available loads it from the cache).
  static Future<MemoryImage?> _fetchTile({
    required MapboxMapProjectionBoundingBox bbox,
    required Brightness brightness,
    String? styleUri,
    double heightRatio = 1,
    double widthRatio = 1,
  }) async {
    // Check if the image exists, and if so, return it.
    final path = await _getImagePath(bbox, brightness, styleUri);
    if (await File(path).exists()) return MemoryImage(await File(path).readAsBytes());

    try {
      // See: https://docs.mapbox.com/api/maps/static-images/
      const accessToken =
          "access_token=pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA";
      String styleId = "";
      // remove prefix "mapbox://styles/" from the styles
      if (styleUri != null) {
        styleId = styleUri.replaceFirst("mapbox://styles/", "");
      } else {
        styleId = brightness == Brightness.dark
            ? MapDesign.standard.darkStyle.replaceFirst("mapbox://styles/", "")
            : MapDesign.standard.lightStyle.replaceFirst("mapbox://styles/", "");
      }
      final bboxStr = "[${bbox.minLon},${bbox.minLat},${bbox.maxLon},${bbox.maxLat}]";
      // we display the logo and attribution, so we can hide it in the image

      // The background image that should be displayed in the feedback view.
      final feedbackUrl =
          "https://api.mapbox.com/styles/v1/$styleId/static/$bboxStr/${(1000 * widthRatio).toInt()}x${(1000 * heightRatio).toInt()}/?attribution=false&logo=false&$accessToken";
      final feedbackEndpoint = Uri.parse(feedbackUrl);
      final feedbackResponse = await Http.get(feedbackEndpoint).timeout(const Duration(seconds: 4));
      if (feedbackResponse.statusCode != 200) {
        final err = "Error while fetching background image status from Mapbox: ${feedbackResponse.statusCode}";
        throw Exception(err);
      }

      // the background image that should be cached and displayed in the all rides view.
      final cacheUrl =
          "https://api.mapbox.com/styles/v1/$styleId/static/$bboxStr/1000x1000/?attribution=false&logo=false&$accessToken";

      // Use Cache url when height or width ratio is given.
      final endpoint = Uri.parse(heightRatio != 1 || widthRatio != 1 ? cacheUrl : feedbackUrl);

      // Only run if ratios differ. Otherwise we would make the same request.
      final cacheResponse = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (cacheResponse.statusCode != 200) {
        final err = "Error while fetching background image status from Mapbox: ${cacheResponse.statusCode}";
        throw Exception(err);
      }

      final cachedImage = MemoryImage(cacheResponse.bodyBytes);
      log.i("Fetched background image from Mapbox");
      await saveImage(bbox, cachedImage, brightness, styleUri);

      final MemoryImage feedbackImage = MemoryImage(feedbackResponse.bodyBytes);

      log.i("Fetched background image from Mapbox");

      // save timestamp of last fetch to shared preferences, used in pruning of old images
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("priobike.backgroundimage.lastfetch", DateTime.now().millisecondsSinceEpoch);

      return feedbackImage;
    } catch (e) {
      log.e("Error while fetching background-image-service: $e");
      return null;
    }
  }

  /// Helper function to get the path to the background images on local storage.
  static Future<String> _getImageDir() async {
    return "${(await getApplicationDocumentsDirectory()).path}/background-images";
  }

  /// Helper function to get the path to the background images on local storage.
  static Future<String> _getImagePath(
      MapboxMapProjectionBoundingBox bbox, Brightness brightness, String? styleUri) async {
    final dirPath = await _getImageDir();
    final imagesDir = Directory(dirPath);
    if (!await imagesDir.exists()) await imagesDir.create();
    return "$dirPath/${_getImageName(bbox, brightness, styleUri)}";
  }

  /// Helper function to get the image name.
  static String _getImageName(MapboxMapProjectionBoundingBox bbox, Brightness brightness, String? styleUri) {
    final brightnessKey = brightness == Brightness.light ? "light" : "dark";
    if (styleUri != null) {
      final styleId = styleUri.replaceFirst("mapbox://styles/", "").replaceAll("/", "");
      return "${bbox.minLat}_${bbox.minLon}_${bbox.maxLat}_${bbox.maxLon}+$brightnessKey+$styleId.png";
    }
    return "${bbox.minLat}_${bbox.minLon}_${bbox.maxLat}_${bbox.maxLon}+$brightnessKey.png";
  }

  /// Saves the given image to the cache and the local storage.
  static Future<void> saveImage(
      MapboxMapProjectionBoundingBox bbox, MemoryImage image, Brightness brightness, String? styleUri) async {
    final path = await _getImagePath(bbox, brightness, styleUri);
    final file = File(path);
    await file.writeAsBytes(image.bytes);
    log.i("Saved image $path to local storage.");
  }

  /// Deletes all images from the cache and the local storage.
  static Future<void> deleteAllImages() async {
    final dirPath = await _getImageDir();
    final imagesDir = Directory(dirPath);
    if (!await imagesDir.exists()) return;
    await imagesDir.delete(recursive: true);
    log.i("Deleted all images from $dirPath");
    ToastMessage.showSuccess("Alle Hintergrundbilder gelöscht");
  }

  /// Prunes all images that were not used within 7 days since last fetch of background image.
  /// Gets called during app launch.
  static Future<void> pruneUnusedImages() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lastFetch = prefs.getInt("priobike.backgroundimage.lastfetch");
    if (lastFetch == null) return;

    final dirPath = await _getImageDir();
    final imagesDir = Directory(dirPath);
    if (!await imagesDir.exists()) return;

    final files = await imagesDir.list().toList();
    for (final FileSystemEntity file in files) {
      final path = file.path;
      final stat = await file.stat();
      final lastAccessed = stat.accessed.millisecondsSinceEpoch;
      if ((lastFetch - lastAccessed) > (7 * 24 * 60 * 60 * 1000)) {
        try {
          await file.delete();
        } catch (e) {
          log.e("Tried to delete unused image from $path, but failed: $e");
        }
        log.i("Deleted unused image from $path");
      }
    }
  }

  /// Returns the size in bytes of all images in the local storage.
  static Future<int> calculateTotalSize() async {
    final dirPath = await _getImageDir();
    final imagesDir = Directory(dirPath);
    if (!await imagesDir.exists()) return 0;

    final files = await imagesDir.list().toList();
    int size = 0;
    for (final FileSystemEntity file in files) {
      if (file is File && file.path.endsWith(".png")) {
        final stat = await file.stat();
        size += stat.size;
      }
    }
    return size;
  }
}
