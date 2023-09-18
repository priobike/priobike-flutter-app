import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/achieved_location/achieved_location.dart';
import 'package:priobike/gamification/common/services/evaluation_data_service.dart';
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';

class CommunityService with ChangeNotifier {
  static const baseUrl = 'http://10.0.2.2:8000/community/';

  static const double locationThresholdMetres = 100;

  static const vincenty = Distance(roundResult: true, calculator: Vincenty());

  final AchievedLocationDao _achievedLocationDao = AppDatabase.instance.achievedLocationDao;

  CommunityEvent? _event;

  StreamSubscription? _achievedLocStream;

  int numOfActiveUsers = 0;

  int numOfAchievedBadges = 0;

  int numOfOverallAchievedLocations = 0;

  List<EventLocation> _locations = [];

  List<AchievedLocation> _achievedLocations = [];

  bool get noEvent => _event == null;

  bool get eventStarted => noEvent ? false : DateTime.now().isAfter(_event!.startTime);

  bool get eventEnded => noEvent ? false : DateTime.now().isAfter(_event!.endTime);

  bool get activeEvent => eventStarted && !eventEnded;

  bool get waitingForEvent => noEvent ? false : DateTime.now().isBefore(_event!.startTime);

  CommunityEvent? get event => _event;

  List<EventLocation> get _unachievedLocations =>
      _locations.where((loc) => _achievedLocations.where((e) => e.locationId == loc.id).isEmpty).toList();

  List<EventLocation> get locations => List.from(_locations);

  int get numOfAchievedLocations => _achievedLocations.length;

  bool wasLocationAchieved(EventLocation loc) {
    return !_unachievedLocations.contains(loc);
  }

  Stream<List<AchievedLocation>> getStreamOfAllBadges() => _achievedLocationDao.streamAllObjects();

  Future<void> checkLocations() async {
    try {
      if (!activeEvent) return;

      final positioning = getIt<Positioning>();
      final positions = positioning.positions;
      if (positions.isEmpty) return;

      final latLngList = positions.map((e) => LatLng(e.latitude, e.longitude));

      for (var location in _unachievedLocations) {
        var hasBeenAchieved = checkIfLocationWasAchieved(location, latLngList);
        if (hasBeenAchieved) {
          var achievedLocation = await _achievedLocationDao.addLocation(location, _event!);
          if (achievedLocation == null) {
            log.e('Failed to store achieved location in database');
            continue;
          }
          Map<String, dynamic> json = {
            'eventId': achievedLocation.eventId,
            'locationId': achievedLocation.id,
          };
          getIt<EvaluationDataService>().sendJsonToAddress('community/send-achieved-location/', json);
        }
      }
    } catch (_) {
      log.e('Failed to check event locations after saving routes.');
    }
  }

  bool checkIfLocationWasAchieved(EventLocation location, Iterable<LatLng> positions) {
    for (var pos in positions) {
      var distance = vincenty.distance(LatLng(location.lat, location.lon), pos);
      log.i('distance to ${location.title} is $distance what');
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
      _event = null;
      log.e("Failed to load open event: $e");
    }
  }

  Future<void> loadEventLocations() async {
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
        List<EventLocation> list = [];
        for (var location in results) {
          list.add(EventLocation.fromJson(location));
        }
        _locations = list;
      } on TypeError catch (e) {
        _locations.clear();
        final err = "Could not decode the resonse body ${response.body} with error: $e";
        throw Exception(err);
      }
    }
    // Catch the error if there is no connection to the internet or something else went wrong.
    catch (e) {
      log.e("Failed to load locations: $e");
    }
  }

  Future<void> fetchEventStatus() async {
    const url = '${baseUrl}get-event-status/';
    final endpoint = Uri.parse(url);

    try {
      // Try to retrieve status of the current event from the gamification service.
      http.Response response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Could not be fetched from endpoint $endpoint: ${response.body}";
        throw Exception(err);
      }

      /// Try to decode the result list and save in locations variale.
      try {
        var result = jsonDecode(response.body);
        numOfActiveUsers = result['numOfUsers'];
        numOfOverallAchievedLocations = result['achievedLocations'];
      } on TypeError catch (e) {
        numOfActiveUsers = 0;
        numOfOverallAchievedLocations = 0;
        final err = "Could not decode the resonse body ${response.body} with error: $e";
        throw Exception(err);
      }
    }
    // Catch the error if there is no connection to the internet or something else went wrong.
    catch (e) {
      log.e("Failed to load event status: $e");
    }
  }

  Future<void> fetchCommunityEventData() async {
    loadOpenCommunityEvent();
    loadEventLocations();
    fetchEventStatus();
    numOfAchievedBadges = (await _achievedLocationDao.getAllObjects()).length;
    notifyListeners();
  }
}
