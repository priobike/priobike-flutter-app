import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class POIResult {
  final String name;
  final double distance;
  final double lon;
  final double lat;
  POIResult({
    required this.name,
    required this.distance,
    required this.lon,
    required this.lat,
  });
}

class POIElement {
  final String name;
  final double lon;
  final double lat;

  POIElement({
    required this.name,
    required this.lon,
    required this.lat,
  });
}

class POI with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("POI");

  /// The distance model.
  static const vincenty = Distance(roundResult: false);

  List<POIResult> rentalResults = [];
  List<POIResult> bikeAirResults = [];
  List<POIResult> repairResults = [];

  final List<POIElement> _allRentalElements = List.empty(growable: true);
  final List<POIElement> _allBikeAirElements = List.empty(growable: true);
  final List<POIElement> _allRepairElements = List.empty(growable: true);

  var positionPermissionDenied = false;
  var errorDuringFetch = false;

  Future<void> _fetchRentalData() async {
    try {
      final data = await _fetchData("/map-data/bicycle_rental.geojson");
      data["features"].forEach(
        (element) {
          var name = element["properties"]["name"] ?? "Fahrradleihe";
          name = name.length < 2 ? "Fahrradleihe" : name;

          final POIElement poiElement = POIElement(
            name: name,
            lon: element["geometry"]["coordinates"][0],
            lat: element["geometry"]["coordinates"][1],
          );
          _allRentalElements.add(poiElement);
        },
      );
    } catch (e) {
      log.e("Failed to load rental stations: $e");
      errorDuringFetch = true;
    }
  }

  Future<void> _fetchBikeAirData() async {
    try {
      final data = await _fetchData("/map-data/bike_air_station.geojson");
      data["features"].forEach(
        (element) {
          var name = element["properties"]["name"] ?? "Luftstation";
          name = name.length < 2 ? "Luftstation" : name;

          final POIElement poiElement = POIElement(
            name: name,
            lon: element["geometry"]["coordinates"][0],
            lat: element["geometry"]["coordinates"][1],
          );
          _allBikeAirElements.add(poiElement);
        },
      );
    } catch (e) {
      log.e("Failed to load bike air stations: $e");
      errorDuringFetch = true;
    }
  }

  Future<void> _fetchRepairData() async {
    try {
      final data = await _fetchData("/map-data/bicycle_shop.geojson");
      data["features"].forEach(
        (element) {
          var name = element["properties"]["name"] ?? "Fahrradladen";
          name = name.length < 2 ? "Fahrradladen" : name;

          final POIElement poiElement = POIElement(
            name: name,
            lon: element["geometry"]["coordinates"][0],
            lat: element["geometry"]["coordinates"][1],
          );
          _allRepairElements.add(poiElement);
        },
      );
    } catch (e) {
      log.e("Failed to load bike repair stations: $e");
      errorDuringFetch = true;
    }
  }

  Future<dynamic> _fetchData(String relativeUrl) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final dataUrl = "https://$baseUrl$relativeUrl";
    final dataEndpoint = Uri.parse(dataUrl);

    Response response = await Http.get(dataEndpoint).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      final err = "Data could not be fetched from endpoint $dataEndpoint: ${response.body}";
      throw Exception(err);
    }

    return await json.decode(response.body);
  }

  Future<List<POIResult>> _getClosest(List<POIElement> allElements) async {
    positionPermissionDenied = false;
    final positioning = getIt<Positioning>();
    await positioning.requestSingleLocation(onNoPermission: () => positionPermissionDenied = true);
    if (positionPermissionDenied) {
      return [];
    }
    final lastPosition = positioning.lastPosition;
    if (lastPosition == null) {
      errorDuringFetch = true;
      return [];
    }

    const resultCount = 3;

    final List<POIResult> results = [];
    for (var i = 0; i < allElements.length; i++) {
      final element = allElements[i];
      final distance = vincenty.distance(
        LatLng(
          lastPosition.latitude,
          lastPosition.longitude,
        ),
        LatLng(
          element.lat,
          element.lon,
        ),
      );
      results.add(
        POIResult(
          name: element.name,
          distance: distance,
          lon: element.lon,
          lat: element.lat,
        ),
      );
    }
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results.sublist(0, resultCount);
  }

  Future<void> getRentalResults() async {
    errorDuringFetch = false;
    rentalResults.clear();
    if (_allRentalElements.isEmpty) {
      await _fetchRentalData();
    }
    rentalResults = await _getClosest(_allRentalElements);
    bikeAirResults.clear();
    repairResults.clear();
    notifyListeners();
  }

  Future<void> getBikeAirResults() async {
    errorDuringFetch = false;
    bikeAirResults.clear();
    if (_allBikeAirElements.isEmpty) {
      await _fetchBikeAirData();
    }
    bikeAirResults = await _getClosest(_allBikeAirElements);
    rentalResults.clear();
    repairResults.clear();
    notifyListeners();
  }

  Future<void> getRepairResults() async {
    errorDuringFetch = false;
    repairResults.clear();
    if (_allRepairElements.isEmpty) {
      await _fetchRepairData();
    }
    repairResults = await _getClosest(_allRepairElements);
    rentalResults.clear();
    bikeAirResults.clear();
    notifyListeners();
  }
}
