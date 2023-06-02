import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/photon.dart';
import 'package:priobike/routing/services/bounding_box.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class Geocoding with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Geocoding");

  /// A boolean indicating if the service is currently loading an address.
  bool isFetchingAddress = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  /// A boolean indicating if the coordinates are inside the bounding box of the city.
  bool pointIsInside = true;

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
      // Discard the request if the point is not inside the bounding box (ie. not in Hamburg/Dresden)
      pointIsInside = await getIt<BoundingBox>().checkIfPointIsInBoundingBox(coordinate.longitude, coordinate.latitude);
      if (!pointIsInside) {
        throw Exception("Coordinates are not inside bounding box");
      }

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

      final displayName = geocodeResponse.getDisplayName();
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

  /// Reset the state of the service.
  void reset() {
    isFetchingAddress = false;
    hadErrorDuringFetch = false;
    pointIsInside = true;
    notifyListeners();
  }
}
