import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/photon.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class Geocoding with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Geocoding");

  /// A boolean indicating if the service is currently loading an address.
  bool isFetchingAddress = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  Geocoding();

  /// Fetch the address to a given coordinate.
  Future<String?> reverseGeocodeLatLng(double lat, double lng) async {
    return await reverseGeocode(LatLng(lat, lng));
  }

  /// Fetch the address to a given coordinate.
  Future<String?> reverseGeocode(LatLng coordinate) async {
    if (isFetchingAddress) return null;

    isFetchingAddress = true;
    notifyListeners();

    hadErrorDuringFetch = false;

    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.backend.path;

      var url = "https://$baseUrl/photon/reverse";
      url += "?lon=${coordinate.longitude}";
      url += "&lat=${coordinate.latitude}";
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
      final geocodeResponse = PhotonAddress.fromJson(decoded["features"][0]);

      // Example DisplayName: "Andreas-Pfitzmann-Bau, Nöthnitzer Straße 46, Räcknitz, 01187, Dresden, Sachsen, Deutschland"
      var displayName = "";
      if (geocodeResponse.name != null) displayName += "${geocodeResponse.name}, ";

      // Only show house number if street is also present
      if (geocodeResponse.street != null && geocodeResponse.houseNumber != null) {
        displayName += "${geocodeResponse.street} ${geocodeResponse.houseNumber}, ";
      } else if (geocodeResponse.street != null) {
        displayName += "${geocodeResponse.street}, ";
      }
      if (geocodeResponse.district != null) displayName += "${geocodeResponse.district}, ";
      if (geocodeResponse.postcode != null) displayName += "${geocodeResponse.postcode}, ";
      if (geocodeResponse.city != null) displayName += "${geocodeResponse.city}, ";
      if (geocodeResponse.state != null) displayName += "${geocodeResponse.state}, ";
      if (geocodeResponse.country != null) displayName += "${geocodeResponse.country}";

      isFetchingAddress = false;
      hadErrorDuringFetch = false;
      notifyListeners();
      return displayName;
    } catch (error) {
      final hint = "Error during reverse geocode: $error";
      log.e(hint);
      isFetchingAddress = false;
      hadErrorDuringFetch = true;
      notifyListeners();
      return null;
    }
  }
}
