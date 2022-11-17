import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:provider/provider.dart';

class StatisticsElementView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final void Function()? onPressed;

  const StatisticsElementView({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onPressed,
    required BuildContext context,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(),
      const SmallVSpace(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldSmall(text: title, maxLines: 1, context: context),
              const SizedBox(height: 4),
              Small(text: subtitle, context: context),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: 32),
          ),
        ],
      ),
      const SmallVSpace(),
    ]);
  }
}

class TotalStatisticsView extends StatefulWidget {
  const TotalStatisticsView({Key? key}) : super(key: key);

  @override
  State<TotalStatisticsView> createState() => TotalStatisticsViewState();
}

class TotalStatisticsViewState extends State<TotalStatisticsView> {
  /// The statistics service, which is injected by the provider.
  late Statistics statistics;

  @override
  void didChangeDependencies() {
    statistics = Provider.of<Statistics>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const SizedBox(width: 40),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BoldContent(text: "Fahrtstatistiken", context: context),
            const SizedBox(height: 4),
            Small(text: "Auf diesem Gerät", context: context),
          ]),
          Expanded(child: Container()),
          SmallIconButton(
            icon: Icons.info_outline_rounded,
            fill: Theme.of(context).colorScheme.background,
            splash: Colors.white,
            onPressed: () {
              // Show a small modal sheet explaining that the
              // data is only stored on this device.
              showAppSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(child: BoldSubHeader(text: "Information zu Fahrtstatistiken", context: context)),
                      const SizedBox(height: 4),
                      BoldContent(text: "auf diesem Gerät", context: context),
                      const Divider(),
                      Content(
                          text:
                              "Die gezeigten Fahrtstatistiken werden nur auf diesem Gerät gespeichert. Sie werden nicht an einen Server gesendet.",
                          context: context),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 40),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SmallVSpace(),
              StatisticsElementView(
                icon: Icons.co2_rounded,
                title: "${(statistics.totalSavedCO2Kg)?.toStringAsFixed(1) ?? 0} kg",
                subtitle: "CO2 eingespart",
                context: context,
                onPressed: () {
                  showAppSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(child: BoldSubHeader(text: "Information zur CO2-Berechnung", context: context)),
                          const Divider(),
                          Content(
                            text:
                                "Bei diesem Wert handelt es sich um eine Schätzung anhand deiner gefahrenen Distanz und einem durchschnittlichen CO2-Ausstoß von 118,7 g/km (Daten: Statista.com, 2021). Der tatsächliche CO2-Ausstoß kann je nach Fahrzeug und Fahrweise abweichen.",
                            context: context,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              StatisticsElementView(
                icon: Icons.directions_bike_rounded,
                title: "${((statistics.totalDistanceMeters ?? 0) / 1000).toStringAsFixed(2)} km",
                subtitle: "Gefahrene Distanz",
                context: context,
              ),
              StatisticsElementView(
                icon: Icons.timer_outlined,
                title:
                    "${Duration(seconds: (statistics.totalDurationSeconds ?? 0.0).toInt()).toString().split('.').first} Std.",
                subtitle: "Gefahrene Zeit",
                context: context,
              ),
              StatisticsElementView(
                icon: Icons.speed_rounded,
                title: "⌀ ${(statistics.averageSpeedKmH?.toInt() ?? 0).round()} km/h",
                subtitle: "Durchschnittsgeschwindigkeit",
                context: context,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
