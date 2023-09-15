import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';

class CommunityService with ChangeNotifier {
  static const baseUrl = 'http://10.0.2.2:8000/community/';

  CommunityEvent? _event;

  CommunityEvent? get event => _event;

  final List<EventLocation> _locations = [];

  List<EventLocation> get locations => List.from(_locations);

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
