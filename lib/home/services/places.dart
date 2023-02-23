import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/home/models/place.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/services/bottom_sheet_state.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Places with ChangeNotifier {
  /// All available places.
  List<Place>? places;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  Places();

  /// Reset the places service.
  Future<void> reset() async {
    places = null;
  }

  /// Save a new place from selected waypoint. Array length == 1.
  Future<void> saveNewPlaceFromWaypoint(String name) async {
    final routing = getIt.get<Routing>();
    final bottomSheetState = getIt.get<BottomSheetState>();

    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return;

    // Check if waypoint contains "Standort" as address and change it to geolocation
    if (routing.selectedWaypoints![0].address == null) {
      final geocoding = getIt.get<Geocoding>();
      final String? address =
          await geocoding.reverseGeocodeLatLng(routing.selectedWaypoints![0].lat, routing.selectedWaypoints![0].lon);
      if (address == null) return;
      routing.selectedWaypoints![0].address = address;
    }

    // Save the first waypoint.
    final newPlace = Place(name: name, waypoint: routing.selectedWaypoints![0]);
    if (places == null) await loadPlaces();
    if (places == null) return;
    places = [newPlace] + places!;
    await storePlaces();

    bottomSheetState.reset();
    routing.reset();
    ToastMessage.showSuccess("Ort gespeichert!");
    notifyListeners();
  }

  /// Save a new place.
  Future<void> saveNewPlace(Place place) async {
    if (places == null) await loadPlaces();
    if (places == null) return;
    places = [place] + places!;
    await storePlaces();
    notifyListeners();
  }

  /// Update the places.
  Future<void> updatePlaces(List<Place> newPlaces) async {
    places = newPlaces;
    await storePlaces();
    notifyListeners();
  }

  /// Store all places.
  Future<void> storePlaces() async {
    if (places == null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt.get<Settings>().backend;

    final jsonStr = jsonEncode(places!.map((e) => e.toJson()).toList());
    if (backend == Backend.production) {
      storage.setString("priobike.home.places.production", jsonStr);
    } else if (backend == Backend.staging) {
      storage.setString("priobike.home.places.staging", jsonStr);
    }
  }

  /// Load the custom places.
  Future<void> loadPlaces() async {
    if (places != null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt.get<Settings>().backend;
    String? jsonStr;
    if (backend == Backend.production) {
      jsonStr = storage.getString("priobike.home.places.production");
    } else if (backend == Backend.staging) {
      jsonStr = storage.getString("priobike.home.places.staging");
    }

    if (jsonStr == null) {
      places = [];
    } else {
      places = (jsonDecode(jsonStr) as List).map((e) => Place.fromJson(e)).toList();
    }

    notifyListeners();
  }
}
