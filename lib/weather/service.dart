import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/weather/messages.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Weather with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Weather");

  /// If the weather has been loaded.
  bool hasLoaded = false;

  /// The weather forecast.
  List<WeatherForecast>? forecast;

  /// The current weather.
  CurrentWeather? current;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  /// Fetch the weather for the given location.
  Future<void> fetch() async {
    final settings = getIt.get<Settings>();
    final lat = settings.backend.center.latitude;
    final lon = settings.backend.center.longitude;

    hasLoaded = false;
    notifyListeners();

    try {
      // Fetch the weather forecast.
      var url = "https://api.brightsky.dev/weather?lat=$lat&lon=$lon&date=${DateTime.now().toIso8601String()}";
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
      url = "https://api.brightsky.dev/current_weather?lat=$lat&lon=$lon";
      response = await Http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "Weather could not be fetched from endpoint $url: ${response.body}";
        log.e(err);
        throw Exception(err);
      }

      decoded = jsonDecode(response.body);
      log.i("Fetched current weather.");
      current = CurrentWeatherResponse.fromJson(decoded).weather;
    } catch (e, stacktrace) {
      final hint = "Failed to fetch weather: $e $stacktrace";
      log.e(hint);
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stacktrace, hint: hint);
      }
    }

    hasLoaded = true;
    notifyListeners();
  }
}
