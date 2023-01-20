import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routingNew/services/bottomSheetState.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

class Places with ChangeNotifier {
  /// All available places.
  List<Place>? places;

  Places();

  /// Reset the places service.
  Future<void> reset() async {
    places = null;
  }

  /// Save a new place from selected waypoint. Array length == 1.
  Future<void> saveNewPlaceFromWaypoint(String name, BuildContext context) async {
    final routing = Provider.of<Routing>(context, listen: false);
    final bottomSheetState = Provider.of<BottomSheetState>(context, listen: false);

    if (routing.selectedWaypoints == null ||
        routing.selectedWaypoints!.isEmpty ||
        routing.selectedWaypoints![0] == null) return;

    // Check if waypoint contains "Standort" as address and change it to geolocation
    if (routing.selectedWaypoints![0] != null && routing.selectedWaypoints![0]!.address == null) {
      final geocoding = Provider.of<Geocoding>(context, listen: false);
      final String? address = await geocoding.reverseGeocodeLatLng(
          context, routing.selectedWaypoints![0]!.lat, routing.selectedWaypoints![0]!.lon);
      if (address == null) return;
      routing.selectedWaypoints![0]!.address = address;
    }

    // Save the first waypoint.
    final newPlace = Place(name: name, waypoint: routing.selectedWaypoints![0]!);
    if (places == null) await loadPlaces(context);
    if (places == null) return;
    places = [newPlace] + places!;
    await storePlaces(context);

    bottomSheetState.reset();
    routing.reset();
    ToastMessage.showSuccess("Ort gespeichert!");
    notifyListeners();
  }

  /// Save a new place.
  Future<void> saveNewPlace(Place place, BuildContext context) async {
    if (places == null) await loadPlaces(context);
    if (places == null) return;
    places = [place] + places!;
    await storePlaces(context);
    notifyListeners();
  }

  /// Update the places.
  Future<void> updatePlaces(List<Place> newPlaces, BuildContext context) async {
    places = newPlaces;
    await storePlaces(context);
    notifyListeners();
  }

  /// Store all places.
  Future<void> storePlaces(BuildContext context) async {
    if (places == null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;

    final jsonStr = jsonEncode(places!.map((e) => e.toJson()).toList());
    if (backend == Backend.production) {
      storage.setString("priobike.home.places.production", jsonStr);
    } else if (backend == Backend.staging) {
      storage.setString("priobike.home.places.staging", jsonStr);
    }
  }

  /// Load the custom places.
  Future<void> loadPlaces(BuildContext context) async {
    if (places != null) return;
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;
    String? jsonStr;
    if (backend == Backend.production) {
      jsonStr = storage.getString("priobike.home.places.production");
    } else if (backend == Backend.staging) {
      jsonStr = storage.getString("priobike.home.places.staging");
    }

    if (jsonStr == null) {
      places = backend.defaultPlaces;
    } else {
      places = (jsonDecode(jsonStr) as List).map((e) => Place.fromJson(e)).toList();
    }

    notifyListeners();
  }
}
