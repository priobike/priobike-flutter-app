import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/achieved_location/achieved_location.dart';
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';

class CommunityService with ChangeNotifier {
  static const baseUrl = 'http://10.0.2.2:8000/community/';

  static const double locationThresholdMetres = 100;

  final AchievedLocationDao _achievedLocationDao = AppDatabase.instance.achievedLocationDao;

  CommunityEvent? _event;

  StreamSubscription? _achievedLocStream;

  final List<EventLocation> _locations = [];

  List<AchievedLocation> _achievedLocations = [];

  bool get noEvent => _event == null;

  bool get eventStarted => noEvent ? false : DateTime.now().isAfter(_event!.startTime);

  bool get eventEnded => noEvent ? false : DateTime.now().isAfter(_event!.endTime);

  CommunityEvent? get event => _event;

  List<EventLocation> get _unachievedLocations =>
      _locations.where((loc) => _achievedLocations.where((e) => e.id == e.id).isEmpty).toList();

  List<EventLocation> get locations => List.from(_locations);

  int get numOfAchievedLocations => _achievedLocations.length;

  Future<void> checkLocations() async {
    try {
      if (!eventStarted) return;

      final positioning = getIt<Positioning>();
      final positions = positioning.positions;
      if (positions.isEmpty) return;

      final latLngList = positions.map((e) => LatLng(e.latitude, e.longitude));

      for (var location in _unachievedLocations) {
        var hasBeenAchieved = checkIfLocationWasAchieved(location, latLngList);
        if (hasBeenAchieved) await _achievedLocationDao.addLocation(location, _event!.id);
      }
    } catch (_) {
      log.e('Failed to check event locations after saving routes.');
    }
  }

  bool checkIfLocationWasAchieved(EventLocation location, Iterable<LatLng> positions) {
    for (var pos in positions) {
      var distance = vincenty.distance(LatLng(location.lat, location.lon), pos);
      if (distance <= locationThresholdMetres) return true;
    }
    return false;
  }

  void startAchievedLocationStream(int eventId) async {
    await _achievedLocStream?.cancel();
    _achievedLocStream = _achievedLocationDao.streamLocationsForEvent(eventId).listen((locations) {
      _achievedLocations = locations;
      notifyListeners();
    });
  }

  Future<void> loadOpenCommunityEvent() async {
    _event = null;
    const url = '${baseUrl}get-open-event/';
    final endpoint = Uri.parse(url);
    try {
      // Try to retreive the current open community event.
      http.Response response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Could not be fetched from endpoint $endpoint: ${response.body}";
        throw Exception(err);
      }

      // Try to decode the community event
      var result = jsonDecode(response.body);
      try {
        _event = CommunityEvent.fromJson(result);
        startAchievedLocationStream(_event!.id);
      } on TypeError catch (e) {
        final err = "Could not decode the resonse body ${response.body} with error: $e";
        throw Exception(err);
      }
    }
    // Catch the error if there is no connection to the internet or something else went wrong.
    catch (e) {
      log.e("Failed to load open event: $e");
    }
    notifyListeners();
  }

  Future<void> loadEventLocations() async {
    _locations.clear();
    const url = '${baseUrl}get-locations/';
    final endpoint = Uri.parse(url);

    try {
      // Try to retrieve list of lcoations for the current event from the gamification service.
      http.Response response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Could not be fetched from endpoint $endpoint: ${response.body}";
        throw Exception(err);
      }

      /// Try to decode the result list and save in locations variale.
      try {
        var results = jsonDecode(response.body);
        for (var location in results) {
          _locations.add(EventLocation.fromJson(location));
        }
      } on TypeError catch (e) {
        final err = "Could not decode the resonse body ${response.body} with error: $e";
        throw Exception(err);
      }
    }
    // Catch the error if there is no connection to the internet or something else went wrong.
    catch (e) {
      log.e("Failed to load locations: $e");
    }
    notifyListeners();
  }
}
