import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/achieved_location/achieved_location.dart';
import 'package:priobike/gamification/common/database/model/event_badge/event_badge.dart';
import 'package:priobike/gamification/common/services/evaluation_data_service.dart';
import 'package:priobike/gamification/community_event/model/event.dart';
import 'package:priobike/gamification/community_event/model/location.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// This service manages the weekend events and pulls all necessary data from the backend.
class EventService with ChangeNotifier {
  String get baseUrl => 'https://${getIt<Settings>().backend.path}/game-service/community/';

  /// Threshold within which a user needs to pass a location to achieve it.
  static const double locationThresholdMetres = 100;

  /// Vincenty distance object to measure the distance between to points.
  static const vincenty = Distance(roundResult: true, calculator: Vincenty());

  /// Data access object to access the locations achieved by the user.
  final AchievedLocationDao _achievedLocationDao = AppDatabase.instance.achievedLocationDao;

  /// Data access object to access the badges rewarded to the user.
  final EventBadgeDao _badgeDao = AppDatabase.instance.eventBadgeDao;

  /// The current open weekend event pulled from the server. If null, the server didn't provide one.
  WeekendEvent? _event;

  /// List of locations that belong to the current event.
  List<EventLocation> _locations = [];

  /// Stream subscription to the stream of achieved locations, to cancel a stream if the event changes.
  StreamSubscription? _achievedLocStream;

  /// List of all badges the user has collected.
  List<EventBadge> userBadges = [];

  /// The number of users that have achieved at least one location of the current event.
  int numOfActiveUsers = 0;

  /// The number of achieved locations by all users participating in the current event.
  int numOfAchievedLocations = 0;

  /// List of locations that the user has achieved, out of the locations of the current event.
  List<AchievedLocation> _achievedLocations = [];

  /// Whether there is an event.
  bool get noEvent => _event == null;

  /// Returns true, if the current event has started.
  bool get eventStarted => noEvent ? false : DateTime.now().isAfter(_event!.startTime);

  /// Returns true, if the current event has ended.
  bool get eventEnded => noEvent ? false : DateTime.now().isAfter(_event!.endTime);

  /// Returns true, if the current event has started, but has not ended yet, which means the user can participate.
  bool get activeEvent => eventStarted && !eventEnded;

  /// Returns true, if there is an event, but it hasn't started yet.
  bool get waitingForEvent => noEvent ? false : DateTime.now().isBefore(_event!.startTime);

  /// Getter for the current event.
  WeekendEvent? get event => _event;

  bool get wasCurrentEventAchieved => userBadges.where((b) => b.eventId == event?.id).isNotEmpty;

  /// Get list of locations from the current event, that the user has not achieved yet.
  List<EventLocation> get _unachievedLocations =>
      _locations.where((loc) => _achievedLocations.where((e) => e.locationId == loc.id).isEmpty).toList();

  /// Getter for the list of locations of the current event.
  List<EventLocation> get locations => List.from(_locations);

  /// This function checks, whether a given location has been achieved by the user.
  bool wasLocationAchieved(EventLocation loc) => !_unachievedLocations.contains(loc);

  EventService() {
    _badgeDao.streamAllObjects().listen((results) {
      userBadges = results;
      notifyListeners();
    });
  }

  /// This function can be called after a ride to check, if the user has passed some of the current locations.
  Future<void> checkLocations() async {
    try {
      if (!activeEvent) return;

      final positioning = getIt<Positioning>();
      final positions = positioning.positions;
      if (positions.isEmpty) return;

      final latLngList = positions.map((e) => LatLng(e.latitude, e.longitude));

      // Iterate through all unachieved locations and check, if the user was close enough to achieve them.
      for (var location in _unachievedLocations) {
        var hasBeenAchieved = checkIfLocationWasAchieved(location, latLngList);
        // If a new location has been achieved, save the corresponding object in the database and send it to the service.
        if (hasBeenAchieved) {
          var achievedLocation = await _achievedLocationDao.createAchievedLocation(location, _event!);
          if (achievedLocation == null) {
            log.e('Failed to store achieved location in database');
            continue;
          }
          // If a location was achieved, create a event badge, if there isn't already one.
          _badgeDao.createEventBadge(_event!);
          Map<String, dynamic> json = {
            'eventId': achievedLocation.eventId,
            'locationId': achievedLocation.id,
          };
          getIt<EvaluationDataService>().sendJsonToAddress('community/send-achieved-location/', json);
        }
      }
    } catch (e) {
      log.e('Failed to check event locations after saving route: $e');
    }
  }

  /// Check if a location was achieved by iterating through a given list of positions and calculating the distance.
  bool checkIfLocationWasAchieved(EventLocation location, Iterable<LatLng> positions) {
    for (var pos in positions) {
      var distance = vincenty.distance(LatLng(location.lat, location.lon), pos);
      log.i('distance to ${location.title} is $distance what');
      if (distance <= locationThresholdMetres) return true;
    }
    return false;
  }

  /// Start a stream to listen to changes in the achieved locations for the current event.
  void startAchievedLocationStream(int eventId) async {
    await _achievedLocStream?.cancel();
    _achievedLocStream = _achievedLocationDao.streamLocationsForEvent(eventId).listen((locations) {
      _achievedLocations = locations;
      notifyListeners();
    });
  }

  /// Fetch the current open weekend event from the server.
  Future<void> fetchWeekendEvent() async {
    var url = '${baseUrl}get-open-event/';
    final endpoint = Uri.parse(url);
    try {
      // Try to retreive the current open event.
      http.Response response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Could not be fetched from endpoint $endpoint: ${response.body}";
        throw Exception(err);
      }

      // Try to decode the event
      var result = jsonDecode(response.body);
      try {
        _event = WeekendEvent.fromJson(result);
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

  /// Fetch the locations corresponding to the current event from the server.
  Future<void> fetchEventLocations() async {
    var url = '${baseUrl}get-locations/';
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

  /// Fetch status data about the current event from the service.
  Future<void> fetchEventStatus() async {
    var url = '${baseUrl}get-event-status/';
    final endpoint = Uri.parse(url);

    try {
      // Try to retrieve status of the current event from the gamification service.
      http.Response response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Could not be fetched from endpoint $endpoint: ${response.body}";
        throw Exception(err);
      }

      /// Try to decode the result list and save in local variales.
      try {
        var result = jsonDecode(response.body);
        numOfActiveUsers = result['numOfUsers'];
        numOfAchievedLocations = result['achievedLocations'];
      } on TypeError catch (e) {
        numOfActiveUsers = 0;
        numOfAchievedLocations = 0;
        final err = "Could not decode the resonse body ${response.body} with error: $e";
        throw Exception(err);
      }
    }
    // Catch the error if there is no connection to the internet or something else went wrong.
    catch (e) {
      log.e("Failed to load event status: $e");
    }
  }

  /// Fetch all relevant data from the backend and update the total number of achieved badges of the user.
  Future<void> fetchData() async {
    await fetchWeekendEvent();
    await fetchEventLocations();
    await fetchEventStatus();
    notifyListeners();
  }
}
