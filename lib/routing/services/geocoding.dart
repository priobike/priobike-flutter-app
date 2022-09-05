import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/messages/nominatim.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class GeocodingService with ChangeNotifier {
  /// The logger for this service.
  final Logger log = Logger("GeocodingService");

  /// The HTTP client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// A boolean indicating if the service is currently loading an address.
  bool isFetchingAddress = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  GeocodingService() {
    log.i("GeocodingService started.");
  }

  /// Fetch the address to a given coordinate.
  /// See: https://nominatim.org/release-docs/develop/api/Reverse/
  Future<String?> reverseGeocode(BuildContext context, LatLng coordinate) async {
    if (isFetchingAddress) return null;

    isFetchingAddress = true;
    notifyListeners();

    hadErrorDuringFetch = false;
 
    try {
      final settings = Provider.of<SettingsService>(context, listen: false);
      final baseUrl = settings.backend.path;
      var url = "https://$baseUrl/nominatim/reverse";
      url += "?accept-language=de";
      url += "&lat=${coordinate.latitude}";
      url += "&lon=${coordinate.longitude}";
      url += "&format=json";
      url += "&zoom=18";
      url += "&addressdetails=1";
      url += "&extratags=1";
      url += "&namedetails=1";
      url += "&polygon_geojson=1";
      final endpoint = Uri.parse(url);

      final response = await httpClient.get(endpoint);
      if (response.statusCode != 200) {
        isFetchingAddress = false;
        notifyListeners();
        final err = "Address could not be fetched from $endpoint: ${response.body}";
        log.e(err); ToastMessage.showError(err); throw Exception(err);
      }

      final decoded = json.decode(response.body);
      final geocodeResponse = NominatimReverseResponse.fromJson(decoded);

      isFetchingAddress = false;
      hadErrorDuringFetch = false;
      notifyListeners();
      return geocodeResponse.displayName;
    } catch (error, stacktrace) { 
      log.e("Error during reverse geocode: $error $stacktrace");
      isFetchingAddress = false;
      hadErrorDuringFetch = true;
      notifyListeners();
      return null;
    }
  }
}