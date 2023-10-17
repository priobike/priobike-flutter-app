import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
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
  }) async {
    final bbox = MapboxMapProjection.mercatorBoundingBox(coords);
    if (bbox == null) return null;
    final imageName = _getImageName(bbox, brightness, styleUri);

    // Check if we are currently already fetching the image.
    if (MapboxTileImageCache.ongoingFetches.containsKey(imageName)) {
      return MapboxTileImageCache.ongoingFetches[imageName];
    } else {
      // Fetch the image.
      final Future<MemoryImage?> fetch =
          MapboxTileImageCache._fetchTile(bbox: bbox, brightness: brightness, styleUri: styleUri);
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
            ? getIt<MapDesigns>().mapDesign.darkStyle.replaceFirst("mapbox://styles/", "")
            : getIt<MapDesigns>().mapDesign.lightStyle.replaceFirst("mapbox://styles/", "");
      }
      final bboxStr = "[${bbox.minLon},${bbox.minLat},${bbox.maxLon},${bbox.maxLat}]";
      // we display the logo and attribution, so we can hide it in the image
      final url =
          "https://api.mapbox.com/styles/v1/$styleId/static/$bboxStr/1000x1000/?attribution=false&logo=false&$accessToken";
      final endpoint = Uri.parse(url);
      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Error while fetching background image status from Mapbox: ${response.statusCode}";
        throw Exception(err);
      }
      final MemoryImage image = MemoryImage(response.bodyBytes);

      log.i("Fetched background image from Mapbox: $url");
      await saveImage(bbox, image, brightness, styleUri);

      // save timestamp of last fetch to shared preferences, used in pruning of old images
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("priobike.backgroundimage.lastfetch", DateTime.now().millisecondsSinceEpoch);

      return image;
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
