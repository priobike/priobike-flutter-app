import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/colors.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/common/database/database.dart';

class TotalStatisticsView extends StatefulWidget {
  final RideSummary? rideSummary;

  const TotalStatisticsView({Key? key, this.rideSummary}) : super(key: key);

  @override
  State<TotalStatisticsView> createState() => TotalStatisticsViewState();
}

class TotalStatisticsViewState extends State<TotalStatisticsView> {
  /// padding for the rows used in the statistics view
  double paddingStats = 16.0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget renderDistanceStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
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
          value: (widget.rideSummary?.distance ?? 0) / 1000,
          icon: Icons.directions_bike_rounded,
          unit: "km",
        ),
      ),
    );
  }

  Widget renderDurationStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
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
          value: (widget.rideSummary?.duration ?? 0) / 60,
          icon: Icons.timer_outlined,
          unit: "min",
        ),
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
                text: "⌀ ${(widget.rideSummary?.averageSpeed.toInt() ?? 0).round()} km/h",
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            renderDistanceStats(),
            renderDurationStats(),
            renderSpeedStats(),
          ],
        ),
      ),
    );
  }
}
