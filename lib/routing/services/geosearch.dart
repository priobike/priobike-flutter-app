import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/photon.dart';
import 'package:priobike/routing/models/waypoint.dart';
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
  List<Waypoint>? results;

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
      final baseUrl = settings.backend.path;

      var url = "https://$baseUrl/photon/api";
      url += "?q=$query";

      // Add custom bounding box to limit search results
      final boundingBox = getBoundingBox();
      if (boundingBox.isNotEmpty) {
        final minLon = boundingBox["minLon"];
        final maxLon = boundingBox["maxLon"];
        final minLat = boundingBox["minLat"];
        final maxLat = boundingBox["maxLat"];
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
      results = addresses.map((e) {
        // Example DisplayName: "Andreas-Pfitzmann-Bau, Nöthnitzer Straße 46, Räcknitz, 01187, Dresden, Sachsen, Deutschland"
        var displayName = "";
        if (e.name != null) displayName += "${e.name}, ";
        // only show house number if street is also present
        if (e.street != null && e.houseNumber != null) {
          displayName += "${e.street} ${e.houseNumber}, ";
        } else if (e.street != null) {
          displayName += "${e.street}, ";
        }
        if (e.district != null) displayName += "${e.district}, ";
        if (e.postcode != null) displayName += "${e.postcode}, ";
        if (e.city != null) displayName += "${e.city}, ";
        if (e.state != null) displayName += "${e.state}, ";
        if (e.country != null) displayName += "${e.country}";

        return Waypoint(
          e.lat,
          e.lon,
          address: displayName,
        );
      }).toList();
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

  /// Delete the search history from the device.
  Future<void> deleteSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final backend = getIt<Settings>().backend;
    if (backend == Backend.production) {
      await preferences.remove("priobike.routing.searchHistory.production");
    } else if (backend == Backend.staging) {
      await preferences.remove("priobike.routing.searchHistory.staging");
    } else {
      log.e("Unknown backend used for geosearch: $backend");
    }
    searchHistory = [];
    notifyListeners();
  }

  /// Initialize the search history from the shared preferences by decoding it from a String List.
  Future<void> loadSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final backend = getIt<Settings>().backend;
    List<String> savedList = [];
    if (backend == Backend.production) {
      savedList = preferences.getStringList("priobike.routing.searchHistory.production") ?? [];
    } else if (backend == Backend.staging) {
      savedList = preferences.getStringList("priobike.routing.searchHistory.staging") ?? [];
    } else {
      log.e("Unknown backend used for geosearch: $backend");
    }
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
    final backend = getIt<Settings>().backend;
    List<String> newList = [];
    for (Waypoint waypoint in searchHistory) {
      newList.add(json.encode(waypoint.toJSON()));
    }
    if (backend == Backend.production) {
      await preferences.setStringList("priobike.routing.searchHistory.production", newList);
    } else if (backend == Backend.staging) {
      await preferences.setStringList("priobike.routing.searchHistory.staging", newList);
    } else {
      log.e("Unknown backend used for geosearch: $backend");
    }
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
    notifyListeners();
  }

  /// The BoundingBox is used to limit the geosearch-results to a certain area, i.e. Hamburg or Dresden.
  /// It doesn't exactly match the borders of the city, but uses a rectangle as an approximation.
  Map<String, double> getBoundingBox() {
    final backend = getIt<Settings>().backend;

    if (backend == Backend.production) {
      // See: http://bboxfinder.com/#53.350000,9.650000,53.750000,10.400000
      return {
        "minLon": 9.65,
        "maxLon": 10.4,
        "minLat": 53.35,
        "maxLat": 53.75,
      };
    } else if (backend == Backend.staging) {
      // See: http://bboxfinder.com/#50.900000,13.500000,51.200000,14.000000
      return {
        "minLon": 13.5,
        "maxLon": 14.0,
        "minLat": 50.9,
        "maxLat": 51.2,
      };
    } else {
      log.e("Unknown backend used for trying to access BoundingBox: $backend");
      return {};
    }
  }
}
