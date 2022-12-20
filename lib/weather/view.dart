import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/weather/messages.dart';
import 'package:priobike/weather/service.dart';
import 'package:provider/provider.dart';

class WeatherView extends StatefulWidget {
  const WeatherView({Key? key}) : super(key: key);

  @override
  WeatherViewState createState() => WeatherViewState();
}

class WeatherViewState extends State<WeatherView> {
  /// The associated weather service, which is injected by the provider.
  late Weather weather;

  /// The currently displayed weather icon.
  Icon? icon;

  /// The currently displayed weather summary.
  String? summary;

  /// If the current weather should be displayed as a warning.
  bool warning = false;

  @override
  void didChangeDependencies() {
    weather = Provider.of<Weather>(context);
    loadIcon();
    loadSummary();
    super.didChangeDependencies();
  }

  /// Load the weather icon from the weather service.
  Future<void> loadIcon() async {
    switch (weather.current?.icon) {
      case "clear-day":
        icon = const Icon(Icons.wb_sunny_rounded, size: 32, color: Colors.white);
        break;
      case "clear-night":
        icon = const Icon(Icons.nights_stay, size: 32, color: Colors.white);
        break;
      case "partly-cloudy-day":
        icon = const Icon(Icons.wb_cloudy_rounded, size: 32, color: Colors.white);
        break;
      case "partly-cloudy-night":
        icon = const Icon(Icons.wb_cloudy_rounded, size: 32, color: Colors.white);
        break;
      case "cloudy":
        icon = const Icon(Icons.wb_cloudy_rounded, size: 32, color: Colors.white);
        break;
      case "fog":
        icon = const Icon(Icons.foggy, size: 32, color: Colors.white);
        break;
      case "wind":
        icon = const Icon(Icons.air, size: 32, color: Colors.white);
        break;
      case "rain":
        icon = const Icon(Icons.umbrella_rounded, size: 32, color: Colors.white);
        break;
      case "sleet":
        icon = const Icon(Icons.cloudy_snowing, size: 32, color: Colors.white);
        break;
      case "snow":
        icon = const Icon(Icons.cloudy_snowing, size: 32, color: Colors.white);
        break;
      case "hail":
        icon = const Icon(Icons.cloudy_snowing, size: 32, color: Colors.white);
        break;
      case "thunderstorm":
        icon = const Icon(Icons.bolt, size: 32, color: Colors.white);
        break;
    }
  }

  /// Load the weather summary from the weather service.
  Future<void> loadSummary() async {
    warning = false;
    summary = "";
    final temp = weather.current?.temperature ?? 0;
    if (temp > 40) {
      summary = summary! + "Achtung vor extremer Hitze! ";
      warning = true;
    } else if (temp > 30) {
      summary = summary! + "Achtung vor starker Hitze! ";
      warning = true;
    } else if (temp > 0) {
      // Do nothing.
    } else if (temp > -10) {
      summary = summary! + "Kältewarnung! ";
      warning = true;
    } else {
      summary = summary! + "Achtung vor extremer Kälte! ";
      warning = true;
    }
    switch (weather.current?.icon) {
      case "clear-day":
        summary = summary! + "Es ist sonnig";
        break;
      case "clear-night":
        summary = summary! + "Es ist klar";
        break;
      case "partly-cloudy-day":
        summary = summary! + "Es ist teilweise bewölkt";
        break;
      case "partly-cloudy-night":
        summary = summary! + "Es ist teilweise bewölkt";
        break;
      case "cloudy":
        summary = summary! + "Es ist bewölkt";
        break;
      case "fog":
        summary = summary! + "Es ist neblig";
        break;
      case "wind":
        summary = "Es ist windig";
        warning = true;
        break;
      case "rain":
        summary = "Es regnet";
        warning = true;
        break;
      case "sleet":
        summary = "Es schneit";
        warning = true;
        break;
      case "snow":
        summary = "Es schneit";
        warning = true;
        break;
      case "hail":
        summary = "Es hagelt";
        warning = true;
        break;
      case "thunderstorm":
        summary = "Es gibt Gewitter";
        warning = true;
        break;
    }
    summary = summary! + " bei ${temp.toStringAsFixed(1)}°C.";

    // Check if the icon changes in the forecast.
    for (final forecast in weather.forecast ?? <WeatherForecast>[]) {
      if (forecast.icon != weather.current?.icon) {
        // Convert the timestamp to a clock time.
        summary = summary! +
            " Ab ${forecast.timestamp.hour.toString()}:${forecast.timestamp.minute.toString().padLeft(2, '0')} Uhr wird es";
        switch (forecast.icon) {
          case "clear-day":
            summary = summary! + " sonnig.";
            break;
          case "clear-night":
            summary = summary! + " klar.";
            break;
          case "partly-cloudy-day":
            summary = summary! + " teilweise bewölkt.";
            break;
          case "partly-cloudy-night":
            summary = summary! + " teilweise bewölkt.";
            break;
          case "cloudy":
            summary = summary! + " bewölkt.";
            break;
          case "fog":
            summary = summary! + " neblig.";
            break;
          case "wind":
            summary = summary! + " windig.";
            warning = true;
            break;
          case "rain":
            summary = summary! + " regnerisch.";
            warning = true;
            break;
          case "sleet":
            summary = summary! + " schneien.";
            warning = true;
            break;
          case "snow":
            summary = summary! + " schneien.";
            warning = true;
            break;
          case "hail":
            summary = summary! + " hageln.";
            warning = true;
            break;
          case "thunderstorm":
            summary = summary! + " gewittern.";
            warning = true;
            break;
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          icon ?? const Icon(Icons.cloudy_snowing, size: 32, color: Colors.white),
          const SmallHSpace(),
          Flexible(
            child: Small(
              text: summary ?? "Wetterinformationen sind aktuell noch nicht verfügbar.",
              color: Colors.white,
              context: context,
            ),
          ),
        ],
      ),
    );
  }
}
