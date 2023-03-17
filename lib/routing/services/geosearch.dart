import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/nominatim.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Geosearch with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Geosearch");

  /// A boolean indicating if the service is currently loading addresses.
  bool isFetchingAddress = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  /// The list of results.
  List<Waypoint>? results;

  /// The search history, saved in the shared preferences.
  List<Waypoint> searchHistory = [];

  Geosearch();

  /// Fetch addresses to a given query.
  /// See: https://nominatim.org/release-docs/develop/api/Search/
  Future<void> geosearch(String query) async {
    if (isFetchingAddress) return;

    isFetchingAddress = true;
    notifyListeners();

    hadErrorDuringFetch = false;

    try {
      final settings = getIt<Settings>();
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
        throw Exception(err);
      }

      final List<NominatimAddress> addresses = [];
      final json = jsonDecode(response.body);
      for (var i = 0; i < json.length; i++) {
        addresses.add(NominatimAddress.fromJson(json[i]));
      }

      isFetchingAddress = false;
      results = addresses.map((e) => Waypoint(e.lat, e.lon, address: e.displayName)).toList();
      notifyListeners();
    } catch (e, stack) {
      isFetchingAddress = false;
      notifyListeners();
      hadErrorDuringFetch = true;
      notifyListeners();
      final hint = "Addresses could not be fetched: $e";
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stack, hint: hint);
      }
      log.e(hint);
    }
  }

  /// Clear the search results.
  void clearGeosearch() {
    results = [];
    notifyListeners();
  }

  /// Delete the search history from the device.
  Future<void> deleteSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove("priobike.routing.searchHistory");
    searchHistory = [];
    notifyListeners();
  }

  /// Initialize the search history from the shared preferences by decoding it from a String List.
  Future<void> loadSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    List<String> savedList = preferences.getStringList("priobike.routing.searchHistory") ?? [];
    searchHistory = [];
    for (String waypoint in savedList) {
      searchHistory.add(Waypoint.fromJson(json.decode(waypoint)));
    }
    notifyListeners();
  }

  /// Save the search history to the shared preferences by encoding it as a String List.
  Future<void> saveSearchHistory() async {
    if (searchHistory.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    List<String> newList = [];
    for (Waypoint waypoint in searchHistory) {
      newList.add(json.encode(waypoint.toJSON()));
    }
    await preferences.setStringList("priobike.routing.searchHistory", newList);
    notifyListeners();
  }

  /// Add a waypoint to the search history.
  void addToSearchHistory(Waypoint waypoint) {
    // Remove the waypoint from the history if it already exists.
    // It still should be added again, to be shown as the last search.
    if (searchHistory.any((element) => element.address == waypoint.address)) {
      searchHistory.removeWhere((element) => element.address == waypoint.address);
    }

    // Only keep the last 10 searches.
    if (searchHistory.length > 10) searchHistory.removeAt(0);

    searchHistory.add(waypoint);
    notifyListeners();
  }
}
