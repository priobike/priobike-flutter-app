import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/messages/nominatim.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Geosearch with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Geosearch");

  /// A boolean indicating if the service is currently loading addresses.
  bool isFetchingAddress = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  /// The list of results.
  List<Waypoint>? results;

  Geosearch() {
    log.i("Geosearch started.");
  }

  /// Fetch addresses to a given query.
  /// See: https://nominatim.org/release-docs/develop/api/Search/
  Future<void> geosearch(BuildContext context, String query) async {
    if (isFetchingAddress) return;

    isFetchingAddress = true;
    notifyListeners();

    hadErrorDuringFetch = false;
 
    try {
      final settings = Provider.of<Settings>(context, listen: false);
      final baseUrl = settings.backend.path;
      var url = "https://$baseUrl/nominatim/search";
      url += "?accept-language=de";
      url += "&q=$query";
      url += "&format=json";
      url += "&limit=10";
      url += "&addressdetails=1";
      url += "&extratags=1";
      url += "&namedetails=1";
      url += "&dedupe=1";
      url += "&polygon_geojson=1";
      final endpoint = Uri.parse(url);

      final response = await Http.get(endpoint);
      if (response.statusCode != 200) {
        isFetchingAddress = false;
        notifyListeners();
        final err = "Addresses could not be fetched from $endpoint: ${response.body}";
        log.e(err); ToastMessage.showError(err); throw Exception(err);
      }

      final List<NominatimAddress> addresses = [];
      final json = jsonDecode(response.body);
      for (var i = 0; i < json.length; i++) {
        addresses.add(NominatimAddress.fromJson(json[i]));
      }

      isFetchingAddress = false;
      results = addresses.map((e) => Waypoint(
        e.lat, e.lon, address: e.displayName
      )).toList();
      notifyListeners();
    } catch (e, stack) {
      isFetchingAddress = false;
      notifyListeners();
      hadErrorDuringFetch = true;
      notifyListeners();
      final hint = "Addresses could not be fetched: $e";
      if (!kDebugMode) await Sentry.captureException(e, stackTrace: stack, hint: hint);
      log.e(hint); ToastMessage.showError(hint); throw Exception(hint);
    }
  }


  void clearGeosearch()  {
    results = [];
    notifyListeners();
  }
}