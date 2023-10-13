import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/weather/messages.dart';
import 'package:priobike/weather/service.dart';

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
  void initState() {
    super.initState();
    weather = getIt<Weather>();
    weather.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    loadIcon();
    loadSummary();
    super.didChangeDependencies();
  }

  /// Load the weather icon from the weather service.
  Future<void> loadIcon() async {
    if (weather.current == null || weather.current!.icon == null) return;

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
    if (weather.current == null || weather.current!.temperature == null) return;

    summary = "";
    final temp = weather.current?.temperature ?? 0;
    if (temp > 40) {
      summary = "${summary!}Achtung vor extremer Hitze! ";
      warning = true;
    } else if (temp > 30) {
      summary = "${summary!}Achtung vor starker Hitze! ";
      warning = true;
    } else if (temp > 0) {
      // Do nothing.
    } else if (temp > -10) {
      summary = "${summary!}Kältewarnung! ";
      warning = true;
    } else {
      summary = "${summary!}Achtung vor extremer Kälte! ";
      warning = true;
    }
    switch (weather.current?.icon) {
      case "clear-day":
        summary = "${summary!}Es ist sonnig";
        break;
      case "clear-night":
        summary = "${summary!}Es ist klar";
        break;
      case "partly-cloudy-day":
        summary = "${summary!}Es ist teilweise bewölkt";
        break;
      case "partly-cloudy-night":
        summary = "${summary!}Es ist teilweise bewölkt";
        break;
      case "cloudy":
        summary = "${summary!}Es ist bewölkt";
        break;
      case "fog":
        summary = "${summary!}Es ist neblig";
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
    summary = "${summary!} bei ${temp.toStringAsFixed(1)}°C.";

    // Don't add the forecast to the summary if the display height is to small (resulting in an overflow).
    if (MediaQuery.of(context).size.height < 550) {
      return;
    }

    // Check if the icon changes in the forecast.
    for (final forecast in weather.forecast ?? <WeatherForecast>[]) {
      if (forecast.icon != weather.current?.icon) {
        // Convert the timestamp to a clock time.
        final clock = "${forecast.timestamp.hour.toString()}:${forecast.timestamp.minute.toString().padLeft(2, '0')}";
        final isTomorrow = forecast.timestamp.day != DateTime.now().day;
        summary = "${summary!}${isTomorrow ? ' Morgen' : ' Heute'} ab $clock Uhr";
        switch (forecast.icon) {
          case "clear-day":
            summary = "${summary!} wird es sonnig.";
            break;
          case "clear-night":
            summary = "${summary!} wird es klar.";
            break;
          case "partly-cloudy-day":
            summary = "${summary!} wird es teilweise bewölkt.";
            break;
          case "partly-cloudy-night":
            summary = "${summary!} wird es teilweise bewölkt.";
            break;
          case "cloudy":
            summary = "${summary!} wird es bewölkt.";
            break;
          case "fog":
            summary = "${summary!} wird es neblig.";
            break;
          case "wind":
            summary = "${summary!} wird es windig.";
            warning = true;
            break;
          case "rain":
            summary = "${summary!} wird Regen erwartet.";
            warning = true;
            break;
          case "sleet":
            summary = "${summary!} wird Schneeregen erwartet.";
            warning = true;
            break;
          case "snow":
            summary = "${summary!} wird Schneefall erwartet.";
            warning = true;
            break;
          case "hail":
            summary = "${summary!} wird Hagel erwartet.";
            warning = true;
            break;
          case "thunderstorm":
            summary = "${summary!} wird ein Gewitter erwartet.";
            warning = true;
            break;
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!weather.hasLoaded) return Container();

    return Expanded(
      child: Row(
        children: [
          weather.hadError
              ? const Icon(Icons.cloud_off_rounded, size: 32, color: Colors.white)
              : Stack(
                  children: [
                    icon ?? const Icon(Icons.cloudy_snowing, size: 32, color: Colors.white),
                    if (warning)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: CI.radkulturYellow,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: const Icon(Icons.warning_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
          const SmallHSpace(),
          Flexible(
            child: Small(
              text: summary ?? "Wetterinformationen sind aktuell nicht verfügbar.",
              color: Colors.white,
              context: context,
            ),
          ),
        ],
      ),
    );
  }
}
