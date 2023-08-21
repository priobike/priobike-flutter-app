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

  Future<ImageProvider?> loadImage(
      {required double minLon, required double minLat, required double maxLon, required double maxLat}) async {
    //TODO: Check if image is cached, if not fetchImage
    return await fetchImage(minLon: minLon, minLat: minLat, maxLon: maxLon, maxLat: maxLat);
  }

  Future<MemoryImage?> fetchImage(
      {required double minLon, required double minLat, required double maxLon, required double maxLat}) async {
    hadError = false;

    if (isLoading) return null;
    isLoading = true;
    hasLoaded = false;

    try {
      // For Styles see: https://docs.mapbox.com/api/maps/styles/
      const String style = "satellite-v9";
      final String url =
          "https://api.mapbox.com/styles/v1/mapbox/$style/static/[$minLon,$minLat,$maxLon,$maxLat]/1000x1000?padding=0&@2x&access_token=pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA";
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
      notifyListeners();
      return image;
    } catch (e) {
      isLoading = false;
      hadError = true;
      notifyListeners();
      log.e("Error while fetching background-image-service: $e");
      return null;
    }

    //TODO: safe to cache....vllt als Map mit SessionId als Key und dem Bild als Value
  }

  saveImage() {
    //TODO:
  }

  deleteImage() {
    //TODO:
  }

  clearAllImages() {
    //TODO:
  }
}
