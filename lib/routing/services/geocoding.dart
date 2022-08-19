import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/service.dart';
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
  /// See: https://docs.graphhopper.com/#operation/getGeocode
  Future<String?> reverseGeocode(BuildContext context, LatLng coordinate) async {
    // TODO: Currently not supported.
    return null;

    if (isFetchingAddress) return null;

    isFetchingAddress = true;
    notifyListeners();

    hadErrorDuringFetch = false;

    try {
      final settings = Provider.of<SettingsService>(context, listen: false);
      final baseUrl = settings.backend.path;
      var url = "https://$baseUrl/graphhopper/geocode";
      url += "?locale=de";
      url += "&limit=1";
      url += "&reverse=true";
      url += "&point=${coordinate.latitude},${coordinate.longitude}";
      final endpoint = Uri.parse(url);

      final response = await httpClient.get(endpoint);
      if (response.statusCode != 200) {
        isFetchingAddress = false;
        notifyListeners();
        final err = "Address could not be fetched from $endpoint: ${response.body}";
        log.e(err); ToastMessage.showError(err); throw Exception(err);
      }

      final decoded = json.decode(response.body);
      final geocodeResponse = GHGeocodeResponse.fromJson(decoded);
      if (geocodeResponse.hits.isEmpty) return null;
      return geocodeResponse.hits.first.name;
    } catch (error, stacktrace) { 
      log.e("Error during reverse geocode: $error $stacktrace");
      isFetchingAddress = false;
      hadErrorDuringFetch = true;
      notifyListeners();
      return null;
    }
  }
}