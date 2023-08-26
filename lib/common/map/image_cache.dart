import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/settings.dart';

class MapboxTileImageCache {
  /// The logger for this service.
  static final log = Logger("MapboxTileImageCache");

  // TODO: Make a loop that periodically checks how frequently each
  // image was used and deletes the least used ones. This loop is then
  // executed when the app is launched.

  /// Fetches the background image for the given route from the mapbox api.
  static Future<MemoryImage?> fetchTile({required List<LatLng> coords}) async {
    final bbox = MapboxMapProjection.mercatorBoundingBox(coords);
    if (bbox == null) {
      return null;
    }

    // Check if the image exists, and if so, return it.
    final path = await _getImagePath(bbox);
    if (await File(path).exists()) {
      return MemoryImage(await File(path).readAsBytes());
    }

    try {
      // See: https://docs.mapbox.com/api/maps/static-images/
      const String accessToken =
          "access_token=pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA";
      final ColorMode colorMode = getIt<Settings>().colorMode;
      final String styleId = colorMode == ColorMode.dark
          // remove prefix "mapbox://styles/" from the styles
          ? getIt<MapDesigns>().mapDesign.darkStyle.replaceFirst("mapbox://styles/", "")
          : getIt<MapDesigns>().mapDesign.lightStyle.replaceFirst("mapbox://styles/", "");
      final String bboxStr = "[${bbox.minLon},${bbox.minLat},${bbox.maxLon},${bbox.maxLat}]";
      // we display the logo and attribution, so we can hide it in the image
      final String url =
          "https://api.mapbox.com/styles/v1/$styleId/static/$bboxStr/1000x1000/?attribution=false&logo=false&$accessToken";
      log.i("Fetching background image from Mapbox: $url");
      final endpoint = Uri.parse(url);
      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Error while fetching background image status from Mapbox: ${response.statusCode}";
        throw Exception(err);
      }
      final MemoryImage image = MemoryImage(response.bodyBytes);

      log.i("Fetched background image from Mapbox.");
      await saveImage(bbox, image);
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
  static Future<String> _getImagePath(MapboxMapProjectionBoundingBox bbox) async {
    final colorMode = getIt<Settings>().colorMode;
    final dirPath = await _getImageDir();
    final imagesDir = Directory(dirPath);
    if (!await imagesDir.exists()) await imagesDir.create();
    return "$dirPath/${bbox.minLat}_${bbox.minLon}_${bbox.maxLat}_${bbox.maxLon}+${colorMode.toString()}.png";
  }

  /// Saves the given image to the cache and the local storage.
  static Future<void> saveImage(MapboxMapProjectionBoundingBox bbox, MemoryImage image) async {
    final path = await _getImagePath(bbox);
    final file = File(path);
    await file.writeAsBytes(image.bytes);
    log.i("Saved image $path to local storage.");
  }

  /// Deletes the given image from the cache and the local storage.
  static Future<void> deleteImage(MapboxMapProjectionBoundingBox bbox) async {
    final path = await _getImagePath(bbox);
    final file = File(path);
    try {
      await file.delete();
      log.i("Deleted image from $path");
    } catch (e) {
      log.e("Error while deleting image from $path: $e");
    }
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
}
