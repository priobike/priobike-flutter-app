import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:provider/provider.dart';

class StatisticsElementView extends StatelessWidget {
  final IconData icon;
  final String title;
  final void Function()? onPressed;

  const StatisticsElementView({
    Key? key, 
    required this.icon, 
    required this.title, 
    this.onPressed,
    required BuildContext context
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tile(
      padding: const EdgeInsets.all(8),
      fill: Theme.of(context).colorScheme.background,
      onPressed: onPressed,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const Divider(),
          BoldSmall(text: title, maxLines: 4, context: context),
        ],
      ),
    );
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
            icon: Icons.info, 
            fill: Theme.of(context).colorScheme.background,
            splash: Colors.white,
            onPressed: () {
              // Show a small modal sheet explaining that the 
              // data is only stored on this device.
              showModalBottomSheet(
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
                      Content(text: "Die gezeigten Fahrtstatistiken werden nur auf diesem Gerät gespeichert. Sie werden nicht an einen Server gesendet.", context: context),
                    ],
                  ),
                )
              );
            },
          ),
          const SizedBox(width: 40),
        ]),
        GridView.count(
          primary: false,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          crossAxisCount: 2,
          padding: const EdgeInsets.all(24),
          children: [
            StatisticsElementView(
              icon: Icons.co2,
              title: "ca. ${(statistics.totalSavedCO2Kg)?.toStringAsFixed(1) ?? 0} kg\neingespart",
              context: context,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(child: BoldSubHeader(text: "Information zur CO2-Berechnung", context: context)),
                        const Divider(),
                        Content(
                          text: "Bei diesem Wert handelt es sich um eine Schätzung anhand deiner gefahrenen Distanz und einem durchschnittlichen CO2-Ausstoß von 118,7 g/km (Daten: Statista.com, 2021). Der tatsächliche CO2-Ausstoß kann je nach Fahrzeug und Fahrweise abweichen.", 
                          context: context,
                        ),
                      ],
                    ),
                  )
                );
              },
            ),
            StatisticsElementView(
              icon: Icons.directions_bike,
              title: "${((statistics.totalDistanceMeters ?? 0) / 1000).toStringAsFixed(2)} km",
              context: context,
            ),
            StatisticsElementView(
              icon: Icons.timer,
              title: "${Duration(seconds: (statistics.totalDurationSeconds ?? 0.0).toInt()).toString().split('.').first} Std.",
              context: context,
            ),
            StatisticsElementView(
              icon: Icons.speed,
              title: "⌀ ${(statistics.averageSpeedKmH?.toInt() ?? 0).round()} km/h",
              context: context,
            ),
          ],
        )
      ],
    );
  }
}