import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:flutter/material.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:proj4dart/proj4dart.dart';

class TrackPictogramImageCache {
  /// The logger for this service.
  static final log = Logger("TrackPictogramImageCache");

  static var projMercator = Projection.get('EPSG:3857')!;
  static var projWGS84 = Projection.get('EPSG:4326')!;

  /// Convert lat and lon to Mercator coordinates (absolute, not in relation to screen).
  static Point convertLatLonToMercator(double lat, double lon) {
    return projWGS84.transform(projMercator, Point(x: lon, y: lat));
  }

  /// Convert Mercator coordinates to lat and lon.
  static LatLng convertMercatorToLatLon(double x, double y) {
    final point = projMercator.transform(projWGS84, Point(x: x, y: y));
    return LatLng(point.y, point.x);
  }

  /// Fetches the background image for the given route from the mapbox api.
  static Future<MemoryImage?> fetchImage({
    required String sessionId,
    required List<Position> positions, // The GPS positions of the track
  }) async {
    double? minLon;
    double? minLat;
    double? maxLon;
    double? maxLat;

    // calculate the bounding box of the route
    for (final position in positions) {
      if (minLon == null || position.longitude < minLon) minLon = position.longitude;
      if (minLat == null || position.latitude < minLat) minLat = position.latitude;
      if (maxLon == null || position.longitude > maxLon) maxLon = position.longitude;
      if (maxLat == null || position.latitude > maxLat) maxLat = position.latitude;
    }

    if (minLon == null || minLat == null || maxLon == null || maxLat == null) return null;
    if (minLon == maxLon || minLat == maxLat) return null;

    final minM = convertLatLonToMercator(minLat, minLon);
    final maxM = convertLatLonToMercator(maxLat, maxLon);

    double minMx = minM.x;
    double minMy = minM.y;
    double maxMx = maxM.x;
    double maxMy = maxM.y;

    final dBeta = maxMx - minMx;
    final dAlpha = maxMy - minMy;
    if (dAlpha > dBeta) {
      final d = (dAlpha - dBeta) / 2;
      minMx -= d;
      maxMx += d;
    } else {
      final d = (dBeta - dAlpha) / 2;
      minMy -= d;
      maxMy += d;
    }

    // Convert back to lat/lon.
    final paddedMin = convertMercatorToLatLon(minMx, minMy);
    final paddedMax = convertMercatorToLatLon(maxMx, maxMy);

    // Check if the image exists, and if so, return it.
    final path = await _getImagePath(sessionId: sessionId);
    if (await File(path).exists()) {
      log.i("Fetched background image $sessionId from local storage.");
      return MemoryImage(await File(path).readAsBytes());
    }

    log.i("Fetching background image $sessionId from Mapbox.");
    try {
      // See: https://docs.mapbox.com/api/maps/static-images/
      const String accessToken =
          "access_token=pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA";
      final ColorMode colorMode = getIt<Settings>().colorMode;
      final String styleId = colorMode == ColorMode.dark
          // remove prefix "mapbox://styles/" from the styles
          ? getIt<MapDesigns>().mapDesign.darkStyle.replaceFirst("mapbox://styles/", "")
          : getIt<MapDesigns>().mapDesign.lightStyle.replaceFirst("mapbox://styles/", "");
      final String bbox = "[${paddedMin.longitude},${paddedMin.latitude},${paddedMax.longitude},${paddedMax.latitude}]";
      // we display the logo and attribution, so we can hide it in the image
      final String url =
          "https://api.mapbox.com/styles/v1/$styleId/static/$bbox/500x500/?attribution=false&logo=false&$accessToken";
      log.i("Fetching background image $sessionId from Mapbox: $url");
      final endpoint = Uri.parse(url);
      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Error while fetching background image status from Mapbox: ${response.statusCode}";
        throw Exception(err);
      }
      final MemoryImage image = MemoryImage(response.bodyBytes);

      log.i("Fetched background image $sessionId from Mapbox.");
      await saveImage(sessionId, image);
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
  static Future<String> _getImagePath({required String sessionId}) async {
    final colorMode = getIt<Settings>().colorMode;
    final dirPath = await _getImageDir();
    final imagesDir = Directory(dirPath);
    if (!await imagesDir.exists()) await imagesDir.create();
    return "$dirPath/$sessionId+${colorMode.toString()}.png";
  }

  /// Saves the given image to the cache and the local storage.
  static Future<void> saveImage(String sessionId, MemoryImage image) async {
    final path = await _getImagePath(sessionId: sessionId);
    final file = File(path);
    await file.writeAsBytes(image.bytes);
    log.i("Saved image $path to local storage.");
  }

  /// Deletes the given image from the cache and the local storage.
  static Future<void> deleteImage(String sessionId) async {
    final path = await _getImagePath(sessionId: sessionId);
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
