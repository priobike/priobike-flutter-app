import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/weather/messages/response.dart';

class Weather with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Weather");

  /// If the weather has been loaded.
  bool hasLoaded = false;

  /// The timestamp of the last weather fetch.
  DateTime? lastFetch;

  /// Fetch the weather for the given location.
  Future<void> fetchWeather({required double lat, required double lon}) async {
    // If the last fetch was less than 5 minutes ago, don't fetch again.
    if (lastFetch != null && lastFetch!.isAfter(DateTime.now().subtract(const Duration(minutes: 5)))) return;

    hasLoaded = false;
    notifyListeners();

    // Fetch the weather forecast.
    final forecastUrl = "https://api.brightsky.dev/weather?lat=$lat&lon=$lon&date=${DateTime.now().toIso8601String()}";
    try {
      http.Response response = await Http.get(Uri.parse(forecastUrl)).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Weather could not be fetched from endpoint $forecastUrl: ${response.body}";
        log.e(err);
        throw Exception(err);
      }

      final decoded = jsonDecode(response.body);
      log.i("Fetched weather forecast: $decoded");
      final forecast = WeatherForecastResponse.fromJson(decoded);
      log.i("Parsed weather forecast: $forecast");
    } catch (e) {
      log.e("Failed to fetch weather forecast: $e");
    }

    hasLoaded = true;
    lastFetch = DateTime.now();
    notifyListeners();
  }
}
