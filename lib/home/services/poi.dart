import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

enum POIType {
  bikeShop,
  bikeRental,
  airStation,
  parking,
}

/// A POI element.
class POIElement {
  /// The optional id of the POI.
  final String? id;

  /// The name of the POI.
  final String name;

  /// The type of element.
  final String typeDescription;

  /// The longitude of the POI.
  final double lon;

  /// The latitude of the POI.
  final double lat;

  /// The distance of the user to the POI.
  final double? distance;

  /// The type of the POI.
  final POIType? type;

  POIElement({
    required this.name,
    required this.typeDescription,
    required this.lon,
    required this.lat,
    this.distance,
    this.type,
    this.id,
  });
}

class POI with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("POI");

  /// The distance model.
  static const vincenty = Distance(roundResult: false);

  /// The nearest rental stations.
  List<POIElement> rentalResults = [];

  /// The nearest bike air stations.
  List<POIElement> bikeAirResults = [];

  /// The nearest repair stations.
  List<POIElement> repairResults = [];

  /// All rental stations.
  final List<POIElement> _allRentalElements = List.empty(growable: true);

  /// All bike air stations.
  final List<POIElement> _allBikeAirElements = List.empty(growable: true);

  /// All repair stations.
  final List<POIElement> _allRepairElements = List.empty(growable: true);

  /// If the user has denied the position permission.
  var positionPermissionDenied = false;

  /// If an error occured during the fetch.
  var errorDuringFetch = false;

  /// If the service is currently loading data.
  var loading = false;

  /// Get all rental POI elements.
  Future<void> _fetchRentalData() async {
    try {
      final data = await _fetchData("/map-data/bicycle_rental.geojson");
      data["features"].forEach(
        (element) {
          var name = element["properties"]["name"] ?? "Fahrradleihe";
          name = name.length < 2 ? "Fahrradleihe" : name;

          final POIElement poiElement = POIElement(
            name: name,
            typeDescription: "Fahrradleihe",
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

  /// Get all bike air POI elements.
  Future<void> _fetchBikeAirData() async {
    try {
      final data = await _fetchData("/map-data/bike_air_station.geojson");
      data["features"].forEach(
        (element) {
          var name = element["properties"]["name"] ?? "Luftstation";
          name = name.length < 2 ? "Luftstation" : name;

          final POIElement poiElement = POIElement(
            name: name,
            typeDescription: "Luftstation",
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

  /// Get all bike repair POI elements.
  Future<void> _fetchRepairData() async {
    try {
      final data = await _fetchData("/map-data/bicycle_shop.geojson");
      data["features"].forEach(
        (element) {
          var name = element["properties"]["name"] ?? "Fahrradladen";
          name = name.length < 2 ? "Fahrradladen" : name;

          final POIElement poiElement = POIElement(
            name: name,
            typeDescription: "Fahrradladen",
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

  /// A method which is used to fetch the POI data from the backend.
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

    return await json.decode(utf8.decode(response.bodyBytes));
  }

  /// Returns the closest POI elements given a list with all available elements.
  Future<List<POIElement>> _getClosest(List<POIElement> allElements, Position lastPosition) async {
    var resultCount = 3;

    final List<POIElement> results = [];
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
        POIElement(
          name: element.name,
          typeDescription: element.typeDescription,
          distance: distance,
          lon: element.lon,
          lat: element.lat,
        ),
      );
    }
    results.sort((a, b) => a.distance!.compareTo(b.distance!));
    if (results.length < resultCount) {
      resultCount = results.length;
    }
    return results.sublist(0, resultCount);
  }

  /// Returns a list with rental stations closest to the user.
  Future<void> getRentalResults() async {
    errorDuringFetch = false;
    loading = true;
    positionPermissionDenied = false;
    notifyListeners();

    final positioning = getIt<Positioning>();
    await positioning.requestSingleLocation(onNoPermission: () => positionPermissionDenied = true);
    if (positionPermissionDenied) {
      errorDuringFetch = true;
      notifyListeners();
      return;
    }
    final lastPosition = positioning.lastPosition;
    if (lastPosition == null) {
      errorDuringFetch = true;
      notifyListeners();
      return;
    }

    rentalResults.clear();
    if (_allRentalElements.isEmpty) {
      await _fetchRentalData();
    }
    rentalResults = await _getClosest(_allRentalElements, lastPosition);

    loading = false;
    notifyListeners();
  }

  /// Returns a list with bike air stations closest to the user.
  Future<void> getBikeAirResults() async {
    errorDuringFetch = false;
    loading = true;
    positionPermissionDenied = false;
    notifyListeners();

    final positioning = getIt<Positioning>();
    await positioning.requestSingleLocation(onNoPermission: () => positionPermissionDenied = true);
    if (positionPermissionDenied) {
      errorDuringFetch = true;
      notifyListeners();
      return;
    }
    final lastPosition = positioning.lastPosition;
    if (lastPosition == null) {
      errorDuringFetch = true;
      notifyListeners();
      return;
    }

    bikeAirResults.clear();
    if (_allBikeAirElements.isEmpty) {
      await _fetchBikeAirData();
    }
    bikeAirResults = await _getClosest(_allBikeAirElements, lastPosition);

    loading = false;
    notifyListeners();
  }

  /// Returns a list with bike repair stations closest to the user.
  Future<void> getRepairResults() async {
    errorDuringFetch = false;
    loading = true;
    positionPermissionDenied = false;
    notifyListeners();

    final positioning = getIt<Positioning>();
    await positioning.requestSingleLocation(onNoPermission: () => positionPermissionDenied = true);
    if (positionPermissionDenied) {
      errorDuringFetch = true;
      notifyListeners();
      return;
    }
    final lastPosition = positioning.lastPosition;
    if (lastPosition == null) {
      errorDuringFetch = true;
      notifyListeners();
      return;
    }

    repairResults.clear();
    if (_allRepairElements.isEmpty) {
      await _fetchRepairData();
    }
    repairResults = await _getClosest(_allRepairElements, lastPosition);

    loading = false;
    notifyListeners();
  }
}
