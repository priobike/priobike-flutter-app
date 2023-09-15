import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';

class CommunityService with ChangeNotifier {
  CommunityEvent? event;

  List<EventLocation> locations = [];

  Future<void> loadOpenCommunityEvent() async {
    const baseUrl = 'http://10.0.2.2:8000/community/get-open-event/';
    final endpoint = Uri.parse(baseUrl);
    // Catch the error if there is no connection to the internet.
    try {
      http.Response response = await Http.get(endpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Could not be fetched from endpoint $endpoint: ${response.body}";
        throw Exception(err);
      }

      var result = jsonDecode(response.body);

      try {
        event = CommunityEvent.fromJson(result);
      } on TypeError catch (e) {
        event = null;
        log.i(e.toString());
      }
    } catch (e) {
      log.e("Failed to load open event: $e");
    }
    notifyListeners();
  }

  Future<void> loadEventLocations() async {
    locations.clear();

    const baseUrl = 'http://10.0.2.2:8000/community/get-locations/';
    final endpoint = Uri.parse(baseUrl);

    // Catch the error if there is no connection to the internet.
    try {
      http.Response response = await Http.get(endpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Could not be fetched from endpoint $endpoint: ${response.body}";
        throw Exception(err);
      }

      var results = jsonDecode(response.body);

      for (var location in results) {
        locations.add(EventLocation.fromJson(location));
      }
    } catch (e) {
      log.e("Failed to load locations: $e");
    }
    notifyListeners();
  }
}
