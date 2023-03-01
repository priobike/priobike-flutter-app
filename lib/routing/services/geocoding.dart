import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/nominatim.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Geocoding with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Geocoding");

  /// A boolean indicating if the service is currently loading an address.
  bool isFetchingAddress = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  Geocoding();

  /// Fetch the address to a given coordinate.
  /// See: https://nominatim.org/release-docs/develop/api/Reverse/
  Future<String?> reverseGeocodeLatLng(double lat, double lng) async {
    return await reverseGeocode(LatLng(lat, lng));
  }

  /// Fetch the address to a given coordinate.
  /// See: https://nominatim.org/release-docs/develop/api/Reverse/
  Future<String?> reverseGeocode(LatLng coordinate) async {
    if (isFetchingAddress) return null;

    isFetchingAddress = true;
    notifyListeners();

    hadErrorDuringFetch = false;

    try {
      final settings = getIt<Settings>();
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

      final response = await Http.get(endpoint);
      if (response.statusCode != 200) {
        isFetchingAddress = false;
        notifyListeners();
        final err = "Address could not be fetched from $endpoint: ${response.body}";
        log.e(err);
        throw Exception(err);
      }

      final decoded = json.decode(response.body);
      final geocodeResponse = NominatimAddress.fromJson(decoded);

      isFetchingAddress = false;
      hadErrorDuringFetch = false;
      notifyListeners();
      return geocodeResponse.displayName;
    } catch (error, stacktrace) {
      final hint = "Error during reverse geocode: $error";
      log.e(hint);
      if (!kDebugMode) {
        Sentry.captureException(error, stackTrace: stacktrace, hint: hint);
      }
      isFetchingAddress = false;
      hadErrorDuringFetch = true;
      notifyListeners();
      return null;
    }
  }
}
