import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/colors.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:provider/provider.dart';

class TotalStatisticsView extends StatefulWidget {
  const TotalStatisticsView({Key? key}) : super(key: key);

  @override
  State<TotalStatisticsView> createState() => TotalStatisticsViewState();
}

class TotalStatisticsViewState extends State<TotalStatisticsView> {
  /// The statistics service, which is injected by the provider.
  late Statistics statistics;

  /// padding for the rows used in the statistics view
  double paddingStats = 16.0;

  @override
  void didChangeDependencies() {
    statistics = Provider.of<Statistics>(context);
    super.didChangeDependencies();
  }

  Container renderTableBorder() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromARGB(20, 1, 1, 1),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget renderInfoDialogBox() {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      title: BoldContent(text: "Fahrtstatistiken", context: context),
      content: Content(
          text:
              "Beim gezeigten CO2-Wert handelt es sich um eine Schätzung anhand deiner gefahrenen Distanz im Vergleich zu dem durchschnittlichen CO2-Ausstoß von 118,7 g/km bei neuzugelassenen Personenkraftwagen in Deutschland (Daten: Statista.com, 2021). Der tatsächliche CO2-Ausstoß kann je nach Fahrzeug und Fahrweise abweichen.",
          context: context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Alles klar"),
        ),
      ],
    );
  }

  Widget renderRideStats() {
    return Row(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(text: "Dein Fortschritt", context: context),
              const SizedBox(height: 4),
              Small(text: "Auf diesem Gerät", context: context),
            ],
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 48,
              height: 48,
              child: SmallIconButton(
                icon: Icons.info_outline_rounded,
                fill: Theme.of(context).colorScheme.background,
                splash: Colors.white,
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => renderInfoDialogBox(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget renderCo2Stats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Small(text: "CO2", context: context),
              ],
            ),
          ),
          const HSpace(),
          Expanded(child: Container()),
          Container(
            alignment: Alignment.centerRight,
            child: LevelView(
              levels: const [
                // Bronze levels
                Level(value: 0, title: "Öko-Kämpfer", color: Medals.bronze),
                Level(value: 1, title: "Grüner Riese", color: Medals.bronze),
                // Silver levels
                Level(value: 5, title: "Planetenschützer", color: Medals.silver),
                Level(value: 10, title: "Nachhaltigkeits-Star", color: Medals.silver),
                // Gold levels
                Level(value: 25, title: "Öko-Held", color: Medals.gold),
                Level(value: 50, title: "Umwelt-Retter", color: Medals.gold),
                // PrioBike (Blue) levels
                Level(value: 100, title: "Klima-Champion", color: Medals.priobike),
              ],
              value: (statistics.totalSavedCO2Kg ?? 0),
              icon: Icons.co2_rounded,
              unit: "kg",
            ),
          ),
        ],
      ),
    );
  }

  Widget renderDistanceStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Small(text: "Distanz", context: context),
              ],
            ),
          ),
          const HSpace(),
          Expanded(child: Container()),
          Container(
            alignment: Alignment.centerRight,
            child: LevelView(
              levels: const [
                // Bronze levels
                Level(value: 0, title: "Meilen-Mampfer", color: Medals.bronze),
                Level(value: 50, title: "Zweirad-Wanderer", color: Medals.bronze),
                // Silver levels
                Level(value: 100, title: "Radfahr-Begleiter", color: Medals.silver),
                Level(value: 150, title: "Fahrrad-Buddha", color: Medals.silver),
                // Gold levels
                Level(value: 250, title: "Velociped-Virtuose", color: Medals.gold),
                Level(value: 500, title: "Sattel-Kenner", color: Medals.gold),
                // PrioBike (Blue) levels
                Level(value: 1000, title: "Radfahr-Champion", color: Medals.priobike),
              ],
              value: (statistics.totalDistanceMeters ?? 0) / 1000,
              icon: Icons.directions_bike_rounded,
              unit: "km",
            ),
          ),
        ],
      ),
    );
  }

  Widget renderDurationStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Small(text: "Zeit", context: context),
              ],
            ),
          ),
          const HSpace(),
          Expanded(child: Container()),
          Container(
            alignment: Alignment.centerRight,
            child: LevelView(
              levels: const [
                // Bronze levels
                Level(value: 0, title: "Radel-Rookie", color: Medals.bronze),
                Level(value: 10, title: "Mittelstrecken-Fahrer", color: Medals.bronze),
                // Silver levels
                Level(value: 30, title: "Dauerläufer", color: Medals.silver),
                Level(value: 180, title: "Bike-Boss", color: Medals.silver),
                // Gold levels
                Level(value: 600, title: "Pedal-Powerhouse", color: Medals.gold),
                Level(value: 1200, title: "Tour de Force", color: Medals.gold),
                // PrioBike (Blue) levels
                Level(value: 3000, title: "Radrennen-Routinier", color: Medals.priobike),
              ],
              value: (statistics.totalDurationSeconds ?? 0.0) / 60,
              icon: Icons.timer_outlined,
              unit: "min",
            ),
          ),
        ],
      ),
    );
  }

  Widget renderSpeedStats() {
    return Row(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(
                text: "⌀ ${(statistics.averageSpeedKmH?.toInt() ?? 0).round()} km/h",
                context: context,
              ),
              const SizedBox(height: 4),
              Small(text: "Geschwindigkeit", context: context),
            ],
          ),
        ),
        const HSpace(),
        Expanded(child: Container()),
        Container(
          alignment: Alignment.centerRight,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.speed_rounded,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          renderRideStats(),
          renderTableBorder(),
          renderCo2Stats(),
          renderTableBorder(),
          renderDistanceStats(),
          renderTableBorder(),
          renderDurationStats(),
          renderTableBorder(),
          renderSpeedStats(),
        ],
      ),
    );
  }
}
