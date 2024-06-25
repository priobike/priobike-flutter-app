import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/photon.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Geosearch with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Geosearch");

  /// A boolean indicating if the service is currently loading addresses.
  bool isFetchingAddress = false;

  /// A boolean indicating if there was an error.
  bool hadErrorDuringFetch = false;

  /// The list of results.
  List<Waypoint> results = [];

  /// The search history, saved in the shared preferences.
  List<Waypoint> searchHistory = [];

  Geosearch();

  /// Fetch addresses to a given query.
  Future<void> geosearch(String query) async {
    if (isFetchingAddress) return;

    isFetchingAddress = true;
    notifyListeners();

    hadErrorDuringFetch = false;

    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.city.selectedBackend(true).path;

      var url = "https://$baseUrl/photon/api";
      url += "?q=$query";

      // Bias search results to current position
      final positionLat = getIt<Positioning>().lastPosition?.latitude;
      final positionLon = getIt<Positioning>().lastPosition?.longitude;
      if (positionLat != null && positionLon != null) {
        url += "&lat=$positionLat";
        url += "&lon=$positionLon";
      }

      // There needs to be a rough bounding box (just a rectangle) here
      // and a finer one below by checking if the point is inside the boundingBox (with the exakt geojson of the city).
      // The rough bounding box is nessessary for photon to limit the search results
      // while it checks below if every point is exactly within the city boundries
      final boundaryService = getIt<Boundary>();
      final roughBoundingBox = settings.city.roughBoundingBox;
      if (roughBoundingBox.isNotEmpty) {
        final minLon = roughBoundingBox["minLon"];
        final maxLon = roughBoundingBox["maxLon"];
        final minLat = roughBoundingBox["minLat"];
        final maxLat = roughBoundingBox["maxLat"];
        url += "&bbox=$minLon,$minLat,$maxLon,$maxLat";
      }

      url += "&lang=de";
      url += "&limit=10";

      final endpoint = Uri.parse(url);
      final response = await Http.get(endpoint);
      if (response.statusCode != 200) {
        isFetchingAddress = false;
        notifyListeners();
        final err = "Addresses could not be fetched from $endpoint: ${response.body}";
        throw Exception(err);
      }
      final List<PhotonAddress> addresses = [];
      final json = jsonDecode(response.body);
      for (var jsonItem in json["features"]) {
        addresses.add(PhotonAddress.fromJson(jsonItem));
      }

      isFetchingAddress = false;
      results = [];
      for (final address in addresses) {
        final pointIsInside = boundaryService.checkIfPointIsInBoundary(address.lon, address.lat);
        // ignore addresses that are not inside the bounding box
        if (!pointIsInside) {
          continue;
        }
        final displayName = address.getDisplayName();
        results.add(
          Waypoint(
            address.lat,
            address.lon,
            address: displayName,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      isFetchingAddress = false;
      hadErrorDuringFetch = true;
      notifyListeners();
      final hint = "Addresses could not be fetched: $e";
      log.e(hint);
    }
  }

  /// Clear the search results.
  void clearGeosearch() {
    results = [];
    notifyListeners();
  }

  /// Delete the search history from the SharedPreferences.
  Future<void> deleteSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final city = getIt<Settings>().city;
    await preferences.remove("priobike.routing.searchHistory.${city.nameDE}");
    searchHistory = [];
  }

  /// Initialize the search history from the SharedPreferences by decoding it from a String List.
  Future<void> loadSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final city = getIt<Settings>().city;
    List<String> savedList = preferences.getStringList("priobike.routing.searchHistory.${city.nameDE}") ?? [];
    searchHistory = [];
    for (String waypoint in savedList) {
      try {
        searchHistory.add(Waypoint.fromJson(json.decode(waypoint)));
      } catch (e) {
        final hint =
            "Waypoint could not be decoded from json: $e -> Deleting history because of a change in the waypoint model.";
        log.e(hint);
        deleteSearchHistory();
        return;
      }
    }
    notifyListeners();
  }

  /// Save the search history to the shared preferences by encoding it as a String List.
  Future<void> saveSearchHistory() async {
    if (searchHistory.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final city = getIt<Settings>().city;
    List<String> newList = [];
    for (Waypoint waypoint in searchHistory) {
      newList.add(json.encode(waypoint.toJSON()));
    }
    await preferences.setStringList("priobike.routing.searchHistory.${city.nameDE}", newList);
  }

  /// Add a waypoint to the search history.
  Future<void> addToSearchHistory(Waypoint waypoint) async {
    await loadSearchHistory();
    // Remove the waypoint from the history if it already exists.
    // It still should be added again, to be shown as the last search.
    if (searchHistory.any((element) => element.address == waypoint.address)) {
      searchHistory.removeWhere((element) => element.address == waypoint.address);
    }

    // Only keep the last 10 searches.
    if (searchHistory.length > 10) searchHistory.removeAt(0);

    searchHistory.add(waypoint);
    await saveSearchHistory();
  }

  /// Remove a waypoint from the search history.
  Future<void> removeItemFromSearchHistory(Waypoint waypoint) async {
    if (searchHistory.isEmpty) return;
    searchHistory.removeWhere((element) => element.address == waypoint.address);
    await saveSearchHistory();
    notifyListeners();
  }
}
