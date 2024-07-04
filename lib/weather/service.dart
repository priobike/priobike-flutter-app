import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/weather/messages.dart';

class Weather with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Weather");

  /// If the weather has been loaded.
  bool hasLoaded = false;

  /// If an error occurred while loading the weather.
  bool hadError = false;

  /// The weather forecast.
  List<WeatherForecast>? forecast;

  /// The current weather.
  CurrentWeather? current;

  /// Fetch the weather for the given location.
  Future<void> fetch() async {
    final settings = getIt<Settings>();
    final lat = settings.city.center.latitude;
    final lon = settings.city.center.longitude;
    final backend = settings.city.selectedBackend(true);

    hasLoaded = false;
    notifyListeners();

    try {
      // Fetch the weather forecast.
      var url = "https://${backend.path}/bright-sky/weather?lat=$lat&lon=$lon&date=${DateTime.now().toIso8601String()}";
      var response = await Http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Weather could not be fetched from endpoint $url: ${response.body}";
        log.e(err);
        throw Exception(err);
      }

      var decoded = jsonDecode(response.body);
      log.i("Fetched weather forecast.");
      forecast = WeatherForecastResponse.fromJson(decoded).weather;

      // Fetch the current weather.
      url = "https://${backend.path}/bright-sky/current_weather?lat=$lat&lon=$lon";
      response = await Http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Weather could not be fetched from endpoint $url: ${response.body}";
        log.e(err);
        throw Exception(err);
      }

      decoded = jsonDecode(response.body);
      log.i("Fetched current weather.");
      current = CurrentWeatherResponse.fromJson(decoded).weather;
      hadError = false;
    } catch (e, stacktrace) {
      final hint = "Failed to fetch weather: $e $stacktrace";
      log.e(hint);
      hadError = true;
    }

    hasLoaded = true;
    notifyListeners();
  }
}
