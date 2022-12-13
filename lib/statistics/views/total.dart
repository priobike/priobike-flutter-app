import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
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

  BoxDecoration renderTableBorder() {
    return const BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Color.fromARGB(20, 1, 1, 1),
          width: 1,
        ),
      ),
    );
  }

  Widget renderCo2DialogBox() {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      title: BoldContent(text: "Information zur CO2-Berechnung", context: context),
      content: Content(
          text:
              "Bei diesem Wert handelt es sich um eine Schätzung anhand deiner gefahrenen Distanz und einem durchschnittlichen CO2-Ausstoß von 118,7 g/km (Daten: Statista.com, 2021). Der tatsächliche CO2-Ausstoß kann je nach Fahrzeug und Fahrweise abweichen.",
          context: context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Alles klar"),
        ),
      ],
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
              "Die gezeigten Fahrtstatistiken werden nur auf diesem Gerät gespeichert. Sie werden nicht an einen Server gesendet.",
          context: context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Alles klar"),
        ),
      ],
    );
  }

  TableRow renderRideStats() {
    return TableRow(
      decoration: renderTableBorder(),
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(text: "Fahrtstatistiken", context: context),
              const SizedBox(height: 4),
              Small(text: "Auf diesem Gerät", context: context),
            ],
          ),
        ),
        Container(
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
      ],
    );
  }

  TableRow renderCo2Stats() {
    return TableRow(
      decoration: renderTableBorder(),
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(
                text: (statistics.totalSavedCO2Kg ?? 0) < 1
                    ? "${((statistics.totalSavedCO2Kg ?? 0) * 1000).toStringAsFixed(1)} g"
                    : "${(statistics.totalSavedCO2Kg)?.toStringAsFixed(1) ?? 0} kg",
                context: context,
              ),
              const SizedBox(height: 4),
              Small(text: "CO2 eingespart", context: context),
            ],
          ),
        ),
        Container(
          alignment: Alignment.centerRight,
          child: Container(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 48,
              height: 48,
              child: SmallIconButton(
                icon: Icons.co2_rounded,
                fill: Theme.of(context).colorScheme.background,
                splash: Colors.white,
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => renderCo2DialogBox(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow renderDistanceStats() {
    return TableRow(
      decoration: renderTableBorder(),
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(
                text: (statistics.totalDistanceMeters ?? 0) >= 1000
                    ? "${((statistics.totalDistanceMeters ?? 0) / 1000).toStringAsFixed(2)} km"
                    : "${(statistics.totalDistanceMeters ?? 0).toStringAsFixed(0)} m",
                context: context,
              ),
              const SizedBox(height: 4),
              Small(text: "Gefahre Distanz", context: context),
            ],
          ),
        ),
        Container(
          alignment: Alignment.centerRight,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.directions_bike_rounded,
            ),
          ),
        ),
      ],
    );
  }

  TableRow renderDurationStats() {
    return TableRow(
      decoration: renderTableBorder(),
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: paddingStats, bottom: paddingStats),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(
                text: (statistics.totalDurationSeconds ?? 0.0) >= 3600
                    ? "${Duration(seconds: (statistics.totalDurationSeconds ?? 0.0).toInt()).toString().split('.').first} Std."
                    : "${((statistics.totalDurationSeconds ?? 0) / 60).toStringAsFixed(0)} Min.",
                context: context,
              ),
              const SizedBox(height: 4),
              Small(text: "Gefahre Zeit", context: context),
            ],
          ),
        ),
        Container(
          alignment: Alignment.centerRight,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.timer_outlined,
            ),
          ),
        ),
      ],
    );
  }

  TableRow renderSpeedStats() {
    return TableRow(
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
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          renderRideStats(),
          renderCo2Stats(),
          renderDistanceStats(),
          renderDurationStats(),
          renderSpeedStats(),
        ],
      ),
    );
  }
}
